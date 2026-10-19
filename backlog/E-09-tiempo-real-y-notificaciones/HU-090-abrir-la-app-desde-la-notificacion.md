# HU-090 · Abrir la app desde la notificación

| Campo | Valor |
|---|---|
| Épica | [E-09 · Tiempo real y notificaciones](README.md) |
| Entrega (hito) | R5 · Protegido y avisado |
| Rol | Usuario |
| Prioridad | Media |
| Módulos afectados | M-14, M-01 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-09` · `M-14` · `M-01` · `prioridad-media` |

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** tocar una notificación y llegar directo a lo que debo atender,  
**para** decidir rápido, pero siempre dentro de la app.

## Requisitos funcionales

- [FR-196 · Apertura desde la notificación](../requisitos-funcionales/FR-196-apertura-desde-la-notificacion.md)
- [FR-197 · Aviso dentro de la app](../requisitos-funcionales/FR-197-aviso-dentro-de-la-app.md)

## Reglas

09 §5.2 · 04 §8 · D-35

## Criterios de aceptación

- **CA-1** Dado un push de una sugerencia, cuando la persona lo toca, entonces la app se abre, pide biometría y muestra `/sugerencias/{id}`.
- **CA-2** Dada la notificación en la pantalla bloqueada, cuando la persona la mira, entonces no ofrece botones para aprobar ni para rechazar.
- **CA-3** Dada la app abierta, cuando llega un aviso, entonces se muestra como un banner dentro de la app y no como una notificación del sistema.
- **CA-4** Dado un enlace a una pantalla que el rol no tiene, cuando se abre, entonces el enrutador lleva al inicio.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] App: manejo del toque de la notificación con `firebase_messaging` y `flutter_local_notifications`, y navegación con `go_router` a la ruta de la entidad.
- [ ] App: esquema profundo `com.ritech.inversiones://` y bloqueo biométrico antes de mostrar la pantalla.
- [ ] App: banner dentro de la app cuando está en primer plano.
- [ ] Pruebas de widget de la navegación desde un aviso.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-088 · Recibir avisos por push](HU-088-recibir-avisos-por-push.md) | Abre la app desde el push recibido. |
| Depende de | [HU-009 · Sesión segura, bloqueo biométrico y confirmación de acciones sensibles](../E-02-identidad-y-acceso/HU-009-sesion-segura-bloqueo-biometrico-y-confirmacion-de-acciones-sensibles.md) | Pide biometría antes de mostrar datos. |
| Depende de | [HU-061 · Mis sugerencias: bandeja y detalle con explicación](../E-07-sugerencias-y-decisiones/HU-061-mis-sugerencias-bandeja-y-detalle-con-explicacion.md) | Lleva al detalle de la sugerencia. |

## Notas técnicas

No se decide desde la notificación: siempre en la app y con biometría (D-35).

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
