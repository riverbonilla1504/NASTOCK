// E2E-03 (parte de backend) · Mercado en vivo: la ingesta simulada publica precios y, cuando se
// detiene, el dato queda con su antigüedad (docs/15 §4). La pantalla y el aviso en la app los
// agregan HU-030 y HU-032 sobre este mismo escenario.
//
// HU-028: ingesta-mercado con el proveedor de mercado simulado, el reloj fijado y un día de mercado
// creado para la prueba (se borra al terminar).

import { assert, assertEquals } from "@std/assert";
import { despertarFuncion, esperarFunciones } from "./utilidades/funciones.ts";
import { conBd, fijarReloj, restablecer } from "./utilidades/pruebas.ts";

const DIA = "2031-03-04"; // martes
const ABIERTO = new Date("2031-03-04T15:00:00Z");
const CERRADO = new Date("2031-03-04T23:00:00Z");

Deno.test("E2E-03: la ingesta simulada publica precios con el mercado en ventana y calla con él cerrado", async () => {
  await esperarFunciones();

  // CA-5: sin el secreto interno la función rechaza.
  assertEquals((await despertarFuncion("ingesta-mercado", null)).estado, 401);
  assertEquals(
    (await despertarFuncion("ingesta-mercado", "secreto-equivocado")).estado,
    403,
  );

  await conBd(async (sql) => {
    try {
      await sql`delete from public.cotizaciones`;
      await sql`
        insert into public.calendario_mercado (fecha, apertura, cierre, sesion)
        values (${DIA}, '2031-03-04T14:30:00Z', '2031-03-04T21:00:00Z', 'regular')
        on conflict (fecha) do nothing`;
      const [{ total }] = await sql`
        select count(*)::int as total from private.simbolos_del_universo()`;
      const [{ antes }] = await sql`
        select count(*)::int as antes from realtime.messages
         where topic = 'mercado' and event = 'cotizaciones'`;

      // CA-1: con el mercado en ventana consulta todo el universo y publica.
      await fijarReloj(sql, ABIERTO);
      const abierta = await despertarFuncion("ingesta-mercado");
      assertEquals(abierta.estado, 200);
      const cuerpo = abierta.cuerpo as Record<string, number>;
      assertEquals(cuerpo.guardadas, total);
      assertEquals(cuerpo.descartadas, 0);

      const [{ guardadas }] = await sql`
        select count(*)::int as guardadas from public.cotizaciones`;
      assertEquals(guardadas, total);
      const [{ qqq }] = await sql`
        select count(*)::int as qqq from public.barras_minuto where simbolo = 'QQQ'`;
      assert(qqq >= 1, "QQQ guarda su barra de minuto");
      const [{ despues }] = await sql`
        select count(*)::int as despues from realtime.messages
         where topic = 'mercado' and event = 'cotizaciones'`;
      assertEquals(despues, antes + 1);

      const [{ recibido }] = await sql`
        select max(recibido_en) as recibido from public.cotizaciones`;
      assertEquals(new Date(recibido), ABIERTO);

      // CA-3 y CA-4: con el mercado cerrado no consulta; el último precio queda con su antigüedad.
      await fijarReloj(sql, CERRADO);
      const cerrada = await despertarFuncion("ingesta-mercado");
      assertEquals(cerrada.estado, 200);
      assertEquals(cerrada.cuerpo, { omitida: true });
      const [{ recibido: igual }] = await sql`
        select max(recibido_en) as recibido from public.cotizaciones`;
      assertEquals(new Date(igual), ABIERTO);
      const [{ despuesDeCerrar }] = await sql`
        select count(*)::int as "despuesDeCerrar" from realtime.messages
         where topic = 'mercado' and event = 'cotizaciones'`;
      assertEquals(despuesDeCerrar, despues);
    } finally {
      await restablecer(sql);
      await sql`delete from public.cotizaciones`;
      await sql`delete from public.barras_minuto where momento >= '2031-01-01'`;
      await sql`delete from public.calendario_mercado where fecha = ${DIA}`;
    }
  });
});
