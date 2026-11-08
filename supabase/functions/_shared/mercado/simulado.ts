// Proveedor de mercado simulado (docs/10 §9, FR-004): caminata aleatoria DETERMINISTA.
//
// Cada barra es una función pura de (símbolo, fecha): el mismo par da siempre el mismo
// resultado, sin importar el rango que se pida ni cuántas veces. Por eso pedir "2024 a
// 2026" o "2025 a 2026" da la misma barra para una fecha dada.
//
// El algoritmo está en specs/026-universo-y-carga-historica/contracts/mercado.md y se repite
// en SQL en supabase/seed.sql (un año de barras de prueba, docs/15 §3). Si cambias algo aquí,
// cambia también el seed: simulado_test.ts y 04_universo_y_barras_test.sql comprueban los
// mismos valores conocidos.
//
// Alcance: los días hábiles son de lunes a viernes. Los feriados los resuelve el calendario
// (HU-027), no este proveedor.

import {
  type Barra,
  type ConsultaDeBarras,
  type Cotizacion,
  type ProveedorDeMercado,
  type ResultadoDeBarras,
} from "./interfaz.ts";
import { horaDeNuevaYork, instanteDeNuevaYork } from "./tiempo.ts";

/** Primer día de la caminata. Todas las series parten de aquí. */
export const ANCLA = "2020-01-01";

/** Módulo y multiplicador del generador congruencial (Park–Miller). */
const MODULO = 2147483647;
const MULTIPLICADOR = 48271;

const MS_POR_DIA = 86_400_000;
const INICIO_DE_CUENTA = Date.UTC(2000, 0, 1);

/** ETF que siguen a QQQ con apalancamiento diario (docs/02 §1). */
const APALANCAMIENTO: Readonly<Record<string, number>> = { QLD: 2, TQQQ: 3 };
const BASE_FIJA: Readonly<Record<string, number>> = {
  QQQ: 400,
  QLD: 80,
  TQQQ: 60,
};

const SIGMA_QQQ = 0.012;
const SIGMA_ACCION = 0.015;

/** Minutos de la sesión regular: 09:30 a 16:00 hora de Nueva York. */
const MINUTO_DE_APERTURA = 9 * 60 + 30;
const MINUTOS_DE_SESION = 390;

/** Días desde 2000-01-01 de una fecha AAAA-MM-DD. */
export function indiceDeDia(fecha: string): number {
  const [anio, mes, dia] = fecha.split("-").map(Number);
  return Math.round(
    (Date.UTC(anio, mes - 1, dia) - INICIO_DE_CUENTA) / MS_POR_DIA,
  );
}

/** Fecha AAAA-MM-DD de un índice de día. */
export function fechaDeIndice(indice: number): string {
  return new Date(INICIO_DE_CUENTA + indice * MS_POR_DIA).toISOString().slice(
    0,
    10,
  );
}

/** Verdadero si el día (índice desde 2000-01-01) es de lunes a viernes. */
export function esDiaHabil(indice: number): boolean {
  const diaDeSemana = new Date(INICIO_DE_CUENTA + indice * MS_POR_DIA)
    .getUTCDay();
  return diaDeSemana >= 1 && diaDeSemana <= 5;
}

/** Semilla de un símbolo: Σ código(letra_i) · 31^(n−1−i) mod 2147483647. */
export function semillaDe(simbolo: string): number {
  let semilla = 0;
  for (let i = 0; i < simbolo.length; i++) {
    semilla = (semilla * 31 + simbolo.charCodeAt(i)) % MODULO;
  }
  return semilla;
}

/** Los cinco números u1…u5 de un símbolo en un día, en [0, 1). Sin estado. */
function sorteo(
  semilla: number,
  indice: number,
): [number, number, number, number, number] {
  let x = (semilla * 131 + indice * 7919 + 12345) % MODULO;
  const u: number[] = [];
  for (let k = 0; k < 5; k++) {
    x = (MULTIPLICADOR * x) % MODULO;
    u.push(x / MODULO);
  }
  return u as [number, number, number, number, number];
}

/** Retorno diario (logarítmico) de QQQ. */
function retornoDeQqq(indice: number): number {
  const [u1] = sorteo(semillaDe("QQQ"), indice);
  return (u1 - 0.5) * 2 * SIGMA_QQQ;
}

/** Retorno diario del símbolo: QLD y TQQQ siguen a QQQ; el resto camina solo. */
function retornoDe(simbolo: string, semilla: number, indice: number): number {
  const factor = APALANCAMIENTO[simbolo];
  if (factor !== undefined) return factor * retornoDeQqq(indice);
  const [u1] = sorteo(semilla, indice);
  return (u1 - 0.5) * 2 * (simbolo === "QQQ" ? SIGMA_QQQ : SIGMA_ACCION);
}

/** Precio inicial del símbolo antes del primer día. */
export function baseDe(simbolo: string): number {
  return BASE_FIJA[simbolo] ?? 30 + (semillaDe(simbolo) % 370);
}

function redondear4(valor: number): number {
  return Math.round(valor * 10_000) / 10_000;
}

/** Una barra sin redondear, con el cierre del día anterior. */
interface BarraExacta {
  indice: number;
  apertura: number;
  maximo: number;
  minimo: number;
  cierre: number;
  volumen: number;
}

