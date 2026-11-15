// HU-076 · E2E-08: cancelar una orden creada antes del envío, por API real.
import { assertEquals, assertStringIncludes } from "@std/assert";
import { conBd, pausarTrabajos } from "./utilidades/pruebas.ts";
import { crearUsuarioDePrueba } from "./utilidades/sesion.ts";

Deno.test("E2E-08 · solo el dueño cancela una orden creada, sin enviarla al broker", async () => {
  await conBd(async (sql) => {
    const reanudar = await pausarTrabajos(sql, [
      "barrer_ejecutor",
      "sincronizar_ordenes",
    ]);
    const usuario = await crearUsuarioDePrueba(sql, "usuario");
    const otro = await crearUsuarioDePrueba(sql, "usuario");
    const id = crypto.randomUUID();
    try {
      await sql`insert into public.ordenes(id,origen,subcuenta_id,simbolo,lado,clase,tipo,tif,cantidad,precio_limite,parametros)
        select ${id}::uuid,'manual',id,'AAPL','compra','simple','limite','day',1,50,'{}'
        from public.subcuentas where usuario_id=${usuario.id} and estado='abierta'`;
      const ajena = await otro.sesion.rpc("cancelar_orden", { p_id: id });
      assertStringIncludes(JSON.stringify(ajena.cuerpo), "NO_AUTORIZADO");
      assertEquals(
        (await usuario.sesion.rpc("cancelar_orden", { p_id: id })).estado,
        204,
      );
      const respuesta = await usuario.sesion.leer(
        "ordenes",
        `id=eq.${id}&select=estado,retencion,broker_order_id`,
      );
      assertEquals(respuesta.estado, 200);
      assertEquals(respuesta.cuerpo, [{
        estado: "cancelada",
        retencion: 0,
        broker_order_id: null,
      }]);
      assertEquals(
        (await usuario.sesion.rpc("cancelar_orden", { p_id: id })).estado,
        204,
      );
    } finally {
      await sql`delete from pgmq.q_ordenes_por_enviar where message->>'orden_id'=${id}`;
      await sql`delete from public.ordenes_eventos where orden_id=${id}::uuid`;
      await sql`delete from public.ordenes where id=${id}::uuid`;
      await usuario.eliminar();
      await otro.eliminar();
      await reanudar();
    }
  });
});
