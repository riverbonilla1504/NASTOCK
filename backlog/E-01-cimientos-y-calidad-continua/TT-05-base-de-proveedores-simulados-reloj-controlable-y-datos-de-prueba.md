# TT-05 · Base de proveedores simulados, reloj controlable y datos de prueba

| Campo | Valor |
|---|---|
| Épica | [E-01 · Cimientos y calidad continua](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Prioridad | Alta |
| Módulos afectados | M-19 |
| Estimación | Por definir al refinar |
| Etiquetas | `tarea-tecnica` · `E-01` · `M-19` · `prioridad-alta` |

## Qué hay que hacer y por qué

Montar el mecanismo que permite probar todo sin servicios externos ni horario de mercado: la selección de proveedor real o simulado por variable de entorno, el reloj controlable y el esquema `pruebas`. El simulado concreto de cada integración lo construye la historia que crea esa integración.

## Documentación fuente

10 §9 · 15 §3 · 05 §6 · 05 §10 · D-47

## Requisitos funcionales

- [FR-004 · Proveedores simulados por integración](../requisitos-funcionales/FR-004-proveedores-simulados-por-integracion.md)
- [FR-005 · Rechazo de proveedores simulados en el proyecto MVP](../requisitos-funcionales/FR-005-rechazo-de-proveedores-simulados-en-el-proyecto-mvp.md)
- [FR-006 · Reloj controlable solo en local y CI](../requisitos-funcionales/FR-006-reloj-controlable-solo-en-local-y-ci.md)

## Criterio de terminado

- [ ] `_shared/proveedores.ts` entrega la implementación real o la simulada de una integración según su variable `PROVEEDOR_*`, y lanza un error al iniciar si `ENTORNO=mvp` y alguna es simulada (CB-91, prueba de función).
- [ ] `private.ahora()` devuelve la hora fijada con `pruebas.fijar_reloj(...)` en local y la hora real cuando el esquema `pruebas` no existe.
- [ ] El esquema `pruebas` lo crea solo `seed.sql`; ninguna migración lo crea.
- [ ] `supabase/functions/.env.e2e` existe sin secretos, con `ENTORNO=ci` y todos los `PROVEEDOR_*=simulado`.
- [ ] `scripts/verificar.sh` completo en verde y CI en verde.

## Tareas

- [ ] Funciones: `_shared/proveedores.ts` con la lectura de `ENTORNO` y de `PROVEEDOR_BROKER`, `PROVEEDOR_MERCADO`, `PROVEEDOR_NOTICIAS`, `PROVEEDOR_CONTEXTO`, `PROVEEDOR_JEV` y `PROVEEDOR_PUSH`, y el rechazo en `mvp`.
- [ ] Migración: `private.ahora()` como única fuente de la hora para la lógica.
- [ ] `seed.sql`: esquema `pruebas` con `fijar_reloj`, la elección del escenario de cada proveedor y la tabla de push simulados.
- [ ] `supabase/functions/.env.e2e` sin secretos.
- [ ] Pruebas: `deno test` de `proveedores.ts` y pgTAP de `private.ahora()`.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [TT-03 · Base de Supabase: esquema private, extensiones, Vault y ping](TT-03-base-de-supabase-esquema-private-extensiones-vault-y-ping.md) | Necesita el proyecto local, el esquema `private` y `seed.sql`. |
| Habilita | [TT-06 · Arnés E2E de backend y de la app](TT-06-arnes-e2e-de-backend-y-de-la-app.md) | TT-06: el E2E usa proveedores simulados y el reloj controlable. |
| Habilita | [HU-002 · Alta solo con invitación vigente](../E-02-identidad-y-acceso/HU-002-alta-solo-con-invitacion-vigente.md) | HU-002: los usuarios de prueba viven en `seed.sql`. |
| Habilita | [HU-026 · Universo del NASDAQ-100 y carga histórica de barras](../E-04-datos-de-mercado/HU-026-universo-del-nasdaq-100-y-carga-historica-de-barras.md) | HU-026: el proveedor de mercado se elige con `_shared/proveedores.ts`. |
| Habilita | [HU-027 · Calendario, reloj y estado del mercado](../E-04-datos-de-mercado/HU-027-calendario-reloj-y-estado-del-mercado.md) | HU-027: usa el reloj controlable y el broker simulado. |
| Habilita | [HU-041 · Noticias de las candidatas](../E-06-ia-contexto-y-decision/HU-041-noticias-de-las-candidatas.md) | HU-041: el proveedor de noticias se elige con `_shared/proveedores.ts`. |
| Habilita | [HU-045 · Adaptador de JEV y estado en etiquetas](../E-06-ia-contexto-y-decision/HU-045-adaptador-de-jev-y-estado-en-etiquetas.md) | HU-045: el proveedor de JEV se elige con `_shared/proveedores.ts`. |
| Habilita | [HU-072 · Adaptador del broker para órdenes](../E-08-ejecucion-y-broker/HU-072-adaptador-del-broker-para-ordenes.md) | HU-072: el proveedor del broker se elige con `_shared/proveedores.ts`. |
