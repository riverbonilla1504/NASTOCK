import { assertEquals } from "@std/assert";
import type { Argumento, Bd } from "./bd.ts";
import {
  LARGO_MAXIMO_DE_ERROR,
  registrarSalud,
  textoDeError,
} from "./salud.ts";

function bdFalsa(falla?: Error) {
  const llamadas: { funcion: string; argumentos: readonly Argumento[] }[] = [];
  const bd: Bd = {
    llamar<T = Record<string, unknown>>(
      funcion: string,
      argumentos: readonly Argumento[] = [],
    ) {
      llamadas.push({ funcion, argumentos });
      return falla ? Promise.reject(falla) : Promise.resolve([] as T[]);
    },
    cerrar: () => Promise.resolve(),
  };
  return { bd, llamadas };
}

Deno.test("un éxito se registra sin error", async () => {
  const { bd, llamadas } = bdFalsa();
  assertEquals(await registrarSalud(bd, "alpaca_datos", true), true);
  assertEquals(llamadas, [{
    funcion: "registrar_salud",
    argumentos: ["alpaca_datos", true, null],
  }]);
});

Deno.test("un fallo se registra con el mensaje del error, recortado", async () => {
  const { bd, llamadas } = bdFalsa();
  await registrarSalud(
    bd,
    "alpaca_trading",
    false,
    new Error("x".repeat(1000)),
  );
  const [, , texto] = llamadas[0].argumentos as [string, boolean, string];
  assertEquals(texto.length, LARGO_MAXIMO_DE_ERROR);
  assertEquals(llamadas[0].argumentos[1], false);
});

Deno.test("un fallo sin error manda nulo", async () => {
  const { bd, llamadas } = bdFalsa();
  await registrarSalud(bd, "jev", false);
  assertEquals(llamadas[0].argumentos, ["jev", false, null]);
});

Deno.test("si la base falla, no lanza y devuelve falso", async () => {
  const { bd } = bdFalsa(new Error("sin base"));
  assertEquals(await registrarSalud(bd, "fcm", true), false);
});

Deno.test("textoDeError acepta cualquier valor", () => {
  assertEquals(textoDeError(new Error("hola")), "hola");
  assertEquals(textoDeError("texto"), "texto");
});
