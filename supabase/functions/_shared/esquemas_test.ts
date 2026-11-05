import { assertEquals, assertThrows } from "@std/assert";
import { ErrorDeDatos, uuid, validar, z } from "./esquemas.ts";

const esquema = z.object({ simbolo: z.string(), cantidad: z.number().int() });

Deno.test("validar devuelve los datos cuando cumplen el esquema", () => {
  assertEquals(validar(esquema, { simbolo: "QQQ", cantidad: 2 }), {
    simbolo: "QQQ",
    cantidad: 2,
  });
});

Deno.test("validar lista un problema por cada campo que no cumple", () => {
  const error = assertThrows(
    () => validar(esquema, { simbolo: 5, cantidad: 1.5 }),
    ErrorDeDatos,
  );
  assertEquals(error.problemas.length, 2);
  assertEquals(error.problemas[0].startsWith("simbolo:"), true);
  assertEquals(error.problemas[1].startsWith("cantidad:"), true);
});

Deno.test("validar nombra la raíz cuando el dato completo no cumple", () => {
  const error = assertThrows(() => validar(esquema, null), ErrorDeDatos);
  assertEquals(error.problemas[0].startsWith("(raíz):"), true);
});

Deno.test("uuid acepta identificadores y rechaza otros textos", () => {
  assertEquals(
    uuid.safeParse("3b7e5c0a-1f2d-4c3b-9a8e-7d6c5b4a3f21").success,
    true,
  );
  assertEquals(uuid.safeParse("no-es-uuid").success, false);
});
