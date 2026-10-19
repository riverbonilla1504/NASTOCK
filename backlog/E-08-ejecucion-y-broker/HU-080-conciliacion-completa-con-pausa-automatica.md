# HU-080 · Conciliación completa con pausa automática

| Campo | Valor |
|---|---|
| Épica | [E-08 · Ejecución y broker](README.md) |
| Entrega (hito) | R5 · Protegido y avisado |
| Rol | Administrador |
| Prioridad | Alta |
| Módulos afectados | M-12 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-08` · `M-12` · `prioridad-alta` |

## Historia

**Como** Administrador,  
**quiero** que el sistema compare el efectivo, las posiciones y las órdenes del libro con el broker y se detenga solo ante un descuadre,  
**para** que nunca se siga operando sobre un libro que no coincide con la realidad.

## Requisitos funcionales

- [FR-179 · Conciliación con el broker](../requisitos-funcionales/FR-179-conciliacion-con-el-broker.md)
- [FR-180 · Excedente no asignado](../requisitos-funcionales/FR-180-excedente-no-asignado.md)
- [FR-181 · Pausa automática por descuadre crítico](../requisitos-funcionales/FR-181-pausa-automatica-por-descuadre-critico.md)

## Reglas

RR-22 · 10 §3 · 10 §8 · 08 §6 · 11 §8

## Criterios de aceptación

- **CA-1** Dado que el efectivo, las posiciones por símbolo y las órdenes vivas coinciden, cuando corre la conciliación, entonces el resultado es `ok`; si el broker tiene más efectivo que el libro, también es `ok` y la diferencia se reporta como excedente no asignado.
- **CA-2** Dada una diferencia de efectivo dentro de `conciliacion.tolerancia_usd`, cuando corre, entonces el resultado es `diferencia_menor`; si se repite 3 veces, se alerta al Administrador de forma informativa.
- **CA-3** (caso borde) CB-40: Dada una orden o una cantidad en el broker que la plataforma no conoce, cuando corre, entonces el resultado es `descuadre_critico`, `trading_activo` se apaga, se alerta de forma crítica a los Administradores y se registra `conciliacion.descuadre`.
- **CA-4** Dado el trading pausado por un descuadre, cuando hay sugerencias vivas, entonces pasan a invalidadas, salvo las de liquidación.
- **CA-5** Dada la conciliación, cuando se programa, entonces corre cada `conciliacion.minutos_entre` minutos en horario de mercado y una vez tras el cierre.

## Casos borde

CB-40

## Escenario E2E

E2E-13 (nuevo)

## Tareas

- [ ] Función `conciliacion`: comparación de las posiciones y de las órdenes vivas, además del efectivo.
- [ ] Migración: `private.registrar_conciliacion(...)` con el detalle por símbolo y la acción de apagar `trading_activo` ante un descuadre crítico.
- [ ] Notificación `descuadre_conciliacion`, auditoría y evento `conciliacion` en el canal `supervision`.
- [ ] Pruebas `deno test` de `conciliacion` con el broker simulado (orden desconocida, cantidad distinta y efectivo menor) y pgTAP.
- [ ] E2E-13: descuadre forzado → trading pausado → sugerencias invalidadas salvo las liquidaciones.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25](../E-03-fondo-y-libro-contable/HU-015-confirmar-el-aporte-por-conciliacion-y-repartirlo-50-25-25.md) | Extiende la conciliación de efectivo. |
| Depende de | [HU-074 · Sincronizar órdenes y aplicar llenados](HU-074-sincronizar-ordenes-y-aplicar-llenados.md) | Compara posiciones y órdenes del libro. |
| Depende de | [HU-039 · Freno de emergencia](../E-05-motor-de-politicas-y-configuracion/HU-039-freno-de-emergencia.md) | Apaga `trading_activo` con los mismos efectos del freno. |
| Depende de | [TT-06 · Arnés E2E de backend y de la app](../E-01-cimientos-y-calidad-continua/TT-06-arnes-e2e-de-backend-y-de-la-app.md) | Agrega el escenario E2E-13. |
| Habilita | [HU-025 · Ajuste por split o agrupación de acciones](../E-03-fondo-y-libro-contable/HU-025-ajuste-por-split-o-agrupacion-de-acciones.md) | HU-025: la conciliación detecta el evento corporativo. |
| Habilita | [HU-040 · Reanudar el trading solo con la conciliación en ok](../E-05-motor-de-politicas-y-configuracion/HU-040-reanudar-el-trading-solo-con-la-conciliacion-en-ok.md) | HU-040: mira el resultado de la última conciliación. |
| Habilita | [HU-081 · Revisar un descuadre y lanzar una conciliación](HU-081-revisar-un-descuadre-y-lanzar-una-conciliacion.md) | HU-081: revisa los resultados de la conciliación. |
| Habilita | [HU-113 · Simulacro de restauración de un respaldo](../E-12-seguridad-auditoria-y-cumplimiento/HU-113-simulacro-de-restauracion-de-un-respaldo.md) | HU-113: concilia la base restaurada contra el broker. |

## Notas técnicas

Nadie opera desde el panel web de Alpaca: una orden desconocida es, por definición, un incidente (10 §8). Un llenado que la sincronización aún no aplicó se resuelve solo en el ciclo siguiente.

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
