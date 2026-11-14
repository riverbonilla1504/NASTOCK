// E2E-06 (parte de backend, D-72) · Ciclo de IA con JEV simulado: Oportunidades con nivel y
// explicación; con la IA apagada el ciclo se omite; el Administrador lanza un ciclo a mano.
// Sin contexto ni alerta de contradicción (D-59). La pantalla se prueba con widgets.
//
// HU-046 CA-3 y CA-5, HU-047 CA-7, HU-048 CA-1 y CA-2, docs/07 §6.3 y §14.

import { assert, assertEquals } from "@std/assert";
import { despertarFuncion, esperarFunciones } from "./utilidades/funciones.ts";
import {
  conBd,
  pausarTrabajos,
  restablecer,
  type Sql,
} from "./utilidades/pruebas.ts";
import { crearUsuarioDePrueba } from "./utilidades/sesion.ts";

type Oportunidad = {
  bolsillo: string;
  resultado: string;
  estado_contexto: string;
  explicacion: {
    que: string;
    nivel: string | null;
    jev: { probabilidades: Record<string, number> | null } | null;
    advertencias: string[];
  };
};

async function fijarIa(sql: Sql, encendida: boolean): Promise<void> {
  await sql`update public.fondos set ia_activa = ${encendida}`;
}

Deno.test("E2E-06: el ciclo de IA llega a Oportunidades con nivel y lo que respondió JEV", async () => {
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
    const admin = await crearUsuarioDePrueba(sql, "administrador");
    const usuario = await crearUsuarioDePrueba(sql, "usuario");
    try {
      // El histórico de barras del proveedor simulado (idempotente).
      assertEquals((await despertarFuncion("calendario-mercado")).estado, 200);

      // HU-046 CA-3: con la IA apagada el ciclo queda omitido y no evalúa.
      await fijarIa(sql, false);
      const apagada = await despertarFuncion("agente");
      assertEquals(apagada.estado, 200);
      const cuerpoApagada = apagada.cuerpo as Record<string, unknown>;
      assertEquals(cuerpoApagada.estado, "omitido");
      assertEquals(cuerpoApagada.motivo, "ia_apagada");

      // Con la IA encendida el ciclo evalúa y guarda cada candidata con su explicación.
      await fijarIa(sql, true);
      const ciclo = await despertarFuncion("agente");
      assertEquals(ciclo.estado, 200);
      const resumen = ciclo.cuerpo as { estado: string; evaluadas: number };
      assertEquals(resumen.estado, "completado");
      assert(resumen.evaluadas > 0, "evalúa candidatas");

      // HU-048 CA-1: el Administrador ve todos los bolsillos, con nivel y JEV (D-72).
      const todas = await admin.sesion.rpc("oportunidades");
      assertEquals(todas.estado, 200);
      const filas = todas.cuerpo as Oportunidad[];
      const evaluadas = filas.filter((f) =>
        !f.resultado.startsWith("excluida")
      );
      assert(evaluadas.length > 0, "hay candidatas evaluadas");
      assert(
        new Set(filas.map((f) => f.bolsillo)).size >= 2,
        "ve más de un bolsillo",
      );
      for (const f of evaluadas) {
        assertEquals(f.estado_contexto, "sin_contexto"); // D-59
        assert(f.explicacion.que.length > 0, "cada una tiene su explicación");
        assert(
          ["favorable", "vigilar", "desfavorable"].includes(
            f.explicacion.nivel ?? "",
          ),
          `nivel válido para ${f.resultado}`,
        );
        const p = f.explicacion.jev?.probabilidades;
        assert(p, "trae las probabilidades de JEV");
        const suma = p.comprar + p.esperar + p.evitar;
        assert(Math.abs(suma - 1) < 0.001, "las probabilidades suman 1");
        // Solo `favorable` cuenta como recomendación (docs/07 §6.3).
        if (f.resultado === "elegida") {
          assertEquals(f.explicacion.nivel, "favorable");
        }
        if (f.explicacion.nivel !== "favorable") {
          assert(
            f.resultado.startsWith("no_elegible"),
            "lo no favorable no se recomienda",
          );
        }
      }

      // HU-048 CA-2: el Usuario solo ve el bolsillo de Usuarios.
      const suyas = await usuario.sesion.rpc("oportunidades");
      assertEquals(suyas.estado, 200);
      const deUsuario = suyas.cuerpo as Oportunidad[];
      assert(deUsuario.length > 0);
      assert(deUsuario.every((f) => f.bolsillo === "usuarios"));
      const ajenas = await usuario.sesion.rpc("oportunidades", {
        p_bolsillo: "arriesgadas",
      });
      assertEquals(ajenas.cuerpo, []);

      // HU-046 CA-5: el Usuario no lanza ciclos; el Administrador sí, con disparador manual.
      assertEquals((await usuario.sesion.rpc("lanzar_ciclo")).estado, 400);
      const [{ ultimo }] = await sql`
        select coalesce(max(iniciado_en), '-infinity') as ultimo from public.ciclos_agente`;
      assertEquals((await admin.sesion.rpc("lanzar_ciclo")).estado, 204);
      let manual: { estado: string } | undefined;
      for (let i = 0; i < 60 && !manual; i++) {
        [manual] = await sql`
          select estado from public.ciclos_agente
           where disparador = 'manual' and iniciado_en > ${ultimo}
             and estado <> 'en_curso'`;
        if (!manual) await new Promise((r) => setTimeout(r, 1_000));
      }
      assertEquals(
        manual?.estado,
        "completado",
        "el ciclo manual corre y termina",
      );
    } finally {
      await reanudar();
      await fijarIa(sql, antes);
      await admin.eliminar();
      await usuario.eliminar();
      await restablecer(sql);
    }
  });
});
