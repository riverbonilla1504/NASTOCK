import { assert, assertEquals, assertRejects } from "@std/assert";
import { type Argumento, type Bd, ErrorDeBd } from "../_shared/bd.ts";
import {
  type Barra,
  type ConsultaDeBarras,
  ErrorDeProveedor,
  type ProveedorDeMercado,
  type ResultadoDeBarras,
} from "../_shared/mercado/interfaz.ts";
import { MercadoSimulado } from "../_shared/mercado/simulado.ts";
import {
  cargarHistoria,
  ErrorDeCarga,
  TAMANO_DE_LOTE,
} from "./carga_historica.ts";

/** Base falsa con la misma semántica que las funciones de private de la historia. */
class BdFalsa implements Bd {
  /** Barras guardadas, por "símbolo fecha". */
  readonly barras = new Map<string, Barra>();
  readonly llamadas: { funcion: string; argumentos: readonly Argumento[] }[] =
    [];
  cerrada = false;

  constructor(
    readonly universo: string[],
    private readonly ahora: Date,
    simbolosConHistoria: string[] = [],
  ) {
    for (const simbolo of simbolosConHistoria) {
      this.barras.set(`${simbolo} 2024-11-05`, {
        simbolo,
        fecha: "2024-11-05",
        apertura: 1,
        maximo: 1,
        minimo: 1,
        cierre: 1,
        volumen: 1,
      });
    }
  }

  llamar<T = Record<string, unknown>>(
    funcion: string,
    argumentos: readonly Argumento[] = [],
  ): Promise<T[]> {
    this.llamadas.push({ funcion, argumentos });
    switch (funcion) {
      case "ahora":
        return Promise.resolve([{ ahora: this.ahora }] as T[]);
      case "simbolos_sin_historia": {
        const conHistoria = new Set(
          [...this.barras.values()].map((b) => b.simbolo),
        );
        return Promise.resolve(
          this.universo.filter((s) => !conHistoria.has(s)).map((simbolo) => ({
            simbolo,
          })) as T[],
        );
      }
      case "guardar_barras_diarias": {
        let nuevas = 0;
        for (const barra of argumentos[0] as Barra[]) {
          const clave = `${barra.simbolo} ${barra.fecha}`;
          if (!this.barras.has(clave)) {
            this.barras.set(clave, barra);
            nuevas++;
          }
        }
        return Promise.resolve([{ guardar_barras_diarias: nuevas }] as T[]);
      }
      default:
        return Promise.reject(new ErrorDeBd(`función inesperada: ${funcion}`));
    }
  }

  cerrar(): Promise<void> {
    this.cerrada = true;
    return Promise.resolve();
  }

  /** Cantidad de barras guardadas de un símbolo. */
  cuantas(simbolo: string): number {
    return [...this.barras.values()].filter((b) => b.simbolo === simbolo)
      .length;
  }
}

/** Proveedor que anota las consultas y delega en el simulado (o falla cuando se le pide). */
function proveedorEspia(opciones: {
  fallaEnLaLlamada?: number;
  errorDeFalla?: Error;
  descartadasPorLote?: number;
  sinBarras?: string[];
} = {}) {
  const consultas: ConsultaDeBarras[] = [];
  const simulado = new MercadoSimulado();
  const proveedor: ProveedorDeMercado = {
    snapshots: simulado.snapshots.bind(simulado),
    async barras(consulta): Promise<ResultadoDeBarras> {
      consultas.push(consulta);
      if (opciones.fallaEnLaLlamada === consultas.length) {
        throw opciones.errorDeFalla ??
          new ErrorDeProveedor("Alpaca respondió 429", 429);
      }
      const resultado = await simulado.barras({
        ...consulta,
        simbolos: consulta.simbolos.filter((s) =>
          !opciones.sinBarras?.includes(s)
        ),
      });
      return {
        barras: resultado.barras,
        descartadas: opciones.descartadasPorLote ?? 0,
      };
    },
  };
  return { proveedor, consultas };
}

