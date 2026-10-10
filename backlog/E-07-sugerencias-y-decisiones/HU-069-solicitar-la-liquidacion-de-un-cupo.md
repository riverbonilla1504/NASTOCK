# HU-069 · Solicitar la liquidación de un cupo

| Campo | Valor |
|---|---|
| Épica | [E-07 · Sugerencias y decisiones](README.md) |
| Entrega (hito) | R6 · Medir y mejorar |
| Rol | Administrador |
| Prioridad | Media |
| Módulos afectados | M-09, M-04 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-07` · `M-09` · `M-04` · `prioridad-media` |

## Historia

**Como** Administrador,  
**quiero** solicitar la liquidación del cupo de un empleado que se retira,  
**para** que sus posiciones se vendan de forma ordenada antes de darlo de baja.

## Requisitos funcionales

- [FR-155 · Solicitud de liquidación de un cupo](../requisitos-funcionales/FR-155-solicitud-de-liquidacion-de-un-cupo.md)

## Reglas

PM-44 · 02 §11 · 08 §7.7 · D-27 · Q-06

## Criterios de aceptación

- **CA-1** Dado un cupo con posiciones, cuando el Administrador solicita su liquidación con un motivo, entonces se crea una sugerencia de venta total por cada posición, con `decide_rol = analista`, origen `liquidacion` y vencimiento al cierre, y se registra `cupo.liquidacion_solicitada`.
- **CA-2** Dadas esas sugerencias, cuando nacen, entonces aparecen en la Bandeja de riesgo y los Analistas reciben `sugerencia_nueva`.
- **CA-3** Dado un cupo sin posiciones, cuando se solicita la liquidación, entonces no se crea ninguna sugerencia.
- **CA-4** Dado `trading_activo` apagado, cuando se solicita, entonces las sugerencias de liquidación se crean igual.
- **CA-5** (permiso) Dado un Analista o un Usuario, cuando llama `solicitar_liquidacion`, entonces recibe `NO_AUTORIZADO`.

## Casos borde

—

## Escenario E2E

E2E-16 (nuevo)

## Tareas

- [ ] RPC `solicitar_liquidacion(usuario_id, motivo)`: una sugerencia de venta total por posición, con el motivo en `detalle`.
- [ ] App: acción "Solicitar liquidación" en la pantalla de cupos, y las liquidaciones en la Bandeja de riesgo.
- [ ] Pruebas pgTAP: con posiciones, sin posiciones, con el trading apagado y permisos.
- [ ] E2E-16: el Administrador solicita la liquidación de un empleado suspendido.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-064 · Bandeja de riesgo del Analista](HU-064-bandeja-de-riesgo-del-analista.md) | Las liquidaciones se deciden en la Bandeja de riesgo. |
| Depende de | [HU-074 · Sincronizar órdenes y aplicar llenados](../E-08-ejecucion-y-broker/HU-074-sincronizar-ordenes-y-aplicar-llenados.md) | Liquida las posiciones abiertas del cupo. |
| Depende de | [HU-010 · Suspender y reactivar una cuenta](../E-02-identidad-y-acceso/HU-010-suspender-y-reactivar-una-cuenta.md) | El flujo empieza con la cuenta suspendida. |
| Depende de | [HU-100 · Pantalla de cupos](../E-11-administracion/HU-100-pantalla-de-cupos.md) | La acción vive en la pantalla de cupos. |
| Depende de | [TT-06 · Arnés E2E de backend y de la app](../E-01-cimientos-y-calidad-continua/TT-06-arnes-e2e-de-backend-y-de-la-app.md) | Agrega el escenario E2E-16. |
| Habilita | [HU-070 · Aprobar las ventas de liquidación](HU-070-aprobar-las-ventas-de-liquidacion.md) | HU-070: decide las sugerencias de liquidación. |

## Notas técnicas

El Administrador solicita, pero no aprueba operaciones: las aprueban los Analistas (D-27). Que las posiciones se liquiden y no se transfieran está pendiente de validar (Q-06).

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
