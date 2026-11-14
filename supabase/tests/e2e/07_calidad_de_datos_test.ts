// E2E-07 · Calidad de datos del ciclo de IA: una candidata con datos incompletos se excluye con
// su motivo y, sin QQQ, el ciclo completo se omite (HU-044 CA-1 y CA-2, CB-87, docs/07 §4.1).
//
// Las barras que la prueba quita se guardan en memoria y se devuelven al terminar.

import { assert, assertEquals } from "@std/assert";
import { despertarFuncion, esperarFunciones } from "./utilidades/funciones.ts";
import {
  conBd,
  pausarTrabajos,
  restablecer,
  type Sql,
} from "./utilidades/pruebas.ts";

type Barra = Record<string, unknown>;

async function quitarBarras(
  sql: Sql,
  simbolo: string,
  dejar: number,
): Promise<Barra[]> {
  const quitadas = await sql`
    delete from public.barras_diarias
     where simbolo = ${simbolo}
       and fecha < (select fecha from public.barras_diarias where simbolo = ${simbolo}
                     order by fecha desc offset ${dejar - 1} limit 1)
    returning *`;
  return [...quitadas];
}

async function devolverBarras(sql: Sql, barras: Barra[]): Promise<void> {
  if (barras.length) {
    await sql`insert into public.barras_diarias ${
      sql(barras)
    } on conflict do nothing`;
  }
}

Deno.test("E2E-07: datos incompletos excluyen la candidata y, sin QQQ, el ciclo se omite", async () => {
  await esperarFunciones();
  await conBd(async (sql) => {
    // EC-040: solo la prueba despierta al agente mientras corre.
    const reanudar = await pausarTrabajos(sql, ["ciclo_agente"]);
    // Un ciclo que pg_cron ya había empezado termina antes de que la prueba corra los suyos.
    for (let i = 0; i < 60; i++) {
      const [{ enCurso }] = await sql`
        select count(*)::int as "enCurso" from public.ciclos_agente where estado = 'en_curso'`;
      if (enCurso === 0) break;
      await new Promise((r) => setTimeout(r, 1_000));
    }
    const [{ antes }] = await sql`select ia_activa as antes from public.fondos`;
    let quitadas: Barra[] = [];
    try {
      assertEquals((await despertarFuncion("calendario-mercado")).estado, 200);
      await sql`update public.fondos set ia_activa = true`;

      // Una acción de la lista blanca con solo 30 barras diarias (menos de 60).
      const [{ simbolo }] = await sql`
        select simbolo from public.lista_blanca
         where activo and simbolo not in ('QQQ', 'QLD', 'TQQQ')
         order by simbolo limit 1`;
      quitadas = await quitarBarras(sql, simbolo, 30);
      assert(quitadas.length > 0, `se quitaron barras de ${simbolo}`);

      const ciclo = await despertarFuncion("agente");
      assertEquals(ciclo.estado, 200);
      assertEquals((ciclo.cuerpo as { estado: string }).estado, "completado");
      const [fila] = await sql`
        select e.resultado, e.calidad_datos
          from public.evaluaciones_candidatos e
          join public.ciclos_agente c on c.id = e.ciclo_id
         where c.id = ${
        (ciclo.cuerpo as { ciclo: string }).ciclo
      } and e.simbolo = ${simbolo}`;
      assertEquals(fila?.calidad_datos, "barras_insuficientes");
      assertEquals(fila?.resultado, "excluida:barras_insuficientes");
      await devolverBarras(sql, quitadas);
      quitadas = [];

      // CB-87: sin barras de QQQ el ciclo entero se omite.
      quitadas =
        await sql`delete from public.barras_diarias where simbolo = 'QQQ' returning *`;
      const sinQqq = await despertarFuncion("agente");
      assertEquals(sinQqq.estado, 200);
      const cuerpo = sinQqq.cuerpo as { estado: string; motivo: string };
      assertEquals(cuerpo.estado, "omitido");
      assertEquals(cuerpo.motivo, "qqq_sin_datos");
    } finally {
      await reanudar();
      await devolverBarras(sql, quitadas);
      await sql`update public.fondos set ia_activa = ${antes}`;
      await restablecer(sql);
    }
  });
});
