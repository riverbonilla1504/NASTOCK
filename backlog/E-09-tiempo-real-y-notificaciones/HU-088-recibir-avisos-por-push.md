# HU-088 · Recibir avisos por push

| Campo | Valor |
|---|---|
| Épica | [E-09 · Tiempo real y notificaciones](README.md) |
| Entrega (hito) | R5 · Protegido y avisado |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-14 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-09` · `M-14` · `prioridad-alta` |

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** recibir un push cuando pasa algo que debo atender,  
**para** enterarme aunque no tenga la app abierta.

## Requisitos funcionales

- [FR-194 · Envío de push](../requisitos-funcionales/FR-194-envio-de-push.md)

## Reglas

09 §5.1 · 09 §5.2 · 09 §5.4 · 05 §8 · D-14

## Criterios de aceptación

- **CA-1** Dada una notificación de un tipo con push en el catálogo, cuando se crea, entonces se encola y `notificador` la envía por FCM a los dispositivos del destinatario y marca `push_enviado_en`.
- **CA-2** Dado el texto del push, cuando se arma, entonces lleva el símbolo pero no montos ni saldos.
- **CA-3** Dado un token inválido o no registrado, cuando FCM lo informa, entonces se borra de `dispositivos`.
- **CA-4** (caso borde) CB-65: Dado que FCM falla, cuando ocurre, entonces el push se reintenta 3 veces y la notificación sigue en la app.
- **CA-5** Dada una alerta de mercado, cuando se crea, entonces sale por push solo si su severidad es `critica`.

## Casos borde

CB-65

## Escenario E2E

E2E-15 (nuevo)

## Tareas

- [ ] Migración: cola `notificaciones_push`, encolado desde el trigger de `notificaciones` según el catálogo y las preferencias, y trabajo `barrer_notificador` de `pg_cron`.
- [ ] Funciones: `_shared/push/` con `fcm.ts` (FCM HTTP v1 con el token OAuth2 cacheado) y `simulado.ts` (guarda los push en la tabla de pruebas).
- [ ] Función `notificador`: lee la cola, envía, borra los tokens inválidos, marca el envío y registra la salud de `fcm`.
- [ ] App: canales de Android `sugerencias` (importancia alta), `operaciones` y `alertas`.
- [ ] Pruebas `deno test` de `notificador` con el simulado y con respuestas grabadas de FCM.
- [ ] E2E-15: una sugerencia nueva genera un push simulado al dispositivo; un token inválido se elimina.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-087 · Registrar mi dispositivo para push](HU-087-registrar-mi-dispositivo-para-push.md) | Envía a los dispositivos registrados. |
| Depende de | [HU-086 · Bandeja de notificaciones](HU-086-bandeja-de-notificaciones.md) | El push sale de la bandeja de notificaciones. |
| Depende de | [HU-059 · Reparto de una señal de Usuarios en sugerencias por cupo](../E-07-sugerencias-y-decisiones/HU-059-reparto-de-una-senal-de-usuarios-en-sugerencias-por-cupo.md) | El escenario usa una sugerencia nueva. |
| Depende de | [TT-06 · Arnés E2E de backend y de la app](../E-01-cimientos-y-calidad-continua/TT-06-arnes-e2e-de-backend-y-de-la-app.md) | Agrega el escenario E2E-15. |
| Habilita | [HU-089 · Elegir qué avisos recibo por push](HU-089-elegir-que-avisos-recibo-por-push.md) | HU-089: decide qué notificaciones salen por push. |
| Habilita | [HU-090 · Abrir la app desde la notificación](HU-090-abrir-la-app-desde-la-notificacion.md) | HU-090: abre la app desde el push recibido. |

## Notas técnicas

La pantalla bloqueada la puede ver cualquiera: por eso el push no lleva montos (09 §5.2).

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
