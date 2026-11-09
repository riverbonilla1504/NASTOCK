// Puntaje compuesto, reglas de decisión, elección de la mejor opción y explicación (docs/07 §6 y §14,
// HU-047 y HU-048). Código determinista: cambiar un peso es cambiar configuración, no volver a
// preguntar al modelo (D-41). La explicación la arma el código con piezas verificables (D-42).
//
// Corte de demo (D-70): no hay contexto (C, S y T valen 0,5), ni motor de políticas, ni tamaño,
// stop u objetivo. La mejor candidata de cada bolsillo queda como recomendación (`elegida`).

import type { RespuestaJev } from "./ia/tipos.ts";

export interface Pesos {
  wQ: number;
  wC: number;
  wS: number;
  wT: number;
  wV: number;
  wE: number;
  wR: number;
}

export interface Umbrales {
  confianzaMinima: number;
  umbralContradiccion: number;
  puntajeMinimo: number;
}

export type Dimension = "Q" | "C" | "S" | "T" | "V" | "E" | "R";

export interface Aporte {
  /** Peso de la dimensión en el bolsillo. */
  peso: number;
  /** Valor de 0 a 1 donde 1 es lo mejor (en riesgos ya es 1 − riesgo). */
  valor: number;
  /** peso × valor. */
  aporte: number;
  /** Sin dato: la dimensión vale 0,5 y no se usa para explicar. */
  neutral: boolean;
}

export type Aportes = Record<Dimension, Aporte>;

export interface Evaluacion {
  puntaje: number;
  aportes: Aportes;
  /** Confianza de `entry_timing`, o nulo sin JEV. */
  confianza: number | null;
  entrada: "buy_now" | "wait" | "avoid" | null;
  contradiccion: number;
  sinJev: boolean;
  /** Nulo si cumple las reglas de compra; si no, el motivo (resultado `no_elegible:<motivo>`). */
  motivo: string | null;
}

export interface EntradaDeEvaluacion {
  q: number;
  /** Percentil de volatilidad (0 a 1); la seguridad es 1 − V. */
  v: number;
  /** Respuesta de JEV o nulo si no hubo. */
  jev: RespuestaJev | null;
  /** Cantidad de niveles de cada pregunta de tipo score (para normalizar a 0–1). */
  niveles: Readonly<Record<string, number>>;
  pesos: Pesos;
  umbrales: Umbrales;
}

const acotar = (x: number) => Math.min(1, Math.max(0, x));

/** Puntaje de una pregunta tipo score normalizado a 0–1; 0,5 si falta. */
function normalizado(
  jev: RespuestaJev | null,
  clave: string,
  niveles: Readonly<Record<string, number>>,
): number | null {
  const respuesta = jev?.answers[clave];
  const n = niveles[clave];
  if (!respuesta || typeof respuesta.score !== "number" || !n || n < 2) {
    return null;
  }
  return acotar(respuesta.score / (n - 1));
}

/** Aplica la fórmula de docs/07 §6.2 y las reglas de §6.3 que no dependen del motor de políticas. */
export function evaluar(e: EntradaDeEvaluacion): Evaluacion {
  const riesgoEvento = normalizado(e.jev, "event_risk", e.niveles);
  const riesgoReversion = normalizado(e.jev, "reversal_risk", e.niveles);
  const sinJev = e.jev === null || riesgoEvento === null ||
    riesgoReversion === null ||
    !e.jev.answers["entry_timing"]?.choice;

  const valores: Record<Dimension, { valor: number; neutral: boolean }> = {
    Q: { valor: acotar(e.q), neutral: false },
    // Sin contexto o contexto no confiable: C, S y T valen 0,5 (docs/07 §6.2, D-59).
    C: { valor: 0.5, neutral: true },
    S: { valor: 0.5, neutral: true },
    T: { valor: 0.5, neutral: true },
    V: { valor: 1 - acotar(e.v), neutral: false },
    E: riesgoEvento === null
      ? { valor: 0.5, neutral: true }
      : { valor: 1 - riesgoEvento, neutral: false },
    R: riesgoReversion === null
      ? { valor: 0.5, neutral: true }
      : { valor: 1 - riesgoReversion, neutral: false },
  };
  const pesoDe: Record<Dimension, number> = {
    Q: e.pesos.wQ,
    C: e.pesos.wC,
    S: e.pesos.wS,
    T: e.pesos.wT,
    V: e.pesos.wV,
    E: e.pesos.wE,
    R: e.pesos.wR,
  };
  const aportes = {} as Aportes;
  let puntaje = 0;
  for (const d of Object.keys(valores) as Dimension[]) {
    const aporte = pesoDe[d] * valores[d].valor;
    aportes[d] = {
      peso: pesoDe[d],
      valor: valores[d].valor,
      aporte,
      neutral: valores[d].neutral,
    };
    puntaje += aporte;
  }

  const entry = e.jev?.answers["entry_timing"];
  const entrada = (entry?.choice === "buy_now" || entry?.choice === "wait" ||
      entry?.choice === "avoid")
    ? entry.choice
    : null;
  const confianza = typeof entry?.confidence === "number"
    ? entry.confidence
    : null;
  const conflicto = e.jev?.answers["data_context_conflict"]?.noul ?? 0;

  let motivo: string | null = null;
  if (sinJev) motivo = "sin_jev";
  else if (entrada === "wait") motivo = "espera";
  else if (entrada === "avoid") motivo = "evitar";
  else if ((confianza ?? 0) < e.umbrales.confianzaMinima) motivo = "confianza";
  else if (conflicto >= e.umbrales.umbralContradiccion) {
    motivo = "contradiccion";
  } else if (puntaje < e.umbrales.puntajeMinimo) motivo = "puntaje";

  return {
    puntaje,
    aportes,
    confianza,
    entrada,
    contradiccion: conflicto,
    sinJev,
    motivo,
  };
}

