# HU-086 · Bandeja de notificaciones

| Campo | Valor |
|---|---|
| Épica | [E-09 · Tiempo real y notificaciones](README.md) |
| Entrega (hito) | R3 · La IA analiza |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-14 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-09` · `M-14` · `prioridad-alta` |

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** tener una bandeja con mis avisos y un contador de los que no he leído,  
**para** no perderme nada de lo que me toca.

## Requisitos funcionales

- [FR-192 · Bandeja de notificaciones](../requisitos-funcionales/FR-192-bandeja-de-notificaciones.md)

## Reglas

09 §5 · 09 §5.1 · 06 §5.5 · 06 §8.1

## Criterios de aceptación

- **CA-1** Dado un aviso del catálogo de 09 §5.1, cuando ocurre, entonces se crea una fila en `notificaciones` para cada destinatario con su tipo, su título, su cuerpo y su referencia.
- **CA-2** Dada una persona con notificaciones sin leer, cuando abre la app, entonces ve el contador y la lista, y la bandeja se actualiza con el evento `notificacion`.
- **CA-3** Dadas las notificaciones `aporte_confirmado` y `cupo_inicial_no_asignado`, cuando ocurren, entonces llegan a los Administradores.
- **CA-4** (aislamiento) Dado cualquier rol, cuando consulta `notificaciones`, entonces solo ve las propias.
- **CA-5** (permiso) Dada una persona, cuando llama `marcar_notificaciones_leidas` con ids ajenos, entonces solo cambian las suyas.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Migración: tabla `notificaciones` (06 §5.5) con RLS de lectura de las propias y RPC `marcar_notificaciones_leidas(ids)`.
- [ ] Migración: función interna que crea las notificaciones por destinatario según el catálogo y evento `notificacion` en `usuario:{id}`.
- [ ] Notificaciones `aporte_confirmado`, `cupo_inicial_no_asignado`, `alerta_mercado` e `integracion_caida`.
- [ ] App: bandeja y contador en `lib/features/alertas/` con `notificacionesProvider`.
- [ ] Pruebas pgTAP (creación por tipo, lectura propia y marcar leídas) y pruebas de widget.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-085 · Alertas del sistema por audiencia](HU-085-alertas-del-sistema-por-audiencia.md) | Las alertas generan notificaciones. |
| Depende de | [HU-084 · Gestor de tiempo real en la app](HU-084-gestor-de-tiempo-real-en-la-app.md) | La bandeja se actualiza con el patrón foto y eventos. |
| Depende de | [HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25](../E-03-fondo-y-libro-contable/HU-015-confirmar-el-aporte-por-conciliacion-y-repartirlo-50-25-25.md) | Avisa `aporte_confirmado`. |
| Depende de | [HU-035 · Salud de las integraciones](../E-05-motor-de-politicas-y-configuracion/HU-035-salud-de-las-integraciones.md) | Avisa `integracion_caida`. |
| Habilita | [HU-058 · Sugerencia de compra para Arriesgadas](../E-07-sugerencias-y-decisiones/HU-058-sugerencia-de-compra-para-arriesgadas.md) | HU-058: avisa a los Analistas con `sugerencia_nueva`. |
| Habilita | [HU-066 · Vencimiento por tiempo y aviso previo](../E-07-sugerencias-y-decisiones/HU-066-vencimiento-por-tiempo-y-aviso-previo.md) | HU-066: avisa que la sugerencia está por vencer o venció. |
| Habilita | [HU-088 · Recibir avisos por push](HU-088-recibir-avisos-por-push.md) | HU-088: el push sale de la bandeja de notificaciones. |
| Habilita | [HU-096 · Reporte diario al Administrador](../E-10-cartera-y-reportes/HU-096-reporte-diario-al-administrador.md) | HU-096: avisa al Administrador. |
| Habilita | [HU-112 · Retención de datos y vigilancia del tamaño de la base](../E-12-seguridad-auditoria-y-cumplimiento/HU-112-retencion-de-datos-y-vigilancia-del-tamano-de-la-base.md) | HU-112: limpia las notificaciones leídas. |

## Notas técnicas

Los demás tipos del catálogo los crea la historia de su flujo: sugerencias, órdenes, protecciones y descuadres. El push sale desde R5 ([HU-088](HU-088-recibir-avisos-por-push.md)).

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
