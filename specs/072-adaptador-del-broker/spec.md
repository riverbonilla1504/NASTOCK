# Especificación de funcionalidad (Feature Specification): HU-072 · Adaptador del broker para órdenes

**Feature Branch**: `072-adaptador-del-broker`

**Created**: 2026-11-09

**Status**: Implementada (pendiente de revisión)

**Input**: Historia de usuario: "HU-072 · Adaptador del broker para órdenes", en [`backlog/E-08-ejecucion-y-broker/HU-072-adaptador-del-broker-para-ordenes.md`](../../backlog/E-08-ejecucion-y-broker/HU-072-adaptador-del-broker-para-ordenes.md)

> **MVP corto** (D-63, [`docs/14` §4.1](../../docs/14-mapa-para-backlog.md#41-mvp-corto-lo-que-se-entrega-primero-d-58)): solo acciones enteras. El adaptador envía compras `bracket` y ventas límite; el simulado no llena fracciones.

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Adaptador del broker para órdenes (Prioridad: P1)

**Como** Administrador, **quiero** que el sistema hable con Alpaca paper a través de un adaptador que también tiene una versión simulada, **para** operar en paper con precios reales y poder probar a cualquier hora sin tocar la cuenta.

**Por qué esta prioridad**: prioridad Alta, entrega R4. Habilita HU-073 (envío de órdenes) y, con ella, HU-074 y HU-077.

**Prueba independiente**: `deno test` del adaptador real con respuestas grabadas y del simulado. Sin escenario E2E propio; lo ejercita E2E-08.

**Escenarios de aceptación**:

1. **CA-1** · **Dado** `PROVEEDOR_BROKER=alpaca`, **cuando** una función usa el adaptador, **entonces** habla con la API de paper de Alpaca con las llaves de la cuenta paper y ofrece enviar, consultar y cancelar orden, posiciones, cuenta y calendario.
2. **CA-2** · **Dado** `PROVEEDOR_BROKER=simulado`, **cuando** se envía una orden, **entonces** el simulado la acepta, la llena con el siguiente precio si cumple el límite y ejecuta las patas del bracket cuando el precio las cruza.
3. **CA-3** · **Dado** el simulado, **cuando** una prueba lo pide, **entonces** fuerza un llenado parcial, un rechazo, la falta de respuesta o un halt.
4. **CA-4** · **Dadas** las funciones `agente`, `contexto-ia` y `opinion-ia`, **cuando** CI revisa sus importaciones, **entonces** ninguna importa `_shared/broker/` (lo vigila `scripts/verificar.sh`).
5. **CA-5** · **Dada** una respuesta del broker, **cuando** se guarda en `ordenes_eventos`, **entonces** no contiene llaves (el adaptador solo devuelve datos ya validados, nunca el cuerpo crudo ni cabeceras).

### Casos borde (Edge Cases)

HU-072 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales

- **FR-158**: El sistema debe hablar con Alpaca paper solo a través de un adaptador con las operaciones enviar, consultar y cancelar orden, posiciones, cuenta y calendario. *(10 §1 · D-07 · D-44)*
- **FR-159**: La IA no ejecuta. *(`agente`, `contexto-ia` y `opinion-ia` no importan `_shared/broker/`)*

### Entidades clave

- **Orden del broker**: id del broker, `idCliente` (`client_order_id`), símbolo, lado, cantidad entera, límite, estado, cantidad y precio promedio llenados, patas.
- **Pata**: `stop_loss` u `objetivo` de un bracket, con su precio, estado y llenado.
- **Posición**: símbolo, cantidad, precio de entrada y precio actual.

## Criterios de éxito

- **SC-001**: todas las operaciones existen con la misma interfaz en Alpaca y en el simulado.
- **SC-002**: ninguna respuesta ni error del adaptador contiene las llaves.
- **SC-003**: lo que sale del alcance D-63 (fracciones, compra sin protección, venta con protección) no llega al broker.

## Supuestos

- Supuestos de `docs/01` §5 aplicables: Alpaca paper no llena órdenes con el mercado cerrado (`docs/10` §2); las pruebas usan el simulado.
- Q-12 (llenado parcial de la entrada de un bracket) sigue abierta: el simulado cancela las patas al cancelar la entrada (política provisional de `docs/10` §6).
- El estado de las órdenes simuladas vive en la memoria de la instancia; persistirlo entre invocaciones es asunto de HU-073/HU-074 (las órdenes viven en la tabla `ordenes`).
- **Fuera de esta historia**: el registro de la salud de `alpaca_trading` (`_shared/salud.ts`, `private.registrar_salud`) depende de HU-035, que se construye en otra rama; se conecta ahí. El adaptador ya lanza `ErrorDeProveedor` con `estado`, que es lo que esa función necesita. La lectura de órdenes vivas (`GET /v2/orders?status=open`) llega con HU-074.
