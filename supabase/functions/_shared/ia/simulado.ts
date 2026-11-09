// JEV simulado para local y CI (docs/10 §9, HU-045): respuestas deterministas a partir de las
// etiquetas del estado, con escenarios de confianza baja, contradicción y sin respuesta.
//
// JEV_ESCENARIO: normal (por defecto) · confianza_baja · contradiccion · sin_respuesta.

import {
  type ConsultaJev,
  ErrorDeJev,
  type ProveedorDeJev,
  type RespuestaDePregunta,
  type RespuestaJev,
} from "./tipos.ts";

export type EscenarioJev = "normal" | "confianza_baja" | "contradiccion" | "sin_respuesta";

/** Hash estable (FNV-1a) a [0, 1): da variedad determinista entre candidatas. */
function azar(texto: string): number {
  let h = 0x811c9dc5;
  for (let i = 0; i < texto.length; i++) {
    h ^= texto.charCodeAt(i);
    h = Math.imul(h, 0x01000193);
  }
  return (h >>> 0) / 0x100000000;
}

export class JevSimulado implements ProveedorDeJev {
  readonly nombre = "simulado";
  private readonly escenario: EscenarioJev;

  constructor(escenario?: string) {
    const valido: EscenarioJev[] = ["normal", "confianza_baja", "contradiccion", "sin_respuesta"];
    this.escenario = valido.includes(escenario as EscenarioJev) ? escenario as EscenarioJev : "normal";
  }

  consultar(consulta: ConsultaJev): Promise<RespuestaJev> {
    if (this.escenario === "sin_respuesta") {
      return Promise.reject(new ErrorDeJev("tiempo_agotado", "JEV simulado sin respuesta"));
    }
    const estado = consulta.state.toLowerCase();
    const ganancia = /"return_20d":"(moderate|strong) gain"/.test(estado);
    const pierde = /"return_20d":"(moderate|strong) loss"/.test(estado);
    const sobrecomprada = estado.includes("overbought");
    const ruido = azar(consulta.state);

    const answers: Record<string, RespuestaDePregunta> = {};
    for (const [clave, pregunta] of Object.entries(consulta.questions)) {
      if (clave === "entry_timing") {
        const eleccion = ganancia && !sobrecomprada ? "buy_now" : pierde ? "avoid" : "wait";
        const base = 0.62 + ruido * 0.3;
        const confianza = this.escenario === "confianza_baja" ? 0.4 + ruido * 0.15 : base;
        answers[clave] = {
          type: "choice",
          choice: eleccion,
          confidence: Math.round(confianza * 100) / 100,
          probabilities: { buy_now: 0.33, wait: 0.33, avoid: 0.34, [eleccion]: Math.round(confianza * 100) / 100 },
        };
      } else if (clave === "reversal_risk") {
        const nivel = sobrecomprada ? 2 + (ruido > 0.5 ? 1 : 0) : ganancia ? 1 : 0;
        answers[clave] = { type: "score", score: nivel, confidence: 0.7 };
      } else if (clave === "event_risk") {
        answers[clave] = { type: "score", score: Math.floor(ruido * 3), confidence: 0.6 };
      } else if (clave === "data_context_conflict") {
        answers[clave] = { type: "noul", noul: this.escenario === "contradiccion" ? 0.8 : 0.1 };
      } else if (pregunta.type === "noul") {
        answers[clave] = { type: "noul", noul: 0.5 };
      } else {
        const niveles = Array.isArray(pregunta.criteria) ? pregunta.criteria.length : 3;
        answers[clave] = { type: "score", score: (niveles - 1) / 2, confidence: 0.5 };
      }
    }
    return Promise.resolve({
      model: consulta.model,
      answers,
      usage: { input_tokens: Math.ceil(consulta.state.length / 4), output_tokens: 0 },
    });
  }
}
