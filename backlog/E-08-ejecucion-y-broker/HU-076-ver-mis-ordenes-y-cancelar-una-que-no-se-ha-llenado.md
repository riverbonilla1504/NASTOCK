# HU-076 · Ver mis órdenes y cancelar una que no se ha llenado

| Campo | Valor |
|---|---|
| Épica | [E-08 · Ejecución y broker](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Usuario |
| Prioridad | Media |
| Módulos afectados | M-10 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-08` · `M-10` · `prioridad-media` |

## Historia

**Como** Usuario,  
**quiero** ver el estado de mis órdenes y cancelar una que aún no se llena,  
**para** cambiar de idea mientras la orden sigue viva.

## Requisitos funcionales

- [FR-171 · Cancelación de una orden propia](../requisitos-funcionales/FR-171-cancelacion-de-una-orden-propia.md)

## Reglas

PM-13 · 08 §2 · 09 §1

## Criterios de aceptación

- **CA-1** Dado un Usuario, cuando abre sus órdenes, entonces ve cada una con su estado (enviada, aceptada, llenada, cancelada y los demás) actualizado en vivo.
- **CA-2** Dada una orden propia aceptada y sin llenar, cuando la cancela, entonces se pide la cancelación al broker, la orden queda `cancelada`, se libera la retención y se registra `orden.cancelada`.
- **CA-3** (caso borde) CB-37: Dada una orden que se llena justo cuando la cancela, cuando llega la cancelación, entonces falla porque ya se llenó, se trata como llenada y se informa.
- **CA-4** Dada una orden parcialmente llenada, cuando la cancela, entonces se cancela el resto y lo llenado se conserva.
- **CA-5** (permiso) Dado un Usuario, cuando intenta cancelar una orden de otro cupo, entonces recibe `NO_AUTORIZADO`.

## Casos borde

CB-37

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] RPC `cancelar_orden(id)`: dueño y estado, solicitud de cancelación y auditoría.
- [ ] Funciones: envío de la cancelación al broker con `cancelarOrden` y aplicación del resultado.
- [ ] App: lista de órdenes del cupo en `lib/features/ordenes/` con su estado en vivo y el botón Cancelar.
- [ ] Pruebas pgTAP y `deno test`: cancelación, carrera con el llenado, parcial y permisos.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-075 · Crear una orden manual en mi cupo](HU-075-crear-una-orden-manual-en-mi-cupo.md) | Cancela las órdenes propias. |
| Depende de | [HU-074 · Sincronizar órdenes y aplicar llenados](HU-074-sincronizar-ordenes-y-aplicar-llenados.md) | Una orden ya llena no se cancela. |

## Notas técnicas

Sin notas adicionales.

## Documentación a actualizar

06 §8.1 dice que `cancelar_orden` "pide la cancelación", pero ni 05 §6 ni 10 §7 dicen qué función envía esa cancelación al broker. Precisarlo en `docs/`.

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
