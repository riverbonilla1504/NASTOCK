// Sincronización diaria del calendario, el reloj y los atributos de los activos (HU-027,
// FR-063, FR-065, docs/05 §6, docs/10 §12).
//
// 1. El calendario: se piden al broker los días de mercado de hoy a CALENDARIO_DIAS_ADELANTE días
//    y se guardan con private.sincronizar_calendario, que también borra los días de ese rango
//    que el broker ya no lista. Las horas llegan en UTC (el adaptador resuelve el horario de
//    verano), así que cambiar de horario no exige ninguna intervención (CB-51).
// 2. El reloj: se contrasta el del broker con private.mercado_abierto(). Solo informa.
// 3. Los atributos: para cada símbolo del universo se guarda si es negociable y fraccionable
//    (private.sincronizar_activos); el que deja de ser negociable queda desactivado en la lista
//    blanca. La alerta al Administrador es de HU-085 (docs/10 §10).
//
// La hora sale de private.ahora() (docs/15 §3), nunca del reloj de la función. La base y el
// broker llegan inyectados: la función los conecta de verdad y las pruebas usan unos falsos.

import type { Bd } from "../_shared/bd.ts";
import type { Broker } from "../_shared/broker/interfaz.ts";
import { fechaDeNuevaYork, sumarDias } from "../_shared/mercado/tiempo.ts";

/** Días hacia adelante que se piden al calendario del broker en cada sincronización. */
export const CALENDARIO_DIAS_ADELANTE = 60;

export interface ResultadoDeCalendario {
  /** Primera fecha pedida, AAAA-MM-DD (hoy en Nueva York). */
  desde: string;
  /** Última fecha pedida, AAAA-MM-DD. */
  hasta: string;
  dias_recibidos: number;
  dias_guardados: number;
  /** Días del rango que estaban guardados y el broker ya no lista. */
  dias_eliminados: number;
}

export interface ResultadoDeReloj {
  abierto_broker: boolean;
  abierto_bd: boolean;
  coincide: boolean;
}

export interface ResultadoDeActivos {
  consultados: number;
  /** Filas de la lista blanca que recibieron los atributos (un símbolo puede estar en dos bolsillos). */
  actualizados: number;
  /** Símbolos que dejaron de ser negociables y quedaron desactivados. */
  desactivados: string[];
}

interface DependenciasDeSincronizacion {
  bd: Bd;
  broker: Broker;
  /** `private.ahora()`. */
  ahora: Date;
}

/** Entero que devuelve una columna de una función de private. */
function entero(fila: Record<string, unknown> | undefined, columna: string) {
  const numero = Number(fila?.[columna]);
  if (!Number.isInteger(numero)) {
    throw new Error(`private.${columna} no devolvió un entero`);
  }
  return numero;
}

export async function sincronizarCalendario(
  { bd, broker, ahora }: DependenciasDeSincronizacion,
): Promise<ResultadoDeCalendario> {
  const desde = fechaDeNuevaYork(ahora);
  const hasta = sumarDias(desde, CALENDARIO_DIAS_ADELANTE);
  const dias = await broker.calendario({ desde, hasta }, ahora);

  const [fila] = await bd.llamar("sincronizar_calendario", [
    desde,
    hasta,
    dias,
  ]);
  return {
    desde,
    hasta,
    dias_recibidos: dias.length,
    dias_guardados: entero(fila, "guardados"),
    dias_eliminados: entero(fila, "eliminados"),
  };
}

export async function contrastarReloj(
  { bd, broker, ahora }: DependenciasDeSincronizacion,
): Promise<ResultadoDeReloj> {
  const reloj = await broker.reloj(ahora);
  const [fila] = await bd.llamar<{ mercado_abierto: boolean }>(
    "mercado_abierto",
  );
  const abiertoBd = fila?.mercado_abierto === true;
  const resultado = {
    abierto_broker: reloj.abierto,
    abierto_bd: abiertoBd,
    coincide: reloj.abierto === abiertoBd,
  };
  if (!resultado.coincide) {
    console.warn(
      "calendario-mercado: el reloj del broker y el calendario guardado no coinciden",
    );
  }
  return resultado;
}

export async function sincronizarActivos(
  { bd, broker }: Omit<DependenciasDeSincronizacion, "ahora">,
): Promise<ResultadoDeActivos> {
  const filas = await bd.llamar<{ simbolo: string }>("simbolos_del_universo");
  const simbolos = filas.map((fila) => fila.simbolo);
  if (simbolos.length === 0) {
    return { consultados: 0, actualizados: 0, desactivados: [] };
  }

  const activos = await broker.activos(simbolos);
  const guardados = await bd.llamar<{ simbolo: string; desactivado: boolean }>(
    "sincronizar_activos",
    [activos],
  );
  const desactivados = [
    ...new Set(guardados.filter((g) => g.desactivado).map((g) => g.simbolo)),
  ].sort();
  return {
    consultados: simbolos.length,
    actualizados: guardados.length,
    desactivados,
  };
}
