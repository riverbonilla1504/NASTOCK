# HU-063 · Rechazar una sugerencia con motivo

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
**quiero** rechazar una sugerencia indicando el motivo,  
**para** descartar lo que no me convence y que ese motivo sirva para medir a la IA.

## Requisitos funcionales

- [FR-144 · Rechazo de una sugerencia con motivo](../requisitos-funcionales/FR-144-rechazo-de-una-sugerencia-con-motivo.md)
- [FR-145 · Decisión única e idempotente](../requisitos-funcionales/FR-145-decision-unica-e-idempotente.md)

## Reglas

PM-11 · PM-21 · RN-53 · 08 §1 · 06 §3

## Criterios de aceptación

- **CA-1** Dada una sugerencia viva de su cupo, cuando el Usuario la rechaza con un motivo del catálogo, entonces pasa a rechazada, se guarda la decisión con el motivo y el precio al decidir y se registra `sugerencia.rechazada`.
- **CA-2** Dado el motivo `otro`, cuando se elige, entonces admite un texto libre.
- **CA-3** Dada una sugerencia que el Usuario ya aprobó, cuando intenta rechazarla, entonces responde `YA_DECIDIDA`.
- **CA-4** (caso borde) CB-31: Dado un Usuario que rechaza todas sus sugerencias, cuando ocurre, entonces nada más cambia: queda en las métricas de desempeño.
- **CA-5** (permiso) Dada una persona que no es quien decide esa sugerencia, cuando intenta rechazarla, entonces recibe `NO_AUTORIZADO`.

## Casos borde

CB-31

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] RPC `rechazar_sugerencia(id, motivo, texto)` con rol, dueño, estado, decisión única, auditoría y evento.
- [ ] App: botón Rechazar con el selector de motivos (`no_estoy_de_acuerdo`, `riesgo_alto`, `mal_momento`, `monto_inadecuado`, `prefiero_otro_activo` y `otro`) y confirmación.
- [ ] Pruebas pgTAP: rechazo, decisión distinta, idempotencia y permisos.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-061 · Mis sugerencias: bandeja y detalle con explicación](HU-061-mis-sugerencias-bandeja-y-detalle-con-explicacion.md) | Se rechaza desde el detalle de la sugerencia. |
| Depende de | [HU-009 · Sesión segura, bloqueo biométrico y confirmación de acciones sensibles](../E-02-identidad-y-acceso/HU-009-sesion-segura-bloqueo-biometrico-y-confirmacion-de-acciones-sensibles.md) | Exige la confirmación de la acción. |
| Habilita | [HU-065 · Decidir en Arriesgadas con doble aprobación](HU-065-decidir-en-arriesgadas-con-doble-aprobacion.md) | HU-065: usa `rechazar_sugerencia`. |
| Habilita | [HU-071 · Aprobar o rechazar un rebalanceo](HU-071-aprobar-o-rechazar-un-rebalanceo.md) | HU-071: usa `rechazar_sugerencia`. |

## Notas técnicas

La misma función la usan los Analistas en Arriesgadas y en liquidaciones, y el Administrador en rebalanceos, según `decide_rol`.

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
