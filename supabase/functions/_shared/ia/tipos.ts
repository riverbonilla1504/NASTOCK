// Tipos, esquema de respuesta y error del adaptador de JEV (docs/07 §5 y §6.1, HU-045).

import { z } from "../esquemas.ts";

/** Pregunta tipada. `criteria` es una lista (score), un objeto opción→descripción (choice) o falta (noul). */
export interface PreguntaJev {
  type: "score" | "choice" | "noul";
  instructions: string;
  criteria?: readonly string[] | Readonly<Record<string, string>>;
}

export interface ConsultaJev {
  /** Estado en etiquetas (JSON como texto). */
  state: string;
  /** Versión fijada (`ia.modelo_jev`). */
  model: string;
  questions: Readonly<Record<string, PreguntaJev>>;
}

const esquemaDeRespuesta = z.object({
  type: z.enum(["score", "choice", "noul"]).optional(),
  score: z.number().optional(),
  choice: z.string().optional(),
  noul: z.number().optional(),
  probabilities: z.unknown().optional(),
  confidence: z.number().optional(),
});

export const esquemaDeRespuestaJev = z.object({
  model: z.string(),
  answers: z.record(esquemaDeRespuesta),
  usage: z.object({
    input_tokens: z.number().optional(),
    output_tokens: z.number().optional(),
  }).optional(),
});

export type RespuestaDePregunta = z.infer<typeof esquemaDeRespuesta>;
export type RespuestaJev = z.infer<typeof esquemaDeRespuestaJev>;

export type CodigoDeFalloJev =
  | "sin_llave"
  | "tiempo_agotado"
  | "sin_acceso"
  | "http"
  | "formato";

/** JEV no respondió como se esperaba. El mensaje nunca trae la llave. */
export class ErrorDeJev extends Error {
  constructor(readonly codigo: CodigoDeFalloJev, mensaje: string) {
    super(mensaje);
    this.name = "ErrorDeJev";
  }
}

export interface ProveedorDeJev {
  /** Nombre del proveedor, para el registro. */
  readonly nombre: string;
  consultar(
    consulta: ConsultaJev,
    opciones: { timeoutMs: number },
  ): Promise<RespuestaJev>;
}
