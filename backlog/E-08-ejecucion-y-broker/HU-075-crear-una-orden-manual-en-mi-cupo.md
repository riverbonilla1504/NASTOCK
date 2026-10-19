# HU-075 · Crear una orden manual en mi cupo

| Campo | Valor |
|---|---|
| Épica | [E-08 · Ejecución y broker](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-10, M-07 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-08` · `M-10` · `M-07` · `prioridad-alta` |

## Historia

**Como** Usuario,  
**quiero** crear una orden de compra o de venta en mi cupo, viendo antes la opinión de la IA,  
**para** operar por iniciativa propia dentro de las reglas de riesgo.

## Requisitos funcionales

- [FR-169 · Orden manual](../requisitos-funcionales/FR-169-orden-manual.md)
- [FR-170 · Orden manual sin duplicados](../requisitos-funcionales/FR-170-orden-manual-sin-duplicados.md)
- [FR-092 · Copia congelada de parámetros](../requisitos-funcionales/FR-092-copia-congelada-de-parametros.md)

## Reglas

PM-12 · RN-43 · RR-06 · RR-08 · 08 §7.5 · 08 §9.3 · 07 §8 · D-15

## Criterios de aceptación

- **CA-1** Dado un Usuario con disponible, cuando arma una compra de USD 150 de QQQ, entonces el stop y el objetivo vienen precargados con `riesgo.cupo.stop_defecto_pct` y `riesgo.cupo.objetivo_defecto_pct`, y ve la opinión de la IA antes de confirmar.
- **CA-2** Dada la confirmación biométrica, cuando envía la orden, entonces se valida con el motor de políticas, se retienen los fondos, se crea la orden con origen `manual` y su `opinion_id`, se encola y se registra `orden.manual_creada`.
- **CA-3** Dado un reintento de la app con el mismo id, cuando llega, entonces devuelve la misma orden sin duplicarla.
- **CA-4** Dado el mercado cerrado, cuando intenta crear la orden, entonces recibe `MERCADO_CERRADO` con la hora de apertura.
- **CA-5** Dada una orden que viola una regla de riesgo, cuando se envía, entonces recibe `REGLA_RR_xx` con el texto de la regla.
- **CA-6** (permiso) Dado un Analista o un Administrador, cuando llama `crear_orden_manual`, entonces recibe `NO_AUTORIZADO`; un Usuario solo puede operar su propio cupo.

## Casos borde

—

## Escenario E2E

E2E-11 (nuevo)

## Tareas

- [ ] RPC `crear_orden_manual(simbolo, lado, monto, cantidad, stop_pct, objetivo_pct, opinion_id)` con el id generado en la app como clave de idempotencia: validación, retención, copia de parámetros, encolado y auditoría.
- [ ] Migración: parámetros `riesgo.cupo.stop_defecto_pct` y `riesgo.cupo.objetivo_defecto_pct`.
- [ ] App: `lib/features/ordenes/` con el formulario de la orden, la llamada a `opinion-ia`, la vista del veredicto y la confirmación.
- [ ] Pruebas pgTAP (validaciones, idempotencia y permisos) y pruebas de widget del formulario.
- [ ] E2E-11: orden manual con opinión de JEV; reintentar con el mismo id no duplica.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-073 · Enviar al broker las órdenes aprobadas](HU-073-enviar-al-broker-las-ordenes-aprobadas.md) | La orden manual se envía con el mismo ejecutor. |
| Depende de | [HU-052 · Opinión de la IA sobre una orden manual](../E-06-ia-contexto-y-decision/HU-052-opinion-de-la-ia-sobre-una-orden-manual.md) | Muestra la opinión de la IA antes de confirmar. |
| Depende de | [HU-019 · Ver mi cupo](../E-03-fondo-y-libro-contable/HU-019-ver-mi-cupo.md) | Opera sobre el disponible del cupo. |
| Depende de | [HU-009 · Sesión segura, bloqueo biométrico y confirmación de acciones sensibles](../E-02-identidad-y-acceso/HU-009-sesion-segura-bloqueo-biometrico-y-confirmacion-de-acciones-sensibles.md) | Exige la confirmación biométrica. |
| Depende de | [TT-06 · Arnés E2E de backend y de la app](../E-01-cimientos-y-calidad-continua/TT-06-arnes-e2e-de-backend-y-de-la-app.md) | Agrega el escenario E2E-11. |
| Habilita | [HU-076 · Ver mis órdenes y cancelar una que no se ha llenado](HU-076-ver-mis-ordenes-y-cancelar-una-que-no-se-ha-llenado.md) | HU-076: cancela las órdenes propias. |

## Notas técnicas

La opinión no bloquea: solo las reglas de riesgo bloquean (07 §8). Con JEV caído, la orden manual sigue sin opinión (CB-57).

## Documentación a actualizar

06 §8.1 lista los parámetros de `crear_orden_manual` sin el id generado en la app, que 08 §7.5 y 08 §9.3 usan como clave de idempotencia. Precisar la firma en `docs/`.

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
