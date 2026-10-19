# HU-009 · Sesión segura, bloqueo biométrico y confirmación de acciones sensibles

| Campo | Valor |
|---|---|
| Épica | [E-02 · Identidad y acceso](README.md) |
| Entrega (hito) | R2 · El fondo existe |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-01 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-02` · `M-01` · `prioridad-alta` |

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** que la app guarde mi sesión de forma segura, se bloquee al volver de segundo plano y me pida confirmar cada acción sensible,  
**para** que nadie decida sobre el dinero con mi teléfono desatendido.

## Requisitos funcionales

- [FR-026 · Sesión en almacenamiento seguro](../requisitos-funcionales/FR-026-sesion-en-almacenamiento-seguro.md)
- [FR-027 · Bloqueo biométrico de la app](../requisitos-funcionales/FR-027-bloqueo-biometrico-de-la-app.md)
- [FR-028 · Confirmación de acciones sensibles](../requisitos-funcionales/FR-028-confirmacion-de-acciones-sensibles.md)

## Reglas

04 §8 · 08 §9.3 · 11 §3

## Criterios de aceptación

- **CA-1** Dada la app en Android, cuando guarda la sesión, entonces usa el almacenamiento seguro del sistema y no preferencias planas.
- **CA-2** Dada la app en segundo plano por más de `app.minutos_bloqueo` minutos, cuando vuelve a primer plano, entonces pide biometría o el PIN del dispositivo antes de mostrar datos.
- **CA-3** Dada una acción sensible (aprobar o rechazar una sugerencia, crear una orden manual o registrar un movimiento de dinero), cuando la persona la inicia en móvil, entonces la app exige confirmación biométrica; en web muestra un diálogo que repite monto y símbolo.
- **CA-4** Dada una confirmación que la persona cancela, cuando la descarta, entonces la acción no se envía.
- **CA-5** (caso borde) CB-08: Dado un teléfono perdido con la app instalada, cuando alguien lo abre, entonces el bloqueo impide ver los datos.

## Casos borde

CB-08

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Migración: parámetro `app.minutos_bloqueo` con su rango (02 §10).
- [ ] App: `LocalStorage` personalizado de `supabase_flutter` sobre `flutter_secure_storage` en `lib/core/`.
- [ ] App: bloqueo con `local_auth` al volver de segundo plano según `app.minutos_bloqueo`.
- [ ] App: componente común de confirmación (biometría en móvil, diálogo en web) con los estados de 08 §9.3: inactivo, confirmando, enviando, hecho, cancelado y error.
- [ ] Pruebas de widget del componente de confirmación y del bloqueo.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-005 · Ingresar con Google en Android y web](HU-005-ingresar-con-google-en-android-y-web.md) | Protege la sesión que abre el ingreso. |
| Habilita | [HU-062 · Aprobar una sugerencia de mi cupo](../E-07-sugerencias-y-decisiones/HU-062-aprobar-una-sugerencia-de-mi-cupo.md) | HU-062: exige la confirmación biométrica. |
| Habilita | [HU-063 · Rechazar una sugerencia con motivo](../E-07-sugerencias-y-decisiones/HU-063-rechazar-una-sugerencia-con-motivo.md) | HU-063: exige la confirmación de la acción. |
| Habilita | [HU-075 · Crear una orden manual en mi cupo](../E-08-ejecucion-y-broker/HU-075-crear-una-orden-manual-en-mi-cupo.md) | HU-075: exige la confirmación biométrica. |
| Habilita | [HU-090 · Abrir la app desde la notificación](../E-09-tiempo-real-y-notificaciones/HU-090-abrir-la-app-desde-la-notificacion.md) | HU-090: pide biometría antes de mostrar datos. |
| Habilita | [HU-099 · Pantalla de capital](../E-11-administracion/HU-099-pantalla-de-capital.md) | HU-099: confirma los movimientos de dinero. |
| Habilita | [HU-100 · Pantalla de cupos](../E-11-administracion/HU-100-pantalla-de-cupos.md) | HU-100: confirma los movimientos de dinero. |

## Notas técnicas

El bloqueo es una protección local, no de servidor (04 §8). En web la sesión queda en el almacenamiento del navegador y se mitiga con el JWT de 15 minutos. No hay actualización optimista en nada que toque dinero.

## Documentación a actualizar

Ninguna.

## Definición de terminado

Lista de `docs/14` §6, la misma del formulario de historia:

- [ ] Criterios de aceptación y casos borde cumplidos
- [ ] `scripts/verificar.sh` completo en verde (incluye E2E) y CI en verde
- [ ] Escenario E2E agregado o actualizado
- [ ] RLS y pruebas pgTAP si toca datos; escrituras solo por RPC
- [ ] `docs/` actualizada (y historial 13 §4) si cambió una regla
- [ ] `docs/17` actualizado si cambiaron rutas, tablas o funciones
- [ ] Error no trivial registrado en `docs/errores-conocidos.md`
- [ ] Desplegada en el proyecto MVP con la prueba de humo en verde
