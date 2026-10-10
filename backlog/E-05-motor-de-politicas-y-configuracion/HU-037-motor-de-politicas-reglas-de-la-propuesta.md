# HU-037 · Motor de políticas: reglas de la propuesta

| Campo | Valor |
|---|---|
| Épica | [E-05 · Motor de políticas y configuración](README.md) |
| Entrega (hito) | R3 · La IA analiza |
| Rol | Analista |
| Prioridad | Alta |
| Módulos afectados | M-08 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-05` · `M-08` · `prioridad-alta` |

## Historia

**Como** Analista,  
**quiero** que toda propuesta de compra o de venta pase por un único motor de reglas de riesgo en la base de datos,  
**para** que ninguna operación que viole un límite llegue a una persona ni al broker.

## Requisitos funcionales

- [FR-085 · Motor de políticas único](../requisitos-funcionales/FR-085-motor-de-politicas-unico.md)
- [FR-086 · Reglas de riesgo de las compras](../requisitos-funcionales/FR-086-reglas-de-riesgo-de-las-compras.md)
- [FR-087 · Reglas de riesgo generales](../requisitos-funcionales/FR-087-reglas-de-riesgo-generales.md)
- [FR-088 · Reglas de horario, precio y salud](../requisitos-funcionales/FR-088-reglas-de-horario-precio-y-salud.md)
- [FR-089 · Confianza mínima de las sugerencias de la IA](../requisitos-funcionales/FR-089-confianza-minima-de-las-sugerencias-de-la-ia.md)
- [FR-090 · Registro de la regla violada](../requisitos-funcionales/FR-090-registro-de-la-regla-violada.md)

## Reglas

RN-38 · RR-01 a RR-09 · RR-11 · RR-14 · RR-17 · RR-18 · RR-21 · RR-22 · 02 §9 · 01 §2 (P3)

## Criterios de aceptación

- **CA-1** Dada una compra de un símbolo que no está en la lista blanca activa del bolsillo, cuando se valida, entonces `validar_operacion` devuelve RR-01.
- **CA-2** Dada una compra que supera el disponible, el máximo por operación o la concentración por símbolo, o cuyo stop-loss falta o está fuera del rango del bolsillo, cuando se valida, entonces devuelve RR-03, RR-04, RR-05 o RR-08 según el caso.
- **CA-3** Dada una operación que usa la Reserva o `usuarios_comun`, que está bajo la orden mínima o cuyo destinatario no está activo, cuando se valida, entonces devuelve RR-02, RR-06 o RR-17.
- **CA-4** Dada una operación con el mercado cerrado o fuera de la ventana de compras, con la cotización más vieja que el máximo, con el interruptor apagado o con el broker o los datos caídos, cuando se valida, entonces devuelve RR-07, RR-11, RR-14 o RR-21.
- **CA-5** Dada una operación que cumple todo, cuando se valida, entonces la lista de reglas violadas llega vacía.
- **CA-6** Dada una función que recibe reglas violadas, cuando responde a la app, entonces usa el código `REGLA_RR_xx` y la app muestra el texto de esa regla.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Migración: `private.validar_operacion(subcuenta, simbolo, lado, monto, cantidad, stop_pct, confianza, momento)`, que devuelve la lista de reglas violadas.
- [ ] Reglas RR-01 a RR-09, RR-11, RR-14, RR-17, RR-18, RR-21 y RR-22 con sus parámetros `riesgo.*`, `mercado.*` y `jev.confianza_minima`.
- [ ] App: mensajes de `REGLA_RR_xx` con el texto de 02 §9.
- [ ] Pruebas pgTAP `politicas_*`: por cada regla, un caso que la viola y uno que la cumple, con el reloj y los precios controlados.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-033 · Parámetros configurables con rango e historial](HU-033-parametros-configurables-con-rango-e-historial.md) | Lee los límites del catálogo de parámetros. |
| Depende de | [HU-034 · Encender y apagar los interruptores del fondo](HU-034-encender-y-apagar-los-interruptores-del-fondo.md) | RR-14 mira los interruptores. |
| Depende de | [HU-035 · Salud de las integraciones](HU-035-salud-de-las-integraciones.md) | RR-21 mira la salud del broker y de los datos. |
| Depende de | [HU-028 · Ingesta de precios cada 15 segundos](../E-04-datos-de-mercado/HU-028-ingesta-de-precios-cada-15-segundos.md) | RR-07 y RR-11 usan el horario y la última cotización. |
| Depende de | [HU-018 · Asignar y reducir cupos](../E-03-fondo-y-libro-contable/HU-018-asignar-y-reducir-cupos.md) | RR-03 a RR-05 usan el disponible y el patrimonio de la subcuenta. |
| Habilita | [HU-038 · Motor de políticas completo en los cuatro momentos](HU-038-motor-de-politicas-completo-en-los-cuatro-momentos.md) | HU-038: completa `private.validar_operacion`. |
| Habilita | [HU-047 · Puntaje compuesto y elección de la mejor opción](../E-06-ia-contexto-y-decision/HU-047-puntaje-compuesto-y-eleccion-de-la-mejor-opcion.md) | HU-047: toda señal pasa por `validar_operacion`. |
| Habilita | [HU-052 · Opinión de la IA sobre una orden manual](../E-06-ia-contexto-y-decision/HU-052-opinion-de-la-ia-sobre-una-orden-manual.md) | HU-052: corre `validar_operacion` antes de opinar. |
| Habilita | [HU-058 · Sugerencia de compra para Arriesgadas](../E-07-sugerencias-y-decisiones/HU-058-sugerencia-de-compra-para-arriesgadas.md) | HU-058: valida la propuesta con el motor de políticas. |
| Habilita | [HU-062 · Aprobar una sugerencia de mi cupo](../E-07-sugerencias-y-decisiones/HU-062-aprobar-una-sugerencia-de-mi-cupo.md) | HU-062: revalida con el motor de políticas al aprobar. |

## Notas técnicas

El motor es uno solo: la IA, la app y el ejecutor lo llaman y ninguno reimplementa reglas (RN-38). Las reglas que dependen de sugerencias, órdenes y posiciones (RR-10, RR-15, RR-16, RR-19 y RR-20) y los cuatro momentos de validación se completan en [HU-038](HU-038-motor-de-politicas-completo-en-los-cuatro-momentos.md). RR-12 (banda) y RR-13 (doble aprobación) se aplican al aprobar y al enviar: [HU-062](../E-07-sugerencias-y-decisiones/HU-062-aprobar-una-sugerencia-de-mi-cupo.md), [HU-065](../E-07-sugerencias-y-decisiones/HU-065-decidir-en-arriesgadas-con-doble-aprobacion.md) y [HU-073](../E-08-ejecucion-y-broker/HU-073-enviar-al-broker-las-ordenes-aprobadas.md). Los límites por defecto están pendientes de validar con RiTech (Q-03).

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
