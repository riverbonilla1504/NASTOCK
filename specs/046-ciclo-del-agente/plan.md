# Plan: HU-046 · Ciclo del agente: programación, uno a la vez y omisiones

**Rama**: `demo-ia-oportunidades` (D-70, #171), cierre en `048-cierre-de-la-ia` (D-72, #196) · **Módulos**: M-07 · **Fuentes**: `docs/07` §2, §3 · PM-58 · CB-62.

- **Ciclos** (migración `20261108200000_agente_ciclos_y_evaluaciones.sql`): tabla `ciclos_agente` con RLS; `private.registrar_ciclo(disparador)` (uno a la vez con candado; un `en_curso` de más de 5 minutos pasa a `fallido`), `private.cerrar_ciclo` (publica `ciclo_agente` en el canal `supervision`) y `private.ciclo_agente_pendiente()`.
- **Programación** (migración `20261108200002_oportunidades_y_trabajo_agente.sql`): trabajo `ciclo_agente` de `pg_cron` cada 5 minutos; con la ventana abierta despierta al agente cada `ia.minutos_entre_ciclos`, y con la bolsa cerrada si no hubo un ciclo completado en 6 horas (D-70).
- **Cierre D-72** (migración `20261114120000_cierre_de_la_ia.sql`): `private.estado_del_agente()` informa `ia_activa`; `private.despertar_funcion(nombre, cuerpo)`; `public.lanzar_ciclo()` para el Administrador, con bitácora `ciclo.lanzado`.
- **Función** (`agente/manejador.ts`): lee el disparador del cuerpo (`programado` o `manual`); con `ia_activa` apagado cierra el ciclo `omitido` (`ia_apagada`).

Decisiones sin regla explícita en `docs/`:
- Con la bolsa cerrada el ciclo no se omite (D-70); el fondo sin capital se cubre con `ia_activa`, que no se enciende sin un aporte confirmado (RN-11).

Pruebas: pgTAP `11_agente_y_oportunidades_test.sql` (22) y `22_cierre_de_la_ia_test.sql` (13) · `deno test agente/manejador_test.ts` (12) · E2E-06.
