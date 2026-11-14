// E2E-02 · Invitación: el invitado entra; el no invitado y el proveedor no permitido son
// rechazados con su mensaje (docs/15 §4, HU-002). Con HU-003, el Administrador invita y revoca
// por las RPC `invitar_usuario` y `revocar_invitacion`, y una invitación revocada o vencida no
// deja entrar.
//
// El ingreso con Google no se puede automatizar (docs/04 §1), así que el alta se prueba con
// correo y contraseña, que solo existen en local y CI: Auth real, con su hook "antes de crear
// usuario" y su trigger de alta. Las pruebas que cambian `parametros` o el reloj los restauran
// siempre en un `finally`.

import { assert, assertEquals, assertStringIncludes } from "@std/assert";
import { esperarFunciones } from "./utilidades/funciones.ts";
import {
  conBd,
  fijarReloj,
  restablecer,
  type Sql,
} from "./utilidades/pruebas.ts";
import {
  crearUsuarioDePrueba,
  iniciarSesion,
  type Respuesta,
  type Sesion,
  sesionAnonima,
} from "./utilidades/sesion.ts";
import { entorno } from "./utilidades/entorno.ts";

const SIN_INVITACION =
  "Tu correo no tiene una invitación vigente. Pídele una al administrador.";
const DOMINIO_NO_PERMITIDO = "Solo se admiten cuentas de Google invitadas.";
const PROVEEDOR_NO_PERMITIDO = "Solo puedes ingresar con tu cuenta de Google.";

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
    // El alta de un Usuario crea su cupo en 0 (HU-017): se quita antes del perfil.
    await sql`delete from public.subcuentas where usuario_id in (select id from public.perfiles where email = ${correo})`;
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

// ---------------------------------------------------------------------------------------------
// HU-003 · Invitar y revocar por las RPC `invitar_usuario` y `revocar_invitacion`.
// El Administrador de la semilla invita por la API, como lo hace la app; la persona entra con esa
// invitación (Auth real, con su hook y su trigger de alta) y una invitación revocada o vencida no
// deja entrar. Los códigos de error viajan en `message` (docs/06 §9).
// ---------------------------------------------------------------------------------------------

const CLAVE_DE_PRUEBA = "prueba-local-1234";

interface InvitacionRpc {
  id: string;
  email: string;
  rol: string;
  estado: string;
  cupo_inicial: number;
}

function codigoDe(respuesta: Respuesta): string | undefined {
  return (respuesta.cuerpo as { message?: string } | null)?.message;
}

function sesionDelAdministrador() {
  return iniciarSesion("admin@prueba.local", CLAVE_DE_PRUEBA);
}

function invitarPorRpc(
  sesion: Sesion,
  correo: string,
  rol = "usuario",
  cupo = 0,
) {
  return sesion.rpc("invitar_usuario", {
    p_email: correo,
    p_rol: rol,
    p_cupo_inicial: cupo,
  });
}

async function eventosDeInvitacion(
  sql: Sql,
  id: string,
  estado: string,
): Promise<number> {
  const [{ cuantos }] = await sql`
    select count(*)::int as cuantos from realtime.messages
    where topic = 'admin' and event = 'invitacion' and private
      and payload->>'id' = ${id} and payload->>'estado' = ${estado}`;
  return cuantos;
}

Deno.test("E2E-02: el Administrador invita por la RPC y la persona entra con esa invitación", async () => {
  await conBd(async (sql) => {
    const admin = await sesionDelAdministrador();
    const correo = correoNuevo("rpc");
    try {
      const respuesta = await invitarPorRpc(admin, correo, "analista", 0);
      assertEquals(respuesta.estado, 200, JSON.stringify(respuesta.cuerpo));
      const invitacion = respuesta.cuerpo as InvitacionRpc;
      assertEquals(
        [invitacion.email, invitacion.rol, invitacion.estado],
        [correo, "analista", "pendiente"],
      );

      // La ve en su lista (RLS) y el evento salió por el canal admin.
      const lista = await admin.leer(
        "invitaciones",
        `id=eq.${invitacion.id}&select=email,estado`,
      );
      assertEquals(lista.cuerpo, [{ email: correo, estado: "pendiente" }]);
      assertEquals(
        await eventosDeInvitacion(sql, invitacion.id, "pendiente"),
        1,
      );

      // La persona entra con esa invitación y queda con el rol que se le dio.
      const alta = await registrarse(correo);
      assertEquals(alta.estado, 200, JSON.stringify(alta.cuerpo));
      const [perfil] = await sql`
        select rol, estado from public.perfiles where email = ${correo}`;
      assertEquals([perfil.rol, perfil.estado], ["analista", "activo"]);
      const [aceptada] = await sql`
        select estado, usuario_id is not null as con_usuario
        from public.invitaciones where id = ${invitacion.id}`;
      assertEquals([aceptada.estado, aceptada.con_usuario], ["aceptada", true]);
      assertEquals(
        await eventosDeInvitacion(sql, invitacion.id, "aceptada"),
        1,
      );

      // Quedó en la bitácora quién invitó.
      const [{ cuantos }] = await sql`
        select count(*)::int as cuantos from public.auditoria
        where accion = 'cuenta.invitada' and entidad_id = ${invitacion.id}
          and actor_rol = 'administrador'`;
      assertEquals(cuantos, 1);
    } finally {
      await limpiar(sql, [correo]);
    }
  });
});

