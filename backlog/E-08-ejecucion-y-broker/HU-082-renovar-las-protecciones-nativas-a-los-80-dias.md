# HU-082 · Renovar las protecciones nativas a los 80 días

| Campo | Valor |
|---|---|
| Épica | [E-08 · Ejecución y broker](README.md) |
| Entrega (hito) | R6 · Medir y mejorar |
| Rol | Usuario |
| Prioridad | Baja |
| Módulos afectados | M-11 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-08` · `M-11` · `prioridad-baja` |

## Historia

**Como** Usuario,  
**quiero** que la protección de una posición que mantengo por meses se renueve sola,  
**para** que no desaparezca cuando el broker cancela las órdenes de 90 días.

## Requisitos funcionales

- [FR-185 · Renovación de protecciones nativas](../requisitos-funcionales/FR-185-renovacion-de-protecciones-nativas.md)

## Reglas

10 §5 · 05 §6

## Criterios de aceptación

- **CA-1** Dadas unas patas de protección nativa con 80 días, cuando corre `cierre-diario`, entonces se cancelan y se crean de nuevo con los mismos precios.
- **CA-2** Dada la renovación, cuando termina, entonces la protección sigue `activa` con los ids nuevos de sus patas.
- **CA-3** Dadas unas patas con menos de 80 días, cuando corre `cierre-diario`, entonces no se tocan.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Función `cierre-diario`: renovación de las patas `gtc` que cumplen 80 días.
- [ ] Pruebas `deno test` con el reloj adelantado y el broker simulado.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-077 · Protección nativa en compras de acciones enteras](HU-077-proteccion-nativa-en-compras-de-acciones-enteras.md) | Renueva las patas de la protección nativa. |

## Notas técnicas

Alpaca cancela las órdenes `gtc` a los 90 días (10 §5).

## Documentación a actualizar

10 §5 no dice qué pasa si falla la recreación de las patas después de cancelarlas (la posición quedaría sin protección). Precisarlo en `docs/`.

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
