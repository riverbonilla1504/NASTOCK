// Salud de las integraciones (HU-035, docs/06 §5.6, docs/08 §6).
//
// Toda función que llama a un proveedor externo registra aquí el resultado de su llamada: un éxito
// devuelve la integración a `ok`; un fallo la pasa a `degradado` (1–2 seguidos) o `caido` (3 o más).
// La transición, la auditoría y el evento `salud` los hace private.registrar_salud en la base.
//
// Registrar la salud nunca debe romper la función que la registra: si la base falla, se avisa en el
// registro y se sigue. El mensaje del error se recorta y no lleva llaves ni datos personales.

import type { Bd } from "./bd.ts";

/** Las seis integraciones externas de docs/06 §5.6. */
export type Integracion =
  | "alpaca_trading"
  | "alpaca_datos"
  | "alpaca_noticias"
  | "deepseek"
  | "jev"
  | "fcm";

/** Largo máximo del error que se guarda (la base lo recorta igual). */
export const LARGO_MAXIMO_DE_ERROR = 300;

/** Texto de un error para `ultimo_error`: solo el mensaje, sin la pila, recortado. */
export function textoDeError(error: unknown): string {
  const mensaje = error instanceof Error ? error.message : String(error);
  return mensaje.slice(0, LARGO_MAXIMO_DE_ERROR);
}

/**
 * Registra el resultado de una llamada a [integracion]. `error` solo se usa cuando `ok` es falso.
 * No lanza: devuelve `false` si no se pudo registrar.
 */
export async function registrarSalud(
  bd: Bd,
  integracion: Integracion,
  ok: boolean,
  error?: unknown,
): Promise<boolean> {
  try {
    await bd.llamar("registrar_salud", [
      integracion,
      ok,
      ok || error === undefined ? null : textoDeError(error),
    ]);
    return true;
  } catch (fallo) {
    console.error(
      `salud: no se pudo registrar ${integracion}: ${
        fallo instanceof Error ? fallo.message : fallo
      }`,
    );
    return false;
  }
}
