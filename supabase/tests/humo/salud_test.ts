// Primera verificación de docs/15 §11: `ping()` responde. Las demás (mercado, proveedores,
// Auth, integraciones, configuración de IA) las agregan TT-08 y las historias que las crean.

import { assertEquals } from "@std/assert";
import { proyecto } from "./entorno.ts";

Deno.test("humo: ping() responde", async () => {
  const respuesta = await fetch(`${proyecto.url}/rest/v1/rpc/ping`, {
    method: "POST",
    headers: {
      apikey: proyecto.llavePublicable,
      Authorization: `Bearer ${proyecto.llavePublicable}`,
      "Content-Type": "application/json",
    },
    body: "{}",
  });
  const cuerpo = await respuesta.text();
  assertEquals(respuesta.status, 200, cuerpo);
});
