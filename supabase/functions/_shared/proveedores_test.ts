import { assert, assertEquals, assertThrows } from "@std/assert";
import {
  elegirProveedor,
  ENTORNOS,
  ErrorDeConfiguracion,
  INTEGRACIONES,
  leerConfiguracion,
  SIMULADO,
  VARIABLE_DE_PROVEEDOR,
} from "./proveedores.ts";

/** Lectura falsa del entorno: solo existen las variables que se pasan. */
function entorno(variables: Record<string, string>) {
  return (nombre: string) => variables[nombre];
}

/** Todas las integraciones con el mismo proveedor. */
function todos(proveedor: string): Record<string, string> {
  return Object.fromEntries(
    INTEGRACIONES.map((i) => [VARIABLE_DE_PROVEEDOR[i], proveedor]),
  );
}

const TODOS_REALES = todos("real");

/** Implementaciones de prueba que dicen quién las creó. */
const implementaciones = {
  simulado: () => "implementación simulada",
  alpaca: () => "implementación real",
};

function problemasDe(fn: () => unknown): string[] {
  const error = assertThrows(fn, ErrorDeConfiguracion);
  return (error as ErrorDeConfiguracion).problemas;
}

// Lectura de la configuración -------------------------------------------------------------

Deno.test("sin variables, el entorno es local y todo es simulado", () => {
  const configuracion = leerConfiguracion(entorno({}));
  assertEquals(configuracion.entorno, "local");
  for (const integracion of INTEGRACIONES) {
    assertEquals(configuracion.proveedores[integracion], SIMULADO);
  }
});

Deno.test("la variable de cada integración elige su proveedor", () => {
  const configuracion = leerConfiguracion(entorno({
    ENTORNO: "demo",
    PROVEEDOR_BROKER: "alpaca",
    PROVEEDOR_MERCADO: "alpaca",
    PROVEEDOR_NOTICIAS: "alpaca",
    PROVEEDOR_CONTEXTO: "deepseek",
    PROVEEDOR_JEV: "typesafe",
    PROVEEDOR_PUSH: "fcm",
  }));
  assertEquals(configuracion.entorno, "demo");
  assertEquals(configuracion.proveedores, {
    broker: "alpaca",
    mercado: "alpaca",
    noticias: "alpaca",
    contexto: "deepseek",
    jev: "typesafe",
    push: "fcm",
  });
});

Deno.test("las seis integraciones tienen su variable PROVEEDOR_*", () => {
  assertEquals(
    INTEGRACIONES.map((i) => VARIABLE_DE_PROVEEDOR[i]),
    [
      "PROVEEDOR_BROKER",
      "PROVEEDOR_MERCADO",
      "PROVEEDOR_NOTICIAS",
      "PROVEEDOR_CONTEXTO",
      "PROVEEDOR_JEV",
      "PROVEEDOR_PUSH",
    ],
  );
});

Deno.test("los valores se normalizan: espacios y mayúsculas no cambian el proveedor", () => {
  const configuracion = leerConfiguracion(entorno({
    ENTORNO: " CI ",
    PROVEEDOR_BROKER: " Alpaca\n",
  }));
  assertEquals(configuracion.entorno, "ci");
  assertEquals(configuracion.proveedores.broker, "alpaca");
});

Deno.test("una variable vacía cuenta como no definida", () => {
  const configuracion = leerConfiguracion(
    entorno({ ENTORNO: "", PROVEEDOR_BROKER: "  " }),
  );
  assertEquals(configuracion.entorno, "local");
  assertEquals(configuracion.proveedores.broker, SIMULADO);
});

Deno.test("un ENTORNO desconocido es un error y no copia el valor", () => {
  const problemas = problemasDe(() =>
    leerConfiguracion(entorno({ ENTORNO: "produccion-secreta" }))
  );
  assertEquals(problemas, [`ENTORNO no es uno de: ${ENTORNOS.join(", ")}`]);
  assert(!problemas.join().includes("produccion-secreta"));
});

