# HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25

| Campo | Valor |
|---|---|
| Épica | [E-03 · Fondo y libro contable](README.md) |
| Entrega (hito) | R2 · El fondo existe |
| Rol | Administrador |
| Prioridad | Alta |
| Módulos afectados | M-04, M-12, M-03 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-03` · `M-04` · `M-12` · `M-03` · `prioridad-alta` |

## Historia

**Como** Administrador,  
**quiero** que el sistema confirme mi aporte contra el efectivo real de la cuenta paper y lo reparta solo,  
**para** que nunca se asigne dinero que el broker no tiene.

## Requisitos funcionales

- [FR-045 · Confirmación del aporte por conciliación](../requisitos-funcionales/FR-045-confirmacion-del-aporte-por-conciliacion.md)
- [FR-046 · Reparto del aporte confirmado](../requisitos-funcionales/FR-046-reparto-del-aporte-confirmado.md)

## Reglas

RN-07 · RN-08 · RN-09 · 02 §3.1 · 08 §4 · 08 §7.6 · 10 §4.1 · 10 §8

## Criterios de aceptación

- **CA-1** Dados un aporte registrado de 10.000 y la cuenta paper con 10.000 de efectivo, cuando corre la conciliación, entonces el aporte pasa a confirmado y el libro registra externa −10.000, reserva +5.000, arriesgadas +2.500 y usuarios_comun +2.500.
- **CA-2** (caso borde) CB-12: Dado un aporte de 1.000,03, cuando se confirma, entonces Arriesgadas recibe 250,00, Usuarios 250,00 y la Reserva 500,03.
- **CA-3** (caso borde) CB-11: Dado un aporte registrado y un broker sin ese efectivo, cuando corre la conciliación, entonces el aporte sigue registrado y a la hora se alerta al Administrador.
- **CA-4** Dado un cambio de los porcentajes de reparto antes de la confirmación, cuando el aporte se confirma, entonces usa los porcentajes vigentes en ese momento y los guarda en `movimientos.parametros`.
- **CA-5** Dada la confirmación, cuando ocurre, entonces se registra `capital.aporte_confirmado` y se publica `resumen_cambio` en el canal `fondo`.

## Casos borde

CB-11, CB-12

## Escenario E2E

E2E-04 (nuevo)

## Tareas

- [ ] Funciones: operación `cuenta` en `_shared/broker/` (interfaz, `alpaca.ts` y `simulado.ts`).
- [ ] Migración: tipo `resultado_conciliacion`, tabla `conciliaciones` (06 §5.6) con RLS para Analista y Administrador y `private.registrar_conciliacion`.
- [ ] Función `conciliacion` en su versión de efectivo: compara el `cash` del broker con el efectivo del libro y confirma los aportes que cuadran.
- [ ] Migración: confirmación del aporte con el movimiento `aporte` y el reparto de RN-08 y RN-09 a partir de los parámetros `reparto.pct_*`.
- [ ] Migración: trabajo `conciliacion` de `pg_cron` y parámetros `conciliacion.minutos_entre` y `conciliacion.tolerancia_usd`.
- [ ] Alerta al Administrador cuando un aporte lleva una hora sin confirmarse.
- [ ] Pruebas: pgTAP `capital_*` y `reparto_*` (redondeo y porcentajes vigentes) y `deno test` de `conciliacion`.
- [ ] E2E-04: aporte → confirmación por conciliación → reparto 50/25/25.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-014 · Registrar y anular aportes](HU-014-registrar-y-anular-aportes.md) | Confirma los aportes registrados. |
| Depende de | [HU-027 · Calendario, reloj y estado del mercado](../E-04-datos-de-mercado/HU-027-calendario-reloj-y-estado-del-mercado.md) | Reutiliza el adaptador del broker y el horario de mercado. |
| Depende de | [HU-085 · Alertas del sistema por audiencia](../E-09-tiempo-real-y-notificaciones/HU-085-alertas-del-sistema-por-audiencia.md) | Alerta al Administrador si el aporte no se confirma. |
| Depende de | [TT-06 · Arnés E2E de backend y de la app](../E-01-cimientos-y-calidad-continua/TT-06-arnes-e2e-de-backend-y-de-la-app.md) | Agrega el escenario E2E-04. |
| Habilita | [HU-016 · Registrar retiros de capital](HU-016-registrar-retiros-de-capital.md) | HU-016: solo hay dinero que retirar después de un aporte confirmado. |
| Habilita | [HU-018 · Asignar y reducir cupos](HU-018-asignar-y-reducir-cupos.md) | HU-018: `usuarios_comun` recibe dinero con el aporte confirmado. |
| Habilita | [HU-020 · Ver el resumen del fondo por bolsillos](HU-020-ver-el-resumen-del-fondo-por-bolsillos.md) | HU-020: hay saldos por bolsillo desde el primer aporte confirmado. |
| Habilita | [HU-034 · Encender y apagar los interruptores del fondo](../E-05-motor-de-politicas-y-configuracion/HU-034-encender-y-apagar-los-interruptores-del-fondo.md) | HU-034: solo se enciende con un aporte confirmado. |
| Habilita | [HU-035 · Salud de las integraciones](../E-05-motor-de-politicas-y-configuracion/HU-035-salud-de-las-integraciones.md) | HU-035: la función `conciliacion` también registra su salud. |
| Habilita | [HU-072 · Adaptador del broker para órdenes](../E-08-ejecucion-y-broker/HU-072-adaptador-del-broker-para-ordenes.md) | HU-072: extiende el adaptador que ya tiene `calendario` y `cuenta`. |
| Habilita | [HU-080 · Conciliación completa con pausa automática](../E-08-ejecucion-y-broker/HU-080-conciliacion-completa-con-pausa-automatica.md) | HU-080: extiende la conciliación de efectivo. |
| Habilita | [HU-086 · Bandeja de notificaciones](../E-09-tiempo-real-y-notificaciones/HU-086-bandeja-de-notificaciones.md) | HU-086: avisa `aporte_confirmado`. |
| Habilita | [HU-099 · Pantalla de capital](../E-11-administracion/HU-099-pantalla-de-capital.md) | HU-099: muestra la confirmación del aporte. |

## Notas técnicas

La conciliación de posiciones y de órdenes y la pausa automática llegan con [HU-080](../E-08-ejecucion-y-broker/HU-080-conciliacion-completa-con-pausa-automatica.md). El efectivo del broker que supera al del libro es excedente no asignado y no se usa (10 §4.1). En paper trading, el Administrador reinicia la cuenta de Alpaca con el monto del fondo fuera de la app.

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
