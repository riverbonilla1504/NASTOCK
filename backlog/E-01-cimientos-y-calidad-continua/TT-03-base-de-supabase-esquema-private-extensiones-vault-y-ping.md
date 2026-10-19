# TT-03 · Base de Supabase: esquema private, extensiones, Vault y ping

| Campo | Valor |
|---|---|
| Épica | [E-01 · Cimientos y calidad continua](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Prioridad | Alta |
| Módulos afectados | M-20 |
| Estimación | Por definir al refinar |
| Etiquetas | `tarea-tecnica` · `E-01` · `M-20` · `prioridad-alta` |

## Qué hay que hacer y por qué

Crear el proyecto local de Supabase y la primera migración con lo que todas las demás necesitan: el esquema `private` no expuesto, las extensiones `pg_cron`, `pg_net` y `pgmq`, la lectura de secretos desde Vault, `private.despertar_funcion` y `public.ping()`. Es la base sobre la que se escriben tablas, funciones y trabajos programados.

## Documentación fuente

05 §3.2 · 05 §7 · 05 §12 · 06 §1 · 06 §7 · 16 §3.2

## Requisitos funcionales

- [FR-008 · Latido del proyecto](../requisitos-funcionales/FR-008-latido-del-proyecto.md)

## Criterio de terminado

- [ ] `supabase start` y `supabase db reset` levantan la base local desde cero con las migraciones y `seed.sql`.
- [ ] El rol anónimo solo puede ejecutar `ping()`, que devuelve la hora del servidor; cualquier otro acceso anónimo falla (pgTAP).
- [ ] `private.despertar_funcion(nombre)` hace `net.http_post` con la URL y el secreto leídos de Vault, y el esquema `private` no aparece en la API.
- [ ] `supabase db lint` y `supabase test db` pasan.
- [ ] `scripts/verificar.sh` completo en verde y CI en verde.

## Tareas

- [ ] `supabase init`: `supabase/config.toml`, `migrations/`, `tests/`, `functions/` y `seed.sql`.
- [ ] Migración: esquema `private` y extensiones `pg_cron`, `pg_net` y `pgmq`.
- [ ] Migración: `public.ping()` con su fila de latido y permiso de ejecución para `anon`.
- [ ] Migración: `private.despertar_funcion(nombre)` con lectura de `url_funciones` y `secreto_interno` desde Vault.
- [ ] Funciones: `_shared/auth.ts` (secreto interno, JWT y rol) y `_shared/esquemas.ts` (validación con zod).
- [ ] Pruebas pgTAP: `anon` sin acceso salvo `ping()` y `private` no expuesto.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [TT-01 · Repositorio, GitHub Projects y wiki](TT-01-repositorio-github-projects-y-wiki.md) | Las migraciones viven en el repositorio y las valida CI. |
| Habilita | [TT-05 · Base de proveedores simulados, reloj controlable y datos de prueba](TT-05-base-de-proveedores-simulados-reloj-controlable-y-datos-de-prueba.md) | TT-05: necesita el proyecto local, el esquema `private` y `seed.sql`. |
| Habilita | [TT-06 · Arnés E2E de backend y de la app](TT-06-arnes-e2e-de-backend-y-de-la-app.md) | TT-06: el E2E de backend corre contra Supabase local. |
| Habilita | [HU-001 · Perfiles, rol actual y lecturas por rol](../E-02-identidad-y-acceso/HU-001-perfiles-rol-actual-y-lecturas-por-rol.md) | HU-001: usa el esquema `private` y el proyecto local. |
| Habilita | [HU-026 · Universo del NASDAQ-100 y carga histórica de barras](../E-04-datos-de-mercado/HU-026-universo-del-nasdaq-100-y-carga-historica-de-barras.md) | HU-026: crea tablas y funciones sobre el proyecto base. |
| Habilita | [HU-107 · Bitácora inmutable con cadena de hash](../E-12-seguridad-auditoria-y-cumplimiento/HU-107-bitacora-inmutable-con-cadena-de-hash.md) | HU-107: usa el esquema `private`. |
