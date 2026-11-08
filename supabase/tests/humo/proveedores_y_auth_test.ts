// Verificaciones de docs/15 §11 sobre proveedores y Auth, contra el proyecto MVP (FR-009).
// `ping()` está en salud_test.ts y el proyecto al que se le habla, en entorno.ts.
//
//   SUPABASE_URL=https://<ref>.supabase.co SUPABASE_PUBLISHABLE_KEY=sb_publishable_… \
//     deno test --config supabase/tests/deno.json \
//       --allow-net --allow-env --allow-read supabase/tests/humo
//
// Entran con su historia: `estado_mercado()` y el calendario (HU-002 y HU-005, cuando haya
// usuarios: solo la ejecuta `authenticated`), cuenta de Alpaca paper (M-10), salud de
// integraciones (M-18), configuración de decisión y prompt de contexto (M-07), y la fila
// `auth.proveedores_permitidos` de `public.parametros` (M-01).

import { assert, assertEquals } from "@std/assert";
import { proyecto } from "./entorno.ts";

/** Llama a la API del proyecto con la llave publicable y devuelve estado y cuerpo. */
async function llamar(
  ruta: string,
  init: { method?: string; body?: string } = {},
): Promise<{ estado: number; cuerpo: string }> {
  const respuesta = await fetch(`${proyecto.url}${ruta}`, {
    method: init.method ?? "GET",
    headers: {
      apikey: proyecto.llavePublicable,
      "Content-Type": "application/json",
    },
    body: init.body,
  });
  return { estado: respuesta.status, cuerpo: await respuesta.text() };
}

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
