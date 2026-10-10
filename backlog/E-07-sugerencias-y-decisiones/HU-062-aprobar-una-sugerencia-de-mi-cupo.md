# HU-062 · Aprobar una sugerencia de mi cupo

| Campo | Valor |
|---|---|
| Épica | [E-07 · Sugerencias y decisiones](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-09, M-08 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-07` · `M-09` · `M-08` · `prioridad-alta` |

## Historia

**Como** Usuario,  
**quiero** aprobar una sugerencia de mi cupo,  
**para** que la compra o la venta se ejecute con mi dinero y bajo mi decisión.

## Requisitos funcionales

- [FR-142 · Aprobación de una sugerencia de mi cupo](../requisitos-funcionales/FR-142-aprobacion-de-una-sugerencia-de-mi-cupo.md)
- [FR-143 · Retención de fondos al aprobar](../requisitos-funcionales/FR-143-retencion-de-fondos-al-aprobar.md)
- [FR-145 · Decisión única e idempotente](../requisitos-funcionales/FR-145-decision-unica-e-idempotente.md)

## Reglas

PM-11 · RN-23 · RN-53 · RR-12 · 08 §1 · 08 §8 · 03 §4.4 · D-33

## Criterios de aceptación

- **CA-1** Dada una sugerencia viva de su cupo, cuando el Usuario la aprueba tras la confirmación biométrica, entonces pasa a aprobada, se retiene `cantidad × precio_referencia × (1 + banda)`, se crea la orden en estado creada, se encola y se registra `sugerencia.aprobada`.
- **CA-2** (caso borde) CB-21: Dada una aprobación en el mismo segundo del vencimiento, cuando llega, entonces decide la hora de la base de datos: si ya venció, responde `VENCIDA`.
- **CA-3** (caso borde) CB-22: Dado un precio que salió de la banda, cuando el Usuario pulsa Aprobar, entonces responde `FUERA_DE_BANDA`.
- **CA-4** (caso borde) CB-29: Dadas dos compras y disponible para una sola, cuando aprueba la segunda, entonces responde `FONDOS_INSUFICIENTES` y la sugerencia sigue pendiente.
- **CA-5** Dado un doble toque en Aprobar, cuando llega la segunda llamada, entonces devuelve el mismo resultado sin duplicar la decisión ni la orden.
- **CA-6** (permiso) Dado otro Usuario, un Analista o un Administrador, cuando intenta aprobar esa sugerencia, entonces recibe `NO_AUTORIZADO`.

## Casos borde

CB-21, CB-22, CB-29

## Escenario E2E

E2E-08 (nuevo)

## Tareas

- [ ] Migración: tipos `origen_orden`, `clase_orden`, `tipo_orden` y `estado_orden`, tablas `ordenes` y `ordenes_eventos` (06 §5.4) con RLS, y cola `ordenes_por_enviar`.
- [ ] RPC `aprobar_sugerencia(id)`: rol y dueño, bloqueo de fila, estado, vencimiento, banda, `validar_operacion`, retención, decisión, orden creada, encolado y `private.despertar_funcion('ejecutor-ordenes')`.
- [ ] Auditoría `sugerencia.aprobada` y eventos `sugerencia` y `orden`.
- [ ] App: botón Aprobar con el componente de confirmación de [HU-009](../E-02-identidad-y-acceso/HU-009-sesion-segura-bloqueo-biometrico-y-confirmacion-de-acciones-sensibles.md), sin actualización optimista.
- [ ] Pruebas pgTAP `sugerencias_*`: cada validación, idempotencia, concurrencia por el disponible y permisos.
- [ ] E2E-08: sugerencia a un cupo → aprobar → orden creada y retención.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-061 · Mis sugerencias: bandeja y detalle con explicación](HU-061-mis-sugerencias-bandeja-y-detalle-con-explicacion.md) | Se aprueba desde el detalle de la sugerencia. |
| Depende de | [HU-009 · Sesión segura, bloqueo biométrico y confirmación de acciones sensibles](../E-02-identidad-y-acceso/HU-009-sesion-segura-bloqueo-biometrico-y-confirmacion-de-acciones-sensibles.md) | Exige la confirmación biométrica. |
| Depende de | [HU-037 · Motor de políticas: reglas de la propuesta](../E-05-motor-de-politicas-y-configuracion/HU-037-motor-de-politicas-reglas-de-la-propuesta.md) | Revalida con el motor de políticas al aprobar. |
| Depende de | [TT-06 · Arnés E2E de backend y de la app](../E-01-cimientos-y-calidad-continua/TT-06-arnes-e2e-de-backend-y-de-la-app.md) | Agrega el escenario E2E-08. |
| Habilita | [HU-038 · Motor de políticas completo en los cuatro momentos](../E-05-motor-de-politicas-y-configuracion/HU-038-motor-de-politicas-completo-en-los-cuatro-momentos.md) | HU-038: RR-10 y RR-16 miran sugerencias y órdenes. |
| Habilita | [HU-065 · Decidir en Arriesgadas con doble aprobación](HU-065-decidir-en-arriesgadas-con-doble-aprobacion.md) | HU-065: extiende `aprobar_sugerencia` y usa la retención y la orden. |
| Habilita | [HU-071 · Aprobar o rechazar un rebalanceo](HU-071-aprobar-o-rechazar-un-rebalanceo.md) | HU-071: extiende `aprobar_sugerencia`. |
| Habilita | [HU-073 · Enviar al broker las órdenes aprobadas](../E-08-ejecucion-y-broker/HU-073-enviar-al-broker-las-ordenes-aprobadas.md) | HU-073: toma las órdenes que crea la aprobación. |

## Notas técnicas

Aquí nacen las tablas `ordenes` y `ordenes_eventos` y la cola `ordenes_por_enviar`; el envío al broker está en [HU-073](../E-08-ejecucion-y-broker/HU-073-enviar-al-broker-las-ordenes-aprobadas.md). La RPC devuelve el registro actualizado y la pantalla se actualiza con eso, sin esperar el evento (08 §9.3).

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