export interface Elegible {
  simbolo: string;
  puntaje: number;
  confianza: number;
  /** Percentil de volatilidad: en un empate gana la menor. */
  v: number;
}

/**
 * La mejor opción de un bolsillo: mayor puntaje; en empate, mayor confianza; luego menor
 * volatilidad (docs/07 §6.3, CB-86). Nulo si no hay elegibles.
 */
export function elegirMejor(elegibles: readonly Elegible[]): string | null {
  if (elegibles.length === 0) return null;
  const ordenadas = [...elegibles].sort((a, b) =>
    b.puntaje - a.puntaje || b.confianza - a.confianza || a.v - b.v ||
    a.simbolo.localeCompare(b.simbolo)
  );
  return ordenadas[0].simbolo;
}

// Explicación (docs/07 §14) ----------------------------------------------------------------------------

export interface Explicacion {
  /** Una línea: qué recomienda el sistema. */
  que: string;
  /** Las dimensiones que más aportaron, en lenguaje llano. */
  por_que: string[];
  /** Las dimensiones de riesgo más altas. */
  frena: string[];
  /** Sin contexto, datos de la sesión anterior, sin JEV, etc. */
  advertencias: string[];
  /** Todo junto, para quien no abre el detalle. */
  resumen: string;
}

const NOMBRE: Record<Dimension, string> = {
  Q: "rendimiento frente al riesgo",
  C: "contexto",
  S: "sentimiento de las noticias",
  T: "sector",
  V: "volatilidad",
  E: "eventos",
  R: "reversión",
};

const BUENO: Record<Dimension, string> = {
  Q: "rinde bien para el riesgo que asumió frente al resto del NASDAQ-100",
  C: "",
  S: "",
  T: "",
  V: "se mueve con calma comparada con el resto del NASDAQ-100",
  E: "JEV no ve eventos de riesgo en el horizonte",
  R: "JEV no la ve sobreextendida: el riesgo de que se revierta es bajo",
};

const MALO: Record<Dimension, string> = {
  Q: "su rendimiento frente al riesgo está entre los más bajos del NASDAQ-100",
  C: "",
  S: "",
  T: "",
  V: "se mueve con fuerza (volatilidad alta frente al resto del NASDAQ-100)",
  E: "JEV ve riesgo de eventos (resultados, anuncios) dentro del horizonte",
  R: "hay riesgo de que la tendencia reciente se revierta",
};

const coma = (x: number, d = 2) => x.toFixed(d).replace(".", ",");
const porcentaje = (x: number) => `${Math.round(x * 100)} %`;

export interface EntradaDeExplicacion {
  simbolo: string;
  evaluacion: Evaluacion;
  /** `elegida`, `elegible_no_elegida` o `no_elegible:<motivo>`. */
  resultado: string;
  horizonte: string;
  mercadoAbierto: boolean;
  umbrales: Umbrales;
  /** Fallo de JEV, si lo hubo (sin_llave, tiempo_agotado…). */
  fallosJev?: string | null;
}

