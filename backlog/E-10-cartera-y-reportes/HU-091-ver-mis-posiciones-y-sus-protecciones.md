# HU-091 · Ver mis posiciones y sus protecciones

| Campo | Valor |
|---|---|
| Épica | [E-10 · Cartera y reportes](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-15, M-11 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-10` · `M-15` · `M-11` · `prioridad-alta` |

## Historia

**Como** Usuario,  
**quiero** ver las posiciones de mi cupo con su valor, su resultado y su protección,  
**para** saber cómo va cada inversión y a qué precio se vendería sola.

## Requisitos funcionales

- [FR-198 · Posiciones valoradas de mi cupo](../requisitos-funcionales/FR-198-posiciones-valoradas-de-mi-cupo.md)
- [FR-199 · Protecciones visibles](../requisitos-funcionales/FR-199-protecciones-visibles.md)

## Reglas

PM-10 · RN-06 · 02 §13 · 06 §6 · 08 §3 · 09 §1

## Criterios de aceptación

- **CA-1** Dado un Usuario con una posición, cuando abre Mi cupo, entonces ve la cantidad, el costo promedio, el último precio, el valor, la ganancia no realizada y la antigüedad del precio.
- **CA-2** Dado un precio nuevo, cuando llega, entonces el valor y la ganancia no realizada de la posición cambian en pantalla.
- **CA-3** Dada la posición, cuando se muestra, entonces trae su protección: tipo (nativa o virtual), stop y objetivo en precio y estado.
- **CA-4** (aislamiento) Dado un Usuario, cuando consulta `posiciones_valoradas` o `protecciones`, entonces solo ve las de su cupo.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-08.

## Tareas

- [ ] App: lista de posiciones en `lib/features/cupo/` con `posicionesValoradasProvider` (posiciones por cotizaciones).
- [ ] App: tarjeta de la protección de cada posición.
- [ ] RPC `mi_cupo()`: resultado realizado y no realizado con las posiciones.
- [ ] Pruebas pgTAP de la lectura por rol de `posiciones` y `protecciones`, y pruebas de widget.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-074 · Sincronizar órdenes y aplicar llenados](../E-08-ejecucion-y-broker/HU-074-sincronizar-ordenes-y-aplicar-llenados.md) | Muestra las posiciones que crean los llenados. |
| Depende de | [HU-077 · Protección nativa en compras de acciones enteras](../E-08-ejecucion-y-broker/HU-077-proteccion-nativa-en-compras-de-acciones-enteras.md) | Muestra la protección de cada posición. |
| Depende de | [HU-019 · Ver mi cupo](../E-03-fondo-y-libro-contable/HU-019-ver-mi-cupo.md) | Extiende la pantalla Mi cupo. |
| Habilita | [HU-094 · Ver el rendimiento y compararlo con el NASDAQ-100](HU-094-ver-el-rendimiento-y-compararlo-con-el-nasdaq-100.md) | HU-094: extiende la pantalla Mi cupo con posiciones. |

## Notas técnicas

La ganancia no realizada no es contable: se calcula al vuelo con el último precio (RN-06).

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