Deno.test("E2E-02: una invitación revocada no deja entrar y se puede invitar de nuevo", async () => {
  await conBd(async (sql) => {
    const admin = await sesionDelAdministrador();
    const correo = correoNuevo("revocada");
    try {
      const creada = await invitarPorRpc(admin, correo);
      assertEquals(creada.estado, 200, JSON.stringify(creada.cuerpo));
      const { id } = creada.cuerpo as InvitacionRpc;

      const revocada = await admin.rpc("revocar_invitacion", { p_id: id });
      assertEquals(revocada.estado, 200, JSON.stringify(revocada.cuerpo));
      assertEquals((revocada.cuerpo as InvitacionRpc).estado, "revocada");
      assertEquals(await eventosDeInvitacion(sql, id, "revocada"), 1);
      const [{ cuantos }] = await sql`
        select count(*)::int as cuantos from public.auditoria
        where accion = 'cuenta.invitacion_revocada' and entidad_id = ${id}`;
      assertEquals(cuantos, 1);

      // Con la invitación revocada, el alta se rechaza con su mensaje y no se crea el usuario.
      const rechazada = await registrarse(correo);
      assertEquals(rechazada.estado, 403, JSON.stringify(rechazada.cuerpo));
      assertStringIncludes(JSON.stringify(rechazada.cuerpo), SIN_INVITACION);
      assert(!(await existeUsuario(sql, correo)));

      // Revocarla otra vez no es posible: ya cambió de estado.
      const otraVez = await admin.rpc("revocar_invitacion", { p_id: id });
      assertEquals(otraVez.estado, 400);
      assertEquals(codigoDe(otraVez), "ESTADO_INVALIDO");

      // Invitar de nuevo ese correo es posible y esa invitación sí deja entrar.
      const nueva = await invitarPorRpc(admin, correo, "usuario", 100);
      assertEquals(nueva.estado, 200, JSON.stringify(nueva.cuerpo));
      const alta = await registrarse(correo);
      assertEquals(alta.estado, 200, JSON.stringify(alta.cuerpo));
      const [perfil] = await sql`
        select rol, estado from public.perfiles where email = ${correo}`;
      assertEquals([perfil.rol, perfil.estado], ["usuario", "activo"]);
    } finally {
      await limpiar(sql, [correo]);
    }
  });
});

Deno.test("E2E-02: invitar un correo con invitación vigente o con cuenta responde su código", async () => {
  await conBd(async (sql) => {
    const admin = await sesionDelAdministrador();
    const correo = correoNuevo("duplicada");
    try {
      const primera = await invitarPorRpc(admin, correo);
      assertEquals(primera.estado, 200, JSON.stringify(primera.cuerpo));

      const duplicada = await invitarPorRpc(admin, correo.toUpperCase());
      assertEquals(duplicada.estado, 400);
      assertEquals(codigoDe(duplicada), "INVITACION_DUPLICADA");

      const conCuenta = await invitarPorRpc(admin, "usuario1@prueba.local");
      assertEquals(conCuenta.estado, 400);
      assertEquals(codigoDe(conCuenta), "CORREO_YA_REGISTRADO");

      const [{ cuantos }] = await sql`
        select count(*)::int as cuantos from public.invitaciones
        where lower(email) in (${correo}, 'usuario1@prueba.local')
          and estado = 'pendiente'`;
      assertEquals(cuantos, 1);
    } finally {
      await limpiar(sql, [correo]);
    }
  });
});

