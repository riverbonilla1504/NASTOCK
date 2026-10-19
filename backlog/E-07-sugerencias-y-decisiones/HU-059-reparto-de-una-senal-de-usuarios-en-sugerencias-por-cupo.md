# HU-059 · Reparto de una señal de Usuarios en sugerencias por cupo

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
**quiero** recibir una sugerencia calculada con el dinero de mi propio cupo cuando la IA propone comprar en el bolsillo de Usuarios,  
**para** decidir sobre una compra que mi cupo sí puede hacer.

## Requisitos funcionales

- [FR-136 · Reparto de la señal de Usuarios en cupos](../requisitos-funcionales/FR-136-reparto-de-la-senal-de-usuarios-en-cupos.md)
- [FR-137 · Tamaño de la orden sugerida](../requisitos-funcionales/FR-137-tamano-de-la-orden-sugerida.md)
- [FR-139 · Vencimiento y precios de la sugerencia](../requisitos-funcionales/FR-139-vencimiento-y-precios-de-la-sugerencia.md)
- [FR-092 · Copia congelada de parámetros](../requisitos-funcionales/FR-092-copia-congelada-de-parametros.md)

## Reglas

07 §7.3 · 07 §7.5 · 02 §6.1 · RR-05 · RR-06 · RR-10 · RR-16 · RR-20 · RN-21 · RN-22 · RN-39

## Criterios de aceptación

- **CA-1** Dadas una señal de compra de Usuarios y varios cupos, cuando se reparte, entonces cada cupo que califica recibe una sugerencia con su propio monto y cantidad, y todas comparten precio de referencia, stop, objetivo, explicación y vencimiento.
- **CA-2** Dado un titular suspendido, de baja o con la recepción en pausa, cuando se reparte, entonces su cupo se omite.
- **CA-3** (caso borde) CB-28: Dado un cupo con una sugerencia u orden viva del mismo símbolo y lado, cuando se reparte, entonces no se crea otra para ese cupo.
- **CA-4** Dado un cupo que superó `sugerencias.max_por_cupo_dia`, que está en enfriamiento por stop en ese símbolo o cuyo monto queda bajo la orden mínima, cuando se reparte, entonces se omite.
- **CA-5** Dado un cupo cuya concentración superaría el límite, cuando se reparte, entonces el monto se reduce al máximo permitido o el cupo se omite.
- **CA-6** Dado que ningún cupo califica, cuando termina el reparto, entonces la señal queda registrada sin sugerencias.

## Casos borde

CB-28

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-08.

## Tareas

- [ ] Migración: rama de Usuarios de `private.crear_sugerencias_desde_senal`: filtros de 07 §7.3 en su orden, monto y cantidad por cupo, y `decide_rol = usuario` con `destinatario_id`.
- [ ] Migración: parámetro `sugerencias.max_por_cupo_dia`.
- [ ] Notificación `sugerencia_nueva` al dueño y evento `sugerencia` en `usuario:{id}`.
- [ ] Pruebas pgTAP `sugerencias_*`: un caso por cada filtro, la reducción por concentración y una señal sin cupos.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-058 · Sugerencia de compra para Arriesgadas](HU-058-sugerencia-de-compra-para-arriesgadas.md) | Usa las tablas de sugerencias y la función de reparto. |
| Depende de | [HU-018 · Asignar y reducir cupos](../E-03-fondo-y-libro-contable/HU-018-asignar-y-reducir-cupos.md) | Calcula cada sugerencia con el disponible del cupo. |
| Habilita | [HU-056 · Evaluación de sugerencias y candidatas tras el cierre](../E-06-ia-contexto-y-decision/HU-056-evaluacion-de-sugerencias-y-candidatas-tras-el-cierre.md) | HU-056: evalúa las sugerencias emitidas. |
| Habilita | [HU-060 · Sugerencias de venta por subcuenta](HU-060-sugerencias-de-venta-por-subcuenta.md) | HU-060: extiende la función de reparto. |
| Habilita | [HU-061 · Mis sugerencias: bandeja y detalle con explicación](HU-061-mis-sugerencias-bandeja-y-detalle-con-explicacion.md) | HU-061: muestra las sugerencias que recibe el cupo. |
| Habilita | [HU-066 · Vencimiento por tiempo y aviso previo](HU-066-vencimiento-por-tiempo-y-aviso-previo.md) | HU-066: vence las sugerencias emitidas. |
| Habilita | [HU-068 · Pausar la recepción de sugerencias](HU-068-pausar-la-recepcion-de-sugerencias.md) | HU-068: el reparto respeta la pausa. |
| Habilita | [HU-088 · Recibir avisos por push](../E-09-tiempo-real-y-notificaciones/HU-088-recibir-avisos-por-push.md) | HU-088: el escenario usa una sugerencia nueva. |

## Notas técnicas

El enfriamiento por stop (RR-20) solo se activa cuando existen ventas por protección ([HU-077](../E-08-ejecucion-y-broker/HU-077-proteccion-nativa-en-compras-de-acciones-enteras.md) y [HU-078](../E-08-ejecucion-y-broker/HU-078-proteccion-virtual-en-compras-fraccionales.md)); el filtro queda listo aquí. La sugerencia muestra exactamente lo que se va a comprar, no el porcentaje (RN-22).

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
