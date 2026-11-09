// Interfaz del broker (docs/10 §1: `_shared/broker/`). HU-027 trae las operaciones de
// lectura del calendario del mercado (`calendario`, `reloj` y `activos`), HU-015 agrega `cuenta`
// y HU-072 las de órdenes: `enviarOrden`, `consultarOrden`, `cancelarOrden` y `posiciones`.
// La sincronización de órdenes vivas llega con HU-074.
//
// La implementan `alpaca.ts` (real) y `simulado.ts` (pruebas y demostraciones, docs/10 §9).
// Cuál se usa lo decide `crearBroker` según PROVEEDOR_BROKER (mod.ts).
//
// Invariante: `agente`, `contexto-ia` y `opinion-ia` nunca importan este directorio: la IA no
// ejecuta (CLAUDE.md). scripts/verificar.sh lo vigila.

import { ErrorDeProveedor } from "../mercado/interfaz.ts";

/** Un día de mercado del calendario del broker (docs/06 §5.2, `calendario_mercado`). */
export interface DiaDeCalendario {
  /** Día de mercado en Nueva York, AAAA-MM-DD. */
  fecha: string;
  /** Apertura, ISO 8601 en UTC, con el horario de verano ya resuelto. */
  apertura: string;
  /** Cierre, ISO 8601 en UTC. */
  cierre: string;
  /** `media_jornada` si el cierre es anterior a las 16:00 de Nueva York (RN-41). */
  sesion: "regular" | "media_jornada";
}

/** El reloj del mercado según el broker. */
export interface RelojDelBroker {
  /** Hora del broker, ISO 8601 en UTC. */
  ahora: string;
  abierto: boolean;
  proximaApertura: string;
  proximoCierre: string;
}

/** Atributos de un activo en el broker (docs/06 §5.2, `lista_blanca`). */
export interface ActivoDelBroker {
  simbolo: string;
  /** El activo está activo y se puede negociar. */
  negociable: boolean;
  /** Admite cantidades fraccionales. */
  fraccionable: boolean;
}

/** Lado de una orden. */
export type LadoDeOrden = "compra" | "venta";

/**
 * Estado de una orden (o de una pata) según el broker, ya traducido. `aceptada` incluye todo lo
 * que Alpaca llama `new`, `accepted`, `pending_new` o `held`.
 */
export type EstadoDeOrdenBroker =
  | "aceptada"
  | "parcial"
  | "llena"
  | "cancelada"
  | "expirada"
  | "rechazada";

/**
 * Orden que se envía al broker. Alcance D-63 (docs/10 §5): solo acciones enteras.
 *  - Compra: `bracket`, `limit`, `gtc`, con `proteccion` obligatoria.
 *  - Venta: `simple`, `limit`, `day`, sin protección.
 */
export interface OrdenAEnviar {
  /** Identificador nuestro (`client_order_id`): permite reconsultar si el envío no respondió. */
  idCliente: string;
  simbolo: string;
  lado: LadoDeOrden;
  /** Acciones enteras, mayor que cero. */
  cantidad: number;
  /** Precio límite en USD (hasta 2 decimales). */
  precioLimite: number;
  /** Solo en compras: precios de las patas del bracket (docs/10 §6). */
  proteccion?: { stopLoss: number; objetivo: number };
}

/** Pata de protección de un bracket. */
export interface PataDeOrden {
  idBroker: string;
  /** `stop_loss` vende a mercado al tocar el stop; `objetivo` vende con límite (take-profit). */
  tipo: "stop_loss" | "objetivo";
  precio: number;
  estado: EstadoDeOrdenBroker;
  cantidadLlenada: number;
  precioPromedio: number | null;
}

/** Una orden tal como la ve el broker. Solo datos ya validados: nunca el cuerpo crudo ni llaves. */
export interface OrdenDelBroker {
  idBroker: string;
  idCliente: string;
  simbolo: string;
  lado: LadoDeOrden;
  cantidad: number;
  precioLimite: number | null;
  estado: EstadoDeOrdenBroker;
  /** Estado crudo del broker (`filled`, `partially_filled`…): se guarda tal cual en `ordenes.broker_estado`. */
  estadoBroker: string;
  cantidadLlenada: number;
  /** Precio promedio de lo llenado; null si no se ha llenado nada. */
  precioPromedio: number | null;
  /** Patas del bracket (vacío en una orden simple). */
  patas: PataDeOrden[];
}

/** Cómo se busca una orden. */
export type ReferenciaDeOrden = { idBroker: string } | { idCliente: string };

/** Resultado de cancelar: `ya_cerrada` si la orden ya estaba llena, cancelada o vencida. */
export type ResultadoDeCancelacion = "cancelada" | "ya_cerrada" | "no_existe";

/** Una posición abierta en la cuenta del broker. */
export interface PosicionDelBroker {
  simbolo: string;
  cantidad: number;
  precioPromedioDeEntrada: number;
  precioActual: number | null;
}

/** El broker rechazó la orden (docs/10 §10): fondos insuficientes (403) o parámetros inválidos (422). */
export class OrdenRechazada extends ErrorDeProveedor {
  constructor(
    readonly motivo: "fondos_insuficientes" | "parametros_invalidos",
    mensaje: string,
    estado?: number,
  ) {
    super(mensaje, estado);
    this.name = "OrdenRechazada";
  }
}

