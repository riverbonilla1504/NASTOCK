# HU-057 · Desempeño y calibración de la IA

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
**quiero** ver si la confianza de JEV corresponde con sus aciertos y cuánto valor agregan el contexto y la decisión humana,  
**para** ajustar la IA con datos y no con intuiciones.

## Requisitos funcionales

- [FR-133 · Desempeño y calibración de la IA](../requisitos-funcionales/FR-133-desempeno-y-calibracion-de-la-ia.md)

## Reglas

PM-32 · 07 §11 · 06 §6 · 01 §6

## Criterios de aceptación

- **CA-1** Dado un rango de fechas, cuando un Analista abre Desempeño de la IA, entonces ve por versión de configuración la tasa de aprobación y el rendimiento de las sugerencias aprobadas, rechazadas y vencidas.
- **CA-2** Dadas las decisiones agrupadas por confianza (0,65 a 0,75, 0,75 a 0,85 y 0,85 o más), cuando se muestran, entonces cada tramo trae su tasa real de acierto para compararla con la confianza informada.
- **CA-3** Dadas las evaluaciones, cuando se muestran, entonces se compara el acierto con contexto frente a "sin contexto" y el resultado de las sugerencias frente a mantener QQQ.
- **CA-4** Dado el rango, cuando se muestra, entonces incluye el costo de DeepSeek y de JEV.
- **CA-5** (permiso) Dado un Usuario, cuando llama `desempeno_ia`, entonces recibe `NO_AUTORIZADO`.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] RPC `desempeno_ia(desde, hasta)` con los agregados por versión de configuración.
- [ ] App: `lib/features/ia/` con las pantallas de desempeño y calibración, ciclos y costos.
- [ ] Pruebas pgTAP de `desempeno_ia` (cálculo y permisos) y pruebas de widget.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-056 · Evaluación de sugerencias y candidatas tras el cierre](HU-056-evaluacion-de-sugerencias-y-candidatas-tras-el-cierre.md) | Agrega las evaluaciones de sugerencias y candidatas. |
| Depende de | [HU-006 · Navegación y guardas según el rol](../E-02-identidad-y-acceso/HU-006-navegacion-y-guardas-segun-el-rol.md) | La pantalla cuelga del menú de Analista y Administrador. |

## Notas técnicas

Meta del MVP: acierto real dentro de ±10 puntos de la confianza informada (01 §6).

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
