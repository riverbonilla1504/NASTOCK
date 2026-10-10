# HU-110 · Verificación semanal de la cadena de hash

| Campo | Valor |
|---|---|
| Épica | [E-12 · Seguridad, auditoría y cumplimiento](README.md) |
| Entrega (hito) | R6 · Medir y mejorar |
| Rol | Administrador |
| Prioridad | Media |
| Módulos afectados | M-17 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-12` · `M-17` · `prioridad-media` |

## Historia

**Como** Administrador,  
**quiero** que el sistema revise cada semana que la bitácora no fue alterada,  
**para** enterarme si alguien modificó el pasado.

## Requisitos funcionales

- [FR-220 · Verificación semanal de la cadena](../requisitos-funcionales/FR-220-verificacion-semanal-de-la-cadena.md)

## Reglas

11 §4.3

## Criterios de aceptación

- **CA-1** Dada la bitácora íntegra, cuando corre el trabajo semanal, entonces recalcula la cadena completa y no genera ninguna alerta.
- **CA-2** Dado un registro alterado directamente en la base de datos, cuando corre el trabajo, entonces detecta la ruptura y crea una alerta crítica.
- **CA-3** Dado el trabajo, cuando se programa, entonces corre una vez por semana sin intervención.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Migración: trabajo semanal de `pg_cron` que llama la función de verificación.
- [ ] Alerta crítica cuando la cadena se rompe.
- [ ] Pruebas pgTAP con una cadena íntegra y con una alterada.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-108 · Consultar y exportar la bitácora](HU-108-consultar-y-exportar-la-bitacora.md) | Usa la función que verifica la cadena. |
| Depende de | [HU-085 · Alertas del sistema por audiencia](../E-09-tiempo-real-y-notificaciones/HU-085-alertas-del-sistema-por-audiencia.md) | Crea la alerta crítica. |
| Habilita | [HU-114 · Lista de verificación antes de abrir el MVP al equipo](HU-114-lista-de-verificacion-antes-de-abrir-el-mvp-al-equipo.md) | HU-114: exige la bitácora verificada. |

## Notas técnicas

Sin notas adicionales.

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
