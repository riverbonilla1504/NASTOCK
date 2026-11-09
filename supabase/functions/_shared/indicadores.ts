// Calidad de datos, métricas y puntaje cuantitativo de la IA principal (docs/07 §4.1, HU-044).
//
// Código determinista y puro: sin red ni base de datos, todo reproducible (D-38). Las barras
// llegan ordenadas de la más vieja a la más nueva.

/** Una barra diaria (docs/06 §5.2). Los números ya vienen como `number`. */
export interface BarraDia {
  fecha: string; // AAAA-MM-DD
  apertura: number;
  maximo: number;
  minimo: number;
  cierre: number;
  volumen: number;
}

/** Controles de completitud de docs/07 §4.1. */
export const MINIMO_DE_BARRAS = 60;
export const BARRAS_PARA_MEDIA_200 = 200;
/** Salto anómalo del día sin suspensión informada. */
export const SALTO_MAXIMO = 0.25;
/** Una sesión de bolsa tiene ~252 días hábiles. */
const DIAS_POR_ANIO = 252;

export interface ContextoDeCalidad {
  /** Fecha de la barra más reciente de todo el universo: la sesión de referencia. */
  ultimaSesion: string;
  /** Precio en vivo y su antigüedad, si el mercado está en ventana y hay cotización. */
  precioEnVivo?: { precio: number; antiguedadSeg: number } | null;
  /** Antigüedad máxima del precio en vivo (segundos); solo se exige con el mercado en ventana. */
  maxAntiguedadSeg: number;
  /** Con el mercado en ventana se exige el precio en vivo reciente (docs/07 §4.1). */
  exigirPrecioEnVivo: boolean;
}

/**
 * Verifica una serie (docs/07 §4.1). Devuelve `ok` o el motivo de exclusión:
 * `barras_insuficientes`, `datos_viejos`, `valores_invalidos`, `salto_anomalo`, `precio_en_vivo_viejo`.
 */
export function verificarCalidad(
  barras: readonly BarraDia[],
  contexto: ContextoDeCalidad,
): string {
  if (barras.length < MINIMO_DE_BARRAS) return "barras_insuficientes";
  for (const b of barras) {
    const valores = [b.apertura, b.maximo, b.minimo, b.cierre, b.volumen];
    if (valores.some((v) => typeof v !== "number" || !Number.isFinite(v))) {
      return "valores_invalidos";
    }
    if (
      b.apertura <= 0 || b.maximo <= 0 || b.minimo <= 0 || b.cierre <= 0 ||
      b.volumen < 0
    ) {
      return "valores_invalidos";
    }
  }
  const ultima = barras[barras.length - 1];
  if (ultima.fecha !== contexto.ultimaSesion) return "datos_viejos";

  const previa = barras[barras.length - 2].cierre;
  if (Math.abs(ultima.cierre / previa - 1) > SALTO_MAXIMO) {
    return "salto_anomalo";
  }

  if (contexto.exigirPrecioEnVivo) {
    const vivo = contexto.precioEnVivo;
    if (!vivo || vivo.antiguedadSeg > contexto.maxAntiguedadSeg) {
      return "precio_en_vivo_viejo";
    }
    if (
      !(vivo.precio > 0) ||
      Math.abs(vivo.precio / ultima.cierre - 1) > SALTO_MAXIMO
    ) {
      return "salto_anomalo";
    }
  }
  return "ok";
}

export interface Metricas {
  precio: number;
  rendimiento_1d: number;
  rendimiento_5d: number;
  rendimiento_20d: number;
  rendimiento_60d: number;
  /** Volatilidad realizada anualizada (desviación de los rendimientos diarios × √252). */
  volatilidad_20d: number;
  volatilidad_60d: number;
  atr_14: number;
  /** ATR de 14 días como fracción del precio. */
  atr_14_pct: number;
  rsi_14: number;
  sma_20: number;
  sma_50: number;
  /** Nulo con menos de 200 barras. */
  sma_200: number | null;
  sobre_sma_20: boolean;
  sobre_sma_50: boolean;
  sobre_sma_200: boolean | null;
  /** Caída desde el máximo de 52 semanas (≤ 0). */
  distancia_maximo_52s: number;
  volumen_relativo: number;
  /** Regla de tendencia de la v2: ±2 % en 30 días (docs/05 §11). */
  tendencia_30d: "alcista" | "bajista" | "lateral";
  /** Rendimiento ajustado por riesgo a 20 y 60 días (rendimiento / volatilidad de la ventana). */
  ra_20d: number;
  ra_60d: number;
  /** Fecha de la última barra usada. */
  ultima_fecha: string;
}

