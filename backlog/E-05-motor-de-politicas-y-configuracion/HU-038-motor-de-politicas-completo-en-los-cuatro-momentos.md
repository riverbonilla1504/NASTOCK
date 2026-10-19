# HU-038 · Motor de políticas completo en los cuatro momentos

| Campo | Valor |
|---|---|
| Épica | [E-05 · Motor de políticas y configuración](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Analista |
| Prioridad | Alta |
| Módulos afectados | M-08 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-05` · `M-08` · `prioridad-alta` |

## Historia

**Como** Analista,  
**quiero** que todas las reglas de riesgo se evalúen al proponer, al aprobar, antes de enviar y al dispararse una protección,  
**para** que una operación válida al nacer no se ejecute si dejó de serlo.

## Requisitos funcionales

- [FR-091 · Reglas que dependen de lo ya operado](../requisitos-funcionales/FR-091-reglas-que-dependen-de-lo-ya-operado.md)
- [FR-092 · Copia congelada de parámetros](../requisitos-funcionales/FR-092-copia-congelada-de-parametros.md)
- [FR-085 · Motor de políticas único](../requisitos-funcionales/FR-085-motor-de-politicas-unico.md)

## Reglas

RN-38 · RN-39 · RR-10 · RR-15 · RR-16 · RR-19 · RR-20 · 02 §9

## Criterios de aceptación

- **CA-1** Dada una sugerencia u orden viva de una subcuenta, símbolo y lado, cuando se propone otra igual, entonces devuelve RR-10.
- **CA-2** Dada una venta por más cantidad de la que tiene la posición, cuando se valida, entonces devuelve RR-15.
- **CA-3** Dado un cupo que ya recibió hoy `sugerencias.max_por_cupo_dia` sugerencias, cuando se valida otra, entonces devuelve RR-16.
- **CA-4** Dado que Arriesgadas perdió hoy más de `riesgo.arriesgadas.perdida_diaria_max_pct` de su patrimonio, cuando se valida una compra, entonces devuelve RR-19 hasta el día siguiente.
- **CA-5** Dada una venta por stop-loss de un símbolo en una subcuenta, cuando se intenta recomprarlo antes de `riesgo.enfriamiento_horas` horas, entonces devuelve RR-20.
- **CA-6** (caso borde) CB-73 y CB-74: Dado un cambio de la banda, del vencimiento o del umbral de doble aprobación con sugerencias vivas, cuando se decide una de ellas, entonces conserva sus parámetros congelados y su `requiere_doble` original.
- **CA-7** Dada una venta por una protección disparada, cuando se valida, entonces no la frenan el interruptor apagado ni el titular suspendido.

## Casos borde

CB-73, CB-74

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Migración: reglas RR-10, RR-15, RR-16, RR-19 y RR-20 en `private.validar_operacion`.
- [ ] Excepciones de 02 §9 para protecciones y liquidaciones (RR-14, RR-17 y RR-21).
- [ ] Revisar que existen las cuatro llamadas: al crear la propuesta, al aprobar, en `private.tomar_orden_para_envio` y en `private.disparar_proteccion_virtual`.
- [ ] Pruebas pgTAP `politicas_*`: cada regla, las excepciones y los parámetros congelados (RN-39).
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-037 · Motor de políticas: reglas de la propuesta](HU-037-motor-de-politicas-reglas-de-la-propuesta.md) | Completa `private.validar_operacion`. |
| Depende de | [HU-062 · Aprobar una sugerencia de mi cupo](../E-07-sugerencias-y-decisiones/HU-062-aprobar-una-sugerencia-de-mi-cupo.md) | RR-10 y RR-16 miran sugerencias y órdenes. |
| Depende de | [HU-077 · Protección nativa en compras de acciones enteras](../E-08-ejecucion-y-broker/HU-077-proteccion-nativa-en-compras-de-acciones-enteras.md) | RR-15 y RR-20 miran posiciones y ventas por stop. |
| Depende de | [HU-078 · Protección virtual en compras fraccionales](../E-08-ejecucion-y-broker/HU-078-proteccion-virtual-en-compras-fraccionales.md) | Valida al dispararse una protección virtual. |

## Notas técnicas

Con esta historia quedan activas RR-01 a RR-22: es el "motor completo" que 14 §4 ubica en R4.

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
