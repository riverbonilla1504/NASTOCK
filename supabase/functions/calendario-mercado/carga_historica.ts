// Carga inicial de dos años de barras diarias del universo (HU-026, FR-062, docs/10 §12).
//
// 1. La hora sale de private.ahora() (docs/15 §3), nunca del reloj de la función.
// 2. Pide a la base los símbolos del universo que aún no tienen la historia completa
//    (private.simbolos_sin_historia) y los carga en lotes.
// 3. Guarda cada lote con private.guardar_barras_diarias, que no duplica: repetir la carga, o
//    correrla de nuevo cada día, no cambia lo que ya está guardado (CA-3).
//
// La base y el proveedor llegan inyectados: la función los conecta de verdad y las pruebas
// usan unos falsos.

import type { Bd } from "../_shared/bd.ts";
import {
  ErrorDeProveedor,
  type ProveedorDeMercado,
} from "../_shared/mercado/interfaz.ts";
import {
  fechaDeNuevaYork,
  restarAnios,
  sumarDias,
} from "../_shared/mercado/tiempo.ts";

/** Años de historia que se cargan (docs/10 §12). */
export const ANIOS_DE_HISTORIA = 2;
/** Símbolos que se piden a la vez al proveedor. */
export const TAMANO_DE_LOTE = 20;
/** Tiempo para empezar lotes nuevos: calendario-mercado dura como máximo 120 s (docs/05 §6). */
export const PRESUPUESTO_DE_TIEMPO_MS = 100_000;

export interface DependenciasDeCarga {
  bd: Bd;
  mercado: ProveedorDeMercado;
  /** Milisegundos actuales para el presupuesto de tiempo; las pruebas lo reemplazan. */
  reloj?: () => number;
  tamanoDeLote?: number;
  presupuestoMs?: number;
}

export interface ResultadoDeCarga {
  /** Primera fecha pedida, AAAA-MM-DD. */
  desde: string;
  /** Última fecha pedida (ayer, en Nueva York), AAAA-MM-DD. */
  hasta: string;
  simbolos_consultados: number;
  barras_recibidas: number;
  barras_nuevas: number;
  barras_descartadas: number;
  /** Símbolos de los que el proveedor no devolvió ninguna barra. */
  sin_datos: string[];
  /** Símbolos que quedaron sin cargar (se acabó el tiempo o el proveedor falló). */
  pendientes: string[];
}

/** El proveedor falló: trae lo que ya se alcanzó a guardar y lo que quedó pendiente. */
export class ErrorDeCarga extends Error {
  constructor(mensaje: string, readonly parcial: ResultadoDeCarga) {
    super(mensaje);
    this.name = "ErrorDeCarga";
  }
}

/** Entero que devuelve una función de private con una sola columna. */
function entero(filas: Record<string, unknown>[], columna: string): number {
  const valor = filas[0]?.[columna];
  const numero = Number(valor);
  if (!Number.isInteger(numero)) {
    throw new Error(`private.${columna} no devolvió un entero`);
  }
  return numero;
}

export async function cargarHistoria(
  dependencias: DependenciasDeCarga,
): Promise<ResultadoDeCarga> {
  const { bd, mercado } = dependencias;
  const reloj = dependencias.reloj ?? Date.now;
  const tamanoDeLote = dependencias.tamanoDeLote ?? TAMANO_DE_LOTE;
  const presupuestoMs = dependencias.presupuestoMs ?? PRESUPUESTO_DE_TIEMPO_MS;
  const inicio = reloj();

  const [{ ahora }] = await bd.llamar<{ ahora: Date }>("ahora");
  if (!(ahora instanceof Date) || Number.isNaN(ahora.getTime())) {
    throw new Error("private.ahora() no devolvió una hora válida");
  }
  const hoy = fechaDeNuevaYork(ahora);
  const desde = restarAnios(hoy, ANIOS_DE_HISTORIA);
  const hasta = sumarDias(hoy, -1);

  const filas = await bd.llamar<{ simbolo: string }>("simbolos_sin_historia", [
    desde,
  ]);
  const simbolos = filas.map((fila) => fila.simbolo);

  const resultado: ResultadoDeCarga = {
    desde,
    hasta,
    simbolos_consultados: 0,
    barras_recibidas: 0,
    barras_nuevas: 0,
    barras_descartadas: 0,
    sin_datos: [],
    pendientes: [],
  };

  for (let i = 0; i < simbolos.length; i += tamanoDeLote) {
    const lote = simbolos.slice(i, i + tamanoDeLote);
    const resto = simbolos.slice(i);

    if (reloj() - inicio >= presupuestoMs) {
      resultado.pendientes = resto;
      break;
    }

    let recibidas;
    try {
      recibidas = await mercado.barras({ simbolos: lote, desde, hasta });
    } catch (error) {
      if (error instanceof ErrorDeProveedor) {
        resultado.pendientes = resto;
        throw new ErrorDeCarga(error.message, resultado);
      }
      throw error;
    }

    resultado.simbolos_consultados += lote.length;
    resultado.barras_recibidas += recibidas.barras.length;
    resultado.barras_descartadas += recibidas.descartadas;

    const conBarras = new Set(recibidas.barras.map((b) => b.simbolo));
    resultado.sin_datos.push(...lote.filter((s) => !conBarras.has(s)));

    if (recibidas.barras.length > 0) {
      const guardadas = await bd.llamar("guardar_barras_diarias", [
        recibidas.barras,
      ]);
      resultado.barras_nuevas += entero(guardadas, "guardar_barras_diarias");
    }
  }

  return resultado;
}