/** La orden que se pidió enviar no cumple el alcance del MVP; no se llegó a llamar al broker. */
export class OrdenInvalida extends Error {
  constructor(mensaje: string) {
    super(mensaje);
    this.name = "OrdenInvalida";
  }
}

/**
 * Verdadero si, tras este error al enviar, no se sabe si el broker recibió la orden (sin
 * respuesta o 5xx, docs/10 §10): hay que consultarla por `idCliente` antes de reintentar.
 */
export function envioIncierto(error: unknown): boolean {
  return error instanceof ErrorDeProveedor &&
    !(error instanceof OrdenRechazada) &&
    (error.estado === undefined || error.estado >= 500);
}

/** Valida una orden contra el alcance D-63 (docs/10 §5). Lanza `OrdenInvalida`. */
export function validarOrden(orden: OrdenAEnviar): void {
  if (!orden.idCliente.trim()) throw new OrdenInvalida("Falta el idCliente");
  if (!orden.simbolo.trim()) throw new OrdenInvalida("Falta el símbolo");
  if (!Number.isInteger(orden.cantidad) || orden.cantidad <= 0) {
    throw new OrdenInvalida("Solo se envían acciones enteras (D-63)");
  }
  if (!precioValido(orden.precioLimite)) {
    throw new OrdenInvalida(
      "El precio límite debe ser positivo con 2 decimales",
    );
  }
  const { proteccion } = orden;
  if (orden.lado === "venta") {
    if (proteccion) throw new OrdenInvalida("La venta no lleva protección");
    return;
  }
  if (!proteccion) {
    throw new OrdenInvalida("Toda compra lleva protección nativa (RR-08)");
  }
  if (
    !precioValido(proteccion.stopLoss) || !precioValido(proteccion.objetivo)
  ) {
    throw new OrdenInvalida(
      "La protección debe tener precios positivos con 2 decimales",
    );
  }
  if (
    proteccion.stopLoss >= orden.precioLimite ||
    proteccion.objetivo <= orden.precioLimite
  ) {
    throw new OrdenInvalida(
      "El stop debe estar bajo el límite y el objetivo sobre el límite",
    );
  }
}

function precioValido(precio: number): boolean {
  return Number.isFinite(precio) && precio > 0 &&
    Math.abs(precio * 100 - Math.round(precio * 100)) < 1e-6;
}

/** Qué se pide al calendario. */
export interface ConsultaDeCalendario {
  /** AAAA-MM-DD, incluido. */
  desde: string;
  /** AAAA-MM-DD, incluido. */
  hasta: string;
}

/** La cuenta del broker (docs/10 §8): hoy solo el efectivo que la conciliación compara con el libro. */
export interface CuentaDelBroker {
  /** `cash` de la cuenta, en USD. */
  efectivo: number;
}

export interface Broker {
  /**
   * Días de mercado entre `desde` y `hasta`, ordenados por fecha. Los feriados y los fines de
   * semana no aparecen. `ahora` sale de `private.ahora()` (docs/15 §3): el simulado lo usa para
   * armar su reloj; el real lo ignora.
   */
  calendario(
    consulta: ConsultaDeCalendario,
    ahora: Date,
  ): Promise<DiaDeCalendario[]>;

  /** El reloj del mercado. Mismo uso de `ahora` que en `calendario`. */
  reloj(ahora: Date): Promise<RelojDelBroker>;

  /**
   * Atributos de cada símbolo, en el mismo orden en que se pidieron (sin repetidos). Un símbolo
   * que el broker no conoce vuelve como no negociable y no fraccionable.
   */
  activos(simbolos: readonly string[]): Promise<ActivoDelBroker[]>;

  /** El efectivo de la cuenta paper (HU-015). Lo usa la conciliación para confirmar aportes. */
  cuenta(): Promise<CuentaDelBroker>;

  /**
   * Envía una orden (docs/10 §5). Lanza `OrdenInvalida` si no cumple el alcance D-63,
   * `OrdenRechazada` si el broker la rechaza y `ErrorDeProveedor` ante cualquier otro fallo;
   * `envioIncierto(error)` dice si hay que consultarla por `idCliente` antes de reintentar.
   */
  enviarOrden(orden: OrdenAEnviar): Promise<OrdenDelBroker>;

  /** Una orden, con sus patas. Null si el broker no la conoce. */
  consultarOrden(referencia: ReferenciaDeOrden): Promise<OrdenDelBroker | null>;

  /**
   * Cancela una orden (o una pata). Cancelar un bracket cancela también sus patas vivas
   * (política provisional de docs/10 §6, Q-12).
   */
  cancelarOrden(idBroker: string): Promise<ResultadoDeCancelacion>;

  /** Posiciones abiertas de la cuenta. */
  posiciones(): Promise<PosicionDelBroker[]>;
}

/** Hora de cierre (minutos desde la medianoche de Nueva York) de una sesión regular: 16:00. */
export const MINUTO_DE_CIERRE_REGULAR = 16 * 60;
