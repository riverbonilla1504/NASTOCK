# HU-034 · Encender y apagar los interruptores del fondo

| Campo | Valor |
|---|---|
| Épica | [E-05 · Motor de políticas y configuración](README.md) |
| Entrega (hito) | R2 · El fondo existe |
| Rol | Administrador |
| Prioridad | Alta |
| Módulos afectados | M-08 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-05` · `M-08` · `prioridad-alta` |

## Historia

**Como** Administrador,  
**quiero** encender la IA y el trading cuando el fondo ya tiene capital, y apagarlos,  
**para** que el sistema empiece a analizar y a operar solo cuando yo lo decido.

## Requisitos funcionales

- [FR-079 · Interruptores del fondo](../requisitos-funcionales/FR-079-interruptores-del-fondo.md)
- [FR-080 · Encendido de un interruptor](../requisitos-funcionales/FR-080-encendido-de-un-interruptor.md)
- [FR-047 · Fondo sin capital](../requisitos-funcionales/FR-047-fondo-sin-capital.md)

## Reglas

PM-57 · RN-11 · RR-14 · 06 §4 · 08 §6 · 08 §7.6

## Criterios de aceptación

- **CA-1** Dado el fondo recién creado, cuando se consulta, entonces `ia_activa` y `trading_activo` están apagados.
- **CA-2** (caso borde) CB-80: Dado el fondo sin un aporte confirmado, cuando el Administrador intenta encender un interruptor, entonces responde `FONDO_SIN_CAPITAL` y la app muestra "Fondo sin capital".
- **CA-3** Dado un aporte confirmado, cuando el Administrador enciende `ia_activa` o `trading_activo`, entonces el interruptor queda encendido, se registra `interruptor.encendido` y se publica `interruptor` en el canal `admin`.
- **CA-4** Dado un Administrador, cuando apaga un interruptor con un motivo, entonces queda apagado con el motivo, el autor y la hora, y se registra `interruptor.apagado`.
- **CA-5** (permiso) Dado un Usuario o un Analista, cuando llama `reanudar`, entonces recibe `NO_AUTORIZADO`.

## Casos borde

CB-80

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] RPC `reanudar(interruptor)` (solo Administrador; exige un aporte confirmado) y `activar_freno(interruptor, motivo)` con `motivo_pausa`, `pausado_por` y `pausado_en`.
- [ ] Auditoría `interruptor.encendido` e `interruptor.apagado` y evento `interruptor` en el canal `admin`.
- [ ] Pruebas pgTAP `politicas_*`: nacen apagados, fondo sin capital, encender, apagar y permisos.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25](../E-03-fondo-y-libro-contable/HU-015-confirmar-el-aporte-por-conciliacion-y-repartirlo-50-25-25.md) | Solo se enciende con un aporte confirmado. |
| Depende de | [HU-107 · Bitácora inmutable con cadena de hash](../E-12-seguridad-auditoria-y-cumplimiento/HU-107-bitacora-inmutable-con-cadena-de-hash.md) | Registra el encendido y el apagado. |
| Depende de | [HU-083 · Canales privados de tiempo real](../E-09-tiempo-real-y-notificaciones/HU-083-canales-privados-de-tiempo-real.md) | Publica `interruptor` en el canal `admin`. |
| Habilita | [HU-037 · Motor de políticas: reglas de la propuesta](HU-037-motor-de-politicas-reglas-de-la-propuesta.md) | HU-037: RR-14 mira los interruptores. |
| Habilita | [HU-039 · Freno de emergencia](HU-039-freno-de-emergencia.md) | HU-039: extiende `activar_freno`. |
| Habilita | [HU-046 · Ciclo del agente: programación, uno a la vez y omisiones](../E-06-ia-contexto-y-decision/HU-046-ciclo-del-agente-programacion-uno-a-la-vez-y-omisiones.md) | HU-046: no corre con `ia_activa` apagado ni con el fondo sin capital. |
| Habilita | [HU-101 · Pantalla de parámetros e interruptores](../E-11-administracion/HU-101-pantalla-de-parametros-e-interruptores.md) | HU-101: enciende y apaga los interruptores. |
| Habilita | [HU-108 · Consultar y exportar la bitácora](../E-12-seguridad-auditoria-y-cumplimiento/HU-108-consultar-y-exportar-la-bitacora.md) | HU-108: el escenario audita un interruptor. |

## Notas técnicas

El freno para Analistas con botón en la barra y sus efectos sobre sugerencias y órdenes llegan en [HU-039](HU-039-freno-de-emergencia.md); la condición de reanudar con la conciliación en `ok`, en [HU-040](HU-040-reanudar-el-trading-solo-con-la-conciliacion-en-ok.md). La pantalla está en [HU-101](../E-11-administracion/HU-101-pantalla-de-parametros-e-interruptores.md).

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
