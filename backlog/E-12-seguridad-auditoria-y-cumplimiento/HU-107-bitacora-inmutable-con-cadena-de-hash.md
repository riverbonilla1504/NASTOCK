# HU-107 · Bitácora inmutable con cadena de hash

| Campo | Valor |
|---|---|
| Épica | [E-12 · Seguridad, auditoría y cumplimiento](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Rol | Administrador |
| Prioridad | Alta |
| Módulos afectados | M-17 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-12` · `M-17` · `prioridad-alta` |

## Historia

**Como** Administrador,  
**quiero** que toda acción sensible quede en una bitácora que nadie puede alterar,  
**para** poder demostrar después quién hizo qué y cuándo.

## Requisitos funcionales

- [FR-218 · Bitácora de acciones sensibles](../requisitos-funcionales/FR-218-bitacora-de-acciones-sensibles.md)
- [FR-219 · Bitácora inmutable y encadenada](../requisitos-funcionales/FR-219-bitacora-inmutable-y-encadenada.md)

## Reglas

11 §4.1 · 11 §4.3 · 06 §5.6 · 01 §2 (P6)

## Criterios de aceptación

- **CA-1** Dada una acción del catálogo de 11 §4.1, cuando ocurre, entonces `private.auditar` agrega un registro con momento, actor, rol, acción, entidad, id, valores anterior y nuevo y origen.
- **CA-2** Dado un registro nuevo, cuando se inserta, entonces su `hash` es `sha256(hash_anterior ‖ momento ‖ actor ‖ acción ‖ entidad ‖ id ‖ detalle)`, y dos inserciones simultáneas no usan el mismo `hash_anterior`.
- **CA-3** (permiso) Dado cualquier rol de la API, incluida la llave secreta, cuando intenta un `INSERT`, un `UPDATE` o un `DELETE` directo sobre `auditoria`, entonces se rechaza.
- **CA-4** Dado un registro, cuando se revisa, entonces no contiene llaves, tokens ni respuestas de Google.
- **CA-5** (aislamiento) Dado un Usuario o un Analista, cuando consulta `auditoria`, entonces no recibe filas.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-14.

## Tareas

- [ ] Migración: tabla `auditoria` (06 §5.6) con RLS de lectura solo para el Administrador.
- [ ] Migración: `private.auditar(actor, accion, entidad, id, detalle)` con el bloqueo y el encadenado del hash.
- [ ] Migración: trigger que rechaza `UPDATE` y `DELETE`.
- [ ] Pruebas pgTAP `auditoria_*`: encadenado, concurrencia, inmutabilidad y lectura por rol.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [TT-03 · Base de Supabase: esquema private, extensiones, Vault y ping](../E-01-cimientos-y-calidad-continua/TT-03-base-de-supabase-esquema-private-extensiones-vault-y-ping.md) | Usa el esquema `private`. |
| Depende de | [HU-001 · Perfiles, rol actual y lecturas por rol](../E-02-identidad-y-acceso/HU-001-perfiles-rol-actual-y-lecturas-por-rol.md) | Usa el tipo `rol_app` y `private.rol_actual()` en su política de lectura. |
| Habilita | [HU-002 · Alta solo con invitación vigente](../E-02-identidad-y-acceso/HU-002-alta-solo-con-invitacion-vigente.md) | HU-002: el alta registra `cuenta.activada`. |
| Habilita | [HU-010 · Suspender y reactivar una cuenta](../E-02-identidad-y-acceso/HU-010-suspender-y-reactivar-una-cuenta.md) | HU-010: registra `cuenta.suspendida` y `cuenta.reactivada`. |
| Habilita | [HU-011 · Cambiar el rol de una cuenta](../E-02-identidad-y-acceso/HU-011-cambiar-el-rol-de-una-cuenta.md) | HU-011: registra `cuenta.rol_cambiado`. |
| Habilita | [HU-014 · Registrar y anular aportes](../E-03-fondo-y-libro-contable/HU-014-registrar-y-anular-aportes.md) | HU-014: registra `capital.aporte_registrado` y `capital.aporte_anulado`. |
| Habilita | [HU-022 · Registrar ajustes contables](../E-03-fondo-y-libro-contable/HU-022-registrar-ajustes-contables.md) | HU-022: registra `ajuste.registrado`. |
| Habilita | [HU-033 · Parámetros configurables con rango e historial](../E-05-motor-de-politicas-y-configuracion/HU-033-parametros-configurables-con-rango-e-historial.md) | HU-033: registra `parametro.cambiado`. |
| Habilita | [HU-034 · Encender y apagar los interruptores del fondo](../E-05-motor-de-politicas-y-configuracion/HU-034-encender-y-apagar-los-interruptores-del-fondo.md) | HU-034: registra el encendido y el apagado. |
| Habilita | [HU-035 · Salud de las integraciones](../E-05-motor-de-politicas-y-configuracion/HU-035-salud-de-las-integraciones.md) | HU-035: registra `integracion.caida` e `integracion.recuperada`. |
| Habilita | [HU-036 · Editar la lista blanca](../E-05-motor-de-politicas-y-configuracion/HU-036-editar-la-lista-blanca.md) | HU-036: registra `lista_blanca.cambiada`. |
| Habilita | [HU-050 · Presupuesto mensual de IA](../E-06-ia-contexto-y-decision/HU-050-presupuesto-mensual-de-ia.md) | HU-050: registra `ia.presupuesto_agotado`. |
| Habilita | [HU-054 · Versiones del prompt de contexto y de la configuración de decisión](../E-06-ia-contexto-y-decision/HU-054-versiones-del-prompt-de-contexto-y-de-la-configuracion-de-decision.md) | HU-054: registra `prompt.creado` y `prompt.activado`. |
| Habilita | [HU-096 · Reporte diario al Administrador](../E-10-cartera-y-reportes/HU-096-reporte-diario-al-administrador.md) | HU-096: incluye el último hash de la bitácora. |
| Habilita | [HU-108 · Consultar y exportar la bitácora](HU-108-consultar-y-exportar-la-bitacora.md) | HU-108: consulta la tabla `auditoria`. |

## Notas técnicas

14 §4 ubica la bitácora de E-12 en R2, pero el trigger de alta de 04 §6 (R1) ya llama a `private.auditar`: por eso la base va en R1, y su pantalla y el E2E-14 en R2 ([HU-108](HU-108-consultar-y-exportar-la-bitacora.md)). No se duplica lo que ya es un registro inmutable propio: sugerencias, órdenes, ciclos y asientos (11 §4.1).

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
