// Proveedor de mercado real: Alpaca Market Data, feed IEX (docs/10 §1, §12).
//
// Barras diarias: GET {urlDatos}/v2/stocks/bars   (varios símbolos por llamada, con páginas)
// Cotizaciones:   GET {urlDatos}/v2/stocks/snapshots
//
// Las llaves viajan solo en las cabeceras APCA-API-KEY-ID y APCA-API-SECRET-KEY; nunca en la
// URL ni en los mensajes de error (CLAUDE.md, invariantes). Toda respuesta se valida con zod
// (docs/05 §2, A5). Si Alpaca falla, se lanza ErrorDeProveedor: no se reintenta a ciegas;
// la carga es idempotente y la siguiente ejecución retoma lo que falte.

import { z } from "../esquemas.ts";
import {
  type Barra,
  type ConsultaDeBarras,
  type Cotizacion,
  ErrorDeProveedor,
  esBarraCoherente,
  type ProveedorDeMercado,
  type ResultadoDeBarras,
} from "./interfaz.ts";
import { fechaDeNuevaYork } from "./tiempo.ts";

export interface ConfiguracionDeAlpaca {
  /** Normalmente https://data.alpaca.markets (ALPACA_DATA_URL). */
  urlDatos: string;
  /** ALPACA_KEY_ID. */
  keyId: string;
  /** ALPACA_SECRET_KEY. */
  secretKey: string;
  /** Para las pruebas: reemplaza a `fetch`. */
  fetch?: typeof fetch;
  /** Milisegundos máximos por solicitud. */
  tiempoMaximoMs?: number;
}

const TIEMPO_MAXIMO_POR_DEFECTO_MS = 15_000;
/** Tope de páginas por consulta: evita un ciclo si la API repitiera el token. */
const MAXIMO_DE_PAGINAS = 200;
/** Barras por página que se piden (el máximo de Alpaca). */
const BARRAS_POR_PAGINA = 10_000;

const esquemaBarra = z.object({
  t: z.string(),
  o: z.number(),
  h: z.number(),
  l: z.number(),
  c: z.number(),
  v: z.number(),
});

const esquemaPaginaDeBarras = z.object({
  // Con varios símbolos llega `{}`; sin datos, a veces `null`. Cada barra se valida aparte.
  bars: z.record(z.array(z.unknown())).nullable().optional(),
  next_page_token: z.string().nullable().optional(),
});

const esquemaOperacion = z.object({ t: z.string(), p: z.number() });
const esquemaCotizacion = z.object({ bp: z.number(), ap: z.number() });
const esquemaBarraDeResumen = z.object({
  c: z.number().optional(),
  v: z.number().optional(),
});

const esquemaBarraDeMinuto = z.object({
  t: z.string(),
  o: z.number(),
  h: z.number(),
  l: z.number(),
  c: z.number(),
  v: z.number(),
});

const esquemaSnapshot = z.object({
  minuteBar: z.unknown().optional(),
  latestTrade: esquemaOperacion.nullable().optional(),
  latestQuote: esquemaCotizacion.nullable().optional(),
  dailyBar: esquemaBarraDeResumen.nullable().optional(),
  prevDailyBar: esquemaBarraDeResumen.nullable().optional(),
});

const esquemaSnapshots = z.record(esquemaSnapshot);

export class MercadoAlpaca implements ProveedorDeMercado {
  readonly #configuracion: ConfiguracionDeAlpaca;

  constructor(configuracion: ConfiguracionDeAlpaca) {
    if (
      !configuracion.keyId || !configuracion.secretKey ||
      !configuracion.urlDatos
    ) {
      throw new ErrorDeProveedor(
        "Faltan ALPACA_KEY_ID, ALPACA_SECRET_KEY o ALPACA_DATA_URL para usar Alpaca",
      );
    }
    this.#configuracion = configuracion;
  }

  async barras(consulta: ConsultaDeBarras): Promise<ResultadoDeBarras> {
    const simbolos = [...new Set(consulta.simbolos)].sort();
    if (simbolos.length === 0 || consulta.desde > consulta.hasta) {
      return { barras: [], descartadas: 0 };
    }

    // `end` incluye todo el día: la barra diaria lleva la hora de la medianoche de Nueva York.
    const parametros = new URLSearchParams({
      symbols: simbolos.join(","),
      timeframe: "1Day",
      start: `${consulta.desde}T00:00:00Z`,
      end: `${consulta.hasta}T23:59:59Z`,
      limit: String(BARRAS_POR_PAGINA),
      adjustment: "split",
      feed: "iex",
      sort: "asc",
    });

    const pedidas = new Set(simbolos);
    const vistas = new Set<string>();
    const barras: Barra[] = [];
    let descartadas = 0;
    let token: string | null = null;

    for (let pagina = 0; pagina < MAXIMO_DE_PAGINAS; pagina++) {
      if (token) parametros.set("page_token", token);
      const cuerpo = await this.#pedir("/v2/stocks/bars", parametros);
      const datos = interpretar(esquemaPaginaDeBarras, cuerpo, "barras");

      for (const [simbolo, lista] of Object.entries(datos.bars ?? {})) {
        if (!pedidas.has(simbolo)) continue;
        for (const crudo of lista) {
          const barra = aBarra(simbolo, crudo);
          if (!barra || !esBarraCoherente(barra)) {
            descartadas++;
            continue;
          }
          const clave = `${simbolo} ${barra.fecha}`;
          if (vistas.has(clave)) continue;
          vistas.add(clave);
          barras.push(barra);
        }
      }

      token = datos.next_page_token ?? null;
      if (!token) break;
      if (pagina === MAXIMO_DE_PAGINAS - 1) {
        throw new ErrorDeProveedor(
          "Alpaca devolvió demasiadas páginas de barras",
        );
      }
    }

    barras.sort((a, b) =>
      a.simbolo === b.simbolo
        ? a.fecha.localeCompare(b.fecha)
        : a.simbolo.localeCompare(b.simbolo)
    );
    return { barras, descartadas };
  }

