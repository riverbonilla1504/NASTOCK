import { assertEquals } from "@std/assert";
import { aInstanteUtc, instanteDeNuevaYork, minutosDeHora } from "./tiempo.ts";

Deno.test("minutosDeHora: HH:MM válido o null", () => {
  assertEquals(minutosDeHora("09:30"), 570);
  assertEquals(minutosDeHora("16:00"), 960);
  assertEquals(minutosDeHora("00:00"), 0);
  for (const malo of ["9:30", "24:00", "12:60", "9h30", "", "12:30:00"]) {
    assertEquals(minutosDeHora(malo), null, malo);
  }
});

Deno.test("aInstanteUtc resuelve el horario de verano de 2026 sin intervención (CB-51)", () => {
  // Hasta el 8 de marzo Nueva York está en UTC−5; desde ese día, en UTC−4.
  assertEquals(
    aInstanteUtc("2026-03-06", "09:30")?.toISOString(),
    "2026-03-06T14:30:00.000Z",
  );
  assertEquals(
    aInstanteUtc("2026-03-09", "09:30")?.toISOString(),
    "2026-03-09T13:30:00.000Z",
  );
  // Hasta el 1 de noviembre UTC−4; desde ese día, UTC−5.
  assertEquals(
    aInstanteUtc("2026-10-30", "16:00")?.toISOString(),
    "2026-10-30T20:00:00.000Z",
  );
  assertEquals(
    aInstanteUtc("2026-11-02", "16:00")?.toISOString(),
    "2026-11-02T21:00:00.000Z",
  );
});

Deno.test("aInstanteUtc: la media jornada y las entradas inválidas", () => {
  assertEquals(
    aInstanteUtc("2026-11-27", "13:00")?.toISOString(),
    "2026-11-27T18:00:00.000Z",
  );
  assertEquals(aInstanteUtc("2026-11-27", "1pm"), null);
  assertEquals(aInstanteUtc("27/11/2026", "13:00"), null);
});

Deno.test("instanteDeNuevaYork: la hora que no existe usa el desfase de invierno", () => {
  // 02:30 del 8 de marzo de 2026 no existe en Nueva York.
  assertEquals(
    instanteDeNuevaYork("2026-03-08", 2 * 60 + 30).toISOString(),
    "2026-03-08T07:30:00.000Z",
  );
});
