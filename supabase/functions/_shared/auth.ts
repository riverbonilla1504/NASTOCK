// Autenticación de las Edge Functions (docs/05 §6, columna "Autenticación").
//
// Una función acepta el secreto interno (cron y pg_net, ver
// private.despertar_funcion), el JWT de una persona con ciertos roles, o ambos.
// La autorización lee el rol de `perfiles`, nunca de los claims del JWT
// (CLAUDE.md, invariantes). Las funciones que solo aceptan el secreto interno se
// configuran con `verify_jwt = false` en config.toml, porque el gateway de
// Supabase rechaza antes cualquier llamada sin JWT.

/** Cabecera en la que private.despertar_funcion envía el secreto interno. */
export const CABECERA_SECRETO_INTERNO = "x-secreto-interno";

/** Roles de la app (docs/06 §3, `rol_app`). */
export type Rol = "usuario" | "analista" | "administrador";

/** Quién hizo la llamada. */
export type Llamante =
  | { tipo: "interno" }
  | { tipo: "persona"; usuarioId: string; rol: Rol };

/** Códigos del catálogo de docs/06 §9 que puede devolver la autenticación. */
export type CodigoDeAcceso = "SESION_INVALIDA" | "NO_AUTORIZADO";

/** Fallo de autenticación con su código y su estado HTTP. */
export class ErrorDeAcceso extends Error {
  constructor(readonly codigo: CodigoDeAcceso) {
    super(codigo);
    this.name = "ErrorDeAcceso";
  }

  get estado(): 401 | 403 {
    return this.codigo === "SESION_INVALIDA" ? 401 : 403;
  }
}

/** Lo que la función necesita para identificar a la persona. */
export interface Identidad {
  /** Id del usuario si el JWT es válido; null si no lo es. */
  usuarioDelToken(token: string): Promise<string | null>;
  /** Rol de un perfil activo, leído de `perfiles`; null si no hay perfil activo. */
  rolDe(usuarioId: string): Promise<Rol | null>;
}

/** Qué llamadas acepta una función. */
export interface Reglas {
  /** Acepta el secreto interno (cron y pg_net). */
  aceptaInterno: boolean;
  /** Roles de persona que pueden llamar. Vacío: ninguna persona. */
  roles: readonly Rol[];
}

/** Compara en tiempo constante, para no revelar el secreto por los tiempos. */
export function iguales(a: string, b: string): boolean {
  const codificador = new TextEncoder();
  const x = codificador.encode(a);
  const y = codificador.encode(b);
  let diferencia = x.length ^ y.length;
  const largo = Math.max(x.length, y.length);
  for (let i = 0; i < largo; i++) {
    diferencia |= (x[i] ?? 0) ^ (y[i] ?? 0);
  }
  return diferencia === 0;
}

/** Verdadero si la llamada trae el secreto interno correcto. */
export function traeSecretoInterno(
  req: Request,
  secreto: string | undefined,
): boolean {
  const recibido = req.headers.get(CABECERA_SECRETO_INTERNO);
  if (!secreto || !recibido) return false;
  return iguales(recibido, secreto);
}

/** Token de la cabecera `Authorization: Bearer …`, o null. */
export function tokenDeSesion(req: Request): string | null {
  const valor = req.headers.get("Authorization") ?? "";
  const coincidencia = /^Bearer\s+(\S+)$/i.exec(valor.trim());
  return coincidencia ? coincidencia[1] : null;
}

/**
 * Identifica al llamante o lanza ErrorDeAcceso.
 *
 * - Secreto interno correcto y la función lo acepta: llamante interno.
 * - Un secreto interno que no sirve, sin sesión: NO_AUTORIZADO.
 * - Sin sesión o con una sesión inválida: SESION_INVALIDA.
 * - Persona sin perfil activo o con un rol que la función no acepta: NO_AUTORIZADO.
 */
export async function autenticar(
  req: Request,
  reglas: Reglas,
  identidad: Identidad,
  secreto: string | undefined = Deno.env.get("SECRETO_INTERNO"),
): Promise<Llamante> {
  if (reglas.aceptaInterno && traeSecretoInterno(req, secreto)) {
    return { tipo: "interno" };
  }

  const token = tokenDeSesion(req);
  if (!token) {
    throw new ErrorDeAcceso(
      req.headers.has(CABECERA_SECRETO_INTERNO)
        ? "NO_AUTORIZADO"
        : "SESION_INVALIDA",
    );
  }

  const usuarioId = await identidad.usuarioDelToken(token);
  if (!usuarioId) throw new ErrorDeAcceso("SESION_INVALIDA");

  const rol = await identidad.rolDe(usuarioId);
  if (!rol || !reglas.roles.includes(rol)) {
    throw new ErrorDeAcceso("NO_AUTORIZADO");
  }
  return { tipo: "persona", usuarioId, rol };
}

/** Respuesta con el código del error; la app la traduce (docs/06 §9). */
export function respuestaDeAcceso(error: ErrorDeAcceso): Response {
  return new Response(JSON.stringify({ codigo: error.codigo }), {
    status: error.estado,
    headers: { "Content-Type": "application/json" },
  });
}
