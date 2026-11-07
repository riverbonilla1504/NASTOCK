// Llamar a las Edge Functions servidas con `supabase functions serve` (proveedores simulados).

import { entorno } from "./entorno.ts";
import { leerRespuesta, type Respuesta } from "./sesion.ts";

/** Cabecera con la que private.despertar_funcion envía el secreto interno. */
export const CABECERA_SECRETO_INTERNO = "x-secreto-interno";

/**
 * Hace lo mismo que `private.despertar_funcion` (pg_net): un POST con el secreto interno en
 * `x-secreto-interno` y nada más. Con `secreto` en `null`, la llamada va sin él.
 */
export async function despertarFuncion(
  nombre: string,
  secreto: string | null = entorno.secretoInterno,
): Promise<Respuesta> {
  const cabeceras: Record<string, string> = {
    "Content-Type": "application/json",
  };
  if (secreto !== null) cabeceras[CABECERA_SECRETO_INTERNO] = secreto;
  return leerRespuesta(
    await fetch(`${entorno.urlApi}/functions/v1/${nombre}`, {
      method: "POST",
      headers: cabeceras,
      body: "{}",
    }),
  );
}

/**
 * Espera a que las funciones estén servidas: llama a `calendario-mercado` sin secreto hasta que
 * responda 401 (la respuesta propia de la función, sin efectos). Reemplaza una espera fija.
 */
export async function esperarFunciones(
  limiteMs = 90_000,
  nombre = "calendario-mercado",
): Promise<void> {
  const limite = Date.now() + limiteMs;
  let ultimo = "sin respuesta";
  while (Date.now() < limite) {
    try {
      const respuesta = await despertarFuncion(nombre, null);
      if (respuesta.estado === 401) return;
      ultimo = `estado ${respuesta.estado}`;
    } catch (error) {
      ultimo = error instanceof Error ? error.message : String(error);
    }
    await new Promise((resolver) => setTimeout(resolver, 1_000));
  }
  throw new Error(
    `Las funciones no respondieron en ${limiteMs / 1000} s (${ultimo}). ` +
      "¿Está corriendo `supabase functions serve`?",
  );
}
