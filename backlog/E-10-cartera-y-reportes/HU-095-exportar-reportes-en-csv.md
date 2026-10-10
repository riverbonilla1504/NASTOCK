# HU-095 · Exportar reportes en CSV

| Campo | Valor |
|---|---|
| Épica | [E-10 · Cartera y reportes](README.md) |
| Entrega (hito) | R6 · Medir y mejorar |
| Rol | Usuario |
| Prioridad | Media |
| Módulos afectados | M-15 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-10` · `M-15` · `prioridad-media` |

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** exportar mis reportes en CSV,  
**para** llevarlos a una hoja de cálculo o entregarlos a contabilidad.

## Requisitos funcionales

- [FR-203 · Exportación CSV](../requisitos-funcionales/FR-203-exportacion-csv.md)
- [FR-204 · Advertencia de paper trading](../requisitos-funcionales/FR-204-advertencia-de-paper-trading.md)

## Reglas

PM-33 · 01 §4 · 10 §2 · Q-15 · RSG-10

## Criterios de aceptación

- **CA-1** Dado un Usuario, cuando exporta, entonces obtiene un CSV con la cartera y el historial de su cupo.
- **CA-2** Dado un Analista o un Administrador, cuando exporta, entonces obtiene los del fondo: cartera, historial de operaciones y desempeño.
- **CA-3** Dado cualquier reporte, cuando se genera, entonces incluye la advertencia de que los resultados en paper trading son más optimistas que con dinero real y no incluyen dividendos ni tarifas.
- **CA-4** (aislamiento) Dado un Usuario, cuando exporta, entonces el archivo no contiene datos de otros cupos.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] App: `lib/features/reportes/` con los reportes de cartera, historial y desempeño sobre el exportador de [HU-117](../E-13-transicion-desde-la-v2/HU-117-exportador-de-reportes-de-la-v2-con-sus-pruebas.md).
- [ ] App: descarga del archivo en web y guardado o compartido en Android.
- [ ] Pruebas unitarias del contenido de cada CSV y de la advertencia.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-093 · Ver el historial de operaciones](HU-093-ver-el-historial-de-operaciones.md) | Exporta el historial. |
| Depende de | [HU-094 · Ver el rendimiento y compararlo con el NASDAQ-100](HU-094-ver-el-rendimiento-y-compararlo-con-el-nasdaq-100.md) | Exporta el desempeño. |
| Depende de | [HU-117 · Exportador de reportes de la v2 con sus pruebas](../E-13-transicion-desde-la-v2/HU-117-exportador-de-reportes-de-la-v2-con-sus-pruebas.md) | Usa el exportador copiado de la v2. |

## Notas técnicas

Sin notas adicionales.

## Documentación a actualizar

Q-15 sigue abierta: qué reportes necesita contabilidad, con qué formato y con qué periodicidad. `docs/` no lista las columnas de cada CSV. Cerrarlo antes de implementar.

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
