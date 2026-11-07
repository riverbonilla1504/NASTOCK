// TT-06 · Escenario mínimo del arnés E2E de backend (docs/15 §2).
//
// Comprueba que el arnés funciona de punta a punta contra Supabase local con las funciones
// servidas y los proveedores simulados: llamar a una función, controlar el reloj y los
// escenarios, y actuar como distintos usuarios. No es un escenario del catálogo de docs/15 §4:
// cada historia agrega después el suyo (E2E-01 a E2E-16) con estas mismas utilidades.
//
// Se corre con `deno test --allow-all supabase/tests/e2e` (scripts/verificar.sh y CI lo hacen
// con las funciones ya servidas: `supabase functions serve --env-file …`).

import { assert, assertEquals } from "@std/assert";
import { despertarFuncion, esperarFunciones } from "./utilidades/funciones.ts";
import {
  conBd,
  elegirEscenario,
  fijarReloj,
  restablecer,
} from "./utilidades/pruebas.ts";
import { crearUsuarioDePrueba } from "./utilidades/sesion.ts";

Deno.test("arnés: calendario-mercado responde solo con el secreto interno", async () => {
  await esperarFunciones();

  assertEquals(
    (await despertarFuncion("calendario-mercado", null)).estado,
    401,
  );
  assertEquals(
    (await despertarFuncion("calendario-mercado", "secreto-equivocado")).estado,
    403,
  );

  const respuesta = await despertarFuncion("calendario-mercado");
  assertEquals(respuesta.estado, 200);
  const resultado = respuesta.cuerpo as Record<string, unknown>;
  assertEquals(typeof resultado.simbolos_consultados, "number");
  assertEquals(resultado.pendientes, []);
});

Deno.test("arnés: la prueba controla el reloj y los escenarios de los proveedores", async () => {
  await conBd(async (sql) => {
    try {
      const hora = new Date("2027-03-15T14:30:00Z");
      assertEquals(await fijarReloj(sql, hora), hora);
      const [{ ahora }] = await sql`select private.ahora() as ahora`;
      assertEquals(new Date(ahora), hora);

      await elegirEscenario(sql, "broker", "llenado_parcial");
      const escenarios = await sql`
        select proveedor, escenario from pruebas.escenarios`;
      assertEquals(
        escenarios.map((e) => [e.proveedor, e.escenario]),
        [["broker", "llenado_parcial"]],
      );
    } finally {
      await restablecer(sql);
    }

    const [{ ahora }] = await sql`select private.ahora() as ahora`;
    assert(
      Math.abs(new Date(ahora).getTime() - Date.now()) < 60_000,
      "después de restablecer, private.ahora() vuelve a la hora real",
    );
    const [{ cuantos }] = await sql`
      select count(*)::int as cuantos from pruebas.escenarios`;
    assertEquals(cuantos, 0);
  });
});

Deno.test("arnés: se actúa como distintos usuarios y la RLS decide qué ve cada uno", async () => {
  await conBd(async (sql) => {
    const usuario = await crearUsuarioDePrueba(sql, "usuario");
    const analista = await crearUsuarioDePrueba(sql, "analista");
    try {
      const consulta =
        `select=email&id=in.(${usuario.id},${analista.id})&order=email`;

      // Un Usuario ve solo su perfil; un Analista ve el de todos (docs/03 §4.3).
      const delUsuario = await usuario.sesion.leer("perfiles", consulta);
      assertEquals(delUsuario.estado, 200);
      assertEquals(delUsuario.cuerpo, [{ email: usuario.correo }]);

      const delAnalista = await analista.sesion.leer("perfiles", consulta);
      assertEquals(delAnalista.estado, 200);
      assertEquals(
        delAnalista.cuerpo,
        [{ email: analista.correo }, { email: usuario.correo }].sort((a, b) =>
          a.email.localeCompare(b.email)
        ),
      );
    } finally {
      await usuario.eliminar();
      await analista.eliminar();
    }
  });
});
