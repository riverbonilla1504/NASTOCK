# HU-092 · Ver el detalle del fondo

| Campo | Valor |
|---|---|
| Épica | [E-10 · Cartera y reportes](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Analista |
| Prioridad | Alta |
| Módulos afectados | M-15 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-10` · `M-15` · `prioridad-alta` |

## Historia

**Como** Analista,  
**quiero** ver cada subcuenta, cupo, posición, sugerencia, decisión y orden del fondo,  
**para** supervisar el riesgo de todo el fondo.

## Requisitos funcionales

- [FR-200 · Detalle del fondo para supervisión](../requisitos-funcionales/FR-200-detalle-del-fondo-para-supervision.md)
- [FR-199 · Protecciones visibles](../requisitos-funcionales/FR-199-protecciones-visibles.md)

## Reglas

PM-31 · 03 §3 · 03 §4.3

## Criterios de aceptación

- **CA-1** Dado un Analista o un Administrador, cuando abre Fondo, entonces ve el detalle por bolsillo: subcuentas, cupos con su titular, posiciones valoradas con su protección, sugerencias, decisiones y órdenes, en solo lectura.
- **CA-2** Dado un cambio en una posición, una orden o una subcuenta, cuando ocurre, entonces la pantalla se actualiza con los eventos del canal `supervision`.
- **CA-3** (aislamiento) Dado un Usuario, cuando abre Fondo, entonces solo ve el resumen agregado; y si consulta por la API las tablas de otros cupos, no recibe filas.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] App: vista de detalle en `lib/features/fondo/` para Analista y Administrador, con navegación a cada cupo.
- [ ] Revisar que los eventos `subcuenta`, `posicion`, `orden` y `decision` llegan al canal `supervision`.
- [ ] Pruebas de widget por rol y pgTAP de la lectura por rol de las tablas del detalle.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-020 · Ver el resumen del fondo por bolsillos](../E-03-fondo-y-libro-contable/HU-020-ver-el-resumen-del-fondo-por-bolsillos.md) | Extiende la pantalla Fondo. |
| Depende de | [HU-074 · Sincronizar órdenes y aplicar llenados](../E-08-ejecucion-y-broker/HU-074-sincronizar-ordenes-y-aplicar-llenados.md) | Muestra posiciones y órdenes. |
| Depende de | [HU-064 · Bandeja de riesgo del Analista](../E-07-sugerencias-y-decisiones/HU-064-bandeja-de-riesgo-del-analista.md) | Muestra sugerencias y decisiones. |

## Notas técnicas

Los Usuarios ven el fondo solo en agregados, nunca cupos ajenos (D-22).

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
