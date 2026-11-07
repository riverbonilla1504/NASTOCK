// Actuar como distintas personas contra la API local (docs/15 §2, "como distintos usuarios").
//
// - `sesionAnonima()`: sin iniciar sesión.
// - `iniciarSesion(correo, contrasena)`: con un usuario que ya existe, por ejemplo los de
//   prueba por rol de docs/15 §3 (`admin@prueba.local`, `analista1@…`…) cuando `seed.sql`
//   los cree (HU-002).
// - `crearUsuarioDePrueba(rol)`: crea en la prueba un usuario con su perfil y su rol, inicia
//   sesión y lo borra al terminar. Sirve mientras `seed.sql` no los siembre.
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
  /** Borra el perfil y el usuario. Llamarlo siempre al terminar (en un `finally`). */
  eliminar(): Promise<void>;
}

/**
 * Crea un usuario con perfil activo del rol dado y devuelve su sesión.
 * El usuario nace confirmado (Auth local no manda correos) y su perfil se inserta por SQL,
 * porque `perfiles` solo la escriben funciones `security definer`.
 */
export async function crearUsuarioDePrueba(
  sql: Sql,
  rol: "usuario" | "analista" | "administrador",
): Promise<UsuarioDePrueba> {
  const sufijo = crypto.randomUUID().slice(0, 8);
  const correo = `e2e-${rol}-${sufijo}@prueba.local`;
  const contrasena = crypto.randomUUID();

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
    throw new Error(`No se pudo crear el usuario de prueba: ${creado.estado}`);
  }

  const eliminar = async () => {
    await sql`delete from public.perfiles where id = ${id}`;
    await fetch(`${entorno.urlApi}/auth/v1/admin/users/${id}`, {
      method: "DELETE",
      headers: {
        apikey: entorno.llaveDeServicio,
        Authorization: `Bearer ${entorno.llaveDeServicio}`,
      },
    }).then((r) => r.body?.cancel());
  };

  try {
    await sql`
      insert into public.perfiles (id, email, nombre, rol)
      values (${id}, ${correo}, ${"Prueba E2E " + rol}, ${rol})`;
    return {
      sesion: await iniciarSesion(correo, contrasena),
      id,
      correo,
      eliminar,
    };
  } catch (error) {
    await eliminar();
    throw error;
  }
}
