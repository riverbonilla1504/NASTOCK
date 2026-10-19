# HU-035 · Salud de las integraciones

| Campo | Valor |
|---|---|
| Épica | [E-05 · Motor de políticas y configuración](README.md) |
| Entrega (hito) | R3 · La IA analiza |
| Rol | Administrador |
| Prioridad | Alta |
| Módulos afectados | M-18 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-05` · `M-18` · `prioridad-alta` |

## Historia

**Como** Administrador,  
**quiero** saber en todo momento si cada integración está funcionando,  
**para** enterarme de una caída antes de que afecte una operación.

## Requisitos funcionales

- [FR-081 · Salud de las integraciones](../requisitos-funcionales/FR-081-salud-de-las-integraciones.md)
- [FR-082 · Alerta por integración caída](../requisitos-funcionales/FR-082-alerta-por-integracion-caida.md)
- [FR-083 · Consulta de la salud](../requisitos-funcionales/FR-083-consulta-de-la-salud.md)

## Reglas

PM-34 · RR-21 · 06 §5.6 · 08 §6 · 07 §10 · 05 §13

## Criterios de aceptación

- **CA-1** Dada una integración en `ok`, cuando falla una vez, entonces pasa a `degradado`; al tercer fallo seguido pasa a `caido`; y un éxito la devuelve a `ok` con los fallos seguidos en 0.
- **CA-2** (caso borde) CB-64: Dada una integración que pasa a `caido`, cuando ocurre, entonces se crea una alerta para Administradores y Analistas y se registra `integracion.caida`; cuando se recupera, se registra `integracion.recuperada`.
- **CA-3** Dado un cambio de estado de una integración, cuando ocurre, entonces se publica el evento `salud` en el canal `supervision`.
- **CA-4** (aislamiento) Dado un Usuario, cuando consulta `salud_integraciones`, entonces no recibe filas; un Analista y un Administrador las ven todas.

## Casos borde

CB-64

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Migración: tipo `estado_integracion` y tabla `salud_integraciones` (06 §5.6) con sus seis integraciones y RLS para Analista y Administrador.
- [ ] Migración: `private.registrar_salud(integracion, ok, error)` con la transición de estados, la alerta, la auditoría y el evento `salud`.
- [ ] Funciones: `_shared/salud.ts` y su uso en `ingesta-mercado`, `calendario-mercado` y `conciliacion`.
- [ ] Pruebas pgTAP `salud_*`: transiciones, alerta al caer, recuperación y lectura por rol.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-028 · Ingesta de precios cada 15 segundos](../E-04-datos-de-mercado/HU-028-ingesta-de-precios-cada-15-segundos.md) | La ingesta es la primera función que registra su salud. |
| Depende de | [HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25](../E-03-fondo-y-libro-contable/HU-015-confirmar-el-aporte-por-conciliacion-y-repartirlo-50-25-25.md) | La función `conciliacion` también registra su salud. |
| Depende de | [HU-085 · Alertas del sistema por audiencia](../E-09-tiempo-real-y-notificaciones/HU-085-alertas-del-sistema-por-audiencia.md) | Crea la alerta de integración caída. |
| Depende de | [HU-107 · Bitácora inmutable con cadena de hash](../E-12-seguridad-auditoria-y-cumplimiento/HU-107-bitacora-inmutable-con-cadena-de-hash.md) | Registra `integracion.caida` e `integracion.recuperada`. |
| Habilita | [HU-037 · Motor de políticas: reglas de la propuesta](HU-037-motor-de-politicas-reglas-de-la-propuesta.md) | HU-037: RR-21 mira la salud del broker y de los datos. |
| Habilita | [HU-041 · Noticias de las candidatas](../E-06-ia-contexto-y-decision/HU-041-noticias-de-las-candidatas.md) | HU-041: registra la salud de `alpaca_noticias`. |
| Habilita | [HU-045 · Adaptador de JEV y estado en etiquetas](../E-06-ia-contexto-y-decision/HU-045-adaptador-de-jev-y-estado-en-etiquetas.md) | HU-045: registra la salud de `jev`. |
| Habilita | [HU-072 · Adaptador del broker para órdenes](../E-08-ejecucion-y-broker/HU-072-adaptador-del-broker-para-ordenes.md) | HU-072: registra la salud de `alpaca_trading`. |
| Habilita | [HU-086 · Bandeja de notificaciones](../E-09-tiempo-real-y-notificaciones/HU-086-bandeja-de-notificaciones.md) | HU-086: avisa `integracion_caida`. |
| Habilita | [HU-103 · Pantalla de salud e integraciones](../E-11-administracion/HU-103-pantalla-de-salud-e-integraciones.md) | HU-103: muestra la salud que registra el sistema. |

## Notas técnicas

Con el broker o los datos de mercado en `caido` no se crean ni se envían órdenes (RR-21, en [HU-037](HU-037-motor-de-politicas-reglas-de-la-propuesta.md)). Toda función nueva que llame a un proveedor usa `_shared/salud.ts`. La pantalla está en [HU-103](../E-11-administracion/HU-103-pantalla-de-salud-e-integraciones.md).

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
