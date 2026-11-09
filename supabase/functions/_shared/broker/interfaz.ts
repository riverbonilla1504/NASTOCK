// Interfaz del broker (docs/10 §1: `_shared/broker/`). HU-027 trae las operaciones de
// lectura del calendario del mercado (`calendario`, `reloj` y `activos`) y HU-015 agrega `cuenta`. Las
// operaciones de órdenes (`enviarOrden`, `consultarOrden`…) llegan con E-08.
//
// La implementan `alpaca.ts` (real) y `simulado.ts` (pruebas y demostraciones, docs/10 §9).
// Cuál se usa lo decide `crearBroker` según PROVEEDOR_BROKER (mod.ts).
//
// Invariante: `agente`, `contexto-ia` y `opinion-ia` nunca importan este directorio: la IA no
// ejecuta (CLAUDE.md). scripts/verificar.sh lo vigila.

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
}

/** Hora de cierre (minutos desde la medianoche de Nueva York) de una sesión regular: 16:00. */
export const MINUTO_DE_CIERRE_REGULAR = 16 * 60;
