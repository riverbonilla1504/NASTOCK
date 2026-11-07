// E2E-02 · Invitación: el invitado entra; el no invitado y el proveedor no permitido son
// rechazados con su mensaje (docs/15 §4, HU-002).
//
// El ingreso con Google no se puede automatizar (docs/04 §1), así que el alta se prueba con
// correo y contraseña, que solo existen en local y CI: Auth real, con su hook "antes de crear
// usuario" y su trigger de alta. Las pruebas que cambian `parametros` o el reloj los restauran
// siempre en un `finally`.

import { assert, assertEquals, assertStringIncludes } from "@std/assert";
import { esperarFunciones } from "./utilidades/funciones.ts";
import { conBd, fijarReloj, restablecer, type Sql } from "./utilidades/pruebas.ts";
import { iniciarSesion, sesionAnonima } from "./utilidades/sesion.ts";
import { entorno } from "./utilidades/entorno.ts";

const SIN_INVITACION =
  "Tu correo no tiene una invitación vigente. Pídele una al administrador.";
const DOMINIO_NO_PERMITIDO = "Solo se admiten cuentas corporativas de RiTech.";
const PROVEEDOR_NO_PERMITIDO =
  "Solo puedes ingresar con tu cuenta de Google de RiTech.";

function correoNuevo(prefijo: string, dominio = "prueba.local"): string {
  return `e2e02-${prefijo}-${crypto.randomUUID().slice(0, 8)}@${dominio}`;
}

/** Intenta darse de alta con correo y contraseña, como lo haría el cliente de Auth. */
function registrarse(correo: string) {
  return sesionAnonima().peticion("/auth/v1/signup", {
    method: "POST",
    body: JSON.stringify({ email: correo, password: crypto.randomUUID() }),
  });
}

async function invitar(
  sql: Sql,
  correo: string,
  rol: string,
  vencida = false,
) {
  if (vencida) {
    await sql`insert into public.invitaciones (email, rol, expira_en)
              values (${correo}, ${rol}, now() - interval '1 day')`;
  } else {
    await sql`insert into public.invitaciones (email, rol) values (${correo}, ${rol})`;
  }
}

async function existeUsuario(sql: Sql, correo: string): Promise<boolean> {
  const [{ cuantos }] = await sql`
    select count(*)::int as cuantos from auth.users where lower(email) = ${correo}`;
  return cuantos > 0;
}

/** Borra lo que una prueba dejó: perfil, invitaciones y usuario de Auth. */
async function limpiar(sql: Sql, correos: string[]) {
  for (const correo of correos) {
    await sql`update public.invitaciones set usuario_id = null where lower(email) = ${correo}`;
    await sql`delete from public.perfiles where email = ${correo}`;
    await sql`delete from public.invitaciones where lower(email) = ${correo}`;
    await sql`delete from auth.identities where lower(email) = ${correo}`;
    await sql`delete from auth.users where lower(email) = ${correo}`;
  }
}

Deno.test("E2E-02: el invitado entra y queda activo con el rol de su invitación", async () => {
  await esperarFunciones();
  await conBd(async (sql) => {
    const correo = correoNuevo("ok");
    try {
      await invitar(sql, correo, "analista");
      const respuesta = await registrarse(correo);
      assertEquals(respuesta.estado, 200, JSON.stringify(respuesta.cuerpo));

      const [perfil] = await sql`
        select rol, estado from public.perfiles where email = ${correo}`;
      assertEquals([perfil.rol, perfil.estado], ["analista", "activo"]);
      const [invitacion] = await sql`
        select estado from public.invitaciones where email = ${correo}`;
      assertEquals(invitacion.estado, "aceptada");
      const [{ cuantos }] = await sql`
        select count(*)::int as cuantos from public.auditoria a
        join public.perfiles p on p.id::text = a.entidad_id
        where a.accion = 'cuenta.activada' and p.email = ${correo}`;
      assertEquals(cuantos, 1);
    } finally {
      await limpiar(sql, [correo]);
    }
  });
});

