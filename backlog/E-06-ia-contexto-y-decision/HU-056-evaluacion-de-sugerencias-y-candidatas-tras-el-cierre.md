# HU-056 · Evaluación de sugerencias y candidatas tras el cierre

| Campo | Valor |
|---|---|
| Épica | [E-06 · IA: contexto y decisión](README.md) |
| Entrega (hito) | R6 · Medir y mejorar |
| Rol | Analista |
| Prioridad | Alta |
| Módulos afectados | M-07 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-06` · `M-07` · `prioridad-alta` |

## Historia

**Como** Analista,  
**quiero** que el sistema mida después lo que habría pasado con cada sugerencia, aprobada o no,  
**para** saber con datos si la IA acierta.

## Requisitos funcionales

- [FR-132 · Evaluación de sugerencias y candidatas](../requisitos-funcionales/FR-132-evaluacion-de-sugerencias-y-candidatas.md)

## Reglas

07 §11 · 06 §5.3 · RSG-01

## Criterios de aceptación

- **CA-1** Dada una sugerencia con horizonte de días, cuando pasan 5 sesiones, entonces `cierre-diario` calcula su rendimiento hipotético: si se tocó primero el stop o el objetivo y, si ninguno, el precio al horizonte.
- **CA-2** Dada una sugerencia con horizonte de semanas, cuando pasan 20 sesiones, entonces se evalúa de la misma forma.
- **CA-3** Dada una sugerencia ejecutada, cuando se evalúa, entonces guarda además su rendimiento real tomado del libro.
- **CA-4** Dada una sugerencia rechazada, vencida o invalidada, cuando se cumple su horizonte, entonces también se evalúa.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Migración: tabla `evaluaciones_ia` (06 §5.3) con RLS para Analista y Administrador.
- [ ] Función `cierre-diario`: evaluación de sugerencias y candidatas con barras diarias según `ia.horizonte.*`.
- [ ] Pruebas `deno test` con series conocidas: stop primero, objetivo primero y ninguno.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-059 · Reparto de una señal de Usuarios en sugerencias por cupo](../E-07-sugerencias-y-decisiones/HU-059-reparto-de-una-senal-de-usuarios-en-sugerencias-por-cupo.md) | Evalúa las sugerencias emitidas. |
| Depende de | [HU-074 · Sincronizar órdenes y aplicar llenados](../E-08-ejecucion-y-broker/HU-074-sincronizar-ordenes-y-aplicar-llenados.md) | Toma del libro el rendimiento real de las ejecutadas. |
| Depende de | [HU-029 · Barra diaria tras el cierre y retención de barras de minuto](../E-04-datos-de-mercado/HU-029-barra-diaria-tras-el-cierre-y-retencion-de-barras-de-minuto.md) | Usa las barras diarias y la función `cierre-diario`. |
| Habilita | [HU-057 · Desempeño y calibración de la IA](HU-057-desempeno-y-calibracion-de-la-ia.md) | HU-057: agrega las evaluaciones de sugerencias y candidatas. |

## Notas técnicas

Se evalúan todas las sugerencias, aprobadas o no (07 §11).

## Documentación a actualizar

07 §11 pide evaluar también las candidatas cuyo horizonte se cumplió, pero 06 §5.3 define `evaluaciones_ia` solo con clave en la sugerencia. Precisar en `docs/` dónde se guarda la evaluación de una candidata que no produjo sugerencia.

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
