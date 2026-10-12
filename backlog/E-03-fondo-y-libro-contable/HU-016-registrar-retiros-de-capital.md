# HU-016 · Registrar retiros de capital

| Campo | Valor |
|---|---|
| Épica | [E-03 · Fondo y libro contable](README.md) |
| Entrega (hito) | R2 · El fondo existe |
| Rol | Administrador |
| Prioridad | Media |
| Módulos afectados | M-04 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-03` · `M-04` · `prioridad-media` |

## Historia

**Como** Administrador,  
**quiero** registrar un retiro de capital desde la Reserva o desde otro bolsillo,  
**para** sacar dinero del fondo dejando su rastro contable.

## Requisitos funcionales

- [FR-048 · Registro de un retiro](../requisitos-funcionales/FR-048-registro-de-un-retiro.md)

## Reglas

PM-41 · RN-12 · RN-13 · RN-14 · 02 §4 · 08 §4

## Criterios de aceptación

- **CA-1** Dados un Administrador y la Reserva con 5.000 disponibles, cuando registra un retiro de 1.000 sin elegir subcuenta, entonces sale de la Reserva, queda confirmado al registrarse y el libro registra reserva −1.000 y externa +1.000.
- **CA-2** (caso borde) CB-13: Dado un retiro mayor al disponible de la subcuenta de origen, cuando se registra, entonces responde `FONDOS_INSUFICIENTES`.
- **CA-3** Dado un retiro, cuando se indica un cupo como origen, entonces la función lo rechaza: primero se reduce el cupo.
- **CA-4** Dado un retiro registrado, cuando ocurre, entonces quedan en la bitácora `capital.retiro_registrado` y `capital.retiro_confirmado`.
- **CA-5** (permiso) Dado un Usuario o un Analista, cuando llama `registrar_retiro`, entonces recibe `NO_AUTORIZADO`.
- **CA-6** Dado un Administrador, cuando registra un retiro eligiendo `arriesgadas` o `usuarios_comun` como origen, entonces sale de esa subcuenta.

## Casos borde

CB-13

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] RPC `registrar_retiro(monto, subcuenta_tipo, referencia, nota)`: valida el origen y el disponible, crea el movimiento `retiro`, audita y publica `capital` y `resumen_cambio`.
- [ ] Pruebas pgTAP `capital_*`: retiro desde cada subcuenta permitida, desde un cupo, sin disponible y permisos.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25](HU-015-confirmar-el-aporte-por-conciliacion-y-repartirlo-50-25-25.md) | Solo hay dinero que retirar después de un aporte confirmado. |
| Habilita | [HU-099 · Pantalla de capital](../E-11-administracion/HU-099-pantalla-de-capital.md) | HU-099: registra retiros. |

## Notas técnicas

En paper trading un retiro es solo contable: la cuenta paper conserva el efectivo y la conciliación lo reporta como excedente no asignado (02 §4). Un retiro no se anula: se corrige con un aporte (08 §4). La pantalla está en [HU-099](../E-11-administracion/HU-099-pantalla-de-capital.md).

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
