# HU-013 · Libro contable de doble partida

| Campo | Valor |
|---|---|
| Épica | [E-03 · Fondo y libro contable](README.md) |
| Entrega (hito) | R2 · El fondo existe |
| Rol | Administrador |
| Prioridad | Alta |
| Módulos afectados | M-03 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-03` · `M-03` · `prioridad-alta` |

## Historia

**Como** Administrador,  
**quiero** que todo el dinero del fondo se lleve en un libro de doble partida que nadie puede editar,  
**para** reconstruir cualquier saldo y confiar en que cada peso tiene origen y destino.

## Requisitos funcionales

- [FR-038 · Fondo único con subcuentas](../requisitos-funcionales/FR-038-fondo-unico-con-subcuentas.md)
- [FR-039 · Movimientos de doble partida](../requisitos-funcionales/FR-039-movimientos-de-doble-partida.md)
- [FR-040 · Saldos nunca negativos](../requisitos-funcionales/FR-040-saldos-nunca-negativos.md)
- [FR-041 · Libro inmutable](../requisitos-funcionales/FR-041-libro-inmutable.md)
- [FR-042 · Verificación diaria del libro](../requisitos-funcionales/FR-042-verificacion-diaria-del-libro.md)

## Reglas

RN-01 · RN-04 · RN-05 · RN-06 · 06 §4 · 01 §2 (P4)

## Criterios de aceptación

- **CA-1** Dado el fondo recién creado, cuando se consulta, entonces existe un solo fondo con las subcuentas `reserva`, `arriesgadas`, `usuarios_comun`, `externa` y `resultados`, todas en 0 y con los interruptores apagados.
- **CA-2** Dado un movimiento cuyos asientos no suman cero, cuando se intenta registrar, entonces `private.registrar_movimiento` lo rechaza y la verificación diferida lo vuelve a impedir al confirmar la transacción.
- **CA-3** Dado un movimiento que dejaría en negativo el efectivo de una subcuenta de bolsillo o de cupo, o el retenido por encima del efectivo, cuando se registra, entonces la base de datos lo rechaza.
- **CA-4** (permiso) Dado cualquier rol, incluida la llave secreta, cuando intenta un `UPDATE` o un `DELETE` sobre `asientos` o `movimientos`, entonces el trigger lo rechaza.
- **CA-5** Dado un saldo guardado que difiere de la suma de sus asientos, cuando corre la verificación diaria, entonces se genera una alerta.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-04.

## Tareas

- [ ] Migración: tipos `bolsillo`, `tipo_subcuenta`, `estado_subcuenta`, `concepto_asiento` y `tipo_movimiento`, y tablas `fondos`, `subcuentas`, `movimientos` y `asientos` (06 §4) con sus `CHECK` y el índice de un solo fondo.
- [ ] Migración: `private.registrar_movimiento(tipo, asientos, referencia, descripcion, parametros)` como única escritura del libro; actualiza `efectivo` e `invertido` en la misma transacción.
- [ ] Migración: verificación diferida de suma cero y trigger que rechaza `UPDATE` y `DELETE` en `asientos` y `movimientos`.
- [ ] Migración: RLS de lectura de `subcuentas`, `movimientos` y `asientos` según 03 §4.3, sin políticas de escritura.
- [ ] Migración: datos iniciales del fondo y de sus cinco subcuentas fijas.
- [ ] Trabajo diario que recalcula los saldos desde `asientos` y crea la alerta si difieren.
- [ ] Pruebas pgTAP `libro_*`: invariantes L1 a L5, no negativos, inmutabilidad y lectura por rol.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-001 · Perfiles, rol actual y lecturas por rol](../E-02-identidad-y-acceso/HU-001-perfiles-rol-actual-y-lecturas-por-rol.md) | Las subcuentas de cupo y las políticas dependen de `perfiles` y de `private.rol_actual()`. |
| Depende de | [HU-085 · Alertas del sistema por audiencia](../E-09-tiempo-real-y-notificaciones/HU-085-alertas-del-sistema-por-audiencia.md) | La verificación diaria crea una alerta. |
| Habilita | [HU-014 · Registrar y anular aportes](HU-014-registrar-y-anular-aportes.md) | HU-014: el aporte se contabiliza en el libro al confirmarse. |
| Habilita | [HU-017 · Cupo al aceptar la invitación](HU-017-cupo-al-aceptar-la-invitacion.md) | HU-017: el cupo es una subcuenta del libro. |
| Habilita | [HU-021 · Foto diaria de patrimonio y rendimiento TWR](HU-021-foto-diaria-de-patrimonio-y-rendimiento-twr.md) | HU-021: la foto se toma de los saldos del libro. |
| Habilita | [HU-022 · Registrar ajustes contables](HU-022-registrar-ajustes-contables.md) | HU-022: el ajuste es un movimiento del libro. |

## Notas técnicas

Dinero en `numeric(14,2)` en USD. `retenido` no forma parte del libro (L5). Las ganancias no realizadas no son contables: se calculan al vuelo (RN-06).

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
