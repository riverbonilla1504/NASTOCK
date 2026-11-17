// HU-109 · E2E-05: un Usuario no ve el cupo de otro ni escribe directo en las tablas de dinero
// (CA-5). Por la API, con Auth real: lo mismo que haría la app o alguien con su token.
// La suite pgTAP (28 a 30) lo prueba tabla por tabla y función por función.
import { assertEquals } from "@std/assert";
import { conBd, type Sql } from "./utilidades/pruebas.ts";
import { crearUsuarioDePrueba, type Sesion } from "./utilidades/sesion.ts";

async function cupoDe(sql: Sql, usuarioId: string): Promise<string> {
  const [{ id }] = await sql`
    select id from public.subcuentas
     where usuario_id = ${usuarioId} and tipo = 'cupo' and estado = 'abierta'`;
  return id;
}

/** La API rechaza la escritura por permisos (42501) y responde 403. */
async function rechazada(
  sesion: Sesion,
  descripcion: string,
  ruta: string,
  metodo: "POST" | "PATCH" | "DELETE",
  cuerpo?: Record<string, unknown>,
) {
  const respuesta = await sesion.peticion(ruta, {
    method: metodo,
    body: cuerpo ? JSON.stringify(cuerpo) : undefined,
  });
  assertEquals(
    [respuesta.estado, (respuesta.cuerpo as { code?: string } | null)?.code],
    [403, "42501"],
    `${descripcion}: ${JSON.stringify(respuesta.cuerpo)}`,
  );
}

Deno.test("E2E-05 · un Usuario no ve el cupo de otro ni escribe directo en el dinero", async () => {
  await conBd(async (sql) => {
    const a = await crearUsuarioDePrueba(sql, "usuario");
    const b = await crearUsuarioDePrueba(sql, "usuario");
    try {
      const cupoA = await cupoDe(sql, a.id);
      const cupoB = await cupoDe(sql, b.id);
      const [{ fondo_id: fondo }] =
        await sql`select fondo_id from public.subcuentas where id = ${cupoA}`;

      // Lectura: cada uno ve su cupo y nada del otro, aunque lo pida por su id.
      const propios = await a.sesion.leer("subcuentas", "select=id");
      assertEquals(propios.estado, 200);
      assertEquals(propios.cuerpo, [{ id: cupoA }]);
      const ajeno = await a.sesion.leer(
        "subcuentas",
        `select=id&id=eq.${cupoB}`,
      );
      assertEquals(ajeno.estado, 200);
      assertEquals(ajeno.cuerpo, []);
      const asientosAjenos = await a.sesion.leer(
        "asientos",
        `select=id&subcuenta_id=eq.${cupoB}`,
      );
      assertEquals(asientosAjenos.cuerpo, []);
      const delOtro = await b.sesion.leer(
        "subcuentas",
        `select=id&id=eq.${cupoA}`,
      );
      assertEquals(delOtro.cuerpo, []);

      const miCupo = await a.sesion.rpc("mi_cupo");
      assertEquals(miCupo.estado, 200);
      assertEquals(
        (miCupo.cuerpo as { subcuenta_id: string }[]).map((f) =>
          f.subcuenta_id
        ),
        [cupoA],
      );

      // Escritura directa: rechazada en subcuentas, movimientos y asientos.
      await rechazada(
        a.sesion,
        "subirse el saldo del cupo propio",
        `/rest/v1/subcuentas?id=eq.${cupoA}`,
        "PATCH",
        {
          efectivo: 1_000_000,
        },
      );
      await rechazada(
        a.sesion,
        "vaciar el cupo de otro",
        `/rest/v1/subcuentas?id=eq.${cupoB}`,
        "PATCH",
        {
          efectivo: 0,
        },
      );
      await rechazada(
        a.sesion,
        "crearse otro cupo",
        "/rest/v1/subcuentas",
        "POST",
        {
          fondo_id: fondo,
          tipo: "cupo",
          usuario_id: a.id,
        },
      );
      await rechazada(
        a.sesion,
        "borrar el cupo de otro",
        `/rest/v1/subcuentas?id=eq.${cupoB}`,
        "DELETE",
      );
      await rechazada(
        a.sesion,
        "registrar un movimiento",
        "/rest/v1/movimientos",
        "POST",
        {
          fondo_id: fondo,
          tipo: "aporte",
          descripcion: "E2E-05",
        },
      );
      await rechazada(
        a.sesion,
        "anotar un asiento en su cupo",
        "/rest/v1/asientos",
        "POST",
        {
          movimiento_id: crypto.randomUUID(),
          subcuenta_id: cupoA,
          concepto: "efectivo",
          monto: 1000,
        },
      );
      await rechazada(
        a.sesion,
        "borrar asientos",
        `/rest/v1/asientos?subcuenta_id=eq.${cupoB}`,
        "DELETE",
      );

      // Y nada cambió.
      const cupos = await sql`
        select id, efectivo::text, estado::text from public.subcuentas
         where id in (${cupoA}, ${cupoB}) order by id`;
      assertEquals(
        cupos.map((c) => [c.efectivo, c.estado]),
        [["0.00", "abierta"], ["0.00", "abierta"]],
      );
      const [{ asientos }] = await sql`
        select count(*)::int as asientos from public.asientos where subcuenta_id in (${cupoA}, ${cupoB})`;
      assertEquals(asientos, 0);
    } finally {
      await b.eliminar();
      await a.eliminar();
    }
  });
});
