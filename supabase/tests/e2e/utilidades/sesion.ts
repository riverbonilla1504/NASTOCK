// Actuar como distintas personas contra la API local (docs/15 §2, "como distintos usuarios").
//
// - `sesionAnonima()`: sin iniciar sesión.
// - `iniciarSesion(correo, contrasena)`: con un usuario que ya existe, por ejemplo los de
//   prueba por rol de docs/15 §3 (`admin@prueba.local`, `analista1@…`…) cuando `seed.sql`
//   los cree (HU-002).
// - `crearUsuarioDePrueba(rol)`: crea en la prueba un usuario con su perfil y su rol, inicia
//   sesión y lo borra al terminar. Como cualquier alta, pasa por una invitación vigente
//   (HU-002): la crea y deja que `private.al_crear_usuario` cree el perfil.
//
// Las respuestas vuelven ya leídas ({ estado, cuerpo }) para que ninguna prueba deje un
// cuerpo sin consumir.

import { entorno } from "./entorno.ts";
import type { Sql } from "./pruebas.ts";

export interface Respuesta {
  estado: number;
  /** JSON de la respuesta; el texto si no era JSON; null si venía vacía. */
  cuerpo: unknown;
}

export async function leerRespuesta(respuesta: Response): Promise<Respuesta> {
  const texto = await respuesta.text();
  let cuerpo: unknown = texto === "" ? null : texto;
  try {
    if (texto !== "") cuerpo = JSON.parse(texto);
  } catch {
    // no era JSON: se deja el texto
  }
  return { estado: respuesta.status, cuerpo };
}

/** Una persona (o nadie) hablando con la API. */
export class Sesion {
  constructor(readonly nombre: string, readonly token: string | null) {}

  /** Petición a la API con la llave anónima y, si hay sesión, su token. */
  async peticion(ruta: string, init: RequestInit = {}): Promise<Respuesta> {
    const cabeceras = new Headers(init.headers);
    cabeceras.set("apikey", entorno.llaveAnonima);
    cabeceras.set(
      "Authorization",
      `Bearer ${this.token ?? entorno.llaveAnonima}`,
    );
    if (init.body) cabeceras.set("Content-Type", "application/json");
    return leerRespuesta(
      await fetch(`${entorno.urlApi}${ruta}`, { ...init, headers: cabeceras }),
    );
  }

  /** Llama una función pública de la base: `POST /rest/v1/rpc/<funcion>`. */
  rpc(funcion: string, argumentos: Record<string, unknown> = {}) {
    return this.peticion(`/rest/v1/rpc/${funcion}`, {
      method: "POST",
      body: JSON.stringify(argumentos),
    });
  }

  /** Lee una tabla o vista (la RLS decide qué ve): `GET /rest/v1/<tabla>?<consulta>`. */
  leer(tabla: string, consulta = "") {
    return this.peticion(`/rest/v1/${tabla}${consulta ? `?${consulta}` : ""}`);
  }
}

export function sesionAnonima(): Sesion {
  return new Sesion("anonimo", null);
}

/** Inicia sesión con correo y contraseña. Falla si Auth la rechaza. */
export async function iniciarSesion(
  correo: string,
  contrasena: string,
): Promise<Sesion> {
  const respuesta = await sesionAnonima().peticion(
    "/auth/v1/token?grant_type=password",
    {
      method: "POST",
      body: JSON.stringify({ email: correo, password: contrasena }),
    },
  );
  const token = (respuesta.cuerpo as { access_token?: string } | null)
    ?.access_token;
  if (respuesta.estado !== 200 || !token) {
    throw new Error(
      `No se pudo iniciar sesión como ${correo}: ${respuesta.estado}`,
    );
  }
  return new Sesion(correo, token);
}

export interface UsuarioDePrueba {
  sesion: Sesion;
  id: string;
  correo: string;
  /** Su contraseña, para volver a iniciar sesión (p. ej. tras cambiar su estado) y obtener un token nuevo. */
  contrasena: string;
  /** Borra el perfil y el usuario. Llamarlo siempre al terminar (en un `finally`). */
  eliminar(): Promise<void>;
}

/**
 * Crea un usuario con perfil activo del rol dado y devuelve su sesión.
 * El usuario nace confirmado (Auth local no manda correos). Antes se inserta su invitación
 * por SQL (`invitaciones` solo la escriben funciones `security definer`) y el trigger de
 * alta crea el perfil con el rol de la invitación. El dominio `prueba.local` y el proveedor
 * `email` los permite `seed.sql`.
 */
export async function crearUsuarioDePrueba(
  sql: Sql,
  rol: "usuario" | "analista" | "administrador",
): Promise<UsuarioDePrueba> {
  const sufijo = crypto.randomUUID().slice(0, 8);
  const correo = `e2e-${rol}-${sufijo}@prueba.local`;
  const contrasena = crypto.randomUUID();

  await sql`
    insert into public.invitaciones (email, rol) values (${correo}, ${rol})`;

  const creado = await leerRespuesta(
    await fetch(`${entorno.urlApi}/auth/v1/admin/users`, {
      method: "POST",
      headers: {
        apikey: entorno.llaveDeServicio,
        Authorization: `Bearer ${entorno.llaveDeServicio}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        email: correo,
        password: contrasena,
        email_confirm: true,
      }),
    }),
  );
  const id = (creado.cuerpo as { id?: string } | null)?.id;
  if (creado.estado >= 300 || !id) {
    await sql`delete from public.invitaciones where lower(email) = ${correo}`;
    throw new Error(`No se pudo crear el usuario de prueba: ${creado.estado}`);
  }

  const eliminar = async () => {
    // Las llaves foráneas se cruzan: se suelta la de la invitación antes de borrar el perfil.
    await sql`update public.invitaciones set usuario_id = null where usuario_id = ${id}`;
    // Desde HU-017 el alta crea el cupo del Usuario (subcuenta en 0, sin asientos). La limpieza de
    // pruebas lo quita antes del perfil; si tuviera asientos, la llave foránea falla y avisa.
    await sql`delete from public.subcuentas where usuario_id = ${id}`;
    await sql`delete from public.perfiles where id = ${id}`;
    await sql`delete from public.invitaciones where lower(email) = ${correo}`;
    await fetch(`${entorno.urlApi}/auth/v1/admin/users/${id}`, {
      method: "DELETE",
      headers: {
        apikey: entorno.llaveDeServicio,
        Authorization: `Bearer ${entorno.llaveDeServicio}`,
      },
    }).then((r) => r.body?.cancel());
  };

  try {
    return {
      sesion: await iniciarSesion(correo, contrasena),
      id,
      correo,
      contrasena,
      eliminar,
    };
  } catch (error) {
    await eliminar();
    throw error;
  }
}