export function armarExplicacion(e: EntradaDeExplicacion): Explicacion {
  const ev = e.evaluacion;
  const medibles = (Object.keys(ev.aportes) as Dimension[]).filter((d) =>
    !ev.aportes[d].neutral
  );
  const porAporte = [...medibles].sort((a, b) =>
    ev.aportes[b].aporte - ev.aportes[a].aporte
  );
  const porValor = [...medibles].sort((a, b) =>
    ev.aportes[a].valor - ev.aportes[b].valor
  );

  const por_que = porAporte
    .filter((d) => ev.aportes[d].valor >= 0.5)
    .slice(0, 3)
    .map((d) => `${capital(NOMBRE[d])}: ${BUENO[d]}.`);
  const frena = porValor
    .filter((d) => ev.aportes[d].valor < 0.5)
    .slice(0, 2)
    .map((d) => `${capital(NOMBRE[d])}: ${MALO[d]}.`);

  const horizonteEs = e.horizonte;
  let que: string;
  if (e.resultado === "elegida") {
    que =
      `Recomendación: considerar comprar ${e.simbolo} (horizonte: ${horizonteEs}). ` +
      `Puntaje ${coma(ev.puntaje)} y confianza de JEV ${
        porcentaje(ev.confianza ?? 0)
      }.`;
  } else if (e.resultado === "elegible_no_elegida") {
    que =
      `${e.simbolo} cumple las condiciones pero hay otra candidata mejor en su bolsillo. ` +
      `Puntaje ${coma(ev.puntaje)}, confianza ${
        porcentaje(ev.confianza ?? 0)
      }.`;
  } else {
    que = `No se recomienda comprar ${e.simbolo} por ahora: ${
      motivoEnPalabras(e.resultado, ev, e.umbrales)
    }`;
  }

  const advertencias = [
    "Sin contexto: no se leyeron noticias, así que el contexto, el sentimiento y el sector valen lo mismo (neutros).",
  ];
  if (!e.mercadoAbierto) {
    advertencias.push(
      "Mercado cerrado: se evaluó con los datos de la última sesión.",
    );
  }
  if (ev.sinJev) {
    advertencias.push(
      e.fallosJev === "sin_llave"
        ? "Sin JEV: falta la llave del proveedor. Solo cuenta la parte cuantitativa y no se recomienda nada."
        : "Sin JEV: no respondió a tiempo. Solo cuenta la parte cuantitativa y no se recomienda nada.",
    );
  }
  advertencias.push(
    "Precios de una sola bolsa (IEX). Demostración en paper trading: no es asesoría financiera.",
  );

  const resumen = [
    que,
    ...por_que,
    ...(frena.length ? ["Lo que la frena: " + frena.join(" ")] : []),
  ]
    .join(" ");
  return { que, por_que, frena, advertencias, resumen };
}

function motivoEnPalabras(
  resultado: string,
  ev: Evaluacion,
  u: Umbrales,
): string {
  switch (resultado.replace("no_elegible:", "")) {
    case "espera":
      return `JEV prefiere esperar un mejor momento (confianza ${
        porcentaje(ev.confianza ?? 0)
      }).`;
    case "evitar":
      return `JEV desaconseja entrar (confianza ${
        porcentaje(ev.confianza ?? 0)
      }).`;
    case "confianza":
      return `JEV no tiene confianza suficiente (${
        porcentaje(ev.confianza ?? 0)
      }; el mínimo es ${porcentaje(u.confianzaMinima)}).`;
    case "contradiccion":
      return "los datos y el contexto se contradicen.";
    case "puntaje":
      return `el puntaje (${coma(ev.puntaje)}) no alcanza el mínimo (${
        coma(u.puntajeMinimo)
      }).`;
    case "sin_jev":
      return "no hubo respuesta de JEV.";
    default:
      return "no cumple las condiciones.";
  }
}

function capital(texto: string): string {
  return texto.charAt(0).toUpperCase() + texto.slice(1);
}

/** Explicación de una candidata excluida por la calidad de sus datos (docs/07 §4.1). */
export function explicacionDeExclusion(
  simbolo: string,
  motivo: string,
): Explicacion {
  const texto: Record<string, string> = {
    barras_insuficientes: "tiene menos de 60 barras diarias",
    datos_viejos: "su última barra diaria no es la de la sesión más reciente",
    valores_invalidos: "tiene valores inválidos en sus barras",
    salto_anomalo: "tuvo un salto de más de ±25 % sin suspensión informada",
    precio_en_vivo_viejo: "su precio en vivo tiene más de 60 segundos",
    sin_datos: "no tiene barras diarias",
  };
  const que = `${simbolo} quedó fuera de este ciclo: ${
    texto[motivo] ?? motivo
  }.`;
  return { que, por_que: [], frena: [], advertencias: [], resumen: que };
}
