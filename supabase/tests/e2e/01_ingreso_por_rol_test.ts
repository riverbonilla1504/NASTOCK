// E2E-01 · Ingreso por rol: cada rol ve su navegación (docs/15 §4, HU-006). Parte de backend.
//
// La navegación de la app sale de los claims del token (`app_rol`, `app_estado`, docs/03 §4.1) y
// la seguridad real, de la RLS. Esta prueba comprueba, con Auth y la API reales, que los dos
// dicen lo mismo para cada rol: el token de cada usuario de la semilla trae su rol y su estado, y
// la RLS de `perfiles` entrega a cada uno lo que su menú supone (un Usuario solo se ve a sí
// mismo; el Analista y el Administrador, a todos). Una cuenta suspendida trae `suspendido` en su
// token y la RLS deja de entregarle su perfil. La parte de la app (menú y redirecciones) está en
// `integration_test/app_test.dart`.
//
// Lo que crea (la cuenta suspendida) lo borra siempre en un `finally`.

import { assertEquals } from "@std/assert";
import { conBd } from "./utilidades/pruebas.ts";
import {
  crearUsuarioDePrueba,
  iniciarSesion,
  type Sesion,
} from "./utilidades/sesion.ts";

const CONTRASENA_DE_LA_SEMILLA = "prueba-local-1234";

const USUARIOS_DE_LA_SEMILLA = [
  ["admin@prueba.local", "administrador"],
  ["analista1@prueba.local", "analista"],
  ["usuario1@prueba.local", "usuario"],
] as const;

function claimsDe(sesion: Sesion): Record<string, unknown> {
  const carga = sesion.token!.split(".")[1].replace(/-/g, "+").replace(
    /_/g,
    "/",
  );
  return JSON.parse(atob(carga));
}

Deno.test("E2E-01: el token de cada usuario de la semilla trae su rol y su estado", async () => {
  for (const [correo, rol] of USUARIOS_DE_LA_SEMILLA) {
    const claims = claimsDe(
      await iniciarSesion(correo, CONTRASENA_DE_LA_SEMILLA),
    );

    assertEquals(claims.app_rol, rol, correo);
    assertEquals(claims.app_estado, "activo", correo);
  }
});

Deno.test("E2E-01: la RLS de perfiles coincide con la navegación de cada rol", async () => {
  const consulta = "select=email&email=like.*@prueba.local&order=email";
  const todos = [
    "admin@prueba.local",
    "analista1@prueba.local",
    "analista2@prueba.local",
    "usuario1@prueba.local",
    "usuario2@prueba.local",
  ];

  // Un Usuario solo se ve a sí mismo (docs/03 §4.3).
  const usuario = await iniciarSesion(
    "usuario1@prueba.local",
    CONTRASENA_DE_LA_SEMILLA,
  );
  const delUsuario = await usuario.leer("perfiles", consulta);
  assertEquals(delUsuario.estado, 200);
  assertEquals(delUsuario.cuerpo, [{ email: "usuario1@prueba.local" }]);

  // El Analista y el Administrador ven a todos.
  for (const correo of ["analista1@prueba.local", "admin@prueba.local"]) {
    const sesion = await iniciarSesion(correo, CONTRASENA_DE_LA_SEMILLA);
    const respuesta = await sesion.leer("perfiles", consulta);

    assertEquals(respuesta.estado, 200, correo);
    assertEquals(
      (respuesta.cuerpo as { email: string }[]).map((f) => f.email),
      todos,
      correo,
    );
  }
});

Deno.test("E2E-01: una cuenta suspendida trae suspendido en su token y deja de ver su perfil", async () => {
  await conBd(async (sql) => {
    const cuenta = await crearUsuarioDePrueba(sql, "usuario");
    try {
      const consulta = `select=email&id=eq.${cuenta.id}`;
      const antes = await cuenta.sesion.leer("perfiles", consulta);
      assertEquals(antes.cuerpo, [{ email: cuenta.correo }], "activa, se ve");
      assertEquals(claimsDe(cuenta.sesion).app_estado, "activo");

      // En R1 no hay forma de suspender desde la app (HU-010 es de R2): se hace por SQL.
      await sql`update public.perfiles set estado = 'suspendido' where id = ${cuenta.id}`;

      // Un token nuevo trae el estado nuevo, para que la app lleve a /cuenta-suspendida...
      const despues = await iniciarSesion(cuenta.correo, cuenta.contrasena);
      const claims = claimsDe(despues);
      assertEquals(claims.app_rol, "usuario");
      assertEquals(claims.app_estado, "suspendido");

      // ...y la RLS, que es la seguridad real, ya no le entrega su perfil.
      const respuesta = await despues.leer("perfiles", consulta);
      assertEquals(respuesta.estado, 200);
      assertEquals(respuesta.cuerpo, []);
    } finally {
      await cuenta.eliminar();
    }
  });
});
