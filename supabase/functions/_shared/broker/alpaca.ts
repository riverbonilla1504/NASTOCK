// Broker real: Alpaca, API de trading paper (docs/10 §1). Lectura (HU-027, HU-015) y órdenes
// (HU-072).
//
// Calendario: GET {urlTrading}/v2/calendar?start=&end=   → [{date, open, close}] en hora de Nueva York
// Reloj:      GET {urlTrading}/v2/clock                   → {timestamp, is_open, next_open, next_close}
// Activo:     GET {urlTrading}/v2/assets/{simbolo}        → {symbol, status, tradable, fractionable}
// Enviar:     POST {urlTrading}/v2/orders                 → la orden (docs/10 §5, ejemplo bracket)
// Consultar:  GET /v2/orders/{id}?nested=true  ·  GET /v2/orders:by_client_order_id?client_order_id=
// Cancelar:   DELETE /v2/orders/{id}                      → 204; 404 no existe; 422 ya no se puede
// Posiciones: GET /v2/positions
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
  type EstadoDeOrdenBroker,
  MINUTO_DE_CIERRE_REGULAR,
  type OrdenAEnviar,
  type OrdenDelBroker,
  OrdenRechazada,
  type PataDeOrden,
  type PosicionDelBroker,
  type ReferenciaDeOrden,
  type RelojDelBroker,
  type ResultadoDeCancelacion,
  validarOrden,
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

const esquemaPata = z.object({
  id: z.string(),
  type: z.string(),
  status: z.string(),
  stop_price: z.string().nullish(),
  limit_price: z.string().nullish(),
  filled_qty: z.string().nullish(),
  filled_avg_price: z.string().nullish(),
});

const esquemaOrden = z.object({
  id: z.string(),
  client_order_id: z.string(),
  symbol: z.string(),
  side: z.enum(["buy", "sell"]),
  qty: z.string().nullish(),
  limit_price: z.string().nullish(),
  status: z.string(),
  filled_qty: z.string().nullish(),
  filled_avg_price: z.string().nullish(),
  legs: z.array(esquemaPata).nullish(),
});

const esquemaPosicion = z.object({
  symbol: z.string(),
  qty: z.string(),
  avg_entry_price: z.string(),
  current_price: z.string().nullish(),
});