function media(valores: readonly number[]): number {
  return valores.reduce((a, b) => a + b, 0) / valores.length;
}

function desviacion(valores: readonly number[]): number {
  const m = media(valores);
  const varianza = valores.reduce((a, v) => a + (v - m) ** 2, 0) /
    Math.max(valores.length - 1, 1);
  return Math.sqrt(varianza);
}

/** Rendimientos diarios simples de las últimas `n` barras. */
function rendimientosDiarios(cierres: readonly number[], n: number): number[] {
  const fin = cierres.length;
  const salida: number[] = [];
  for (let i = Math.max(fin - n, 1); i < fin; i++) {
    salida.push(cierres[i] / cierres[i - 1] - 1);
  }
  return salida;
}

function rsi(cierres: readonly number[], periodo = 14): number {
  if (cierres.length <= periodo) return 50;
  let ganancia = 0;
  let perdida = 0;
  for (let i = 1; i <= periodo; i++) {
    const d = cierres[i] - cierres[i - 1];
    if (d >= 0) ganancia += d;
    else perdida -= d;
  }
  ganancia /= periodo;
  perdida /= periodo;
  for (let i = periodo + 1; i < cierres.length; i++) {
    const d = cierres[i] - cierres[i - 1];
    ganancia = (ganancia * (periodo - 1) + Math.max(d, 0)) / periodo;
    perdida = (perdida * (periodo - 1) + Math.max(-d, 0)) / periodo;
  }
  if (perdida === 0) return ganancia === 0 ? 50 : 100;
  return 100 - 100 / (1 + ganancia / perdida);
}

function atr(barras: readonly BarraDia[], periodo = 14): number {
  const rangos: number[] = [];
  for (let i = Math.max(barras.length - periodo, 1); i < barras.length; i++) {
    const b = barras[i];
    const cierrePrevio = barras[i - 1].cierre;
    rangos.push(
      Math.max(
        b.maximo - b.minimo,
        Math.abs(b.maximo - cierrePrevio),
        Math.abs(b.minimo - cierrePrevio),
      ),
    );
  }
  return media(rangos);
}

/**
 * Calcula las métricas de una serie que ya pasó la verificación (≥ 60 barras).
 * `precioEnVivo` reemplaza al último cierre cuando el mercado está en ventana.
 */
