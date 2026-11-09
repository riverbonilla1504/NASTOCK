// Broker simulado (docs/10 §9, FR-004): mismo contrato que alpaca.ts, sin red ni llaves.
//
// El reloj de mercado es configurable (docs/10 §9: "siempre abierto", "cerrado", "a 10 min del
// cierre"), para que el sistema se pueda probar de punta a punta a cualquier hora:
//
//   calendario        lunes a viernes, 9:30–16:00 de Nueva York; los feriados y las medias jornadas
//                     se inyectan (`excepciones`). Es el modo por defecto.
//   siempre_abierto   como `calendario`, pero la sesión del día de `ahora` rodea a `ahora`.
//   cerrado           como `calendario`, pero el día de `ahora` no hay sesión.
//   cierre_en_10_min  como `calendario`, pero la sesión del día de `ahora` cierra 10 minutos
//                     después de `ahora`.
//
// `ahora` llega de `private.ahora()` (docs/15 §3), igual que en el mercado simulado.

import {
  fechaDeNuevaYork,
  instanteDeNuevaYork,
  sumarDias,
} from "../mercado/tiempo.ts";
import type {
  ActivoDelBroker,
  Broker,
  ConsultaDeCalendario,
  CuentaDelBroker,
  DiaDeCalendario,
  RelojDelBroker,
} from "./interfaz.ts";

/** Modos del reloj de mercado simulado. El primero es el de por defecto. */
export const MODOS_DE_RELOJ = [
  "calendario",
  "siempre_abierto",
  "cerrado",
  "cierre_en_10_min",
] as const;

export type ModoDeReloj = (typeof MODOS_DE_RELOJ)[number];

/** Un día que no es el de un lunes a viernes normal. */
export type Excepcion = "feriado" | "media_jornada";

export interface OpcionesDelBrokerSimulado {
  modo?: ModoDeReloj;
  /** Fecha AAAA-MM-DD → feriado o media jornada. */
  excepciones?: Readonly<Record<string, Excepcion>>;
  /** Símbolos que el broker simulado declara no negociables. */
  noNegociables?: readonly string[];
  /** Símbolos que el broker simulado no declara fraccionables. */
  noFraccionables?: readonly string[];
  /** Símbolos que el broker simulado no conoce (como un 404 de Alpaca). */
  desconocidos?: readonly string[];
  /** Efectivo de la cuenta paper simulada, en USD. Alpaca trae 100.000 por defecto (docs/10 §4.1). */
  efectivo?: number;
}

const MINUTO_DE_APERTURA = 9 * 60 + 30;
const MINUTO_DE_CIERRE = 16 * 60;
const MINUTO_DE_CIERRE_MEDIA_JORNADA = 13 * 60;
const MINUTOS_DE_SESION = MINUTO_DE_CIERRE - MINUTO_DE_APERTURA;
const MS_POR_MINUTO = 60_000;
/** Cuánto se mira hacia adelante para encontrar la próxima apertura o el próximo cierre. */
const DIAS_PARA_EL_RELOJ = 10;

/** Lunes a viernes. */
function esDiaDeSemana(fecha: string): boolean {
  const dia = new Date(`${fecha}T00:00:00Z`).getUTCDay();
  return dia >= 1 && dia <= 5;
}

function dia(
  fecha: string,
  apertura: Date,
  cierre: Date,
  sesion: DiaDeCalendario["sesion"],
): DiaDeCalendario {
  return {
    fecha,
    apertura: apertura.toISOString(),
    cierre: cierre.toISOString(),
    sesion,
  };
}

export class BrokerSimulado implements Broker {
  readonly modo: ModoDeReloj;
  readonly #excepciones: Readonly<Record<string, Excepcion>>;
  readonly #noNegociables: ReadonlySet<string>;
  readonly #noFraccionables: ReadonlySet<string>;
  readonly #desconocidos: ReadonlySet<string>;
  readonly #efectivo: number;

  constructor(opciones: OpcionesDelBrokerSimulado = {}) {
    this.modo = opciones.modo ?? "calendario";
    this.#excepciones = opciones.excepciones ?? {};
    this.#noNegociables = new Set(opciones.noNegociables ?? []);
    this.#noFraccionables = new Set(opciones.noFraccionables ?? []);
    this.#desconocidos = new Set(opciones.desconocidos ?? []);
    this.#efectivo = opciones.efectivo ?? 100_000;
  }