Deno.test("lee Deno.env cuando no se le pasa una lectura", () => {
  const nombres = ["ENTORNO", "PROVEEDOR_BROKER"];
  const antes = nombres.map((n) => Deno.env.get(n));
  try {
    Deno.env.set("ENTORNO", "ci");
    Deno.env.set("PROVEEDOR_BROKER", "alpaca");
    const configuracion = leerConfiguracion();
    assertEquals(configuracion.entorno, "ci");
    assertEquals(configuracion.proveedores.broker, "alpaca");
  } finally {
    nombres.forEach((n, i) => {
      if (antes[i] === undefined) Deno.env.delete(n);
      else Deno.env.set(n, antes[i]);
    });
  }
});

// CB-91: un simulado en el proyecto MVP --------------------------------------------------

Deno.test("CB-91: ENTORNO=mvp con todo real arranca", () => {
  const configuracion = leerConfiguracion(
    entorno({ ENTORNO: "mvp", ...TODOS_REALES }),
  );
  assertEquals(configuracion.entorno, "mvp");
});

Deno.test("CB-91: ENTORNO=mvp con un proveedor simulado no arranca y dice cuál", () => {
  const problemas = problemasDe(() =>
    leerConfiguracion(entorno({
      ENTORNO: "mvp",
      ...TODOS_REALES,
      PROVEEDOR_JEV: "simulado",
    }))
  );
  assertEquals(problemas, [
    "ENTORNO=mvp no admite proveedores simulados: PROVEEDOR_JEV",
  ]);
});

Deno.test("CB-91: ENTORNO=mvp con todo simulado nombra las seis variables", () => {
  const problemas = problemasDe(() =>
    leerConfiguracion(entorno({ ENTORNO: "mvp", ...todos("simulado") }))
  );
  assertEquals(problemas, [
    `ENTORNO=mvp no admite proveedores simulados: ${
      INTEGRACIONES.map((i) => VARIABLE_DE_PROVEEDOR[i]).join(", ")
    }`,
  ]);
});

Deno.test("CB-91: en mvp una variable olvidada cuenta como simulada", () => {
  const { PROVEEDOR_PUSH: _olvidada, ...restantes } = TODOS_REALES;
  const problemas = problemasDe(() =>
    leerConfiguracion(entorno({ ENTORNO: "mvp", ...restantes }))
  );
  assertEquals(problemas, [
    "ENTORNO=mvp no admite proveedores simulados: PROVEEDOR_PUSH",
  ]);
});

Deno.test("CB-91: 'Simulado' en mayúsculas o con espacios tampoco pasa en mvp", () => {
  problemasDe(() =>
    leerConfiguracion(entorno({
      ENTORNO: "MVP",
      ...TODOS_REALES,
      PROVEEDOR_BROKER: " Simulado ",
    }))
  );
});

Deno.test("CB-91: fuera de mvp los simulados sí se admiten", () => {
  for (const nombre of ENTORNOS.filter((e) => e !== "mvp")) {
    leerConfiguracion(entorno({ ENTORNO: nombre, ...todos("simulado") }));
  }
});

// Elección de la implementación ------------------------------------------------------------

Deno.test("con PROVEEDOR_BROKER=simulado entrega la implementación simulada", () => {
  const broker = elegirProveedor(
    "broker",
    implementaciones,
    entorno({ ENTORNO: "ci", PROVEEDOR_BROKER: "simulado" }),
  );
  assertEquals(broker, "implementación simulada");
});

Deno.test("sin la variable entrega la implementación simulada", () => {
  assertEquals(
    elegirProveedor("broker", implementaciones, entorno({})),
    "implementación simulada",
  );
});

Deno.test("con PROVEEDOR_BROKER=alpaca entrega la implementación real", () => {
  const broker = elegirProveedor(
    "broker",
    implementaciones,
    entorno({ PROVEEDOR_BROKER: "alpaca" }),
  );
  assertEquals(broker, "implementación real");
});

