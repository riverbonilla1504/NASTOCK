// JEV por la API de TypeSafe (docs/07 §5): POST /v1/systemone con todas las preguntas en una
// llamada. Reintenta con espera exponencial ante 429 y 529 (docs/07 §10) sin pasar del tiempo máximo.
// La llave solo viaja en la cabecera Authorization y nunca se copia en un mensaje de error.

import {
  type ConsultaJev,
  ErrorDeJev,
  esquemaDeRespuestaJev,
  type ProveedorDeJev,
  type RespuestaJev,
} from "./tipos.ts";

export const URL_DE_TYPESAFE = "https://api.typesafe.ai/v1/systemone";

const REINTENTOS = 3;
const ESPERA_BASE_MS = 400;

export interface OpcionesTypeSafe {
  llave: string;
  url?: string;
  /** Se cambia en las pruebas. */
  fetcher?: typeof fetch;
  esperar?: (ms: number) => Promise<void>;
}

export class JevTypeSafe implements ProveedorDeJev {
  readonly nombre = "typesafe";
  private readonly fetcher: typeof fetch;
  private readonly esperar: (ms: number) => Promise<void>;

  constructor(private readonly opciones: OpcionesTypeSafe) {
    this.fetcher = opciones.fetcher ?? ((...a) => fetch(...a));
    this.esperar = opciones.esperar ??
      ((ms) => new Promise((r) => setTimeout(r, ms)));
  }

  async consultar(
    consulta: ConsultaJev,
    { timeoutMs }: { timeoutMs: number },
  ): Promise<RespuestaJev> {
    if (!this.opciones.llave) {
      throw new ErrorDeJev("sin_llave", "Falta TYPESAFE_API_KEY");
    }
    const limite = Date.now() + timeoutMs;
    let intento = 0;
    while (true) {
      const restante = limite - Date.now();
      if (restante <= 0) {
        throw new ErrorDeJev("tiempo_agotado", "JEV no respondió a tiempo");
      }
      let respuesta: Response;
      try {
        respuesta = await this.fetcher(this.opciones.url ?? URL_DE_TYPESAFE, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${this.opciones.llave}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            state: consulta.state,
            model: consulta.model,
            questions: consulta.questions,
          }),
          signal: AbortSignal.timeout(restante),
        });
      } catch (error) {
        if ((error as Error)?.name === "TimeoutError" || (error as Error)?.name === "AbortError") {
          throw new ErrorDeJev("tiempo_agotado", "JEV no respondió a tiempo");
        }
        throw new ErrorDeJev("http", "No se pudo conectar con JEV");
      }

      if (respuesta.status === 429 || respuesta.status === 529) {
        await respuesta.body?.cancel();
        if (++intento >= REINTENTOS) {
          throw new ErrorDeJev("http", `JEV respondió ${respuesta.status} tras reintentar`);
        }
        await this.esperar(Math.min(ESPERA_BASE_MS * 2 ** (intento - 1), Math.max(limite - Date.now(), 0)));
        continue;
      }
      if (respuesta.status === 401 || respuesta.status === 403) {
        await respuesta.body?.cancel();
        throw new ErrorDeJev("sin_acceso", `JEV negó el acceso (${respuesta.status})`);
      }
      if (!respuesta.ok) {
        await respuesta.body?.cancel();
        throw new ErrorDeJev("http", `JEV respondió ${respuesta.status}`);
      }
      let cuerpo: unknown;
      try {
        cuerpo = await respuesta.json();
      } catch {
        throw new ErrorDeJev("formato", "JEV no devolvió JSON");
      }
      const analizado = esquemaDeRespuestaJev.safeParse(cuerpo);
      if (!analizado.success) {
        throw new ErrorDeJev("formato", "La respuesta de JEV no tiene la forma esperada");
      }
      return analizado.data;
    }
  }
}
