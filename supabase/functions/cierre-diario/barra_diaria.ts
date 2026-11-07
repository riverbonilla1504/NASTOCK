// Primer paso de `cierre-diario` (HU-029, FR-070, docs/10 §12): agrega la barra diaria de hoy de
// cada símbolo del universo. Otras historias suman sus pasos al cierre (fotos de patrimonio,
// rebalanceo, evaluación de la IA, renovación de protecciones).
//
// 1. "Hoy" es el día de Nueva York de private.ahora() (docs/15 §3), nunca del reloj de la función.
// 2. Los símbolos salen de private.simbolos_del_universo() y se piden al proveedor en lotes.
// 3. private.guardar_barras_diarias no duplica ni reemplaza: repetir el cierre no cambia nada.

import type { Bd } from "../_shared/bd.ts";
import {
  ErrorDeProveedor,
  type ProveedorDeMercado,
} from "../_shared/mercado/interfaz.ts";
import { fechaDeNuevaYork } from "../_shared/mercado/tiempo.ts";

/** Símbolos que se piden a la vez al proveedor. */
export const TAMANO_DE_LOTE = 20;

export interface ResultadoDeBarraDiaria {
  /** Día de mercado agregado, AAAA-MM-DD (Nueva York). */
  fecha: string;
  simbolos_consultados: number;
  barras_recibidas: number;
  barras_nuevas: number;
  barras_descartadas: number;
  /** Símbolos de los que el proveedor no devolvió la barra de hoy. */
  sin_datos: string[];
  /** Símbolos que quedaron sin consultar porque el proveedor falló. */
  pendientes: string[];
}

/** El proveedor falló: trae lo que ya se alcanzó a guardar. */
export class ErrorDeCierre extends Error {
  constructor(mensaje: string, readonly parcial: ResultadoDeBarraDiaria) {
    super(mensaje);
    this.name = "ErrorDeCierre";
  }
}

export async function agregarBarraDiaria(
  bd: Bd,
  mercado: ProveedorDeMercado,
  tamanoDeLote = TAMANO_DE_LOTE,
): Promise<ResultadoDeBarraDiaria> {
  const [{ ahora }] = await bd.llamar<{ ahora: Date }>("ahora");
  if (!(ahora instanceof Date) || Number.isNaN(ahora.getTime())) {
    throw new Error("private.ahora() no devolvió una hora válida");
  }
  const fecha = fechaDeNuevaYork(ahora);

  const filas = await bd.llamar<{ simbolo: string }>("simbolos_del_universo");
  const simbolos = filas.map((fila) => fila.simbolo);

  const resultado: ResultadoDeBarraDiaria = {
    fecha,
    simbolos_consultados: 0,
    barras_recibidas: 0,
    barras_nuevas: 0,
    barras_descartadas: 0,
    sin_datos: [],
    pendientes: [],
  };

  for (let i = 0; i < simbolos.length; i += tamanoDeLote) {
    const lote = simbolos.slice(i, i + tamanoDeLote);
    let recibidas;
    try {
      recibidas = await mercado.barras({
        simbolos: lote,
        desde: fecha,
        hasta: fecha,
      });
    } catch (error) {
      if (error instanceof ErrorDeProveedor) {
        resultado.pendientes = simbolos.slice(i);
        throw new ErrorDeCierre(error.message, resultado);
      }
      throw error;
    }

    // Solo la barra de hoy: el proveedor podría devolver otras fechas.
    const deHoy = recibidas.barras.filter((b) => b.fecha === fecha);
    resultado.simbolos_consultados += lote.length;
    resultado.barras_recibidas += deHoy.length;
    resultado.barras_descartadas += recibidas.descartadas;
    const conBarra = new Set(deHoy.map((b) => b.simbolo));
    resultado.sin_datos.push(...lote.filter((s) => !conBarra.has(s)));

    if (deHoy.length > 0) {
      const guardadas = await bd.llamar("guardar_barras_diarias", [deHoy]);
      const nuevas = Number(guardadas[0]?.guardar_barras_diarias);
      if (!Number.isInteger(nuevas)) {
        throw new Error("private.guardar_barras_diarias no devolvió un entero");
      }
      resultado.barras_nuevas += nuevas;
    }
  }

  return resultado;
}