  cuenta(): Promise<CuentaDelBroker> {
    return Promise.resolve({ efectivo: this.#efectivo });
  }

  calendario(
    consulta: ConsultaDeCalendario,
    ahora: Date,
  ): Promise<DiaDeCalendario[]> {
    return Promise.resolve(
      this.#generar(consulta.desde, consulta.hasta, ahora),
    );
  }

  reloj(ahora: Date): Promise<RelojDelBroker> {
    const hoy = fechaDeNuevaYork(ahora);
    // Un día antes por si la sesión de ayer todavía no ha cerrado (no ocurre, pero es barato).
    const dias = this.#generar(
      sumarDias(hoy, -1),
      sumarDias(hoy, DIAS_PARA_EL_RELOJ),
      ahora,
    );
    const t = ahora.getTime();
    const abierto = dias.some((d) =>
      Date.parse(d.apertura) <= t && t < Date.parse(d.cierre)
    );
    const proximaApertura = dias.find((d) => Date.parse(d.apertura) > t);
    const proximoCierre = dias.find((d) => Date.parse(d.cierre) > t);
    return Promise.resolve({
      ahora: ahora.toISOString(),
      abierto,
      // Sin sesiones a la vista (poco probable) se devuelve el propio instante.
      proximaApertura: proximaApertura?.apertura ?? ahora.toISOString(),
      proximoCierre: proximoCierre?.cierre ?? ahora.toISOString(),
    });
  }

  activos(simbolos: readonly string[]): Promise<ActivoDelBroker[]> {
    return Promise.resolve(
      [...new Set(simbolos)].map((simbolo): ActivoDelBroker => {
        if (this.#desconocidos.has(simbolo)) {
          return { simbolo, negociable: false, fraccionable: false };
        }
        return {
          simbolo,
          negociable: !this.#noNegociables.has(simbolo),
          fraccionable: !this.#noFraccionables.has(simbolo),
        };
      }),
    );
  }

  #generar(desde: string, hasta: string, ahora: Date): DiaDeCalendario[] {
    const hoy = fechaDeNuevaYork(ahora);
    const dias: DiaDeCalendario[] = [];
    for (let fecha = desde; fecha <= hasta; fecha = sumarDias(fecha, 1)) {
      if (fecha === hoy && this.modo !== "calendario") {
        const especial = this.#diaDeHoy(fecha, ahora);
        if (especial) dias.push(especial);
        continue;
      }
      const normal = this.#diaNormal(fecha);
      if (normal) dias.push(normal);
    }
    return dias;
  }

  /** El día de `ahora` en los modos que lo fuerzan; null si el modo es `cerrado`. */
  #diaDeHoy(fecha: string, ahora: Date): DiaDeCalendario | null {
    const t = ahora.getTime();
    switch (this.modo) {
      case "siempre_abierto": {
        const apertura = new Date(t - 60 * MS_POR_MINUTO);
        const cierre = new Date(
          apertura.getTime() + MINUTOS_DE_SESION * MS_POR_MINUTO,
        );
        return dia(fecha, apertura, cierre, "regular");
      }
      case "cierre_en_10_min": {
        const cierre = new Date(t + 10 * MS_POR_MINUTO);
        const apertura = new Date(
          cierre.getTime() - MINUTOS_DE_SESION * MS_POR_MINUTO,
        );
        return dia(fecha, apertura, cierre, "regular");
      }
      default:
        return null; // cerrado
    }
  }

  /** Un día según el calendario: lunes a viernes salvo feriados; medias jornadas a las 13:00. */
  #diaNormal(fecha: string): DiaDeCalendario | null {
    if (!esDiaDeSemana(fecha) || this.#excepciones[fecha] === "feriado") {
      return null;
    }
    const media = this.#excepciones[fecha] === "media_jornada";
    return dia(
      fecha,
      instanteDeNuevaYork(fecha, MINUTO_DE_APERTURA),
      instanteDeNuevaYork(
        fecha,
        media ? MINUTO_DE_CIERRE_MEDIA_JORNADA : MINUTO_DE_CIERRE,
      ),
      media ? "media_jornada" : "regular",
    );
  }
}