Deno.test("cada integración lee su propia variable", () => {
  const variables = { PROVEEDOR_MERCADO: "alpaca" };
  assertEquals(
    elegirProveedor("mercado", implementaciones, entorno(variables)),
    "implementación real",
  );
  assertEquals(
    elegirProveedor("noticias", implementaciones, entorno(variables)),
    "implementación simulada",
  );
});

Deno.test("solo crea la implementación elegida", () => {
  const creadas: string[] = [];
  const broker = elegirProveedor(
    "broker",
    {
      simulado: () => {
        creadas.push("simulado");
        return 1;
      },
      alpaca: () => {
        creadas.push("alpaca");
        return 2;
      },
    },
    entorno({ PROVEEDOR_BROKER: "alpaca" }),
  );
  assertEquals(broker, 2);
  assertEquals(creadas, ["alpaca"]);
});

Deno.test("un proveedor que no está registrado es un error y no copia el valor", () => {
  const problemas = problemasDe(() =>
    elegirProveedor(
      "broker",
      implementaciones,
      entorno({ PROVEEDOR_BROKER: "llave-pegada-por-error" }),
    )
  );
  assertEquals(problemas, ["PROVEEDOR_BROKER no es uno de: simulado, alpaca"]);
  assert(!problemas.join().includes("llave-pegada-por-error"));
});

Deno.test("un valor como 'constructor' no se toma por un proveedor", () => {
  for (const valor of ["constructor", "__proto__"]) {
    problemasDe(() =>
      elegirProveedor(
        "broker",
        implementaciones,
        entorno({ PROVEEDOR_BROKER: valor }),
      )
    );
  }
});

Deno.test("CB-91: en mvp no entrega ni el real si otra integración es simulada", () => {
  const problemas = problemasDe(() =>
    elegirProveedor(
      "broker",
      implementaciones,
      entorno({
        ENTORNO: "mvp",
        ...todos("alpaca"),
        PROVEEDOR_NOTICIAS: "simulado",
      }),
    )
  );
  assertEquals(problemas, [
    "ENTORNO=mvp no admite proveedores simulados: PROVEEDOR_NOTICIAS",
  ]);
});

Deno.test("CB-91: en mvp con todo real entrega la implementación real", () => {
  assertEquals(
    elegirProveedor(
      "broker",
      implementaciones,
      entorno({ ENTORNO: "mvp", ...todos("alpaca") }),
    ),
    "implementación real",
  );
});

// supabase/functions/.env.e2e ----------------------------------------------------------------

Deno.test(".env.e2e: ENTORNO=ci, todos los PROVEEDOR_* simulados y ninguna llave", async () => {
  const texto = await Deno.readTextFile(
    new URL("../.env.e2e", import.meta.url),
  );
  const variables: Record<string, string> = {};
  for (const linea of texto.split(/\r?\n/)) {
    const limpia = linea.trim();
    if (limpia === "" || limpia.startsWith("#")) continue;
    const coincidencia = /^([A-Z][A-Z0-9_]*)=(.*)$/.exec(limpia);
    assert(coincidencia, `línea que no es NOMBRE=valor: ${limpia}`);
    variables[coincidencia[1]] = coincidencia[2];
  }

  assertEquals(variables.ENTORNO, "ci");
  for (const integracion of INTEGRACIONES) {
    assertEquals(variables[VARIABLE_DE_PROVEEDOR[integracion]], SIMULADO);
  }
  // Sin secretos: ninguna de las variables que docs/05 §10.1 guarda como secretos.
  const secretos = [
    "ALPACA_KEY_ID",
    "ALPACA_SECRET_KEY",
    "DEEPSEEK_API_KEY",
    "TYPESAFE_API_KEY",
    "CLOUDFLARE_API_TOKEN",
    "FCM_CUENTA_SERVICIO",
    "SECRETO_INTERNO",
  ];
  assertEquals(secretos.filter((nombre) => nombre in variables), []);
  // Y es una configuración que arranca.
  assertEquals(leerConfiguracion((n) => variables[n]).entorno, "ci");
});
