# HU-112 · Retención de datos y vigilancia del tamaño de la base

| Campo | Valor |
|---|---|
| Épica | [E-12 · Seguridad, auditoría y cumplimiento](README.md) |
| Entrega (hito) | R6 · Medir y mejorar |
| Rol | Administrador |
| Prioridad | Baja |
| Módulos afectados | M-20, M-18 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-12` · `M-20` · `M-18` · `prioridad-baja` |

## Historia

**Como** Administrador,  
**quiero** que el sistema borre solo los datos que ya no hacen falta y me avise si la base de datos crece demasiado,  
**para** no superar el límite del plan gratuito sin perder nada con valor contable.

## Requisitos funcionales

- [FR-225 · Retención de datos](../requisitos-funcionales/FR-225-retencion-de-datos.md)
- [FR-226 · Vigilancia del tamaño de la base de datos](../requisitos-funcionales/FR-226-vigilancia-del-tamano-de-la-base-de-datos.md)

## Reglas

06 §10 · 05 §3.4 · 05 §7 · RN-40 · RSG-17

## Criterios de aceptación

- **CA-1** Dada la limpieza diaria, cuando corre, entonces borra las noticias de más de 30 días, los contextos de más de 90, las notificaciones leídas de más de 90 y las evaluaciones de candidatas de más de un año, salvo las elegidas y las que originaron señales.
- **CA-2** Dada la limpieza, cuando corre, entonces no borra nada del libro, las órdenes, las sugerencias, las decisiones, las señales, la bitácora ni los ciclos del agente.
- **CA-3** Dado el tamaño de la base, cuando el trabajo semanal lo registra por encima de 350 MB, entonces se alerta al Administrador.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Migración: completar el trabajo `limpieza` con toda la tabla de 06 §10.
- [ ] Migración: trabajo semanal que registra el tamaño de la base de datos y crea la alerta.
- [ ] Pruebas pgTAP de la limpieza con el reloj adelantado y de lo que nunca se borra.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-029 · Barra diaria tras el cierre y retención de barras de minuto](../E-04-datos-de-mercado/HU-029-barra-diaria-tras-el-cierre-y-retencion-de-barras-de-minuto.md) | Extiende el trabajo `limpieza`. |
| Depende de | [HU-047 · Puntaje compuesto y elección de la mejor opción](../E-06-ia-contexto-y-decision/HU-047-puntaje-compuesto-y-eleccion-de-la-mejor-opcion.md) | Limpia las evaluaciones de candidatas. |
| Depende de | [HU-086 · Bandeja de notificaciones](../E-09-tiempo-real-y-notificaciones/HU-086-bandeja-de-notificaciones.md) | Limpia las notificaciones leídas. |

## Notas técnicas

El plan gratuito de Supabase da 500 MB de base de datos (05 §3.4).

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
