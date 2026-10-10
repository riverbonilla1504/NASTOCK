# HU-040 · Reanudar el trading solo con la conciliación en ok

| Campo | Valor |
|---|---|
| Épica | [E-05 · Motor de políticas y configuración](README.md) |
| Entrega (hito) | R5 · Protegido y avisado |
| Rol | Administrador |
| Prioridad | Alta |
| Módulos afectados | M-08, M-12 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-05` · `M-08` · `M-12` · `prioridad-alta` |

## Historia

**Como** Administrador,  
**quiero** que el sistema solo me deje reanudar el trading cuando la conciliación está bien,  
**para** no volver a operar sobre un libro que no coincide con el broker.

## Requisitos funcionales

- [FR-095 · Reanudación de la operación](../requisitos-funcionales/FR-095-reanudacion-de-la-operacion.md)
- [FR-080 · Encendido de un interruptor](../requisitos-funcionales/FR-080-encendido-de-un-interruptor.md)

## Reglas

PM-57 · 11 §8 · 10 §8

## Criterios de aceptación

- **CA-1** (caso borde) CB-77: Dado un descuadre crítico abierto, cuando el Administrador intenta encender `trading_activo`, entonces la función lo rechaza.
- **CA-2** Dada la última conciliación en `ok`, o el descuadre marcado como revisado, cuando el Administrador reanuda, entonces `trading_activo` queda encendido y se registra `interruptor.encendido`.
- **CA-3** Dado el rechazo, cuando la app lo muestra, entonces explica que hay un descuadre abierto y lleva a la conciliación.
- **CA-4** (permiso) Dado un Analista, cuando llama `reanudar`, entonces recibe `NO_AUTORIZADO`.

## Casos borde

CB-77

## Escenario E2E

E2E-13 (actualizado)

## Tareas

- [ ] RPC `reanudar`: para `trading_activo`, exigir la última conciliación en `ok` o el descuadre revisado.
- [ ] App: mensaje que explica por qué no se puede reanudar y enlace a la conciliación.
- [ ] Pruebas pgTAP: con descuadre, con descuadre revisado, con `ok` y permisos.
- [ ] E2E-13 actualizado: reanudar exige la conciliación en `ok`.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-039 · Freno de emergencia](HU-039-freno-de-emergencia.md) | Reanuda lo que el freno o el sistema pausaron. |
| Depende de | [HU-080 · Conciliación completa con pausa automática](../E-08-ejecucion-y-broker/HU-080-conciliacion-completa-con-pausa-automatica.md) | Mira el resultado de la última conciliación. |
| Depende de | [HU-081 · Revisar un descuadre y lanzar una conciliación](../E-08-ejecucion-y-broker/HU-081-revisar-un-descuadre-y-lanzar-una-conciliacion.md) | Acepta un descuadre marcado como revisado. |
| Habilita | [HU-104 · Pantalla de conciliaciones](../E-11-administracion/HU-104-pantalla-de-conciliaciones.md) | HU-104: da acceso a reanudar el trading. |

## Notas técnicas

Es el paso "reanudar" de la respuesta a incidentes (11 §8).

## Documentación a actualizar

06 §9 no define el código de error al reanudar con un descuadre abierto (CB-77). Precisarlo en `docs/` antes de implementar.

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
