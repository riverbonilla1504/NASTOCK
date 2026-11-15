// HU-085 · E2E-05: el aislamiento se verifica contra la API con Auth real.
import { assertEquals } from "@std/assert";
import { conBd } from "./utilidades/pruebas.ts";
import { crearUsuarioDePrueba } from "./utilidades/sesion.ts";

Deno.test("E2E-05 · alertas por audiencia y privacidad de destinatario", async () => {
  await conBd(async (sql) => {
    const usuario = await crearUsuarioDePrueba(sql, "usuario");
    const admin = await crearUsuarioDePrueba(sql, "administrador");
    const clave = `e2e085-${crypto.randomUUID()}`;
    try {
      await sql`select private.crear_alerta('e2e085','usuario','Personal','Solo destinatario',${clave},${usuario.id}::uuid)`;
      const [{ id }] =
        await sql`select id from public.alertas where clave_dedup=${clave}`;
      const propia = await usuario.sesion.leer(
        "alertas",
        `id=eq.${id}&select=id`,
      );
      assertEquals(propia.estado, 200);
      assertEquals(propia.cuerpo, [{ id }]);
      const ajena = await admin.sesion.leer("alertas", `id=eq.${id}&select=id`);
      assertEquals(ajena.estado, 200);
      assertEquals(ajena.cuerpo, []);
      await sql`select private.resolver_alerta(${clave})`;
      await sql`select private.crear_alerta('e2e085','usuario','Rearmada','Nueva causa',${clave},${usuario.id}::uuid)`;
      const activas = await usuario.sesion.leer(
        "alertas",
        `clave_dedup=eq.${clave}&activa=eq.true&select=id`,
      );
      assertEquals((activas.cuerpo as { id: string }[]).length, 1);
      assertEquals((activas.cuerpo as { id: string }[])[0].id === id, false);
    } finally {
      await sql`delete from public.alertas where clave_dedup=${clave}`;
      await usuario.eliminar();
      await admin.eliminar();
    }
  });
});
