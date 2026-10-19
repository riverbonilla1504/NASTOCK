# HU-039 · Freno de emergencia

| Campo | Valor |
|---|---|
| Épica | [E-05 · Motor de políticas y configuración](README.md) |
| Entrega (hito) | R5 · Protegido y avisado |
| Rol | Analista |
| Prioridad | Alta |
| Módulos afectados | M-08 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-05` · `M-08` · `prioridad-alta` |

## Historia

**Como** Analista,  
**quiero** detener la IA o el trading con un botón siempre visible,  
**para** parar el sistema de inmediato cuando veo algo raro, sin esperar a nadie.

## Requisitos funcionales

- [FR-093 · Freno de emergencia](../requisitos-funcionales/FR-093-freno-de-emergencia.md)
- [FR-094 · Efectos de apagar los interruptores](../requisitos-funcionales/FR-094-efectos-de-apagar-los-interruptores.md)

## Reglas

PM-56 · RR-14 · D-28 · 08 §6 · 11 §8 · 03 §2

## Criterios de aceptación

- **CA-1** Dado un Analista o un Administrador, cuando pulsa el freno y escribe un motivo, entonces el interruptor elegido queda apagado y se registra `interruptor.apagado` con el motivo.
- **CA-2** Dado `ia_activa` apagado, cuando llega la hora del ciclo, entonces queda omitido con el motivo `ia_pausada` y las sugerencias vivas siguen.
- **CA-3** (caso borde) CB-32: Dado `trading_activo` apagado con sugerencias aprobadas y aún no enviadas, cuando el ejecutor las revalida, entonces quedan fallidas con `TRADING_PAUSADO` y se libera su retención; las pendientes pasan a invalidadas, salvo las de liquidación.
- **CA-4** Dado `trading_activo` apagado, cuando una protección se dispara, entonces se ejecuta igual.
- **CA-5** (permiso) Dado un Usuario, cuando llama `activar_freno`, entonces recibe `NO_AUTORIZADO`, y no ve el botón.

## Casos borde

CB-32

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-13.

## Tareas

- [ ] RPC `activar_freno`: al apagar `trading_activo`, invalida las sugerencias vivas salvo las de liquidación y notifica.
- [ ] App: botón de freno en la barra para Analista y Administrador, con motivo obligatorio y confirmación.
- [ ] App: aviso visible de operación pausada y mensajes de `TRADING_PAUSADO` y de `IA_PAUSADA`.
- [ ] Pruebas pgTAP (efectos sobre sugerencias y órdenes, protecciones exentas y permisos) y prueba de widget del botón.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-034 · Encender y apagar los interruptores del fondo](HU-034-encender-y-apagar-los-interruptores-del-fondo.md) | Extiende `activar_freno`. |
| Depende de | [HU-067 · Invalidación por precio y por cambio de situación](../E-07-sugerencias-y-decisiones/HU-067-invalidacion-por-precio-y-por-cambio-de-situacion.md) | Invalida las sugerencias vivas. |
| Depende de | [HU-073 · Enviar al broker las órdenes aprobadas](../E-08-ejecucion-y-broker/HU-073-enviar-al-broker-las-ordenes-aprobadas.md) | El ejecutor revalida y deja fallidas las aprobadas. |
| Depende de | [HU-078 · Protección virtual en compras fraccionales](../E-08-ejecucion-y-broker/HU-078-proteccion-virtual-en-compras-fraccionales.md) | Las protecciones siguen con el trading pausado. |
| Habilita | [HU-040 · Reanudar el trading solo con la conciliación en ok](HU-040-reanudar-el-trading-solo-con-la-conciliacion-en-ok.md) | HU-040: reanuda lo que el freno o el sistema pausaron. |
| Habilita | [HU-080 · Conciliación completa con pausa automática](../E-08-ejecucion-y-broker/HU-080-conciliacion-completa-con-pausa-automatica.md) | HU-080: apaga `trading_activo` con los mismos efectos del freno. |

## Notas técnicas

El Analista puede frenar pero no reanudar: detener es seguro y urgente; reanudar es aceptar el riesgo de nuevo (03 §2). Es el primer paso de la respuesta a incidentes (11 §8).

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
