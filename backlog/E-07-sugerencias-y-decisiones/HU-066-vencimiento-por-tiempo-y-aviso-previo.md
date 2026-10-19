# HU-066 · Vencimiento por tiempo y aviso previo

| Campo | Valor |
|---|---|
| Épica | [E-07 · Sugerencias y decisiones](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-09 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-07` · `M-09` · `prioridad-alta` |

## Historia

**Como** Usuario,  
**quiero** que mis sugerencias venzan solas y que me avisen antes,  
**para** no aprobar nunca algo que se analizó hace demasiado tiempo.

## Requisitos funcionales

- [FR-150 · Vencimiento por tiempo](../requisitos-funcionales/FR-150-vencimiento-por-tiempo.md)
- [FR-151 · Aviso de sugerencia por vencer](../requisitos-funcionales/FR-151-aviso-de-sugerencia-por-vencer.md)

## Reglas

08 §1 · 07 §7.5 · 05 §7 · 09 §5.1 · RN-43 · D-11

## Criterios de aceptación

- **CA-1** Dada una sugerencia viva cuyo `vence_en` ya pasó, cuando corre `vencer_sugerencias()`, entonces pasa a vencida y quien debía decidir recibe `sugerencia_vencida`.
- **CA-2** Dada una sugerencia a `sugerencias.aviso_previo_min` minutos de vencer, cuando corre el trabajo, entonces quien debe decidir recibe `sugerencia_por_vencer` una sola vez.
- **CA-3** (caso borde) CB-56: Dado el cierre del mercado, cuando llega, entonces todas las sugerencias vivas del día vencen: al abrir el día siguiente no queda ninguna.
- **CA-4** Dada una sugerencia con doble aprobación a la que le falta la segunda, cuando vence, entonces queda vencida y no se retiene nada.

## Casos borde

CB-56

## Escenario E2E

E2E-10 (nuevo)

## Tareas

- [ ] Migración: `private.vencer_sugerencias()` con el vencimiento por `private.ahora()` y el aviso previo, y trabajo `expirar_sugerencias` de `pg_cron` cada 30 segundos.
- [ ] Migración: parámetro `sugerencias.aviso_previo_min`.
- [ ] Notificaciones `sugerencia_por_vencer` y `sugerencia_vencida`.
- [ ] Pruebas pgTAP con el reloj adelantado: vencimiento, aviso único y cierre del mercado.
- [ ] E2E-10: vencimiento por tiempo con el reloj adelantado.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-059 · Reparto de una señal de Usuarios en sugerencias por cupo](HU-059-reparto-de-una-senal-de-usuarios-en-sugerencias-por-cupo.md) | Vence las sugerencias emitidas. |
| Depende de | [HU-086 · Bandeja de notificaciones](../E-09-tiempo-real-y-notificaciones/HU-086-bandeja-de-notificaciones.md) | Avisa que la sugerencia está por vencer o venció. |
| Depende de | [TT-06 · Arnés E2E de backend y de la app](../E-01-cimientos-y-calidad-continua/TT-06-arnes-e2e-de-backend-y-de-la-app.md) | Agrega el escenario E2E-10. |
| Habilita | [HU-067 · Invalidación por precio y por cambio de situación](HU-067-invalidacion-por-precio-y-por-cambio-de-situacion.md) | HU-067: extiende el escenario E2E-10. |

## Notas técnicas

El push del aviso previo sale desde R5 ([HU-088](../E-09-tiempo-real-y-notificaciones/HU-088-recibir-avisos-por-push.md)). Si los empleados no responden a tiempo, se ajusta `sugerencias.minutos_vencimiento` (RSG-12).

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
