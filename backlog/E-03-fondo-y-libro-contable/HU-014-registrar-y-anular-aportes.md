# HU-014 · Registrar y anular aportes

| Campo | Valor |
|---|---|
| Épica | [E-03 · Fondo y libro contable](README.md) |
| Entrega (hito) | R2 · El fondo existe |
| Rol | Administrador |
| Prioridad | Alta |
| Módulos afectados | M-04 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-03` · `M-04` · `prioridad-alta` |

## Historia

**Como** Administrador,  
**quiero** registrar un aporte de capital y anularlo si aún no se confirma,  
**para** que el dinero entre al fondo solo por una vía controlada y corregible.

## Requisitos funcionales

- [FR-043 · Registro de un aporte](../requisitos-funcionales/FR-043-registro-de-un-aporte.md)
- [FR-044 · Anulación de un aporte no confirmado](../requisitos-funcionales/FR-044-anulacion-de-un-aporte-no-confirmado.md)

## Reglas

PM-40 · RN-07 · RN-10 · 02 §3 · 08 §4

## Criterios de aceptación

- **CA-1** Dado un Administrador, cuando registra un aporte de 10.000 con la referencia `paper-inicial`, entonces queda en estado registrado, el libro no cambia y se registra `capital.aporte_registrado`.
- **CA-2** Dado un aporte registrado y no confirmado, cuando el Administrador lo anula con un motivo, entonces pasa a anulado, se guarda quién y cuándo lo anuló y se registra `capital.aporte_anulado`.
- **CA-3** Dado un aporte confirmado, cuando se intenta anular, entonces responde `ESTADO_INVALIDO`: se corrige con un retiro.
- **CA-4** Dado un monto menor o igual a 0, cuando se intenta registrar, entonces la base de datos lo rechaza.
- **CA-5** (permiso) Dado un Usuario o un Analista, cuando llama `registrar_aporte` o `anular_aporte`, entonces recibe `NO_AUTORIZADO`.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-04.

## Tareas

- [ ] Migración: tipo `estado_mov_capital` y tabla `movimientos_capital` (06 §4.3) con RLS de lectura para Analista y Administrador.
- [ ] RPC `registrar_aporte(monto, referencia, nota)` y `anular_aporte(id, motivo)` con auditoría y evento `capital` en el canal `admin`.
- [ ] Pruebas pgTAP `capital_*`: registro, anulación, anulación de un aporte confirmado y permisos.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-013 · Libro contable de doble partida](HU-013-libro-contable-de-doble-partida.md) | El aporte se contabiliza en el libro al confirmarse. |
| Depende de | [HU-107 · Bitácora inmutable con cadena de hash](../E-12-seguridad-auditoria-y-cumplimiento/HU-107-bitacora-inmutable-con-cadena-de-hash.md) | Registra `capital.aporte_registrado` y `capital.aporte_anulado`. |
| Depende de | [HU-083 · Canales privados de tiempo real](../E-09-tiempo-real-y-notificaciones/HU-083-canales-privados-de-tiempo-real.md) | Publica el evento `capital` en el canal `admin`. |
| Habilita | [HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25](HU-015-confirmar-el-aporte-por-conciliacion-y-repartirlo-50-25-25.md) | HU-015: confirma los aportes registrados. |
| Habilita | [HU-099 · Pantalla de capital](../E-11-administracion/HU-099-pantalla-de-capital.md) | HU-099: registra y anula aportes. |

## Notas técnicas

Un aporte registrado no mueve el libro (RN-07): lo mueve su confirmación, en [HU-015](HU-015-confirmar-el-aporte-por-conciliacion-y-repartirlo-50-25-25.md). La pantalla está en [HU-099](../E-11-administracion/HU-099-pantalla-de-capital.md).

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
