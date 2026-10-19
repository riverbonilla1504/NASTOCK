# HU-072 · Adaptador del broker para órdenes

| Campo | Valor |
|---|---|
| Épica | [E-08 · Ejecución y broker](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Administrador |
| Prioridad | Alta |
| Módulos afectados | M-10, M-19 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-08` · `M-10` · `M-19` · `prioridad-alta` |

## Historia

**Como** Administrador,  
**quiero** que el sistema hable con Alpaca paper a través de un adaptador que también tiene una versión simulada,  
**para** operar en paper con precios reales y poder probar a cualquier hora sin tocar la cuenta.

## Requisitos funcionales

- [FR-158 · Adaptador del broker](../requisitos-funcionales/FR-158-adaptador-del-broker.md)
- [FR-159 · La IA no ejecuta](../requisitos-funcionales/FR-159-la-ia-no-ejecuta.md)

## Reglas

10 §1 · 10 §9 · 05 §4 · 05 §6 · D-07 · D-44 · D-47 · 01 §2 (P2)

## Criterios de aceptación

- **CA-1** Dado `PROVEEDOR_BROKER=alpaca`, cuando una función usa el adaptador, entonces habla con la API de paper de Alpaca con las llaves de la cuenta paper y ofrece enviar, consultar y cancelar orden, posiciones, cuenta y calendario.
- **CA-2** Dado `PROVEEDOR_BROKER=simulado`, cuando se envía una orden, entonces el simulado la acepta, la llena con el siguiente precio si cumple el límite y ejecuta las patas del bracket cuando el precio las cruza.
- **CA-3** Dado el simulado, cuando una prueba lo pide, entonces fuerza un llenado parcial, un rechazo, la falta de respuesta o un halt.
- **CA-4** Dadas las funciones `agente`, `contexto-ia` y `opinion-ia`, cuando CI revisa sus importaciones, entonces ninguna importa `_shared/broker/`.
- **CA-5** Dada una respuesta del broker, cuando se guarda en `ordenes_eventos`, entonces no contiene llaves.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-08.

## Tareas

- [ ] Funciones: operaciones `enviarOrden`, `consultarOrden`, `cancelarOrden` y `posiciones` en `_shared/broker/` (`alpaca.ts` y `simulado.ts`), con validación zod de las respuestas.
- [ ] Simulado: llenado con el siguiente precio, patas del bracket y escenarios forzables desde el esquema `pruebas`.
- [ ] Registro de la salud de `alpaca_trading` con `_shared/salud.ts`.
- [ ] Pruebas `deno test` del adaptador real con respuestas grabadas y del simulado.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25](../E-03-fondo-y-libro-contable/HU-015-confirmar-el-aporte-por-conciliacion-y-repartirlo-50-25-25.md) | Extiende el adaptador que ya tiene `calendario` y `cuenta`. |
| Depende de | [TT-05 · Base de proveedores simulados, reloj controlable y datos de prueba](../E-01-cimientos-y-calidad-continua/TT-05-base-de-proveedores-simulados-reloj-controlable-y-datos-de-prueba.md) | El proveedor del broker se elige con `_shared/proveedores.ts`. |
| Depende de | [HU-035 · Salud de las integraciones](../E-05-motor-de-politicas-y-configuracion/HU-035-salud-de-las-integraciones.md) | Registra la salud de `alpaca_trading`. |
| Habilita | [HU-073 · Enviar al broker las órdenes aprobadas](HU-073-enviar-al-broker-las-ordenes-aprobadas.md) | HU-073: envía las órdenes con el adaptador del broker. |

## Notas técnicas

Solo paper trading: no hay nada de dinero real (D-44). Alpaca paper no llena órdenes con el mercado cerrado: las pruebas y las demostraciones fuera de horario usan el simulado (10 §2). Las llaves viven solo en los secretos de las Edge Functions.

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