/** Largo máximo del mensaje de error de Alpaca que se conserva (solo texto, sin llaves). */
const LARGO_MAXIMO_DE_DETALLE = 200;

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
    const { cuerpo } = await this.#pedir("/v2/calendar", {
      parametros: new URLSearchParams({
        start: consulta.desde,
        end: consulta.hasta,
      }),
    });
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
    const { cuerpo } = await this.#pedir("/v2/clock");
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
    const { cuerpo } = await this.#pedir("/v2/account");
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
    const { estado, cuerpo } = await this.#pedir(
      `/v2/assets/${encodeURIComponent(simbolo)}`,
      { aceptar: [404] },
    );
    // 404: Alpaca no conoce el símbolo, así que no se puede negociar.
    if (estado === 404) {
      return { simbolo, negociable: false, fraccionable: false };
    }
    const datos = interpretar(esquemaActivo, cuerpo, `el activo ${simbolo}`);
    return {
      simbolo,
      negociable: datos.status === "active" && datos.tradable,
      fraccionable: datos.fractionable === true,
    };
  }

  async enviarOrden(orden: OrdenAEnviar): Promise<OrdenDelBroker> {
    validarOrden(orden);
    const cuerpo: Record<string, unknown> = {
      client_order_id: orden.idCliente,
      symbol: orden.simbolo,
      qty: String(orden.cantidad),
      side: orden.lado === "compra" ? "buy" : "sell",
      type: "limit",
      limit_price: precio(orden.precioLimite),
    };
    if (orden.lado === "compra" && orden.proteccion) {
      // docs/10 §5: bracket gtc para que las patas sigan vivas los días siguientes.
      cuerpo.time_in_force = "gtc";
      cuerpo.order_class = "bracket";
      cuerpo.take_profit = { limit_price: precio(orden.proteccion.objetivo) };
      cuerpo.stop_loss = { stop_price: precio(orden.proteccion.stopLoss) };
    } else {
      cuerpo.time_in_force = "day";
    }
    const respuesta = await this.#pedir("/v2/orders", {
      metodo: "POST",
      cuerpo,
      aceptar: [403, 422],
    });
    if (respuesta.estado === 403 || respuesta.estado === 422) {
      const detalle = detalleDeError(respuesta.cuerpo);
      throw respuesta.estado === 403
        ? new OrdenRechazada(
          "fondos_insuficientes",
          `Alpaca rechazó la orden por fondos (403)${detalle}`,
          403,
        )
        : new OrdenRechazada(
          "parametros_invalidos",
          `Alpaca rechazó los parámetros de la orden (422)${detalle}`,
          422,
        );
    }
    return aOrden(interpretar(esquemaOrden, respuesta.cuerpo, "la orden"));
  }

  async consultarOrden(
    referencia: ReferenciaDeOrden,
  ): Promise<OrdenDelBroker | null> {
    const { ruta, parametros } = "idBroker" in referencia
      ? {
        ruta: `/v2/orders/${encodeURIComponent(referencia.idBroker)}`,
        parametros: new URLSearchParams({ nested: "true" }),
      }
      : {
        ruta: "/v2/orders:by_client_order_id",
        parametros: new URLSearchParams({
          client_order_id: referencia.idCliente,
        }),
      };
    const { estado, cuerpo } = await this.#pedir(ruta, {
      parametros,
      aceptar: [404],
    });
    if (estado === 404) return null;
    return aOrden(interpretar(esquemaOrden, cuerpo, "la orden"));
  }

  async cancelarOrden(idBroker: string): Promise<ResultadoDeCancelacion> {
    const { estado } = await this.#pedir(
      `/v2/orders/${encodeURIComponent(idBroker)}`,
      { metodo: "DELETE", aceptar: [404, 422] },
    );
    if (estado === 404) return "no_existe";
    // 422: la orden ya no se puede cancelar (llena, cancelada o vencida).
    return estado === 422 ? "ya_cerrada" : "cancelada";
  }

  async posiciones(): Promise<PosicionDelBroker[]> {
    const { cuerpo } = await this.#pedir("/v2/positions");
    const lista = interpretar(
      z.array(esquemaPosicion),
      cuerpo,
      "las posiciones",
    );
    return lista.map((p) => ({
      simbolo: p.symbol,
      cantidad: numero(p.qty, "la cantidad de la posición"),
      precioPromedioDeEntrada: numero(
        p.avg_entry_price,
        "el precio de entrada de la posición",
      ),
      precioActual: p.current_price == null || p.current_price === ""
        ? null
        : numero(p.current_price, "el precio actual de la posición"),
    }));
  }

  /**
   * Solicitud con las llaves en las cabeceras. Devuelve el estado y el JSON (null si no hay
   * cuerpo). Los estados de `aceptar` se devuelven en lugar de fallar; cualquier otro estado
   * que no sea 2xx lanza ErrorDeProveedor. No se reintenta: lo decide quien llama (docs/10 §10).
   */
  async #pedir(
    ruta: string,
    opciones: {
      metodo?: "GET" | "POST" | "DELETE";
      parametros?: URLSearchParams;
      cuerpo?: unknown;
      aceptar?: readonly number[];
    } = {},
  ): Promise<{ estado: number; cuerpo: unknown }> {
    const { urlTrading, keyId, secretKey } = this.#configuracion;
    const llamar = this.#configuracion.fetch ?? fetch;
    const consulta = opciones.parametros ? `?${opciones.parametros}` : "";
    const url = `${urlTrading.replace(/\/+$/, "")}${ruta}${consulta}`;
    const cabeceras: Record<string, string> = {
      "APCA-API-KEY-ID": keyId,
      "APCA-API-SECRET-KEY": secretKey,
      "Accept": "application/json",
    };
    if (opciones.cuerpo !== undefined) {
      cabeceras["Content-Type"] = "application/json";
    }
    // La ruta puede llevar un símbolo o un id; nunca lleva llaves (van en cabeceras).
    const rutaCorta = ruta.split("/").slice(0, 3).join("/");

    let respuesta: Response;
    try {
      respuesta = await llamar(url, {
        method: opciones.metodo ?? "GET",
        headers: cabeceras,
        body: opciones.cuerpo === undefined
          ? undefined
          : JSON.stringify(opciones.cuerpo),
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

    const estado = respuesta.status;
    const texto = await respuesta.text().catch(() => "");
    let cuerpo: unknown = null;
    if (texto.trim() !== "") {
      try {
        cuerpo = JSON.parse(texto);
      } catch {
        if (respuesta.ok) {
          throw new ErrorDeProveedor(
            `Alpaca devolvió algo que no es JSON en ${rutaCorta}`,
          );
        }
      }
    }
    if (opciones.aceptar?.includes(estado)) return { estado, cuerpo };
    if (!respuesta.ok) {
      throw new ErrorDeProveedor(
        `Alpaca respondió ${estado} en ${rutaCorta}`,
        estado,
      );
    }
    if (cuerpo === null && opciones.metodo !== "DELETE") {
      throw new ErrorDeProveedor(
        `Alpaca devolvió algo que no es JSON en ${rutaCorta}`,
      );
    }
    return { estado, cuerpo };
  }
}

/** Precio con dos decimales, como lo pide Alpaca. */
function precio(valor: number): string {
  return valor.toFixed(2);
}

function numero(texto: string, que: string): number {
  const valor = Number(texto);
  if (texto.trim() === "" || !Number.isFinite(valor)) {
    throw new ErrorDeProveedor(`Alpaca devolvió ${que} inválido`);
  }
  return valor;
}

function numeroOpcional(texto: string | null | undefined, que: string) {
  return texto == null || texto === "" ? null : numero(texto, que);
}

/** Mensaje de un cuerpo de error de Alpaca ({code, message}), recortado y listo para anexar. */
function detalleDeError(cuerpo: unknown): string {
  const mensaje = (cuerpo as { message?: unknown } | null)?.message;
  return typeof mensaje === "string" && mensaje.trim() !== ""
    ? `: ${mensaje.trim().slice(0, LARGO_MAXIMO_DE_DETALLE)}`
    : "";
}

/** Estado de Alpaca a nuestro estado. Un estado desconocido es un error: no se adivina. */
function aEstado(estado: string): EstadoDeOrdenBroker {
  switch (estado) {
    case "new":
    case "accepted":
    case "pending_new":
    case "accepted_for_bidding":
    case "held":
    case "pending_cancel":
    case "pending_replace":
    case "calculated":
      return "aceptada";
    case "partially_filled":
      return "parcial";
    case "filled":
      return "llena";
    case "canceled":
    case "replaced":
      return "cancelada";
    case "expired":
    case "done_for_day":
      return "expirada";
    case "rejected":
    case "suspended":
    case "stopped":
      return "rechazada";
    default:
      throw new ErrorDeProveedor(
        `Alpaca devolvió un estado desconocido: ${estado}`,
      );
  }
}

function aPata(pata: z.infer<typeof esquemaPata>): PataDeOrden | null {
  // Las patas de un bracket de compra son ventas: `stop` (stop-loss) y `limit` (objetivo).
  const esStop = pata.type === "stop" || pata.type === "stop_limit";
  const esObjetivo = pata.type === "limit";
  if (!esStop && !esObjetivo) return null;
  const precioDePata = numeroOpcional(
    esStop ? pata.stop_price : pata.limit_price,
    "el precio de la pata",
  );
  if (precioDePata === null) return null;
  return {
    idBroker: pata.id,
    tipo: esStop ? "stop_loss" : "objetivo",
    precio: precioDePata,
    estado: aEstado(pata.status),
    cantidadLlenada: numeroOpcional(pata.filled_qty, "lo llenado de la pata") ??
      0,
    precioPromedio: numeroOpcional(
      pata.filled_avg_price,
      "el precio de la pata",
    ),
  };
}

function aOrden(o: z.infer<typeof esquemaOrden>): OrdenDelBroker {
  const cantidad = numeroOpcional(o.qty, "la cantidad de la orden");
  if (cantidad === null) {
    throw new ErrorDeProveedor("Alpaca devolvió la orden sin cantidad");
  }
  return {
    idBroker: o.id,
    idCliente: o.client_order_id,
    simbolo: o.symbol,
    lado: o.side === "buy" ? "compra" : "venta",
    cantidad,
    precioLimite: numeroOpcional(o.limit_price, "el precio límite"),
    estado: aEstado(o.status),
    cantidadLlenada: numeroOpcional(o.filled_qty, "lo llenado de la orden") ??
      0,
    precioPromedio: numeroOpcional(o.filled_avg_price, "el precio de la orden"),
    patas: (o.legs ?? []).flatMap((p) => aPata(p) ?? []),
  };
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
