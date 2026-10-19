# HU-064 · Bandeja de riesgo del Analista

| Campo | Valor |
|---|---|
| Épica | [E-07 · Sugerencias y decisiones](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Analista |
| Prioridad | Alta |
| Módulos afectados | M-09 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-07` · `M-09` · `prioridad-alta` |

## Historia

**Como** Analista,  
**quiero** ver en una bandeja las sugerencias de Arriesgadas y las que esperan mi segunda aprobación,  
**para** decidir a tiempo sobre el riesgo del fondo.

## Requisitos funcionales

- [FR-146 · Bandeja de riesgo](../requisitos-funcionales/FR-146-bandeja-de-riesgo.md)
- [FR-141 · Detalle de la sugerencia](../requisitos-funcionales/FR-141-detalle-de-la-sugerencia.md)

## Reglas

PM-20 · 06 §6 · 03 §3 · 05 §9.3

## Criterios de aceptación

- **CA-1** Dado un Analista, cuando abre la Bandeja de riesgo, entonces ve las sugerencias vivas de Arriesgadas con su cuenta regresiva y la marca "espera tu segunda aprobación" en las que otro Analista ya aprobó.
- **CA-2** Dado un Administrador, cuando abre la bandeja, entonces la ve en solo lectura, sin botones de decisión.
- **CA-3** Dada una sugerencia nueva o un cambio, cuando ocurre, entonces la bandeja se actualiza con los eventos `sugerencia` y `decision` del canal `supervision`.
- **CA-4** (permiso) Dado un Usuario, cuando llama `bandeja_riesgo()` o abre `/riesgo/...`, entonces recibe `NO_AUTORIZADO` y el enrutador lo lleva al inicio.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-09.

## Tareas

- [ ] RPC `bandeja_riesgo()` con las sugerencias vivas que decide un Analista y la marca de segunda aprobación.
- [ ] App: `lib/features/riesgo/` con `bandejaRiesgoProvider` y el detalle con explicación.
- [ ] App: modo de solo lectura para el Administrador.
- [ ] Pruebas pgTAP de `bandeja_riesgo()` por rol y pruebas de widget.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-058 · Sugerencia de compra para Arriesgadas](HU-058-sugerencia-de-compra-para-arriesgadas.md) | Muestra las sugerencias de Arriesgadas. |
| Depende de | [HU-061 · Mis sugerencias: bandeja y detalle con explicación](HU-061-mis-sugerencias-bandeja-y-detalle-con-explicacion.md) | Reutiliza el detalle con explicación. |
| Depende de | [HU-084 · Gestor de tiempo real en la app](../E-09-tiempo-real-y-notificaciones/HU-084-gestor-de-tiempo-real-en-la-app.md) | Se actualiza con el canal `supervision`. |
| Habilita | [HU-065 · Decidir en Arriesgadas con doble aprobación](HU-065-decidir-en-arriesgadas-con-doble-aprobacion.md) | HU-065: se decide desde la Bandeja de riesgo. |
| Habilita | [HU-069 · Solicitar la liquidación de un cupo](HU-069-solicitar-la-liquidacion-de-un-cupo.md) | HU-069: las liquidaciones se deciden en la Bandeja de riesgo. |
| Habilita | [HU-092 · Ver el detalle del fondo](../E-10-cartera-y-reportes/HU-092-ver-el-detalle-del-fondo.md) | HU-092: muestra sugerencias y decisiones. |

## Notas técnicas

Las liquidaciones se suman a esta bandeja en [HU-069](HU-069-solicitar-la-liquidacion-de-un-cupo.md).

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
