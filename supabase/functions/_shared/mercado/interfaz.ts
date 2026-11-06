// Interfaz del proveedor de datos de mercado (docs/10 §1: `snapshots` y `barras`).
//
// La implementan `alpaca.ts` (real) y `simulado.ts` (pruebas y demostraciones, docs/10 §9).
// Cuál se usa lo decide `crearProveedorDeMercado` según PROVEEDOR_MERCADO (mod.ts).

/** Resumen de un día de mercado de un símbolo (docs/06 §5.2, `barras_diarias`). */
export interface Barra {
  simbolo: string;
  /** Día de mercado en Nueva York, AAAA-MM-DD. */
  fecha: string;
  apertura: number;
  maximo: number;
  minimo: number;
  cierre: number;
  /** Cantidad entera de acciones negociadas. */
  volumen: number;
}

/** Último precio conocido de un símbolo. */
export interface Cotizacion {
  simbolo: string;
  precio: number;
  bid: number | null;
  ask: number | null;
  cierreAnterior: number | null;
  volumenDia: number | null;
  /** Hora del dato según el proveedor, ISO 8601 en UTC. */
  momento: string;
}

/** Qué se pide al proveedor al buscar barras diarias. */
export interface ConsultaDeBarras {
  simbolos: readonly string[];
  /** AAAA-MM-DD, incluido. */
  desde: string;
  /** AAAA-MM-DD, incluido. */
  hasta: string;
}

/** Barras que llegaron y barras que se descartaron por incoherentes. */
export interface ResultadoDeBarras {
  barras: Barra[];
  descartadas: number;
}

export interface ProveedorDeMercado {
  /**
   * Última cotización de cada símbolo. `ahora` sale de `private.ahora()` (docs/15 §3):
   * el proveedor simulado lo usa para calcular el precio; el real lo ignora.
   */
  snapshots(simbolos: readonly string[], ahora: Date): Promise<Cotizacion[]>;

  /**
   * Barras diarias entre `desde` y `hasta`, ordenadas por símbolo y fecha. Las barras
   * incoherentes (máximo menor que el cierre, precios no positivos…) no se devuelven y se
   * cuentan en `descartadas`.
   */
  barras(consulta: ConsultaDeBarras): Promise<ResultadoDeBarras>;
}

/** El proveedor respondió con un error o con datos que no se pueden usar. */
export class ErrorDeProveedor extends Error {
  constructor(mensaje: string, readonly estado?: number) {
    super(mensaje);
    this.name = "ErrorDeProveedor";
  }
}

/** Verdadero si la barra cumple las restricciones de `barras_diarias` (docs/06 §5.2). */
export function esBarraCoherente(barra: Barra): boolean {
  const { apertura, maximo, minimo, cierre, volumen } = barra;
  const precios = [apertura, maximo, minimo, cierre];
  return precios.every((p) => Number.isFinite(p) && p > 0) &&
    maximo >= Math.max(apertura, cierre, minimo) &&
    minimo <= Math.min(apertura, cierre, maximo) &&
    Number.isInteger(volumen) && volumen >= 0;
}
