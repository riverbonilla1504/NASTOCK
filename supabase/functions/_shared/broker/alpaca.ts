// Broker real: Alpaca, API de trading paper (docs/10 §1). Solo las operaciones de lectura de
// HU-027.
//
// Calendario: GET {urlTrading}/v2/calendar?start=&end=   → [{date, open, close}] en hora de Nueva York
// Reloj:      GET {urlTrading}/v2/clock                   → {timestamp, is_open, next_open, next_close}
// Activo:     GET {urlTrading}/v2/assets/{simbolo}        → {symbol, status, tradable, fractionable}
//
// Las llaves viajan solo en las cabeceras APCA-API-KEY-ID y APCA-API-SECRET-KEY; nunca en la URL
// ni en los mensajes de error (CLAUDE.md, invariantes). Toda respuesta se valida con zod
// (docs/05 §2, A5). Si Alpaca falla se lanza ErrorDeProveedor: no se reintenta a ciegas, porque
// la sincronización es idempotente y corre todos los días.

import { z } from "../esquemas.ts";
import { ErrorDeProveedor } from "../mercado/interfaz.ts";
import { aInstanteUtc, minutosDeHora } from "../mercado/tiempo.ts";
import {
  type ActivoDelBroker,
  type Broker,
  type ConsultaDeCalendario,
  type CuentaDelBroker,
  type DiaDeCalendario,
  MINUTO_DE_CIERRE_REGULAR,
  type RelojDelBroker,
} from "./interfaz.ts";

export interface ConfiguracionDeAlpacaBroker {
  /** Normalmente https://paper-api.alpaca.markets (ALPACA_TRADING_URL). */
  urlTrading: string;
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
/** Activos que se consultan a la vez: muy por debajo de las 200 solicitudes por minuto de Alpaca. */
const ACTIVOS_EN_PARALELO = 10;

const esquemaDia = z.object({
  date: z.string(),
  open: z.string(),
  close: z.string(),
});
const esquemaCalendario = z.array(z.unknown());

const esquemaReloj = z.object({
  timestamp: z.string(),
  is_open: z.boolean(),
  next_open: z.string(),
  next_close: z.string(),
});

// Alpaca manda el efectivo como texto ("10000" o "-12.5").
const esquemaCuenta = z.object({ cash: z.string() });

const esquemaActivo = z.object({
  symbol: z.string(),
  status: z.string(),
  tradable: z.boolean(),
  // Alpaca lo omite en algunos activos antiguos; sin el dato no se asume fraccionable.
  fractionable: z.boolean().optional(),
});

export class BrokerAlpaca implements Broker {
  readonly #configuracion: ConfiguracionDeAlpacaBroker;

  constructor(configuracion: ConfiguracionDeAlpacaBroker) {
    if (
      !configuracion.keyId || !configuracion.secretKey ||
      !configuracion.urlTrading
    ) {
      throw new ErrorDeProveedor(
        "Faltan ALPACA_KEY_ID, ALPACA_SECRET_KEY o ALPACA_TRADING_URL para usar Alpaca",
      );
    }
    this.#configuracion = configuracion;
  }

  async calendario(
    consulta: ConsultaDeCalendario,
    _ahora: Date,
  ): Promise<DiaDeCalendario[]> {
    if (consulta.desde > consulta.hasta) return [];
    const cuerpo = await this.#pedir(
      "/v2/calendar",
      new URLSearchParams({ start: consulta.desde, end: consulta.hasta }),
    );
    const crudos = interpretar(esquemaCalendario, cuerpo, "calendario");

    const dias = new Map<string, DiaDeCalendario>();
    for (const crudo of crudos) {
      const dia = aDia(crudo);
      // Un día fuera del rango pedido o con horas incoherentes se descarta.
      if (!dia || dia.fecha < consulta.desde || dia.fecha > consulta.hasta) {
        continue;
      }
      dias.set(dia.fecha, dia);
    }
    return [...dias.values()].sort((a, b) => a.fecha.localeCompare(b.fecha));
  }

  async reloj(_ahora: Date): Promise<RelojDelBroker> {
    const cuerpo = await this.#pedir("/v2/clock");
    const datos = interpretar(esquemaReloj, cuerpo, "reloj");
    const ahora = aIso(datos.timestamp);
    const proximaApertura = aIso(datos.next_open);
    const proximoCierre = aIso(datos.next_close);
    if (!ahora || !proximaApertura || !proximoCierre) {
      throw new ErrorDeProveedor(
        "Alpaca devolvió el reloj con fechas inválidas",
      );
    }
    return {
      ahora,
      abierto: datos.is_open,
      proximaApertura,
      proximoCierre,
    };
  }

