# TT-08 · Despliegue continuo al proyecto MVP con prueba de humo

| Campo | Valor |
|---|---|
| Épica | [E-01 · Cimientos y calidad continua](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Prioridad | Alta |
| Módulos afectados | M-20 |
| Estimación | Por definir al refinar |
| Etiquetas | `tarea-tecnica` · `E-01` · `M-20` · `prioridad-alta` |

## Qué hay que hacer y por qué

Hacer que cada integración a `main` con CI en verde despliegue migraciones, funciones, secretos, web y APK al proyecto MVP y corra la prueba de humo. Así cada entrega termina desplegada y alguien del equipo puede abrir la app.

## Documentación fuente

15 §6 · 15 §9 · 15 §11 · 05 §10 · 16 §4 · 14 §1

## Requisitos funcionales

- [FR-001 · Aplicación en Android y web](../requisitos-funcionales/FR-001-aplicacion-en-android-y-web.md)
- [FR-009 · Prueba de humo tras cada despliegue](../requisitos-funcionales/FR-009-prueba-de-humo-tras-cada-despliegue.md)

## Criterio de terminado

- [ ] Tras un merge a `main`, `despliegue.yml` aplica `supabase db push`, despliega las funciones, sincroniza sus secretos, publica la web en Firebase Hosting y distribuye el APK firmado al grupo del equipo.
- [ ] La prueba de humo pasa, y falla si hay un proveedor simulado en `mvp` (CB-91) o si el correo queda habilitado como proveedor de ingreso (CB-92).
- [ ] Una persona del equipo abre la web publicada e instala el APK desde App Distribution.
- [ ] Si la prueba de humo falla, el flujo avisa.
- [ ] `scripts/verificar.sh` completo en verde y CI en verde.

## Tareas

- [ ] `firebase.json` y configuración de Hosting; `flutter build web` con `--dart-define`.
- [ ] Firma de Android con los secretos `ANDROID_*`, `flutter build apk --release` y Firebase App Distribution.
- [ ] Trabajo `supabase`: `supabase link`, `supabase db push`, `supabase functions deploy` y secretos de funciones con `ENTORNO=mvp` y `PROVEEDOR_*` reales.
- [ ] `supabase/tests/humo/`: las verificaciones de 15 §11 que ya aplican; las de mercado, integraciones y configuración de IA entran con sus historias.
- [ ] Probar la reversión de la web desde Firebase Hosting (15 §9).

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [TT-02 · Cuentas, conexiones y secretos de los servicios externos](TT-02-cuentas-conexiones-y-secretos-de-los-servicios-externos.md) | Necesita los proyectos y los secretos de Supabase y Firebase. |
| Depende de | [TT-07 · Integración continua completa en cada PR](TT-07-integracion-continua-completa-en-cada-pr.md) | El despliegue solo corre tras CI en verde. |
| Habilita | [TT-09 · Mantenimiento: ping diario, respaldo cifrado y prueba real semanal](TT-09-mantenimiento-ping-diario-respaldo-cifrado-y-prueba-real-semanal.md) | TT-09: necesita el proyecto MVP desplegado. |
| Habilita | [HU-114 · Lista de verificación antes de abrir el MVP al equipo](../E-12-seguridad-auditoria-y-cumplimiento/HU-114-lista-de-verificacion-antes-de-abrir-el-mvp-al-equipo.md) | HU-114: usa la prueba de humo del despliegue. |
