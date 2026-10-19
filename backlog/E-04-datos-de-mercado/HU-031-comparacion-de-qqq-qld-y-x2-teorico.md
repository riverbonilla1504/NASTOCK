# HU-031 · Comparación de QQQ, QLD y ×2 teórico

| Campo | Valor |
|---|---|
| Épica | [E-04 · Datos de mercado](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Rol | Usuario |
| Prioridad | Media |
| Módulos afectados | M-05 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-04` · `M-05` · `prioridad-media` |

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** comparar en una gráfica QQQ, QLD real y la línea ×2 teórico,  
**para** entender por qué QLD no siempre rinde el doble del índice en un periodo.

## Requisitos funcionales

- [FR-073 · Comparación QQQ, QLD y ×2 teórico](../requisitos-funcionales/FR-073-comparacion-qqq-qld-y-x2-teorico.md)
- [FR-074 · Advertencia sobre el ETF apalancado](../requisitos-funcionales/FR-074-advertencia-sobre-el-etf-apalancado.md)

## Reglas

PM-04 · 02 §1 · 02 §13 · RSG-08

## Criterios de aceptación

- **CA-1** Dada la pantalla de mercado, cuando la persona abre la comparación, entonces ve tres líneas: QQQ, QLD real y ×2 teórico.
- **CA-2** Dado un periodo elegido, cuando se dibuja ×2 teórico, entonces vale dos veces la variación acumulada de QQQ desde el inicio de ese periodo, calculada con barras diarias.
- **CA-3** Dada la comparación, cuando se muestra, entonces incluye la advertencia de que QLD duplica el movimiento de cada día y no el del periodo.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] App: gráfica de tres series en `lib/features/mercado/` con las barras diarias de QQQ y de QLD.
- [ ] App: serie ×2 teórico calculada con el motor de [HU-115](../E-13-transicion-desde-la-v2/HU-115-motor-x2-teorico-de-la-v2-con-sus-pruebas.md).
- [ ] App: texto de la advertencia de 02 §1.
- [ ] Pruebas de widget de la gráfica y de la advertencia.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-030 · Pantalla de mercado en vivo](HU-030-pantalla-de-mercado-en-vivo.md) | La comparación es parte de la pantalla de mercado. |
| Depende de | [HU-029 · Barra diaria tras el cierre y retención de barras de minuto](HU-029-barra-diaria-tras-el-cierre-y-retencion-de-barras-de-minuto.md) | Usa las barras diarias de QQQ y de QLD. |
| Depende de | [HU-115 · Motor ×2 teórico de la v2 con sus pruebas](../E-13-transicion-desde-la-v2/HU-115-motor-x2-teorico-de-la-v2-con-sus-pruebas.md) | Usa el motor ×2 copiado de la v2. |
| Habilita | [HU-094 · Ver el rendimiento y compararlo con el NASDAQ-100](../E-10-cartera-y-reportes/HU-094-ver-el-rendimiento-y-compararlo-con-el-nasdaq-100.md) | HU-094: reutiliza la comparación con QQQ y ×2 teórico. |

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
