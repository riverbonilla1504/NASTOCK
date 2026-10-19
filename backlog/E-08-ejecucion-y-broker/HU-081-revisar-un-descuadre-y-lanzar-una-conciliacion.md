# HU-081 · Revisar un descuadre y lanzar una conciliación

| Campo | Valor |
|---|---|
| Épica | [E-08 · Ejecución y broker](README.md) |
| Entrega (hito) | R5 · Protegido y avisado |
| Rol | Administrador |
| Prioridad | Media |
| Módulos afectados | M-12 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-08` · `M-12` · `prioridad-media` |

## Historia

**Como** Administrador,  
**quiero** revisar el detalle de un descuadre, marcarlo como revisado y lanzar una conciliación cuando quiera,  
**para** cerrar el incidente con rastro y comprobar que el libro volvió a cuadrar.

## Requisitos funcionales

- [FR-182 · Revisión de un descuadre](../requisitos-funcionales/FR-182-revision-de-un-descuadre.md)
- [FR-183 · Conciliación manual](../requisitos-funcionales/FR-183-conciliacion-manual.md)
- [FR-184 · Consulta de conciliaciones](../requisitos-funcionales/FR-184-consulta-de-conciliaciones.md)

## Reglas

PM-34 · PM-58 · 10 §8 · 11 §8

## Criterios de aceptación

- **CA-1** Dado un descuadre crítico, cuando el Administrador lo consulta, entonces ve la diferencia de efectivo y el detalle por símbolo: cantidad en el broker, cantidad en el libro y diferencia.
- **CA-2** Dado el descuadre corregido con un ajuste, cuando el Administrador lo marca como revisado con una nota, entonces queda con quién y cuándo lo revisó y se registra `conciliacion.revisada`.
- **CA-3** Dado un Administrador, cuando llama `lanzar_conciliacion()`, entonces corre una conciliación de inmediato.
- **CA-4** (permiso) Dado un Analista, cuando consulta las conciliaciones, entonces las ve en solo lectura y recibe `NO_AUTORIZADO` si intenta marcarlas o lanzarlas; un Usuario no las ve.

## Casos borde

CB-72

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-13.

## Tareas

- [ ] RPC `marcar_conciliacion_revisada(id, nota)` y `lanzar_conciliacion()` con auditoría.
- [ ] Pruebas pgTAP: revisión, lanzamiento y permisos.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-080 · Conciliación completa con pausa automática](HU-080-conciliacion-completa-con-pausa-automatica.md) | Revisa los resultados de la conciliación. |
| Habilita | [HU-040 · Reanudar el trading solo con la conciliación en ok](../E-05-motor-de-politicas-y-configuracion/HU-040-reanudar-el-trading-solo-con-la-conciliacion-en-ok.md) | HU-040: acepta un descuadre marcado como revisado. |
| Habilita | [HU-104 · Pantalla de conciliaciones](../E-11-administracion/HU-104-pantalla-de-conciliaciones.md) | HU-104: marca descuadres y lanza conciliaciones. |

## Notas técnicas

La corrección nunca edita: usa movimientos de ajuste justificados ([HU-022](../E-03-fondo-y-libro-contable/HU-022-registrar-ajustes-contables.md)). Después de restaurar un respaldo, la conciliación y la consulta por `client_order_id` permiten reconstruir lo que falte con ajustes justificados (CB-72). La pantalla está en [HU-104](../E-11-administracion/HU-104-pantalla-de-conciliaciones.md).

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
