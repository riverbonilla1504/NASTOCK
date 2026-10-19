# HU-020 · Ver el resumen del fondo por bolsillos

| Campo | Valor |
|---|---|
| Épica | [E-03 · Fondo y libro contable](README.md) |
| Entrega (hito) | R2 · El fondo existe |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-15 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-03` · `M-15` · `prioridad-alta` |

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** ver el patrimonio del fondo y el peso de cada bolsillo,  
**para** entender cómo está repartido el dinero de RiTech.

## Requisitos funcionales

- [FR-053 · Resumen agregado del fondo](../requisitos-funcionales/FR-053-resumen-agregado-del-fondo.md)

## Reglas

PM-30 · D-22 · 02 §13 · 06 §6 · Q-04

## Criterios de aceptación

- **CA-1** Dado el fondo con un aporte confirmado de 10.000, cuando cualquier persona activa abre Fondo, entonces ve por bolsillo el efectivo, el valor de las posiciones, el patrimonio, el peso actual y el peso objetivo (50 / 25 / 25).
- **CA-2** (aislamiento) Dado un Usuario, cuando llama `resumen_fondo()`, entonces recibe solo agregados por bolsillo: ningún cupo individual ni ningún nombre.
- **CA-3** Dado un movimiento del libro, cuando ocurre, entonces el evento `resumen_cambio` del canal `fondo` actualiza la pantalla sin recargar.
- **CA-4** Dada una cuenta suspendida, cuando llama `resumen_fondo()`, entonces no recibe datos.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] RPC `resumen_fondo()` `security definer` con los agregados por bolsillo.
- [ ] Migración: trigger que publica `resumen_cambio` en el canal `fondo` cuando cambian los saldos.
- [ ] App: pantalla Fondo (resumen) en `lib/features/fondo/` con `resumenFondoProvider`.
- [ ] Pruebas pgTAP (agregados correctos, sin filas individuales, cuenta no activa) y pruebas de widget.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25](HU-015-confirmar-el-aporte-por-conciliacion-y-repartirlo-50-25-25.md) | Hay saldos por bolsillo desde el primer aporte confirmado. |
| Depende de | [HU-006 · Navegación y guardas según el rol](../E-02-identidad-y-acceso/HU-006-navegacion-y-guardas-segun-el-rol.md) | La pantalla cuelga del menú de los tres roles. |
| Depende de | [HU-084 · Gestor de tiempo real en la app](../E-09-tiempo-real-y-notificaciones/HU-084-gestor-de-tiempo-real-en-la-app.md) | Se actualiza con el patrón foto y eventos. |
| Habilita | [HU-092 · Ver el detalle del fondo](../E-10-cartera-y-reportes/HU-092-ver-el-detalle-del-fondo.md) | HU-092: extiende la pantalla Fondo. |

## Notas técnicas

Es una función y no una vista porque Supabase desaconseja las vistas `security definer` (06 §6). El detalle para Analistas y Administradores está en [HU-092](../E-10-cartera-y-reportes/HU-092-ver-el-detalle-del-fondo.md).

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
