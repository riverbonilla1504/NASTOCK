# HU-021 · Foto diaria de patrimonio y rendimiento TWR

| Campo | Valor |
|---|---|
| Épica | [E-03 · Fondo y libro contable](README.md) |
| Entrega (hito) | R2 · El fondo existe |
| Rol | Administrador |
| Prioridad | Media |
| Módulos afectados | M-15 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-03` · `M-15` · `prioridad-media` |

## Historia

**Como** Administrador,  
**quiero** que el sistema guarde cada día el patrimonio de cada subcuenta y calcule el rendimiento ponderado en el tiempo,  
**para** que los reportes oficiales no dependan de precios en vivo ni se distorsionen con aportes y repartos.

## Requisitos funcionales

- [FR-054 · Foto diaria de patrimonio](../requisitos-funcionales/FR-054-foto-diaria-de-patrimonio.md)
- [FR-055 · Rendimiento ponderado en el tiempo](../requisitos-funcionales/FR-055-rendimiento-ponderado-en-el-tiempo.md)

## Reglas

RN-44 · RN-45 · 02 §13 · 06 §5.6

## Criterios de aceptación

- **CA-1** Dado el cierre del mercado, cuando corre `cierre-diario`, entonces `patrimonio_diario` tiene una fila por subcuenta con efectivo, valor de posiciones, patrimonio, flujos netos y rendimiento del día.
- **CA-2** Dado un día con una asignación de 400 a un cupo, cuando se calcula el rendimiento de ese cupo, entonces la asignación cuenta como flujo y no como ganancia.
- **CA-3** Dado que `cierre-diario` corre dos veces el mismo día, cuando termina, entonces no duplica la foto.
- **CA-4** (aislamiento) Dado un Usuario, cuando consulta `patrimonio_diario`, entonces ve las filas de su cupo y los agregados; un Analista o un Administrador ven todo.
- **CA-5** Dadas las fotos diarias de un periodo, cuando se calcula el rendimiento del fondo, de un bolsillo o de un cupo, entonces es el producto de (1 + rendimiento de cada día) menos 1.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Migración: tabla `patrimonio_diario` (06 §5.6) con RLS según 03 §4.3 y `private.tomar_foto_patrimonio(fecha)`.
- [ ] Función `cierre-diario`: llama `tomar_foto_patrimonio` tras el cierre.
- [ ] Cálculo del TWR (`r_día = (P_fin − P_ini − flujos) / P_ini`; `TWR = Π(1 + r_día) − 1`) disponible para `mi_cupo()` y para los reportes.
- [ ] Pruebas pgTAP: foto con flujos, idempotencia y lectura por rol.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-013 · Libro contable de doble partida](HU-013-libro-contable-de-doble-partida.md) | La foto se toma de los saldos del libro. |
| Depende de | [HU-029 · Barra diaria tras el cierre y retención de barras de minuto](../E-04-datos-de-mercado/HU-029-barra-diaria-tras-el-cierre-y-retencion-de-barras-de-minuto.md) | Reutiliza la función `cierre-diario` y su trabajo programado. |
| Habilita | [HU-024 · Propuesta de rebalanceo tras el cierre](HU-024-propuesta-de-rebalanceo-tras-el-cierre.md) | HU-024: usa el patrimonio por bolsillo tras el cierre. |
| Habilita | [HU-094 · Ver el rendimiento y compararlo con el NASDAQ-100](../E-10-cartera-y-reportes/HU-094-ver-el-rendimiento-y-compararlo-con-el-nasdaq-100.md) | HU-094: usa las fotos diarias y el TWR. |
| Habilita | [HU-096 · Reporte diario al Administrador](../E-10-cartera-y-reportes/HU-096-reporte-diario-al-administrador.md) | HU-096: se genera en el cierre diario. |

## Notas técnicas

Los flujos son aportes, retiros, asignaciones, repartos y rebalanceos (02 §13). Los valores en vivo son indicativos; los reportes oficiales usan la foto diaria (RN-45).

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
