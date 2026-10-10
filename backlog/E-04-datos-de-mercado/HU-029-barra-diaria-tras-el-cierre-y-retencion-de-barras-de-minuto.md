# HU-029 · Barra diaria tras el cierre y retención de barras de minuto

| Campo | Valor |
|---|---|
| Épica | [E-04 · Datos de mercado](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Rol | Analista |
| Prioridad | Media |
| Módulos afectados | M-05 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-04` · `M-05` · `prioridad-media` |

## Historia

**Como** Analista,  
**quiero** que el sistema guarde la barra diaria de cada símbolo al cierre y conserve las de minuto solo lo necesario,  
**para** que las gráficas y las métricas de la IA tengan historia sin llenar la base de datos.

## Requisitos funcionales

- [FR-070 · Barras diarias y de minuto](../requisitos-funcionales/FR-070-barras-diarias-y-de-minuto.md)

## Reglas

06 §5.2 · 06 §10 · 10 §12 · 05 §6 · 05 §7

## Criterios de aceptación

- **CA-1** Dado que el mercado cerró hoy, cuando corre `cierre-diario`, entonces cada símbolo del universo tiene su barra de hoy en `barras_diarias`.
- **CA-2** Dado que `cierre-diario` ya corrió hoy, cuando el trabajo programado vuelve a preguntar, entonces no corre otra vez.
- **CA-3** Dadas barras de minuto con más de 5 días, cuando corre la limpieza, entonces se borran; y solo se guardan las de los ETFs y las de los símbolos con posiciones.
- **CA-4** Dado un día sin sesión de mercado, cuando el trabajo programado pregunta, entonces `cierre-diario` no corre.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Función `cierre-diario` (primera versión): agrega la barra diaria de cada símbolo.
- [ ] Migración: trabajo `cierre_diario` de `pg_cron` cada 10 minutos, condicionado a que el mercado ya cerró hoy y no se ha corrido.
- [ ] Migración: trabajo `limpieza` diario (08:00 UTC) con la retención de `barras_minuto`.
- [ ] Pruebas `deno test` de `cierre-diario` y pgTAP de la condición del trabajo con el reloj fijado.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-026 · Universo del NASDAQ-100 y carga histórica de barras](HU-026-universo-del-nasdaq-100-y-carga-historica-de-barras.md) | Guarda las barras de los símbolos del universo. |
| Depende de | [HU-027 · Calendario, reloj y estado del mercado](HU-027-calendario-reloj-y-estado-del-mercado.md) | Sabe si el mercado ya cerró por el calendario. |
| Habilita | [HU-021 · Foto diaria de patrimonio y rendimiento TWR](../E-03-fondo-y-libro-contable/HU-021-foto-diaria-de-patrimonio-y-rendimiento-twr.md) | HU-021: reutiliza la función `cierre-diario` y su trabajo programado. |
| Habilita | [HU-031 · Comparación de QQQ, QLD y ×2 teórico](HU-031-comparacion-de-qqq-qld-y-x2-teorico.md) | HU-031: usa las barras diarias de QQQ y de QLD. |
| Habilita | [HU-044 · Calidad de datos, métricas y puntaje cuantitativo](../E-06-ia-contexto-y-decision/HU-044-calidad-de-datos-metricas-y-puntaje-cuantitativo.md) | HU-044: usa las barras diarias del universo. |
| Habilita | [HU-056 · Evaluación de sugerencias y candidatas tras el cierre](../E-06-ia-contexto-y-decision/HU-056-evaluacion-de-sugerencias-y-candidatas-tras-el-cierre.md) | HU-056: usa las barras diarias y la función `cierre-diario`. |
| Habilita | [HU-112 · Retención de datos y vigilancia del tamaño de la base](../E-12-seguridad-auditoria-y-cumplimiento/HU-112-retencion-de-datos-y-vigilancia-del-tamano-de-la-base.md) | HU-112: extiende el trabajo `limpieza`. |

## Notas técnicas

`cierre-diario` crece con otras historias: fotos de patrimonio ([HU-021](../E-03-fondo-y-libro-contable/HU-021-foto-diaria-de-patrimonio-y-rendimiento-twr.md)), rebalanceo ([HU-024](../E-03-fondo-y-libro-contable/HU-024-propuesta-de-rebalanceo-tras-el-cierre.md)), evaluación de la IA ([HU-056](../E-06-ia-contexto-y-decision/HU-056-evaluacion-de-sugerencias-y-candidatas-tras-el-cierre.md)) y renovación de protecciones ([HU-082](../E-08-ejecucion-y-broker/HU-082-renovar-las-protecciones-nativas-a-los-80-dias.md)). El resto de la retención de 06 §10 está en [HU-112](../E-12-seguridad-auditoria-y-cumplimiento/HU-112-retencion-de-datos-y-vigilancia-del-tamano-de-la-base.md).

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
