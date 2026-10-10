# HU-113 · Simulacro de restauración de un respaldo

| Campo | Valor |
|---|---|
| Épica | [E-12 · Seguridad, auditoría y cumplimiento](README.md) |
| Entrega (hito) | R6 · Medir y mejorar |
| Rol | Administrador |
| Prioridad | Media |
| Módulos afectados | M-20 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-12` · `M-20` · `prioridad-media` |

## Historia

**Como** Administrador,  
**quiero** comprobar que un respaldo se puede descifrar y restaurar,  
**para** saber que el fondo se puede recuperar si se pierde la base de datos.

## Requisitos funcionales

- [FR-010 · Respaldo diario cifrado](../requisitos-funcionales/FR-010-respaldo-diario-cifrado.md)

## Reglas

11 §7 · 11 §10 · D-55

## Criterios de aceptación

- **CA-1** Dado el respaldo cifrado más reciente, cuando se descifra con la clave guardada fuera de GitHub, entonces se obtiene el volcado completo.
- **CA-2** Dado el volcado, cuando se restaura en un Supabase local, entonces la base levanta y las pruebas pgTAP del libro pasan sobre los datos restaurados.
- **CA-3** (caso borde) CB-72: Dada la base restaurada, cuando se concilia contra la cuenta paper, entonces las diferencias quedan documentadas.
- **CA-4** Dado el simulacro, cuando termina, entonces quedan anotados los pasos y el tiempo de recuperación, para compararlo con el objetivo de 4 horas.

## Casos borde

CB-72

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Descifrar el último artefacto de respaldo y restaurarlo en local.
- [ ] Correr las pruebas del libro y una conciliación sobre los datos restaurados.
- [ ] Documentar los pasos, el tiempo y los problemas; registrar en `docs/errores-conocidos.md` lo que no fue obvio.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [TT-09 · Mantenimiento: ping diario, respaldo cifrado y prueba real semanal](../E-01-cimientos-y-calidad-continua/TT-09-mantenimiento-ping-diario-respaldo-cifrado-y-prueba-real-semanal.md) | Usa el respaldo cifrado diario. |
| Depende de | [HU-080 · Conciliación completa con pausa automática](../E-08-ejecucion-y-broker/HU-080-conciliacion-completa-con-pausa-automatica.md) | Concilia la base restaurada contra el broker. |
| Habilita | [HU-114 · Lista de verificación antes de abrir el MVP al equipo](HU-114-lista-de-verificacion-antes-de-abrir-el-mvp-al-equipo.md) | HU-114: exige el simulacro de restauración hecho. |

## Notas técnicas

Objetivos: perder como máximo 24 horas de datos y recuperar en 4 horas o menos (11 §7). El simulacro se repite una vez al mes.

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
