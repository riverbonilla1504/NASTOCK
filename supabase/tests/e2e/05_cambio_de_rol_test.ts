// E2E-05 · HU-011: el cambio de rol aplica permisos incluso con el JWT anterior.
import { assertEquals, assertStringIncludes } from "@std/assert";
import { conBd } from "./utilidades/pruebas.ts";
import { crearUsuarioDePrueba, iniciarSesion } from "./utilidades/sesion.ts";

Deno.test("E2E-05 · cambiar rol crea/cierra cupo y revoca permisos del token anterior", async () => {
  await conBd(async (sql) => {
    const admin = await crearUsuarioDePrueba(sql, "administrador");
    const destino = await crearUsuarioDePrueba(sql, "analista");
    try {
      const cambiar = (rol: string) =>
        admin.sesion.rpc("cambiar_rol", {
          p_usuario_id: destino.id,
          p_rol: rol,
        });
      assertEquals((await cambiar("usuario")).estado, 204);
      const [cupo] = await sql`select efectivo, estado from public.subcuentas
        where usuario_id = ${destino.id} and estado = 'abierta'`;
      assertEquals(Number(cupo.efectivo), 0);
      assertEquals(cupo.estado, "abierta");
      const usuario = await iniciarSesion(destino.correo, destino.contrasena);
      assertEquals((await cambiar("administrador")).estado, 204);
      const conPermiso = await iniciarSesion(
        destino.correo,
        destino.contrasena,
      );
      // Tras volver a Analista, el token que decía Administrador ya no autoriza.
      assertEquals((await cambiar("analista")).estado, 204);
      const denegado = await conPermiso.rpc("cambiar_rol", {
        p_usuario_id: admin.id,
        p_rol: "analista",
      });
      assertStringIncludes(JSON.stringify(denegado.cuerpo), "NO_AUTORIZADO");
      const sinPermiso = await usuario.rpc("cambiar_rol", {
        p_usuario_id: admin.id,
        p_rol: "analista",
      });
      assertStringIncludes(JSON.stringify(sinPermiso.cuerpo), "NO_AUTORIZADO");
      const [{ abiertos }] = await sql`select count(*)::int as abiertos
        from public.subcuentas where usuario_id = ${destino.id} and estado = 'abierta'`;
      assertEquals(abiertos, 0);
    } finally {
      await destino.eliminar();
      await admin.eliminar();
    }
  });
});
