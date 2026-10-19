# HU-060 · Sugerencias de venta por subcuenta

| Campo | Valor |
|---|---|
| Épica | [E-07 · Sugerencias y decisiones](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Usuario |
| Prioridad | Media |
| Módulos afectados | M-09 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-07` · `M-09` · `prioridad-media` |

## Historia

**Como** Usuario,  
**quiero** recibir una sugerencia de venta cuando la IA propone salir de una acción que tengo,  
**para** decidir si vendo mi posición.

## Requisitos funcionales

- [FR-138 · Sugerencias de venta](../requisitos-funcionales/FR-138-sugerencias-de-venta.md)

## Reglas

07 §7.4 · 07 §7.5 · RR-06 · RR-15

## Criterios de aceptación

- **CA-1** Dada una señal de venta de un símbolo en un bolsillo, cuando se reparte, entonces cada subcuenta con posición abierta en ese símbolo y sin otra venta viva recibe una sugerencia: en un cupo la decide su dueño y en Arriesgadas un Analista.
- **CA-2** Dado un porcentaje de 50 %, cuando se calcula, entonces la cantidad es la mitad de la posición.
- **CA-3** (caso borde) CB-48: Dada una venta parcial que dejaría un residuo menor a la orden mínima, cuando se calcula, entonces se vende toda la posición.
- **CA-4** Dada una sugerencia de venta, cuando nace, entonces vence al cierre o a los `sugerencias.minutos_vencimiento` minutos, lo que ocurra primero.

## Casos borde

CB-48

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Migración: rama de ventas de `private.crear_sugerencias_desde_senal`: posición, cantidad, residuo y `decide_rol` según el tipo de subcuenta.
- [ ] Pruebas pgTAP: reparto por subcuenta, venta parcial, residuo y venta viva existente.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-053 · Señales de venta de posiciones abiertas](../E-06-ia-contexto-y-decision/HU-053-senales-de-venta-de-posiciones-abiertas.md) | Convierte las señales de venta del ciclo. |
| Depende de | [HU-059 · Reparto de una señal de Usuarios en sugerencias por cupo](HU-059-reparto-de-una-senal-de-usuarios-en-sugerencias-por-cupo.md) | Extiende la función de reparto. |

## Notas técnicas

Sin notas adicionales.

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
