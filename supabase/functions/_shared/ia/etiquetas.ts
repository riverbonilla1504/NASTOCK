// Estado que recibe JEV: etiquetas semánticas en inglés, nunca cifras ni fechas para comparar
// (docs/07 §4.3, D-40, HU-045). Los cortes salen de la configuración de decisión activa.
//
// Lista cerrada de campos (docs/07 §12): símbolo, sector y etiquetas. Nada de personas, cupos
// ni montos (docs/07 §4.5).

import type { Metricas } from "../indicadores.ts";

export interface CortesConEtiquetas {
  cortes: readonly number[];
  etiquetas: readonly string[];
}

export interface ConfiguracionDeEtiquetas {
  rendimiento: {
    "1d": { cortes: readonly number[] };
    "5d": { cortes: readonly number[] };
    "20d": { cortes: readonly number[] };
    "60d": { cortes: readonly number[] };
    etiquetas: readonly string[];
    etiquetas_1d: readonly string[];
  };
  volatilidad: CortesConEtiquetas;
  rsi: CortesConEtiquetas;
  distancia_maximo_52s: CortesConEtiquetas;
  volumen_relativo: CortesConEtiquetas;
  horizonte: Record<string, { name: string; horizon: string; profile: string }>;
}

/** Etiqueta del tramo en que cae `valor`: `etiquetas` tiene un elemento más que `cortes`. */
export function etiquetaPorCortes(
  valor: number,
  cortes: readonly number[],
  etiquetas: readonly string[],
): string {
  let i = 0;
  while (i < cortes.length && valor >= cortes[i]) i++;
  return etiquetas[Math.min(i, etiquetas.length - 1)];
}

function ordinal(n: number): string {
  if (n === 1) return "best";
  const sufijo = n % 100 >= 11 && n % 100 <= 13
    ? "th"
    : ({ 1: "st", 2: "nd", 3: "rd" } as Record<number, string>)[n % 10] ?? "th";
  return `${n}${sufijo} best`;
}

function tendencia(m: Metricas): string {
  const medias: string[] = [];
  const sobre = (flag: boolean | null, nombre: string) => ({ flag, nombre });
  const lista = [
    sobre(m.sobre_sma_20, "20-day"),
    sobre(m.sobre_sma_50, "50-day"),
    sobre(m.sobre_sma_200, "200-day"),
  ].filter((x) => x.flag !== null);
  const arriba = lista.filter((x) => x.flag).map((x) => x.nombre);
  const abajo = lista.filter((x) => !x.flag).map((x) => x.nombre);
  if (arriba.length) medias.push(`above its ${arriba.join(" and ")} averages`);
  if (abajo.length) medias.push(`below its ${abajo.join(" and ")} averages`);
  return medias.join(", ");
}

export interface EntradaDeEstado {
  bolsillo: "arriesgadas" | "usuarios";
  simbolo: string;
  sector: string | null;
  metricas: Metricas;
  /** Percentil de volatilidad dentro del universo (0 a 1). */
  percentilVolatilidad: number;
  /** Posición entre las candidatas del bolsillo por Q (1 = la mejor) y cuántas son. */
  posicion: number;
  totalCandidatas: number;
  /** Métricas de QQQ, la referencia del mercado, y su percentil de volatilidad. */
  mercado: { metricas: Metricas; percentilVolatilidad: number } | null;
  mercadoAbierto: boolean;
}

export type EstadoJev = Record<string, unknown>;

/** Arma el estado de una candidata. El resultado se envía a JEV como texto JSON. */
export function armarEstado(
  e: EntradaDeEstado,
  c: ConfiguracionDeEtiquetas,
): EstadoJev {
  const m = e.metricas;
  const r = c.rendimiento;
  const horizonte = c.horizonte[e.bolsillo];
  const mercado = e.mercado
    ? {
      nasdaq100_today: etiquetaPorCortes(
        e.mercado.metricas.rendimiento_1d,
        r["1d"].cortes,
        r.etiquetas_1d,
      ),
      nasdaq100_trend: tendencia(e.mercado.metricas),
      market_volatility: etiquetaPorCortes(
        e.mercado.percentilVolatilidad,
        c.volatilidad.cortes,
        c.volatilidad.etiquetas,
      ),
    }
    : { nasdaq100_today: "unknown" };
  const candidata: Record<string, string> = {
    symbol: e.simbolo,
    return_5d: etiquetaPorCortes(m.rendimiento_5d, r["5d"].cortes, r.etiquetas),
    return_20d: etiquetaPorCortes(
      m.rendimiento_20d,
      r["20d"].cortes,
      r.etiquetas,
    ),
    return_60d: etiquetaPorCortes(
      m.rendimiento_60d,
      r["60d"].cortes,
      r.etiquetas,
    ),
    volatility: etiquetaPorCortes(
      e.percentilVolatilidad,
      c.volatilidad.cortes,
      c.volatilidad.etiquetas,
    ),
    trend: tendencia(m),
    rsi_zone: etiquetaPorCortes(m.rsi_14, c.rsi.cortes, c.rsi.etiquetas),
    distance_from_52w_high: etiquetaPorCortes(
      m.distancia_maximo_52s,
      c.distancia_maximo_52s.cortes,
      c.distancia_maximo_52s.etiquetas,
    ),
    relative_volume: etiquetaPorCortes(
      m.volumen_relativo,
      c.volumen_relativo.cortes,
      c.volumen_relativo.etiquetas,
    ),
    quant_rank: `${
      ordinal(e.posicion)
    } of ${e.totalCandidatas} candidates on risk-adjusted return`,
  };
  if (e.sector) candidata.sector = e.sector;
  return {
    as_of_session: e.mercadoAbierto
      ? "regular session"
      : "market closed: judge as if the next regular session opened under these conditions (data from the last completed session)",
    bucket: horizonte,
    market: mercado,
    candidate: candidata,
    context: {
      status:
        "none (no news context is available; judge only from the market data above)",
    },
  };
}
