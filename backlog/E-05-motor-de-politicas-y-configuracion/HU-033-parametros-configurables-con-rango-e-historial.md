# HU-033 · Parámetros configurables con rango e historial

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
**quiero** cambiar los parámetros del sistema dentro de su rango y con su historial,  
**para** ajustar el comportamiento sin desplegar código y sabiendo quién cambió qué.

## Requisitos funcionales

- [FR-076 · Cambio de un parámetro](../requisitos-funcionales/FR-076-cambio-de-un-parametro.md)
- [FR-077 · Porcentajes de reparto consistentes](../requisitos-funcionales/FR-077-porcentajes-de-reparto-consistentes.md)
- [FR-078 · Consulta de parámetros vigentes](../requisitos-funcionales/FR-078-consulta-de-parametros-vigentes.md)

## Reglas

PM-54 · PM-06 · RN-02 · 02 §10 · 06 §5.6

## Criterios de aceptación

- **CA-1** Dado un Administrador, cuando cambia `sugerencias.minutos_vencimiento` de 30 a 45 con un motivo, entonces el parámetro se actualiza, `parametros_historial` guarda el valor anterior, el nuevo y el motivo, y se registra `parametro.cambiado`.
- **CA-2** Dado un valor fuera del rango del parámetro, cuando se intenta guardar, entonces responde `PARAMETRO_FUERA_DE_RANGO`.
- **CA-3** (caso borde) CB-78: Dados unos porcentajes de reparto que no suman 100, cuando se intentan guardar, entonces responde `PARAMETRO_FUERA_DE_RANGO`: los tres se cambian juntos en una sola operación.
- **CA-4** (caso borde) CB-75: Dado un cambio válido del 50/25/25, cuando se guarda, entonces no se mueve dinero existente.
- **CA-5** (permiso) Dado un Usuario o un Analista, cuando llama `actualizar_parametro`, entonces recibe `NO_AUTORIZADO`; ambos pueden leer los parámetros vigentes, pero no `parametros_historial`.

## Casos borde

CB-75, CB-78

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Migración: catálogo completo de 02 §10 en `parametros` con tipo, mínimo, máximo y descripción, y tabla `parametros_historial` con RLS solo para el Administrador.
- [ ] RPC `actualizar_parametro(clave, valor, motivo)`: valida rango y tipo, guarda el historial, audita y publica `parametro` en el canal `admin`.
- [ ] Cambio conjunto de los tres `reparto.pct_*` con la validación de que suman 100.
- [ ] Pruebas pgTAP `politicas_*`: rango, suma 100, historial, lectura y permisos.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-002 · Alta solo con invitación vigente](../E-02-identidad-y-acceso/HU-002-alta-solo-con-invitacion-vigente.md) | La tabla `parametros` nace con el hook de alta. |
| Depende de | [HU-107 · Bitácora inmutable con cadena de hash](../E-12-seguridad-auditoria-y-cumplimiento/HU-107-bitacora-inmutable-con-cadena-de-hash.md) | Registra `parametro.cambiado`. |
| Depende de | [HU-083 · Canales privados de tiempo real](../E-09-tiempo-real-y-notificaciones/HU-083-canales-privados-de-tiempo-real.md) | Publica `parametro` en el canal `admin`. |
| Habilita | [HU-037 · Motor de políticas: reglas de la propuesta](HU-037-motor-de-politicas-reglas-de-la-propuesta.md) | HU-037: lee los límites del catálogo de parámetros. |
| Habilita | [HU-046 · Ciclo del agente: programación, uno a la vez y omisiones](../E-06-ia-contexto-y-decision/HU-046-ciclo-del-agente-programacion-uno-a-la-vez-y-omisiones.md) | HU-046: lee la frecuencia y los umbrales del catálogo. |
| Habilita | [HU-054 · Versiones del prompt de contexto y de la configuración de decisión](../E-06-ia-contexto-y-decision/HU-054-versiones-del-prompt-de-contexto-y-de-la-configuracion-de-decision.md) | HU-054: los modelos se cambian como parámetros. |
| Habilita | [HU-101 · Pantalla de parámetros e interruptores](../E-11-administracion/HU-101-pantalla-de-parametros-e-interruptores.md) | HU-101: cambia los parámetros. |
| Habilita | [HU-108 · Consultar y exportar la bitácora](../E-12-seguridad-auditoria-y-cumplimiento/HU-108-consultar-y-exportar-la-bitacora.md) | HU-108: el escenario audita un cambio de parámetro. |

## Notas técnicas

Cada sugerencia y cada orden congela los parámetros con los que se validó (RN-39). La lista de modelos permitidos (CB-79) se cubre en [HU-054](../E-06-ia-contexto-y-decision/HU-054-versiones-del-prompt-de-contexto-y-de-la-configuracion-de-decision.md). La pantalla está en [HU-101](../E-11-administracion/HU-101-pantalla-de-parametros-e-interruptores.md).

## Documentación a actualizar

06 §8 define `actualizar_parametro(clave, valor, motivo)` para una sola clave, y CB-78 exige cambiar los tres porcentajes de reparto en una sola operación. Precisar en `docs/` cómo se hace ese cambio conjunto.

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
