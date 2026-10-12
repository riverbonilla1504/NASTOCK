# HU-022 · Registrar ajustes contables

| Campo | Valor |
|---|---|
| Épica | [E-03 · Fondo y libro contable](README.md) |
| Entrega (hito) | R2 · El fondo existe |
| Rol | Administrador |
| Prioridad | Baja |
| Módulos afectados | M-04, M-03 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-03` · `M-04` · `M-03` · `prioridad-baja` |

## Historia

**Como** Administrador,  
**quiero** registrar un ajuste contable justificado,  
**para** corregir el libro sin editar nunca un asiento.

## Requisitos funcionales

- [FR-056 · Ajuste contable](../requisitos-funcionales/FR-056-ajuste-contable.md)

## Reglas

PM-45 · 02 §14 · 06 §4.1 (L3) · 06 §4.2 · 11 §8

## Criterios de aceptación

- **CA-1** Dado un Administrador, cuando registra un ajuste con asientos que suman cero y una justificación, entonces se crea un movimiento `ajuste` y se registra `ajuste.registrado`.
- **CA-2** Dado un ajuste cuyos asientos no suman cero o que no trae justificación, cuando se intenta, entonces la función lo rechaza.
- **CA-3** Dado un ajuste que dejaría un saldo negativo, cuando se intenta, entonces la base de datos lo rechaza.
- **CA-4** (permiso) Dado un Usuario o un Analista, cuando llama `registrar_ajuste`, entonces recibe `NO_AUTORIZADO`.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] RPC `registrar_ajuste(asientos, justificacion)` sobre `private.registrar_movimiento`, con auditoría y eventos.
- [ ] Pruebas pgTAP: ajuste válido, sin suma cero, sin justificación y permisos.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-013 · Libro contable de doble partida](HU-013-libro-contable-de-doble-partida.md) | El ajuste es un movimiento del libro. |
| Depende de | [HU-107 · Bitácora inmutable con cadena de hash](../E-12-seguridad-auditoria-y-cumplimiento/HU-107-bitacora-inmutable-con-cadena-de-hash.md) | Registra `ajuste.registrado`. |
| Habilita | [HU-025 · Ajuste por split o agrupación de acciones](HU-025-ajuste-por-split-o-agrupacion-de-acciones.md) | HU-025: es un ajuste justificado del Administrador. |
| Habilita | [HU-099 · Pantalla de capital](../E-11-administracion/HU-099-pantalla-de-capital.md) | HU-099: registra ajustes. |

## Notas técnicas

Es la única forma de corregir el libro (06 §4.1, L3).

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
