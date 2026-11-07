// Pruebas de humo (docs/15 §11): se corren contra el proyecto MVP después de cada despliegue
// (`despliegue.yml`, trabajo `humo`). Aquí va lo que comparten: a qué proyecto se le habla.
// Cada verificación de docs/15 §11 entra con la historia que la hace posible (TT-08, HU-114).

/** Variable obligatoria: sin ella la prueba falla con un mensaje claro, no con un 404. */
function exigir(nombre: string): string {
  const valor = Deno.env.get(nombre);
  if (!valor) {
    throw new Error(`Falta la variable ${nombre} para la prueba de humo`);
  }
  return valor;
}

export const proyecto = {
  /** URL del proyecto (`vars.SUPABASE_URL` en el despliegue). */
  get url(): string {
    return exigir("SUPABASE_URL").replace(/\/$/, "");
  },
  /** Llave publicable (`vars.SUPABASE_PUBLISHABLE_KEY`): la única que usa la prueba de humo. */
  get llavePublicable(): string {
    return exigir("SUPABASE_PUBLISHABLE_KEY");
  },
};