/** Serie completa de un símbolo desde el ancla hasta el índice indicado. */
function serieExacta(simbolo: string, hastaIndice: number): BarraExacta[] {
  const semilla = semillaDe(simbolo);
  const base = baseDe(simbolo);
  const serie: BarraExacta[] = [];
  let acumulado = 0;
  for (let indice = indiceDeDia(ANCLA); indice <= hastaIndice; indice++) {
    if (!esDiaHabil(indice)) continue;
    const cierreAnterior = base * Math.exp(acumulado);
    acumulado += retornoDe(simbolo, semilla, indice);
    const cierre = base * Math.exp(acumulado);
    const [, u2, u3, u4, u5] = sorteo(semilla, indice);
    const apertura = cierreAnterior * Math.exp((u2 - 0.5) * 0.01);
    serie.push({
      indice,
      apertura,
      maximo: Math.max(apertura, cierre) * (1 + u3 * 0.01),
      minimo: Math.min(apertura, cierre) * (1 - u4 * 0.01),
      cierre,
      volumen: Math.floor(1_000_000 * (0.5 + u5)),
    });
  }
  return serie;
}

function aBarra(simbolo: string, exacta: BarraExacta): Barra {
  return {
    simbolo,
    fecha: fechaDeIndice(exacta.indice),
    apertura: redondear4(exacta.apertura),
    maximo: redondear4(exacta.maximo),
    minimo: redondear4(exacta.minimo),
    cierre: redondear4(exacta.cierre),
    volumen: exacta.volumen,
  };
}

/** Barras diarias de un símbolo entre dos fechas (AAAA-MM-DD, ambas incluidas). */
export function generarBarras(
  simbolo: string,
  desde: string,
  hasta: string,
): Barra[] {
  const primero = indiceDeDia(desde);
  const ultimo = indiceDeDia(hasta);
  if (ultimo < indiceDeDia(ANCLA) || ultimo < primero) return [];
  return serieExacta(simbolo, ultimo)
    .filter((b) => b.indice >= primero)
    .map((b) => aBarra(simbolo, b));
}

/** Día hábil anterior (estrictamente) a un índice. */
function diaHabilAnterior(indice: number): number {
  let anterior = indice - 1;
  while (!esDiaHabil(anterior)) anterior--;
  return anterior;
}

// El proveedor --------------------------------------------------------------------------

export class MercadoSimulado implements ProveedorDeMercado {
  barras(consulta: ConsultaDeBarras): Promise<ResultadoDeBarras> {
    const simbolos = [...new Set(consulta.simbolos)].sort();
    const barras = simbolos.flatMap((s) =>
      generarBarras(s, consulta.desde, consulta.hasta)
    );
    return Promise.resolve({ barras, descartadas: 0 });
  }

  snapshots(simbolos: readonly string[], ahora: Date): Promise<Cotizacion[]> {
    const local = horaDeNuevaYork(ahora);
    const hoy = indiceDeDia(local.fecha);
    const minutoDeSesion = local.minutos - MINUTO_DE_APERTURA;
    const enSesion = esDiaHabil(hoy) && minutoDeSesion >= 0 &&
      minutoDeSesion < MINUTOS_DE_SESION;

    // Sesión de referencia: la de hoy si ya abrió; si no, la última completa.
    const yaAbrio = esDiaHabil(hoy) && minutoDeSesion >= 0;
    const sesion = yaAbrio ? hoy : diaHabilAnterior(hoy);
    const minutos = enSesion ? minutoDeSesion : MINUTOS_DE_SESION;
    const momento = enSesion
      ? new Date(Math.floor(ahora.getTime() / 60_000) * 60_000)
      : instanteDeNuevaYork(
        fechaDeIndice(sesion),
        MINUTO_DE_APERTURA + MINUTOS_DE_SESION,
      );

    const cotizaciones = [...new Set(simbolos)].sort().map(
      (simbolo): Cotizacion => {
        const serie = serieExacta(simbolo, sesion);
        const dia = serie[serie.length - 1];
        const anterior = serie[serie.length - 2];
        const precio = precioEnMinuto(simbolo, dia, minutos);
        return {
          simbolo,
          precio: redondear4(precio),
          bid: redondear4(precio - 0.01),
          ask: redondear4(precio + 0.01),
          cierreAnterior: anterior ? redondear4(anterior.cierre) : null,
          volumenDia: Math.floor(dia.volumen * (minutos / MINUTOS_DE_SESION)),
          momento: momento.toISOString(),
          // Solo en sesión: una barra de un minuto plana en el precio.
          ...(enSesion
            ? {
              barraMinuto: {
                momento: momento.toISOString(),
                apertura: redondear4(precio),
                maximo: redondear4(precio),
                minimo: redondear4(precio),
                cierre: redondear4(precio),
                volumen: Math.floor(dia.volumen / MINUTOS_DE_SESION),
              },
            }
            : {}),
        };
      },
    );
    return Promise.resolve(cotizaciones);
  }
}

/**
 * Precio dentro de la sesión: va de la apertura al cierre del día con un ruido que vale
 * cero en ambos extremos y nunca sale del rango [mínimo, máximo] de la barra.
 */
function precioEnMinuto(
  simbolo: string,
  dia: BarraExacta,
  minutos: number,
): number {
  const avance = minutos / MINUTOS_DE_SESION;
  const lineal = dia.apertura + (dia.cierre - dia.apertura) * avance;
  const [ruido] = sorteo(
    semillaDe(simbolo) ^ 0x5bd1,
    dia.indice * MINUTOS_DE_SESION + minutos,
  );
  const amplitud = 0.5 * (dia.maximo - dia.minimo) * Math.sin(Math.PI * avance);
  const precio = lineal + (ruido - 0.5) * 2 * amplitud;
  return Math.min(dia.maximo, Math.max(dia.minimo, precio));
}
