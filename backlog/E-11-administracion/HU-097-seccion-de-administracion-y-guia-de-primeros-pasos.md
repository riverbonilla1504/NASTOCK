# HU-097 · Sección de Administración y guía de primeros pasos

| Campo | Valor |
|---|---|
| Épica | [E-11 · Administración](README.md) |
| Entrega (hito) | R2 · El fondo existe |
| Rol | Administrador |
| Prioridad | Alta |
| Módulos afectados | M-16 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-11` · `M-16` · `prioridad-alta` |

## Historia

**Como** Administrador,  
**quiero** tener una sección de Administración con todo lo que gobierno y una guía cuando el fondo aún no tiene capital,  
**para** encontrar cada tarea en un solo lugar y saber por dónde empezar.

## Requisitos funcionales

- [FR-206 · Sección de Administración](../requisitos-funcionales/FR-206-seccion-de-administracion.md)
- [FR-207 · Guía de primeros pasos](../requisitos-funcionales/FR-207-guia-de-primeros-pasos.md)

## Reglas

03 §3 · 05 §9.3 · RN-11 · 08 §7.6

## Criterios de aceptación

- **CA-1** Dado un Administrador, cuando abre Administración, entonces ve las entradas Usuarios e invitaciones, Capital, Cupos, Rebalanceos, Parámetros, Lista blanca, Interruptores, Salud e integraciones, Bitácora y Prompts.
- **CA-2** (caso borde) CB-80: Dado el fondo sin capital, cuando el Administrador entra, entonces ve la guía de primeros pasos: registrar el aporte, esperar su confirmación, asignar cupos y encender los interruptores.
- **CA-3** Dado el primer aporte confirmado, cuando el Administrador vuelve a entrar, entonces la guía ya no aparece.
- **CA-4** (permiso) Dado un Usuario o un Analista, cuando abre `/admin/...`, entonces el enrutador lo lleva a `/inicio`.

## Casos borde

CB-80

## Escenario E2E

E2E-01 (actualizado)

## Tareas

- [ ] App: menú y rutas `/admin/*` en `lib/features/admin/` con la guarda de rol.
- [ ] App: guía de primeros pasos mientras no hay un aporte confirmado.
- [ ] Pruebas de widget del menú y de la guarda.
- [ ] E2E-01 actualizado: el Administrador ve Administración y los demás roles no.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-006 · Navegación y guardas según el rol](../E-02-identidad-y-acceso/HU-006-navegacion-y-guardas-segun-el-rol.md) | Cuelga de la navegación por rol. |
| Habilita | [HU-098 · Pantalla de usuarios e invitaciones](HU-098-pantalla-de-usuarios-e-invitaciones.md) | HU-098: es una entrada de la sección de Administración. |
| Habilita | [HU-099 · Pantalla de capital](HU-099-pantalla-de-capital.md) | HU-099: es una entrada de la sección de Administración. |
| Habilita | [HU-100 · Pantalla de cupos](HU-100-pantalla-de-cupos.md) | HU-100: es una entrada de la sección de Administración. |
| Habilita | [HU-101 · Pantalla de parámetros e interruptores](HU-101-pantalla-de-parametros-e-interruptores.md) | HU-101: son entradas de la sección de Administración. |
| Habilita | [HU-102 · Pantalla de lista blanca](HU-102-pantalla-de-lista-blanca.md) | HU-102: es una entrada de la sección de Administración. |
| Habilita | [HU-103 · Pantalla de salud e integraciones](HU-103-pantalla-de-salud-e-integraciones.md) | HU-103: es una entrada de la sección de Administración. |
| Habilita | [HU-105 · Pantalla de rebalanceos](HU-105-pantalla-de-rebalanceos.md) | HU-105: es una entrada de la sección de Administración. |
| Habilita | [HU-106 · Pantalla de prompts y configuraciones de decisión](HU-106-pantalla-de-prompts-y-configuraciones-de-decision.md) | HU-106: es una entrada de la sección de Administración. |
| Habilita | [HU-108 · Consultar y exportar la bitácora](../E-12-seguridad-auditoria-y-cumplimiento/HU-108-consultar-y-exportar-la-bitacora.md) | HU-108: es una entrada de la sección de Administración. |

## Notas técnicas

Cada entrada se habilita con la historia de su pantalla.

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