  async cuenta(): Promise<CuentaDelBroker> {
    const cuerpo = await this.#pedir("/v2/account");
    const datos = interpretar(esquemaCuenta, cuerpo, "la cuenta");
    const efectivo = Number(datos.cash);
    if (datos.cash.trim() === "" || !Number.isFinite(efectivo)) {
      throw new ErrorDeProveedor(
        "Alpaca devolvió la cuenta con un efectivo inválido",
      );
    }
    return { efectivo };
  }

  async activos(simbolos: readonly string[]): Promise<ActivoDelBroker[]> {
    const lista = [...new Set(simbolos)];
    const resultado: ActivoDelBroker[] = [];
    for (let i = 0; i < lista.length; i += ACTIVOS_EN_PARALELO) {
      const tanda = lista.slice(i, i + ACTIVOS_EN_PARALELO);
      resultado.push(...await Promise.all(tanda.map((s) => this.#activo(s))));
    }
    return resultado;
  }

  async #activo(simbolo: string): Promise<ActivoDelBroker> {
    const cuerpo = await this.#pedir(
      `/v2/assets/${encodeURIComponent(simbolo)}`,
      undefined,
      true,
    );
    // 404: Alpaca no conoce el símbolo, así que no se puede negociar.
    if (cuerpo === null) {
      return { simbolo, negociable: false, fraccionable: false };
    }
    const datos = interpretar(esquemaActivo, cuerpo, `el activo ${simbolo}`);
    return {
      simbolo,
      negociable: datos.status === "active" && datos.tradable,
      fraccionable: datos.fractionable === true,
    };
  }

  /**
   * GET con las llaves en las cabeceras. Devuelve el JSON o lanza ErrorDeProveedor. Con
   * `aceptar404` un 404 devuelve null en lugar de fallar.
   */
  async #pedir(
    ruta: string,
    parametros?: URLSearchParams,
    aceptar404 = false,
  ): Promise<unknown> {
    const { urlTrading, keyId, secretKey } = this.#configuracion;
    const llamar = this.#configuracion.fetch ?? fetch;
    const consulta = parametros ? `?${parametros}` : "";
    const url = `${urlTrading.replace(/\/+$/, "")}${ruta}${consulta}`;

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

    if (aceptar404 && respuesta.status === 404) {
      await respuesta.body?.cancel();
      return null;
    }
    if (!respuesta.ok) {
      await respuesta.body?.cancel();
      // La ruta puede llevar un símbolo; nunca lleva llaves (van en cabeceras).
      throw new ErrorDeProveedor(
        `Alpaca respondió ${respuesta.status} en ${
          ruta.split("/").slice(0, 3).join("/")
        }`,
        respuesta.status,
      );
    }
    try {
      return await respuesta.json();
    } catch {
      throw new ErrorDeProveedor(
        `Alpaca devolvió algo que no es JSON en ${
          ruta.split("/").slice(0, 3).join("/")
        }`,
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

/** ISO 8601 con desfase (Alpaca manda "…-05:00") a ISO en UTC; null si no es una fecha. */
function aIso(texto: string): string | null {
  const instante = new Date(texto);
  return Number.isNaN(instante.getTime()) ? null : instante.toISOString();
}

/**
 * Día del calendario de Alpaca a nuestro día: las horas "09:30" y "16:00" son de Nueva York y
 * aquí se pasan a UTC con el horario de verano resuelto (CB-51). Null si el día no sirve.
 */
function aDia(crudo: unknown): DiaDeCalendario | null {
  const analizado = esquemaDia.safeParse(crudo);
  if (!analizado.success) return null;
  const { date, open, close } = analizado.data;
  const apertura = aInstanteUtc(date, open);
  const cierre = aInstanteUtc(date, close);
  const minutosDeCierre = minutosDeHora(close);
  if (
    !apertura || !cierre || minutosDeCierre === null ||
    cierre.getTime() <= apertura.getTime()
  ) {
    return null;
  }
  return {
    fecha: date,
    apertura: apertura.toISOString(),
    cierre: cierre.toISOString(),
    sesion: minutosDeCierre < MINUTO_DE_CIERRE_REGULAR
      ? "media_jornada"
      : "regular",
  };
}