export function calcularMetricas(
  barras: readonly BarraDia[],
  precioEnVivo?: number | null,
): Metricas {
  if (barras.length < MINIMO_DE_BARRAS) {
    throw new Error("calcularMetricas: se necesitan al menos 60 barras");
  }
  const cierres = barras.map((b) => b.cierre);
  const n = cierres.length;
  const precio = precioEnVivo && precioEnVivo > 0
    ? precioEnVivo
    : cierres[n - 1];
  const serie = precio === cierres[n - 1]
    ? cierres
    : [...cierres.slice(0, -1), precio];
  const atras = (k: number) => serie[n - 1] / serie[n - 1 - k] - 1;

  const vol20Diaria = desviacion(rendimientosDiarios(serie, 20));
  const vol60Diaria = desviacion(rendimientosDiarios(serie, 60));
  const rend20 = atras(20);
  const rend60 = atras(60);
  const sma20 = media(serie.slice(-20));
  const sma50 = media(serie.slice(-50));
  const sma200 = n >= BARRAS_PARA_MEDIA_200 ? media(serie.slice(-200)) : null;
  const maximo52 = Math.max(
    ...barras.slice(-DIAS_POR_ANIO).map((b) => b.maximo),
    precio,
  );
  const volumenPrevio = media(barras.slice(-21, -1).map((b) => b.volumen));
  const rend30 = atras(30);
  const atr14 = atr(barras, 14);

  return {
    precio,
    rendimiento_1d: atras(1),
    rendimiento_5d: atras(5),
    rendimiento_20d: rend20,
    rendimiento_60d: rend60,
    volatilidad_20d: vol20Diaria * Math.sqrt(DIAS_POR_ANIO),
    volatilidad_60d: vol60Diaria * Math.sqrt(DIAS_POR_ANIO),
    atr_14: atr14,
    atr_14_pct: atr14 / precio,
    rsi_14: rsi(serie, 14),
    sma_20: sma20,
    sma_50: sma50,
    sma_200: sma200,
    sobre_sma_20: precio > sma20,
    sobre_sma_50: precio > sma50,
    sobre_sma_200: sma200 === null ? null : precio > sma200,
    distancia_maximo_52s: precio / maximo52 - 1,
    volumen_relativo: volumenPrevio > 0
      ? barras[n - 1].volumen / volumenPrevio
      : 1,
    tendencia_30d: rend30 > 0.02
      ? "alcista"
      : rend30 < -0.02
      ? "bajista"
      : "lateral",
    ra_20d: vol20Diaria > 0 ? rend20 / (vol20Diaria * Math.sqrt(20)) : 0,
    ra_60d: vol60Diaria > 0 ? rend60 / (vol60Diaria * Math.sqrt(60)) : 0,
    ultima_fecha: barras[n - 1].fecha,
  };
}

/** Fracción de los otros valores que son menores (0 = el más bajo, 1 = el más alto). */
export function percentilDe(valor: number, todos: readonly number[]): number {
  if (todos.length <= 1) return 0.5;
  let menores = 0;
  let iguales = 0;
  for (const v of todos) {
    if (v < valor) menores++;
    else if (v === valor) iguales++;
  }
  // El propio valor cuenta como igual: se descarta de los iguales.
  return (menores + Math.max(iguales - 1, 0) / 2) / (todos.length - 1);
}

/**
 * Puntaje cuantitativo Q (docs/07 §4.1): percentil dentro del universo de
 * `0,6·ra20 + 0,4·ra60`, con 0,1 de bonificación si está sobre la media de 50 días (tope 1).
 * Devuelve Q y el percentil de volatilidad V de cada símbolo.
 */
export function puntajesCuantitativos(
  universo: ReadonlyMap<string, Metricas>,
): Map<string, { q: number; v: number }> {
  const compuestos = new Map<string, number>();
  for (const [simbolo, m] of universo) {
    compuestos.set(simbolo, 0.6 * m.ra_20d + 0.4 * m.ra_60d);
  }
  const todosQ = [...compuestos.values()];
  const todasVol = [...universo.values()].map((m) => m.volatilidad_20d);
  const salida = new Map<string, { q: number; v: number }>();
  for (const [simbolo, m] of universo) {
    const base = percentilDe(compuestos.get(simbolo)!, todosQ);
    salida.set(simbolo, {
      q: Math.min(1, base + (m.sobre_sma_50 ? 0.1 : 0)),
      v: percentilDe(m.volatilidad_20d, todasVol),
    });
  }
  return salida;
}

/**
 * Candidatas (docs/07 §4.1, FR-104): las `candidatosMax` mejores por Q de Arriesgadas y todos
 * los símbolos activos de Usuarios. En este corte (D-70) no hay posiciones abiertas.
 */
export function elegirCandidatas(
  arriesgadas: readonly string[],
  usuarios: readonly string[],
  q: ReadonlyMap<string, { q: number; v: number }>,
  candidatosMax: number,
): { arriesgadas: string[]; usuarios: string[] } {
  const ordenadas = arriesgadas
    .filter((s) => q.has(s))
    .sort((a, b) => q.get(b)!.q - q.get(a)!.q || a.localeCompare(b));
  return {
    arriesgadas: ordenadas.slice(0, candidatosMax),
    usuarios: usuarios.filter((s) => q.has(s)),
  };
}
