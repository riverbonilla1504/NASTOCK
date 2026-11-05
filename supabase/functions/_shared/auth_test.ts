import { assertEquals, assertRejects } from "@std/assert";
import {
  autenticar,
  CABECERA_SECRETO_INTERNO,
  ErrorDeAcceso,
  type Identidad,
  iguales,
  type Reglas,
  type Rol,
  tokenDeSesion,
} from "./auth.ts";

const SECRETO = "secreto-de-prueba";

function peticion(cabeceras: Record<string, string> = {}): Request {
  return new Request("http://local/funcion", {
    method: "POST",
    headers: cabeceras,
  });
}

/** Identidad falsa: tokens y perfiles en memoria. */
function identidad(
  tokens: Record<string, string>,
  roles: Record<string, Rol>,
): Identidad {
  return {
    usuarioDelToken: (token) => Promise.resolve(tokens[token] ?? null),
    rolDe: (usuarioId) => Promise.resolve(roles[usuarioId] ?? null),
  };
}

const sinPersonas = identidad({}, {});
const soloInterno: Reglas = { aceptaInterno: true, roles: [] };
const internoOAnalista: Reglas = {
  aceptaInterno: true,
  roles: ["analista", "administrador"],
};
const soloUsuario: Reglas = { aceptaInterno: false, roles: ["usuario"] };

async function codigoDe(promesa: Promise<unknown>): Promise<string> {
  const error = await assertRejects(() => promesa, ErrorDeAcceso);
  return (error as ErrorDeAcceso).codigo;
}

Deno.test("el secreto interno correcto identifica al llamante interno", async () => {
  const llamante = await autenticar(
    peticion({ [CABECERA_SECRETO_INTERNO]: SECRETO }),
    soloInterno,
    sinPersonas,
    SECRETO,
  );
  assertEquals(llamante, { tipo: "interno" });
});

Deno.test("un secreto interno equivocado y sin sesión es NO_AUTORIZADO", async () => {
  assertEquals(
    await codigoDe(autenticar(
      peticion({ [CABECERA_SECRETO_INTERNO]: "otro" }),
      soloInterno,
      sinPersonas,
      SECRETO,
    )),
    "NO_AUTORIZADO",
  );
});

Deno.test("sin secreto configurado no se acepta ningún secreto", async () => {
  assertEquals(
    await codigoDe(autenticar(
      peticion({ [CABECERA_SECRETO_INTERNO]: "" }),
      soloInterno,
      sinPersonas,
      undefined,
    )),
    "NO_AUTORIZADO",
  );
});

Deno.test("una función que no acepta el secreto interno lo rechaza", async () => {
  assertEquals(
    await codigoDe(autenticar(
      peticion({ [CABECERA_SECRETO_INTERNO]: SECRETO }),
      soloUsuario,
      sinPersonas,
      SECRETO,
    )),
    "NO_AUTORIZADO",
  );
});

Deno.test("sin secreto ni sesión es SESION_INVALIDA", async () => {
  assertEquals(
    await codigoDe(autenticar(peticion(), soloInterno, sinPersonas, SECRETO)),
    "SESION_INVALIDA",
  );
});

Deno.test("un JWT que no valida es SESION_INVALIDA", async () => {
  assertEquals(
    await codigoDe(autenticar(
      peticion({ Authorization: "Bearer vencido" }),
      internoOAnalista,
      sinPersonas,
      SECRETO,
    )),
    "SESION_INVALIDA",
  );
});

Deno.test("una persona con un rol permitido queda identificada", async () => {
  const llamante = await autenticar(
    peticion({ Authorization: "Bearer bueno" }),
    internoOAnalista,
    identidad({ bueno: "u-1" }, { "u-1": "analista" }),
    SECRETO,
  );
  assertEquals(llamante, {
    tipo: "persona",
    usuarioId: "u-1",
    rol: "analista",
  });
});

Deno.test("una persona con otro rol es NO_AUTORIZADO", async () => {
  assertEquals(
    await codigoDe(autenticar(
      peticion({ Authorization: "Bearer bueno" }),
      internoOAnalista,
      identidad({ bueno: "u-1" }, { "u-1": "usuario" }),
      SECRETO,
    )),
    "NO_AUTORIZADO",
  );
});

Deno.test("una persona sin perfil activo es NO_AUTORIZADO", async () => {
  assertEquals(
    await codigoDe(autenticar(
      peticion({ Authorization: "Bearer bueno" }),
      soloUsuario,
      identidad({ bueno: "u-1" }, {}),
      SECRETO,
    )),
    "NO_AUTORIZADO",
  );
});

Deno.test("los errores de acceso llevan el estado HTTP de su código", () => {
  assertEquals(new ErrorDeAcceso("SESION_INVALIDA").estado, 401);
  assertEquals(new ErrorDeAcceso("NO_AUTORIZADO").estado, 403);
});

Deno.test("tokenDeSesion solo acepta el formato Bearer", () => {
  assertEquals(tokenDeSesion(peticion({ Authorization: "Bearer abc" })), "abc");
  assertEquals(tokenDeSesion(peticion({ Authorization: "Basic abc" })), null);
  assertEquals(tokenDeSesion(peticion()), null);
});

Deno.test("iguales compara textos de cualquier largo", () => {
  assertEquals(iguales("abc", "abc"), true);
  assertEquals(iguales("abc", "abd"), false);
  assertEquals(iguales("abc", "abcd"), false);
  assertEquals(iguales("", ""), true);
});
