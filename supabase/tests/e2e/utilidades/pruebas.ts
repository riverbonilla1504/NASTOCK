// Ayudas del esquema `pruebas` (docs/15 §3): reloj y escenarios de los proveedores simulados.
//
// El esquema `pruebas` está cerrado a la API (anon y authenticated no pueden usarlo), así que
// estas ayudas se conectan directo a Postgres como `postgres`, igual que lo haría una persona
// con `psql`. Solo existe en local y CI: lo crea `supabase/seed.sql`.

import postgres from "postgres";
import { entorno } from "./entorno.ts";

export type Sql = ReturnType<typeof postgres>;

/** Proveedores simulados que admite `pruebas.elegir_escenario` (docs/10 §9). */
export type Proveedor =
  | "broker"
  | "mercado"
  | "noticias"
  | "contexto"
  | "jev"
  | "push";

/** Abre una conexión a la base, la presta y la cierra siempre al terminar. */
export async function conBd<T>(uso: (sql: Sql) => Promise<T>): Promise<T> {
  const sql = postgres(entorno.urlBd, { max: 1, onnotice: () => {} });
  try {
    return await uso(sql);
  } finally {
    await sql.end();
  }
}

/** Fija la hora de `private.ahora()`. Con `null` vuelve a la hora real. Devuelve la hora vigente. */
export async function fijarReloj(
  sql: Sql,
  hora: Date | null,
): Promise<Date> {
  const iso = hora ? hora.toISOString() : null;
  const [fila] = await sql`
    select pruebas.fijar_reloj(${iso}::timestamptz) as hora`;
  return new Date(fila.hora);
}

/** Elige el escenario de un proveedor simulado. Con `null` vuelve al comportamiento normal. */
export async function elegirEscenario(
  sql: Sql,
  proveedor: Proveedor,
  escenario: string | null,
): Promise<void> {
  await sql`select pruebas.elegir_escenario(${proveedor}, ${escenario})`;
}

/**
 * Pausa trabajos de `pg_cron` mientras dura la prueba y devuelve con qué reanudarlos (EC-040).
 * Un trabajo que despierta una función mientras la prueba mueve el reloj escribe con la hora que
 * ya cambió: la prueba debe ser la única que dispara esa función. Llamarla **antes** de fijar el
 * reloj en una hora que active el trabajo; con el reloj real no hay corridas a medias.
 */
export async function pausarTrabajos(
  sql: Sql,
  nombres: readonly string[],
): Promise<() => Promise<void>> {
  const pausados = await sql<{ jobid: number }[]>`
    select jobid from cron.job where jobname in ${sql(nombres)} and active`;
  for (const { jobid } of pausados) {
    await sql`select cron.alter_job(${jobid}::bigint, active := false)`;
  }
  return async () => {
    for (const { jobid } of pausados) {
      await sql`select cron.alter_job(${jobid}::bigint, active := true)`;
    }
  };
}

/** Deja el reloj real y todos los proveedores en su comportamiento normal. */
export async function restablecer(sql: Sql): Promise<void> {
  await fijarReloj(sql, null);
  await sql`delete from pruebas.escenarios`;
}