  async snapshots(
    simbolos: readonly string[],
    _ahora: Date,
  ): Promise<Cotizacion[]> {
    const lista = [...new Set(simbolos)].sort();
    if (lista.length === 0) return [];
    const cuerpo = await this.#pedir(
      "/v2/stocks/snapshots",
      new URLSearchParams({ symbols: lista.join(","), feed: "iex" }),
    );
    const datos = interpretar(esquemaSnapshots, cuerpo, "cotizaciones");

    const cotizaciones: Cotizacion[] = [];
    for (const simbolo of lista) {
      const snapshot = datos[simbolo];
      const operacion = snapshot?.latestTrade;
      if (!operacion || !(operacion.p > 0)) continue; // sin precio no hay cotización
      const instante = new Date(operacion.t);
      if (Number.isNaN(instante.getTime())) continue;
      const cotizacion: Cotizacion = {
        simbolo,
        precio: operacion.p,
        bid: snapshot.latestQuote?.bp ?? null,
        ask: snapshot.latestQuote?.ap ?? null,
        cierreAnterior: snapshot.prevDailyBar?.c ?? null,
        volumenDia: snapshot.dailyBar?.v ?? null,
        momento: instante.toISOString(),
      };
      // La barra de minuto es opcional: si llega mal formada se ignora, la cotización sigue.
      const minuto = esquemaBarraDeMinuto.safeParse(snapshot.minuteBar);
      const inicio = minuto.success ? new Date(minuto.data.t) : null;
      if (minuto.success && inicio && !Number.isNaN(inicio.getTime())) {
        cotizacion.barraMinuto = {
          momento: inicio.toISOString(),
          apertura: minuto.data.o,
          maximo: minuto.data.h,
          minimo: minuto.data.l,
          cierre: minuto.data.c,
          volumen: minuto.data.v,
        };
      }
      cotizaciones.push(cotizacion);
    }
    return cotizaciones;
  }

  /** GET con las llaves en las cabeceras. Devuelve el JSON o lanza ErrorDeProveedor. */
  async #pedir(ruta: string, parametros: URLSearchParams): Promise<unknown> {
    const { urlDatos, keyId, secretKey } = this.#configuracion;
    const llamar = this.#configuracion.fetch ?? fetch;
    const url = `${urlDatos.replace(/\/+$/, "")}${ruta}?${parametros}`;

    let respuesta: Response;
    try {
      respuesta = await llamar(url, {
        method: "GET",
        headers: {
          "APCA-API-KEY-ID": keyId,
          "APCA-API-SECRET-KEY": secretKey,
          "Accept": "application/json",
        },
        signal: AbortSignal.timeout(
          this.#configuracion.tiempoMaximoMs ?? TIEMPO_MAXIMO_POR_DEFECTO_MS,
        ),
      });
    } catch (error) {
      const agotado = error instanceof DOMException &&
        error.name === "TimeoutError";
      throw new ErrorDeProveedor(
        agotado
          ? "Alpaca no respondió a tiempo"
          : "No se pudo conectar con Alpaca",
      );
    }

    if (!respuesta.ok) {
      throw new ErrorDeProveedor(
        `Alpaca respondió ${respuesta.status} en ${ruta}`,
        respuesta.status,
      );
    }
    try {
      return await respuesta.json();
    } catch {
      throw new ErrorDeProveedor(
        `Alpaca devolvió algo que no es JSON en ${ruta}`,
      );
    }
  }
}

/** Valida una respuesta con zod y la convierte en ErrorDeProveedor si no encaja. */
function interpretar<T>(
  esquema: z.ZodType<T>,
  cuerpo: unknown,
  que: string,
): T {
  const resultado = esquema.safeParse(cuerpo);
  if (!resultado.success) {
    const problema = resultado.error.issues[0];
    throw new ErrorDeProveedor(
      `Alpaca devolvió ${que} con un formato inesperado (${
        problema.path.join(".") || "raíz"
      })`,
    );
  }
  return resultado.data;
}

/** Barra de Alpaca a nuestra barra; null si no tiene la forma esperada. */
function aBarra(simbolo: string, crudo: unknown): Barra | null {
  const analizada = esquemaBarra.safeParse(crudo);
  if (!analizada.success) return null;
  const { t, o, h, l, c, v } = analizada.data;
  const instante = new Date(t);
  if (Number.isNaN(instante.getTime())) return null;
  return {
    simbolo,
    fecha: fechaDeNuevaYork(instante),
    apertura: o,
    maximo: h,
    minimo: l,
    cierre: c,
    volumen: v,
  };
}
