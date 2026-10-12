# HU-019 · Ver mi cupo

| Campo | Valor |
|---|---|
| Épica | [E-03 · Fondo y libro contable](README.md) |
| Entrega (hito) | R2 · El fondo existe |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-15, M-04 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-03` · `M-15` · `M-04` · `prioridad-alta` |

## Historia

**Como** Usuario,  
**quiero** ver cuánto dinero tengo en mi cupo y cuánto puedo invertir,  
**para** saber con qué cuento antes de decidir.

## Requisitos funcionales

- [FR-052 · Consulta de mi cupo](../requisitos-funcionales/FR-052-consulta-de-mi-cupo.md)
- [FR-047 · Fondo sin capital](../requisitos-funcionales/FR-047-fondo-sin-capital.md)

## Reglas

PM-10 · RN-11 · RN-20 · 02 §2 · 02 §13 · 06 §6

## Criterios de aceptación

- **CA-1** Dado un Usuario con 400 asignados, cuando abre Mi cupo, entonces ve efectivo 400,00, retenido 0,00, disponible 400,00 y patrimonio 400,00.
- **CA-2** Dado que el Administrador le asigna o le reduce dinero, cuando ocurre, entonces Mi cupo se actualiza solo al recibir el evento `cupo`.
- **CA-3** (aislamiento) Dados dos Usuarios, cuando cada uno llama `mi_cupo()`, entonces cada uno recibe solo su cupo y ninguno puede leer la subcuenta del otro por la API.
- **CA-4** (caso borde) CB-80: Dado el fondo sin capital, cuando el Usuario abre la app, entonces ve "Fondo sin capital".
- **CA-5** Dado un Usuario, cuando abre Mi cupo, entonces ve además el resultado realizado, el no realizado y el rendimiento de su cupo.

## Casos borde

CB-80

## Escenario E2E

E2E-04 (actualizado)

## Tareas

- [ ] RPC `mi_cupo()`: efectivo, retenido, disponible, patrimonio, resultado realizado y no realizado y rendimiento del cupo.
- [ ] App: pantalla Mi cupo en `lib/features/cupo/` con `miCupoProvider` (foto y eventos del canal `usuario:{id}`).
- [ ] App: estado "Fondo sin capital" mientras no hay un aporte confirmado.
- [ ] Pruebas pgTAP de `mi_cupo()` y pruebas de widget de la pantalla.
- [ ] E2E-04 actualizado: el Usuario ve su cupo asignado en Mi cupo.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-018 · Asignar y reducir cupos](HU-018-asignar-y-reducir-cupos.md) | Muestra el dinero que se asigna al cupo. |
| Depende de | [HU-006 · Navegación y guardas según el rol](../E-02-identidad-y-acceso/HU-006-navegacion-y-guardas-segun-el-rol.md) | La pantalla cuelga del menú del Usuario. |
| Depende de | [HU-084 · Gestor de tiempo real en la app](../E-09-tiempo-real-y-notificaciones/HU-084-gestor-de-tiempo-real-en-la-app.md) | Se actualiza con el patrón foto y eventos. |
| Habilita | [HU-075 · Crear una orden manual en mi cupo](../E-08-ejecucion-y-broker/HU-075-crear-una-orden-manual-en-mi-cupo.md) | HU-075: opera sobre el disponible del cupo. |
| Habilita | [HU-091 · Ver mis posiciones y sus protecciones](../E-10-cartera-y-reportes/HU-091-ver-mis-posiciones-y-sus-protecciones.md) | HU-091: extiende la pantalla Mi cupo. |
| Habilita | [HU-093 · Ver el historial de operaciones](../E-10-cartera-y-reportes/HU-093-ver-el-historial-de-operaciones.md) | HU-093: extiende la pantalla Mi cupo. |

## Notas técnicas

Las posiciones, las protecciones y el historial se agregan en [HU-091](../E-10-cartera-y-reportes/HU-091-ver-mis-posiciones-y-sus-protecciones.md) y [HU-093](../E-10-cartera-y-reportes/HU-093-ver-el-historial-de-operaciones.md). El rendimiento TWR usa las fotos de [HU-021](HU-021-foto-diaria-de-patrimonio-y-rendimiento-twr.md).

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
