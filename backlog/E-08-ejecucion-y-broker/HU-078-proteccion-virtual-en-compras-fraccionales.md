# HU-078 · Protección virtual en compras fraccionales

| Campo | Valor |
|---|---|
| Épica | [E-08 · Ejecución y broker](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-11, M-05 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-08` · `M-11` · `M-05` · `prioridad-alta` |

## Historia

**Como** Usuario,  
**quiero** que mi compra fraccional también tenga stop-loss y take-profit, vigilados por el sistema,  
**para** limitar mis pérdidas aunque el broker no admita protección nativa con fracciones.

## Requisitos funcionales

- [FR-174 · Protección virtual](../requisitos-funcionales/FR-174-proteccion-virtual.md)
- [FR-175 · Protecciones sin aprobación ni freno](../requisitos-funcionales/FR-175-protecciones-sin-aprobacion-ni-freno.md)
- [FR-176 · Alerta de protección virtual sin vigilancia](../requisitos-funcionales/FR-176-alerta-de-proteccion-virtual-sin-vigilancia.md)
- [FR-177 · Llenado parcial de un bracket](../requisitos-funcionales/FR-177-llenado-parcial-de-un-bracket.md)

## Reglas

RN-28 · 08 §3 · 08 §7.3 · 10 §6 · D-25 · RSG-05 · Q-12

## Criterios de aceptación

- **CA-1** Dada una compra fraccional llena, cuando se aplica el llenado, entonces existe una protección `virtual` activa con su stop y su objetivo.
- **CA-2** Dado un precio que cruza el stop o el objetivo, cuando se publican las cotizaciones, entonces `disparar_proteccion_virtual` marca la protección `disparada`, crea una venta a mercado con origen `proteccion` y la encola, sin pedir aprobación y aunque `trading_activo` esté apagado.
- **CA-3** Dada la venta por stop llena, cuando se aplica, entonces el cupo absorbe la pérdida completa y el dueño recibe `proteccion_disparada`.
- **CA-4** (caso borde) CB-44: Dados unos precios desactualizados por más de 5 minutos en horario de mercado y protecciones virtuales activas, cuando se detecta, entonces se alerta de forma crítica a sus dueños y a los Analistas.
- **CA-5** (caso borde) CB-34: Dada la entrada de un bracket llena parcialmente y luego cancelada, cuando termina, entonces se cancelan sus patas y lo llenado queda cubierto con una protección virtual con los mismos precios.

## Casos borde

CB-34, CB-44

## Escenario E2E

E2E-12 (nuevo)

## Tareas

- [ ] Migración: `private.disparar_proteccion_virtual(proteccion_id, precio)` y evaluación de las protecciones virtuales dentro de `private.publicar_cotizaciones`.
- [ ] Función `ejecutor-ordenes`: las órdenes con origen `proteccion` no miran `trading_activo` ni piden aprobación.
- [ ] Alerta crítica de protección sin vigilancia.
- [ ] Política provisional de Q-12 para el bracket llenado parcialmente.
- [ ] Pruebas pgTAP `protecciones_*` (cruce de stop y de objetivo y exención del freno) y `deno test`.
- [ ] E2E-12: la protección virtual se dispara en una compra fraccional y la pérdida la absorbe el cupo.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-074 · Sincronizar órdenes y aplicar llenados](HU-074-sincronizar-ordenes-y-aplicar-llenados.md) | La protección se activa al aplicar el llenado de la compra. |
| Depende de | [HU-028 · Ingesta de precios cada 15 segundos](../E-04-datos-de-mercado/HU-028-ingesta-de-precios-cada-15-segundos.md) | Se evalúa con cada lote de cotizaciones. |
| Depende de | [HU-085 · Alertas del sistema por audiencia](../E-09-tiempo-real-y-notificaciones/HU-085-alertas-del-sistema-por-audiencia.md) | Alerta cuando la protección no está siendo vigilada. |
| Depende de | [TT-06 · Arnés E2E de backend y de la app](../E-01-cimientos-y-calidad-continua/TT-06-arnes-e2e-de-backend-y-de-la-app.md) | Agrega el escenario E2E-12. |
| Habilita | [HU-038 · Motor de políticas completo en los cuatro momentos](../E-05-motor-de-politicas-y-configuracion/HU-038-motor-de-politicas-completo-en-los-cuatro-momentos.md) | HU-038: valida al dispararse una protección virtual. |
| Habilita | [HU-039 · Freno de emergencia](../E-05-motor-de-politicas-y-configuracion/HU-039-freno-de-emergencia.md) | HU-039: las protecciones siguen con el trading pausado. |
| Habilita | [HU-079 · Ajustar el stop y el objetivo de una posición](HU-079-ajustar-el-stop-y-el-objetivo-de-una-posicion.md) | HU-079: reemplaza la protección virtual. |

## Notas técnicas

La protección virtual no protege si el sistema está caído (RSG-05): por eso se prefieren acciones enteras. El comportamiento exacto de las patas ante un llenado parcial se confirma en el spike de Q-12.

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