Deno.test("E2E-02: un Usuario, un Analista o quien no ingresó no pueden invitar ni revocar", async () => {
  await conBd(async (sql) => {
    const admin = await sesionDelAdministrador();
    const correo = correoNuevo("permisos");
    try {
      const creada = await invitarPorRpc(admin, correo);
      const { id } = creada.cuerpo as InvitacionRpc;

      for (
        const [correoDeSesion, nombre] of [
          ["usuario1@prueba.local", "un Usuario"],
          ["analista1@prueba.local", "un Analista"],
        ]
      ) {
        const sesion = await iniciarSesion(correoDeSesion, CLAVE_DE_PRUEBA);
        const invita = await invitarPorRpc(sesion, correoNuevo("otro"));
        assertEquals(invita.estado, 400, nombre);
        assertEquals(codigoDe(invita), "NO_AUTORIZADO", nombre);
        const revoca = await sesion.rpc("revocar_invitacion", { p_id: id });
        assertEquals(revoca.estado, 400, nombre);
        assertEquals(codigoDe(revoca), "NO_AUTORIZADO", nombre);
        // y no lee las invitaciones
        assertEquals((await sesion.leer("invitaciones")).cuerpo, []);
      }

      const anonimo = await invitarPorRpc(sesionAnonima(), correoNuevo("anon"));
      assert([401, 403].includes(anonimo.estado), `anónimo: ${anonimo.estado}`);

      const [{ estado }] = await sql`
        select estado from public.invitaciones where id = ${id}`;
      assertEquals(estado, "pendiente");
    } finally {
      await limpiar(sql, [correo]);
    }
  });
});

Deno.test("E2E-02: un administrador suspendido con token vigente no puede invitar ni revocar (CA-7)", async () => {
  await conBd(async (sql) => {
    const admin = await sesionDelAdministrador();
    const correo = correoNuevo("suspendido");
    const suspendido = await crearUsuarioDePrueba(sql, "administrador");
    try {
      const creada = await invitarPorRpc(admin, correo);
      const { id } = creada.cuerpo as InvitacionRpc;

      // Suspender llega con HU-010: la cuenta de prueba se deja ya suspendida. Su token sigue
      // vigente y dice que está activa; la función mira `perfiles`, no el token.
      await sql`update public.perfiles set estado = 'suspendido', suspendido_en = now()
                where id = ${suspendido.id}`;

      const invita = await invitarPorRpc(
        suspendido.sesion,
        correoNuevo("otro"),
      );
      assertEquals(invita.estado, 400);
      assertEquals(codigoDe(invita), "SESION_INVALIDA");
      const revoca = await suspendido.sesion.rpc("revocar_invitacion", {
        p_id: id,
      });
      assertEquals(revoca.estado, 400);
      assertEquals(codigoDe(revoca), "SESION_INVALIDA");

      const [{ estado }] = await sql`
        select estado from public.invitaciones where id = ${id}`;
      assertEquals(estado, "pendiente");
    } finally {
      await suspendido.eliminar();
      await limpiar(sql, [correo]);
    }
  });
});

Deno.test("E2E-02: pasados 7 días la invitación no deja entrar y al invitar de nuevo la anterior pasa a vencida", async () => {
  await conBd(async (sql) => {
    const admin = await sesionDelAdministrador();
    const correo = correoNuevo("vencida-rpc");
    try {
      const primera = await invitarPorRpc(admin, correo, "usuario", 50);
      assertEquals(primera.estado, 200, JSON.stringify(primera.cuerpo));
      const { id: idAnterior } = primera.cuerpo as InvitacionRpc;

      await fijarReloj(sql, new Date(Date.now() + 8 * 24 * 3600 * 1000));
      const rechazada = await registrarse(correo);
      assertEquals(rechazada.estado, 403, JSON.stringify(rechazada.cuerpo));
      assertStringIncludes(JSON.stringify(rechazada.cuerpo), SIN_INVITACION);
      assert(!(await existeUsuario(sql, correo)));

      // La pendiente ya pasó de fecha: no impide invitar de nuevo; pasa a vencida y se crea otra.
      const nueva = await invitarPorRpc(admin, correo, "analista", 0);
      assertEquals(nueva.estado, 200, JSON.stringify(nueva.cuerpo));
      const [anterior] = await sql`
        select estado from public.invitaciones where id = ${idAnterior}`;
      assertEquals(anterior.estado, "vencida");
      assertEquals(await eventosDeInvitacion(sql, idAnterior, "vencida"), 1);

      const alta = await registrarse(correo);
      assertEquals(alta.estado, 200, JSON.stringify(alta.cuerpo));
      const [perfil] = await sql`
        select rol, estado from public.perfiles where email = ${correo}`;
      assertEquals([perfil.rol, perfil.estado], ["analista", "activo"]);
    } finally {
      await restablecer(sql);
      await limpiar(sql, [correo]);
    }
  });
});
