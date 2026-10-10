# HU-073 · Enviar al broker las órdenes aprobadas

| Campo | Valor |
|---|---|
| Épica | [E-08 · Ejecución y broker](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-10 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-08` · `M-10` · `prioridad-alta` |

## Historia

**Como** Usuario,  
**quiero** que la orden que aprobé llegue al broker en segundos, una sola vez y nunca a un precio peor que el aprobado,  
**para** que lo que se ejecuta sea exactamente lo que decidí.

## Requisitos funcionales

- [FR-160 · Envío de órdenes desde una cola](../requisitos-funcionales/FR-160-envio-de-ordenes-desde-una-cola.md)
- [FR-161 · Envío idempotente](../requisitos-funcionales/FR-161-envio-idempotente.md)
- [FR-162 · Tipos de orden](../requisitos-funcionales/FR-162-tipos-de-orden.md)
- [FR-163 · Tratamiento de los errores del broker](../requisitos-funcionales/FR-163-tratamiento-de-los-errores-del-broker.md)
- [FR-164 · Reintentos de la cola de órdenes](../requisitos-funcionales/FR-164-reintentos-de-la-cola-de-ordenes.md)

## Reglas

RN-24 · RR-12 · 08 §1 · 08 §2 · 10 §5 · 10 §10 · 05 §6 · 05 §8

## Criterios de aceptación

- **CA-1** Dada una orden creada y encolada, cuando el ejecutor la toma, entonces la revalida (banda, mercado, políticas, interruptor y salud), la envía con `client_order_id` igual a su id y la sugerencia pasa a `en_ejecucion`.
- **CA-2** Dada una compra de acciones enteras, cuando se envía, entonces es un bracket límite `gtc` con precio límite `referencia × (1 + banda)`, stop-loss y take-profit; una compra fraccional es una orden simple límite `day`.
- **CA-3** (caso borde) CB-33: Dado un envío sin respuesta, cuando ocurre, entonces la orden queda `desconocida` y se consulta por `client_order_id`: si existe, sigue; si no, pasa a `error_envio` y se puede reintentar sin duplicar.
- **CA-4** Dada una revalidación que falla (el mercado cerró, la banda, la salud o el interruptor), cuando ocurre, entonces la sugerencia queda `fallida` con su motivo y se libera la retención.
- **CA-5** (caso borde) CB-36: Dado un rechazo del broker por fondos insuficientes, cuando ocurre, entonces la orden queda `rechazada`, la sugerencia `fallida` y se alerta al Administrador por posible descuadre.
- **CA-6** (caso borde) CB-68: Dado un mensaje de la cola que falla 5 veces, cuando se agota, entonces se archiva, la orden queda en `error_envio` y se alerta al Administrador.
- **CA-7** (permiso) Dada una llamada a `ejecutor-ordenes` sin el secreto interno, cuando llega, entonces la función la rechaza.

## Casos borde

CB-33, CB-36, CB-67, CB-68

## Escenario E2E

E2E-08 (actualizado)

## Tareas

- [ ] Migración: `private.tomar_orden_para_envio(orden_id)` (bloquea, revalida y marca `enviada`), `private.registrar_respuesta_envio(...)` y `private.registrar_error_envio(...)`.
- [ ] Función `ejecutor-ordenes`: lee `ordenes_por_enviar`, arma la orden según 10 §5, la envía con `client_order_id` y trata cada error de 10 §10.
- [ ] Migración: trabajo `barrer_ejecutor` de `pg_cron` cada 10 segundos y reglas de reintento y de archivo de la cola.
- [ ] Notificación `orden_fallida` con el motivo.
- [ ] Pruebas `deno test` de `ejecutor-ordenes` con el broker simulado (sin respuesta, rechazo y 429) y pgTAP de `tomar_orden_para_envio` (concurrencia y revalidación).
- [ ] E2E-08 actualizado: la orden aprobada llega al broker simulado.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-072 · Adaptador del broker para órdenes](HU-072-adaptador-del-broker-para-ordenes.md) | Envía las órdenes con el adaptador del broker. |
| Depende de | [HU-062 · Aprobar una sugerencia de mi cupo](../E-07-sugerencias-y-decisiones/HU-062-aprobar-una-sugerencia-de-mi-cupo.md) | Toma las órdenes que crea la aprobación. |
| Habilita | [HU-039 · Freno de emergencia](../E-05-motor-de-politicas-y-configuracion/HU-039-freno-de-emergencia.md) | HU-039: el ejecutor revalida y deja fallidas las aprobadas. |
| Habilita | [HU-074 · Sincronizar órdenes y aplicar llenados](HU-074-sincronizar-ordenes-y-aplicar-llenados.md) | HU-074: sincroniza las órdenes que envía el ejecutor. |
| Habilita | [HU-075 · Crear una orden manual en mi cupo](HU-075-crear-una-orden-manual-en-mi-cupo.md) | HU-075: la orden manual se envía con el mismo ejecutor. |

## Notas técnicas

Meta del MVP: menos de 5 segundos (p95) entre la aprobación y la orden en el broker (01 §6). `pg_net` dispara y olvida; la cola garantiza que el trabajo siga ahí y el barrido asegura que nada se quede atrás (05 §8). Si la función supera su tiempo máximo, la cola reintenta el trabajo (CB-67).

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
