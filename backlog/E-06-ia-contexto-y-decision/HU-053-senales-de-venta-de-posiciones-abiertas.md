# HU-053 · Señales de venta de posiciones abiertas

| Campo | Valor |
|---|---|
| Épica | [E-06 · IA: contexto y decisión](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Analista |
| Prioridad | Alta |
| Módulos afectados | M-07 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-06` · `M-07` · `prioridad-alta` |

## Historia

**Como** Analista,  
**quiero** que la IA evalúe en cada ciclo las posiciones abiertas y proponga vender cuando conviene salir,  
**para** que las salidas se decidan con el mismo criterio que las entradas.

## Requisitos funcionales

- [FR-127 · Señales de venta](../requisitos-funcionales/FR-127-senales-de-venta.md)

## Reglas

07 §6.1 · 07 §6.3 · 07 §7.4

## Criterios de aceptación

- **CA-1** Dada una posición abierta, cuando corre el ciclo, entonces la llamada a JEV de ese símbolo agrega `exit_timing` y `thesis_broken`.
- **CA-2** Dado `exit_timing = sell_now` con confianza mayor o igual a `jev.confianza_venta`, cuando se decide, entonces se crea una señal de venta del 100 %; con `reduce`, del 50 %.
- **CA-3** Dado `thesis_broken` mayor o igual a 0,7, cuando se decide, entonces se crea una señal de venta del 100 %.
- **CA-4** Dado `exit_timing = hold` o una confianza menor que la mínima, cuando se decide, entonces no se crea señal y la evaluación queda registrada.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Función `agente`: preguntas `exit_timing` y `thesis_broken` para los símbolos con posición abierta, y reglas de venta en `_shared/decision.ts`.
- [ ] Migración: parámetro `jev.confianza_venta`.
- [ ] Evaluaciones de tipo `salida` en `evaluaciones_candidatos`.
- [ ] Pruebas `deno test` de las reglas de venta.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-047 · Puntaje compuesto y elección de la mejor opción](HU-047-puntaje-compuesto-y-eleccion-de-la-mejor-opcion.md) | Extiende las reglas de decisión del ciclo. |
| Depende de | [HU-074 · Sincronizar órdenes y aplicar llenados](../E-08-ejecucion-y-broker/HU-074-sincronizar-ordenes-y-aplicar-llenados.md) | Evalúa las posiciones abiertas. |
| Habilita | [HU-060 · Sugerencias de venta por subcuenta](../E-07-sugerencias-y-decisiones/HU-060-sugerencias-de-venta-por-subcuenta.md) | HU-060: convierte las señales de venta del ciclo. |

## Notas técnicas

La señal se reparte en sugerencias por subcuenta en [HU-060](../E-07-sugerencias-y-decisiones/HU-060-sugerencias-de-venta-por-subcuenta.md).

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