const AHORA = new Date("2026-11-05T15:00:00Z"); // 10:00 en Nueva York
const universo = (n: number) =>
  Array.from({ length: n }, (_, i) => `S${String(i).padStart(2, "0")}`);

Deno.test("carga solo los símbolos sin historia, en lotes de 20, entre hace dos años y ayer", async () => {
  const todos = universo(45);
  const bd = new BdFalsa(todos, AHORA, todos.slice(0, 5)); // 5 ya tienen historia
  const { proveedor, consultas } = proveedorEspia();

  const resultado = await cargarHistoria({ bd, mercado: proveedor });

  assertEquals(resultado.desde, "2024-11-05");
  assertEquals(resultado.hasta, "2026-11-04");
  assertEquals(resultado.simbolos_consultados, 40);
  assertEquals(resultado.pendientes, []);
  assertEquals(resultado.sin_datos, []);
  assertEquals(consultas.map((c) => c.simbolos.length), [20, 20]);
  assertEquals(consultas[0].simbolos, todos.slice(5, 25));
  assertEquals(
    consultas.every((c) =>
      c.desde === "2024-11-05" && c.hasta === "2026-11-04"
    ),
    true,
  );
  assertEquals(resultado.barras_recibidas, resultado.barras_nuevas);
  assert(
    resultado.barras_nuevas > 40 * 500,
    `${resultado.barras_nuevas} barras`,
  );
  assertEquals(TAMANO_DE_LOTE, 20);

  // La hora salió de private.ahora() y la ventana se la pasó a simbolos_sin_historia.
  assertEquals(bd.llamadas[0].funcion, "ahora");
  assertEquals(bd.llamadas[1], {
    funcion: "simbolos_sin_historia",
    argumentos: ["2024-11-05"],
  });
  for (const simbolo of todos.slice(5)) {
    assert(bd.cuantas(simbolo) > 500, simbolo);
  }
});

Deno.test("segunda ejecución: no pide nada y no duplica barras (CA-3)", async () => {
  const todos = universo(25);
  const bd = new BdFalsa(todos, AHORA);
  const { proveedor, consultas } = proveedorEspia();

  const primera = await cargarHistoria({ bd, mercado: proveedor });
  const guardadas = bd.barras.size;
  const llamadasAntes = consultas.length;
  const segunda = await cargarHistoria({ bd, mercado: proveedor });

  assert(primera.barras_nuevas > 0);
  assertEquals(segunda.simbolos_consultados, 0);
  assertEquals(segunda.barras_nuevas, 0);
  assertEquals(segunda.pendientes, []);
  assertEquals(consultas.length, llamadasAntes);
  assertEquals(bd.barras.size, guardadas);
});

Deno.test("guardar las mismas barras otra vez no duplica (CA-3, a través de la función)", async () => {
  const bd = new BdFalsa(["S00"], AHORA);
  const { proveedor } = proveedorEspia();
  const { barras } = await proveedor.barras({
    simbolos: ["S00"],
    desde: "2026-01-05",
    hasta: "2026-01-09",
  });
  const [{ guardar_barras_diarias: primera }] = await bd.llamar<
    { guardar_barras_diarias: number }
  >(
    "guardar_barras_diarias",
    [barras],
  );
  const [{ guardar_barras_diarias: segunda }] = await bd.llamar<
    { guardar_barras_diarias: number }
  >(
    "guardar_barras_diarias",
    [barras],
  );
  assertEquals([primera, segunda], [5, 0]);
});

Deno.test("las fechas son de Nueva York: a las 02:00 UTC todavía es el día anterior", async () => {
  // 2026-11-06 02:00 UTC = 2026-11-05 21:00 en Nueva York.
  const bd = new BdFalsa(["S00"], new Date("2026-11-06T02:00:00Z"));
  const { proveedor, consultas } = proveedorEspia();
  const resultado = await cargarHistoria({ bd, mercado: proveedor });
  assertEquals([resultado.desde, resultado.hasta], [
    "2024-11-05",
    "2026-11-04",
  ]);
  assertEquals([consultas[0].desde, consultas[0].hasta], [
    "2024-11-05",
    "2026-11-04",
  ]);
});

