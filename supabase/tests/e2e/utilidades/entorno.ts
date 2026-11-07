// Dónde está el stack local y con qué llaves se le habla.
//
// `scripts/verificar.sh` y el trabajo `e2e` de CI exportan las variables de
// `supabase status -o env`. Si faltan, se usan los valores por defecto de
// `supabase start`. Todo esto es solo local y CI (docs/15 §3).

/** Valor de prueba de SECRETO_INTERNO: el mismo que siembra supabase/seed.sql en Vault. */
export const SECRETO_INTERNO_DE_PRUEBA = "solo-local-no-es-secreto";

function leer(...nombres: string[]): string | undefined {
  for (const nombre of nombres) {
    const valor = Deno.env.get(nombre);
    if (valor) return valor;
  }
  return undefined;
}

export const entorno = {
  /** API de Supabase (REST, Auth, Edge Functions). */
  urlApi: leer("API_URL") ?? "http://127.0.0.1:54321",
  /** Conexión directa a Postgres, solo para las ayudas del esquema `pruebas`. */
  urlBd: leer("DB_URL") ??
    "postgresql://postgres:postgres@127.0.0.1:54322/postgres",
  /** Llave anónima (o publicable) de la API. */
  llaveAnonima: leer("ANON_KEY", "PUBLISHABLE_KEY") ?? "",
  /** Llave de servicio (o secreta): solo para crear usuarios de prueba. */
  llaveDeServicio: leer("SERVICE_ROLE_KEY", "SECRET_KEY") ?? "",
  /** Secreto que aceptan las funciones internas (x-secreto-interno). */
  secretoInterno: leer("SECRETO_INTERNO") ?? SECRETO_INTERNO_DE_PRUEBA,
};