Deno.test("E2E-02: sin invitación, con invitación vencida o de otro dominio, el alta se rechaza con su mensaje", async () => {
  await conBd(async (sql) => {
    const sinInvitar = correoNuevo("sin");
    const vencida = correoNuevo("vencida");
    const otroDominio = correoNuevo("dominio", "otra.test");
    try {
      const a = await registrarse(sinInvitar);
      assertEquals(a.estado, 403, JSON.stringify(a.cuerpo));
      assertStringIncludes(JSON.stringify(a.cuerpo), SIN_INVITACION);

      await invitar(sql, vencida, "usuario", true);
      const b = await registrarse(vencida);
      assertEquals(b.estado, 403, JSON.stringify(b.cuerpo));
      assertStringIncludes(JSON.stringify(b.cuerpo), SIN_INVITACION);

      await invitar(sql, otroDominio, "usuario");
      const c = await registrarse(otroDominio);
      assertEquals(c.estado, 403, JSON.stringify(c.cuerpo));
      assertStringIncludes(JSON.stringify(c.cuerpo), DOMINIO_NO_PERMITIDO);

      for (const correo of [sinInvitar, vencida, otroDominio]) {
        assert(!(await existeUsuario(sql, correo)), `${correo} no se crea`);
      }
    } finally {
      await limpiar(sql, [sinInvitar, vencida, otroDominio]);
    }
  });
});

Deno.test("E2E-02: una invitación que pasa de 7 días con el reloj deja de servir", async () => {
  await conBd(async (sql) => {
    const correo = correoNuevo("reloj");
    try {
      await invitar(sql, correo, "usuario");
      await fijarReloj(sql, new Date(Date.now() + 8 * 24 * 3600 * 1000));
      const respuesta = await registrarse(correo);
      assertEquals(respuesta.estado, 403, JSON.stringify(respuesta.cuerpo));
      assertStringIncludes(JSON.stringify(respuesta.cuerpo), SIN_INVITACION);
      assert(!(await existeUsuario(sql, correo)));
    } finally {
      await restablecer(sql);
      await limpiar(sql, [correo]);
    }
  });
});

Deno.test("E2E-02: con solo google permitido, el alta con correo y contraseña se rechaza (CB-92)", async () => {
  await conBd(async (sql) => {
    const correo = correoNuevo("proveedor");
    const [{ valor }] = await sql`
      select valor from public.parametros where clave = 'auth.proveedores_permitidos'`;
    try {
      await invitar(sql, correo, "usuario");
      await sql`update public.parametros set valor = '["google"]'::jsonb
                where clave = 'auth.proveedores_permitidos'`;
      const respuesta = await registrarse(correo);
      assertEquals(respuesta.estado, 403, JSON.stringify(respuesta.cuerpo));
      assertStringIncludes(
        JSON.stringify(respuesta.cuerpo),
        PROVEEDOR_NO_PERMITIDO,
      );
      assert(!(await existeUsuario(sql, correo)));
    } finally {
      await sql`update public.parametros set valor = ${sql.json(valor)}
                where clave = 'auth.proveedores_permitidos'`;
      await limpiar(sql, [correo]);
    }
  });
});

Deno.test("E2E-02: los usuarios de prueba de la semilla ingresan con correo y contraseña (CA-7)", async () => {
  for (
    const [correo, rol] of [
      ["admin@prueba.local", "administrador"],
      ["analista1@prueba.local", "analista"],
      ["usuario1@prueba.local", "usuario"],
    ]
  ) {
    const sesion = await iniciarSesion(correo, "prueba-local-1234");
    const claims = JSON.parse(
      atob(sesion.token!.split(".")[1].replace(/-/g, "+").replace(/_/g, "/")),
    );
    assertEquals(claims.app_rol, rol);
    assertEquals(claims.app_estado, "activo");
  }
  assert(entorno.urlApi.length > 0);
});
