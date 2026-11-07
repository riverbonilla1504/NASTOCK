// Prueba de humo contra el proyecto MVP, después de cada despliegue (docs/15 §11, FR-009).
//
// Corre en el trabajo `humo` de despliegue.yml con la URL y la llave PUBLICABLE (no es
// secreta). Solo usa lo que cualquiera con esa llave podría llamar.
//
//   SUPABASE_URL=https://<ref>.supabase.co SUPABASE_PUBLISHABLE_KEY=sb_publishable_… \
//     deno test --config supabase/tests/humo/deno.json \
//       --allow-net --allow-env --allow-read supabase/tests/humo
//
// Entran las verificaciones de docs/15 §11 que ya aplican. Entran con su historia:
// `estado_mercado()` y el calendario (M-05), cuenta de Alpaca paper (M-10), salud de
// integraciones (M-18), configuración de decisión y prompt de contexto (M-07), y la fila
// `auth.proveedores_permitidos` de `public.parametros` (M-01).

import { assert, assertEquals } from "@std/assert";

function variable(nombre: string): string {
  const valor = Deno.env.get(nombre)?.trim();
  if (!valor) throw new Error(`Falta la variable ${nombre}`);
  return valor;
}

const url = variable("SUPABASE_URL").replace(/\/+$/, "");
const llave = variable("SUPABASE_PUBLISHABLE_KEY");

/** Llama a la API del proyecto con la llave publicable y devuelve estado y cuerpo. */
async function llamar(
  ruta: string,
  init: { method?: string; body?: string } = {},
): Promise<{ estado: number; cuerpo: string }> {
  const respuesta = await fetch(`${url}${ruta}`, {
    method: init.method ?? "GET",
    headers: { apikey: llave, "Content-Type": "application/json" },
    body: init.body,
  });
  return { estado: respuesta.status, cuerpo: await respuesta.text() };
}

Deno.test("ping() responde con la hora del servidor", async () => {
  const { estado, cuerpo } = await llamar("/rest/v1/rpc/ping", {
    method: "POST",
    body: "{}",
  });
  assertEquals(estado, 200, `ping() respondió ${estado}`);
  const hora = Date.parse(JSON.parse(cuerpo));
  assert(!Number.isNaN(hora), "ping() no devolvió una fecha");
});

// CB-91: con ENTORNO=mvp una función no arranca si algún PROVEEDOR_* es simulado
// (_shared/proveedores.ts valida los seis al cargar el módulo). Una función que no arranca
// responde 5xx (BOOT_ERROR); una que arrancó responde 4xx porque no enviamos credenciales.
Deno.test("CB-91: todas las funciones arrancan (sin proveedores simulados en mvp)", async () => {
  const funciones = [
    ...Deno.readDirSync(new URL("../../functions/", import.meta.url)),
  ]
    .filter((e) => e.isDirectory && !e.name.startsWith("_"))
    .map((e) => e.name);

  for (const nombre of funciones) {
    const { estado, cuerpo } = await llamar(`/functions/v1/${nombre}`, {
      method: "POST",
      body: "{}",
    });
    assert(
      estado < 500,
      `La función ${nombre} no arrancó: HTTP ${estado}. ¿Hay un proveedor simulado o un ` +
        `ENTORNO distinto de mvp? (CB-91). ${cuerpo.slice(0, 200)}`,
    );
  }
});

// CB-92: en la nube el ingreso es solo con Google. /auth/v1/settings es público y dice
// qué proveedores de Supabase Auth están habilitados.
Deno.test("CB-92: el correo no está habilitado como proveedor de ingreso", async () => {
  const { estado, cuerpo } = await llamar("/auth/v1/settings");
  assertEquals(estado, 200, `/auth/v1/settings respondió ${estado}`);
  const { external } = JSON.parse(cuerpo);
  assert(external, "La respuesta de Auth no trae la lista de proveedores");
  assertEquals(
    external.email,
    false,
    "El proveedor de correo está habilitado en Supabase Auth (CB-92)",
  );
});
