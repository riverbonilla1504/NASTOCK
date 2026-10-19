# HU-067 · Invalidación por precio y por cambio de situación

| Campo | Valor |
|---|---|
| Épica | [E-07 · Sugerencias y decisiones](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-09, M-05 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-07` · `M-09` · `M-05` · `prioridad-alta` |

## Historia

**Como** Usuario,  
**quiero** que una sugerencia se invalide sola cuando la situación que analizó la IA ya no existe,  
**para** no aprobar algo que dejó de tener sentido.

## Requisitos funcionales

- [FR-152 · Invalidación por banda de precio](../requisitos-funcionales/FR-152-invalidacion-por-banda-de-precio.md)
- [FR-153 · Invalidación por cambio de situación](../requisitos-funcionales/FR-153-invalidacion-por-cambio-de-situacion.md)
- [FR-029 · Suspensión de una cuenta](../requisitos-funcionales/FR-029-suspension-de-una-cuenta.md)

## Reglas

RR-12 · 08 §1 · 04 §10 · D-34

## Criterios de aceptación

- **CA-1** (caso borde) CB-22: Dado un precio que se aleja del de referencia más que la banda, hacia arriba o hacia abajo, cuando se publican las cotizaciones, entonces la sugerencia pasa a invalidada con su motivo y la pantalla lo muestra.
- **CA-2** (caso borde) CB-30: Dada una sugerencia de venta cuya posición ya se vendió por protección, cuando ocurre, entonces pasa a invalidada con "La posición ya no existe".
- **CA-3** Dado un titular que queda suspendido o de baja, cuando ocurre, entonces sus sugerencias vivas pasan a invalidadas.
- **CA-4** (caso borde) CB-76: Dado un símbolo que sale de la lista blanca, cuando ocurre, entonces sus sugerencias vivas pasan a invalidadas.
- **CA-5** Dada una sugerencia invalidada, cuando ocurre, entonces quien debía decidir recibe `sugerencia_invalidada`.

## Casos borde

CB-22, CB-30, CB-76

## Escenario E2E

E2E-10 (actualizado)

## Tareas

- [ ] Migración: invalidación por banda dentro de `private.publicar_cotizaciones`.
- [ ] Migración: invalidación al suspender (`private.suspender_cuenta`), al cerrarse la posición (`private.aplicar_llenado`) y al desactivar un símbolo (`actualizar_lista_blanca`).
- [ ] `motivo_estado` con un texto por cada causa y notificación `sugerencia_invalidada`.
- [ ] Pruebas pgTAP `sugerencias_*`: una por cada causa.
- [ ] E2E-10 actualizado: invalidación por banda de precio.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-066 · Vencimiento por tiempo y aviso previo](HU-066-vencimiento-por-tiempo-y-aviso-previo.md) | Extiende el escenario E2E-10. |
| Depende de | [HU-028 · Ingesta de precios cada 15 segundos](../E-04-datos-de-mercado/HU-028-ingesta-de-precios-cada-15-segundos.md) | La banda se revisa al publicar cotizaciones. |
| Depende de | [HU-074 · Sincronizar órdenes y aplicar llenados](../E-08-ejecucion-y-broker/HU-074-sincronizar-ordenes-y-aplicar-llenados.md) | Invalida la venta cuando la posición ya se cerró. |
| Depende de | [HU-036 · Editar la lista blanca](../E-05-motor-de-politicas-y-configuracion/HU-036-editar-la-lista-blanca.md) | Invalida al desactivar un símbolo. |
| Depende de | [HU-010 · Suspender y reactivar una cuenta](../E-02-identidad-y-acceso/HU-010-suspender-y-reactivar-una-cuenta.md) | Invalida las sugerencias del titular suspendido. |
| Habilita | [HU-039 · Freno de emergencia](../E-05-motor-de-politicas-y-configuracion/HU-039-freno-de-emergencia.md) | HU-039: invalida las sugerencias vivas. |

## Notas técnicas

Se invalida en las dos direcciones del precio: si se movió más que la banda, la situación que analizó la IA ya no existe, aunque el precio sea mejor (D-34). La invalidación al apagar `trading_activo` está en [HU-039](../E-05-motor-de-politicas-y-configuracion/HU-039-freno-de-emergencia.md).

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
