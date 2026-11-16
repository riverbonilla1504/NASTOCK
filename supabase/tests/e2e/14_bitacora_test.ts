// HU-108 · La API audita una invitación y respeta el aislamiento por rol.
import { assertEquals, assertStringIncludes } from "@std/assert";
import { conBd } from "./utilidades/pruebas.ts";
import { crearUsuarioDePrueba } from "./utilidades/sesion.ts";

Deno.test("E2E-14 · una invitación se ve en la bitácora del administrador", async () => {
  await conBd(async (sql) => {
    const admin = await crearUsuarioDePrueba(sql, "administrador");
    const usuario = await crearUsuarioDePrueba(sql, "usuario");
    const analista = await crearUsuarioDePrueba(sql, "analista");
    const correo = `e2e-bitacora-${crypto.randomUUID()}@gmail.com`;
    try {
      const invitacion = await admin.sesion.rpc("invitar_usuario", {
        p_email: correo,
        p_rol: "usuario",
        p_cupo_inicial: 0,
      });
      assertEquals(invitacion.estado, 200);
      const filtro = `actor_id=eq.${admin.id}&select=accion,entidad`;
      const lectura = await admin.sesion.leer("auditoria", filtro);
      assertEquals(lectura.estado, 200);
      assertStringIncludes(JSON.stringify(lectura.cuerpo), "cuenta.invitada");
      for (const persona of [usuario, analista]) {
        const denegada = await persona.sesion.leer("auditoria", filtro);
        assertEquals(denegada.estado, 200);
        assertEquals(denegada.cuerpo, []);
      }
      const [cadena] = await sql`select private.verificar_cadena_auditoria() as invalido`;
      assertEquals(cadena.invalido, null);
    } finally {
      await sql`delete from public.invitaciones where email = ${correo}`;
      await analista.eliminar();
      await usuario.eliminar();
      await admin.eliminar();
    }
  });
});