Deno.test("el 29 de febrero, hace dos años es el 28", async () => {
  const bd = new BdFalsa(["S00"], new Date("2028-02-29T15:00:00Z"));
  const { proveedor } = proveedorEspia();
  const resultado = await cargarHistoria({ bd, mercado: proveedor });
  assertEquals([resultado.desde, resultado.hasta], [
    "2026-02-28",
    "2028-02-28",
  ]);
});

Deno.test("sin símbolos pendientes, no llama al proveedor", async () => {
  const bd = new BdFalsa([], AHORA);
  const { proveedor, consultas } = proveedorEspia();
  const resultado = await cargarHistoria({ bd, mercado: proveedor });
  assertEquals(resultado.simbolos_consultados, 0);
  assertEquals(consultas.length, 0);
});

Deno.test("se acabó el tiempo: no empieza lotes nuevos y devuelve los pendientes", async () => {
  const todos = universo(45);
  const bd = new BdFalsa(todos, AHORA);
  const { proveedor, consultas } = proveedorEspia();
  // Cada lectura del reloj avanza 60 s: el primer lote entra y el segundo ya no.
  let ahoraMs = 0;
  const reloj = () => {
    const actual = ahoraMs;
    ahoraMs += 60_000;
    return actual;
  };

  const resultado = await cargarHistoria({
    bd,
    mercado: proveedor,
    reloj,
    presupuestoMs: 100_000,
  });

  assertEquals(consultas.length, 1);
  assertEquals(resultado.simbolos_consultados, 20);
  assertEquals(resultado.pendientes, todos.slice(20));
});

Deno.test("el proveedor falla a la mitad: se conserva lo guardado y se informan los pendientes", async () => {
  const todos = universo(45);
  const bd = new BdFalsa(todos, AHORA);
  const { proveedor } = proveedorEspia({ fallaEnLaLlamada: 2 });

  const error = await assertRejects(
    () => cargarHistoria({ bd, mercado: proveedor }),
    ErrorDeCarga,
    "429",
  );
  const parcial = (error as ErrorDeCarga).parcial;

  assertEquals(parcial.simbolos_consultados, 20);
  assertEquals(parcial.pendientes, todos.slice(20));
  assert(parcial.barras_nuevas > 0);
  assertEquals(bd.cuantas("S00") > 500, true); // lo del primer lote quedó guardado
  assertEquals(bd.cuantas("S25"), 0);
});

Deno.test("un error que no es del proveedor se propaga tal cual", async () => {
  const bd = new BdFalsa(universo(3), AHORA);
  const { proveedor } = proveedorEspia({
    fallaEnLaLlamada: 1,
    errorDeFalla: new TypeError("bug"),
  });
  await assertRejects(
    () => cargarHistoria({ bd, mercado: proveedor }),
    TypeError,
    "bug",
  );
});

Deno.test("un error de la base se propaga", async () => {
  const bd = new BdFalsa(universo(3), AHORA);
  bd.llamar = () => Promise.reject(new ErrorDeBd("private.ahora falló"));
  const { proveedor } = proveedorEspia();
  await assertRejects(
    () => cargarHistoria({ bd, mercado: proveedor }),
    ErrorDeBd,
  );
});

Deno.test("informa los símbolos sin datos y las barras descartadas", async () => {
  const bd = new BdFalsa(universo(4), AHORA);
  const { proveedor } = proveedorEspia({
    sinBarras: ["S01", "S03"],
    descartadasPorLote: 3,
  });
  const resultado = await cargarHistoria({ bd, mercado: proveedor });
  assertEquals(resultado.sin_datos, ["S01", "S03"]);
  assertEquals(resultado.barras_descartadas, 3);
  assertEquals(bd.cuantas("S01"), 0);
  assert(bd.cuantas("S00") > 500);
});
