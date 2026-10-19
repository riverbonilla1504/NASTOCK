# HU-096 · Reporte diario al Administrador

| Campo | Valor |
|---|---|
| Épica | [E-10 · Cartera y reportes](README.md) |
| Entrega (hito) | R6 · Medir y mejorar |
| Rol | Administrador |
| Prioridad | Media |
| Módulos afectados | M-15, M-17 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-10` · `M-15` · `M-17` · `prioridad-media` |

## Historia

**Como** Administrador,  
**quiero** recibir cada día un reporte con el ancla de la bitácora y los accesos denegados,  
**para** detectar una alteración del pasado o un intento de acceso indebido.

## Requisitos funcionales

- [FR-205 · Reporte diario al Administrador](../requisitos-funcionales/FR-205-reporte-diario-al-administrador.md)

## Reglas

11 §4.2 · 11 §4.3 · 14 §2 · 05 §6

## Criterios de aceptación

- **CA-1** Dado el cierre del día, cuando corre `cierre-diario`, entonces se genera el reporte diario del Administrador.
- **CA-2** Dado el reporte, cuando se revisa, entonces incluye el último hash de la bitácora de ese día.
- **CA-3** Dado el reporte, cuando se revisa, entonces incluye el resumen de accesos denegados (`NO_AUTORIZADO`) por usuario.
- **CA-4** (permiso) Dado un Usuario o un Analista, cuando intenta ver el reporte, entonces no tiene acceso.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Función `cierre-diario`: armado del reporte con el último hash del día.
- [ ] Resumen de denegaciones por usuario a partir de los registros de la API.
- [ ] Entrega del reporte al Administrador.
- [ ] Pruebas `deno test` del armado del reporte.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-107 · Bitácora inmutable con cadena de hash](../E-12-seguridad-auditoria-y-cumplimiento/HU-107-bitacora-inmutable-con-cadena-de-hash.md) | Incluye el último hash de la bitácora. |
| Depende de | [HU-021 · Foto diaria de patrimonio y rendimiento TWR](../E-03-fondo-y-libro-contable/HU-021-foto-diaria-de-patrimonio-y-rendimiento-twr.md) | Se genera en el cierre diario. |
| Depende de | [HU-086 · Bandeja de notificaciones](../E-09-tiempo-real-y-notificaciones/HU-086-bandeja-de-notificaciones.md) | Avisa al Administrador. |

## Notas técnicas

Sin notas adicionales.

## Documentación a actualizar

`docs/` no define el contenido completo del reporte, por qué canal llega al Administrador (01 §4 deja el correo para una fase posterior), dónde se guarda "fuera de la base de datos" el hash ancla (11 §4.3) ni cómo se leen las denegaciones de los registros de la API (11 §4.2). Definirlo en `docs/` antes de implementar.

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
