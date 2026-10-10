# HU-058 · Sugerencia de compra para Arriesgadas

| Campo | Valor |
|---|---|
| Épica | [E-07 · Sugerencias y decisiones](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Analista |
| Prioridad | Alta |
| Módulos afectados | M-09 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-07` · `M-09` · `prioridad-alta` |

## Historia

**Como** Analista,  
**quiero** que cada señal de compra de Arriesgadas me llegue como una sugerencia concreta, con monto, cantidad, protección y vencimiento,  
**para** decidir sobre algo exacto y no sobre un porcentaje.

## Requisitos funcionales

- [FR-134 · Sugerencia de compra en Arriesgadas](../requisitos-funcionales/FR-134-sugerencia-de-compra-en-arriesgadas.md)
- [FR-135 · Marca de doble aprobación](../requisitos-funcionales/FR-135-marca-de-doble-aprobacion.md)
- [FR-137 · Tamaño de la orden sugerida](../requisitos-funcionales/FR-137-tamano-de-la-orden-sugerida.md)
- [FR-139 · Vencimiento y precios de la sugerencia](../requisitos-funcionales/FR-139-vencimiento-y-precios-de-la-sugerencia.md)
- [FR-092 · Copia congelada de parámetros](../requisitos-funcionales/FR-092-copia-congelada-de-parametros.md)

## Reglas

07 §7.2 · 07 §7.5 · 02 §6.1 · RR-04 · RR-13 · RN-21 · RN-39 · D-05

## Criterios de aceptación

- **CA-1** Dada una señal de compra de Arriesgadas, cuando se convierte, entonces se crea una sugerencia con `decide_rol = analista`, el monto recortado al máximo por operación, la cantidad, el precio de referencia, el stop y el objetivo en precio, el vencimiento y una copia de los parámetros.
- **CA-2** Dados un monto mayor o igual a `aprobacion.umbral_doble_usd` y 2 o más Analistas activos, cuando se crea, entonces `requiere_doble` es verdadero.
- **CA-3** (caso borde) CB-25: Dado un solo Analista activo, cuando el monto alcanza el umbral, entonces se recorta justo por debajo del umbral y no requiere doble aprobación.
- **CA-4** Dado un monto que alcanza para una o más acciones, cuando se calcula la cantidad, entonces son acciones enteras y el sobrante queda en efectivo; si no alcanza y el activo es fraccionable, es una fracción; en otro caso no se crea la sugerencia.
- **CA-5** Dada la sugerencia creada, cuando nace, entonces todos los Analistas activos reciben `sugerencia_nueva` y el evento `sugerencia` llega al canal `supervision`.

## Casos borde

CB-25

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-09.

## Tareas

- [ ] Migración: tipos `tipo_sugerencia`, `origen_sugerencia`, `estado_sugerencia`, `tipo_decision`, `motivo_rechazo`, `nivel_riesgo`, `horizonte` y `lado` (si aún no existe), y tablas `sugerencias` y `decisiones` (06 §5.4) con RLS: las propias y, para los supervisores, todas.
- [ ] Migración: `private.crear_sugerencias_desde_senal(senal_id)` en su rama de Arriesgadas: recorte por RR-04, regla de doble aprobación, tamaño de 02 §6.1, vencimiento y precios de 07 §7.5 y copia de parámetros.
- [ ] Migración: parámetros `aprobacion.umbral_doble_usd`, `sugerencias.minutos_vencimiento` y `sugerencias.banda_precio_pct`.
- [ ] Función `agente`: llama `crear_sugerencias_desde_senal` después de `crear_senal`.
- [ ] Notificación `sugerencia_nueva` a los Analistas y evento en `supervision`.
- [ ] Pruebas pgTAP `sugerencias_*`: recorte, doble aprobación, un solo Analista, acciones enteras y fracción.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-047 · Puntaje compuesto y elección de la mejor opción](../E-06-ia-contexto-y-decision/HU-047-puntaje-compuesto-y-eleccion-de-la-mejor-opcion.md) | Convierte las señales del ciclo. |
| Depende de | [HU-037 · Motor de políticas: reglas de la propuesta](../E-05-motor-de-politicas-y-configuracion/HU-037-motor-de-politicas-reglas-de-la-propuesta.md) | Valida la propuesta con el motor de políticas. |
| Depende de | [HU-086 · Bandeja de notificaciones](../E-09-tiempo-real-y-notificaciones/HU-086-bandeja-de-notificaciones.md) | Avisa a los Analistas con `sugerencia_nueva`. |
| Habilita | [HU-024 · Propuesta de rebalanceo tras el cierre](../E-03-fondo-y-libro-contable/HU-024-propuesta-de-rebalanceo-tras-el-cierre.md) | HU-024: la propuesta se guarda en la tabla `sugerencias`. |
| Habilita | [HU-059 · Reparto de una señal de Usuarios en sugerencias por cupo](HU-059-reparto-de-una-senal-de-usuarios-en-sugerencias-por-cupo.md) | HU-059: usa las tablas de sugerencias y la función de reparto. |
| Habilita | [HU-064 · Bandeja de riesgo del Analista](HU-064-bandeja-de-riesgo-del-analista.md) | HU-064: muestra las sugerencias de Arriesgadas. |

## Notas técnicas

Aquí nacen las tablas `sugerencias` y `decisiones`, que usan las demás historias de la épica. El umbral de doble aprobación está pendiente de validar (Q-02).

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
