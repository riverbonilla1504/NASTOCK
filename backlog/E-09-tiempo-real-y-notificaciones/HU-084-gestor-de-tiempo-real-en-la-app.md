# HU-084 · Gestor de tiempo real en la app

| Campo | Valor |
|---|---|
| Épica | [E-09 · Tiempo real y notificaciones](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-13 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-09` · `M-13` · `prioridad-alta` |

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** que las pantallas se actualicen solas y me avisen si pierdo la conexión,  
**para** confiar en que lo que veo está al día.

## Requisitos funcionales

- [FR-188 · Actualización en vivo con foto y eventos](../requisitos-funcionales/FR-188-actualizacion-en-vivo-con-foto-y-eventos.md)
- [FR-189 · Indicador de conexión](../requisitos-funcionales/FR-189-indicador-de-conexion.md)
- [FR-190 · Reloj corregido con el servidor](../requisitos-funcionales/FR-190-reloj-corregido-con-el-servidor.md)

## Reglas

08 §9 · 09 §7 · 05 §9.2

## Criterios de aceptación

- **CA-1** Dada una sesión iniciada, cuando la app arranca, entonces abre los canales de su rol: todos abren `mercado`, `fondo` y `usuario:{id}`; el Analista, además, `supervision`; y el Administrador, además, `supervision` y `admin`.
- **CA-2** Dado un evento con una versión menor o igual a la que la app ya tiene, cuando llega, entonces se ignora; con una versión mayor, la app pide ese registro por la API.
- **CA-3** (caso borde) CB-66: Dada una pérdida de conexión, cuando ocurre, entonces la app muestra "Reconectando…" con los datos atenuados y, al reconectar, pide otra vez las fotos completas.
- **CA-4** Dado el estado sin conexión, cuando la persona ve una pantalla con decisiones, entonces los botones de decisión quedan deshabilitados.
- **CA-5** (caso borde) CB-70: Dado un teléfono con el reloj desfasado, cuando se muestra una cuenta regresiva, entonces usa el desfase medido contra el servidor.

## Casos borde

CB-66, CB-70

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-03.

## Tareas

- [ ] App: `lib/core/realtime/` con el gestor de canales por rol y el ciclo de vida de 09 §7.
- [ ] App: patrón foto y eventos reutilizable por los repositorios (08 §9.2).
- [ ] App: `conexionProvider` con la barra de estado de la conexión y `relojProvider` con el desfase contra el servidor.
- [ ] Pruebas unitarias del descarte por versión, de la reconexión y del reloj corregido.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-083 · Canales privados de tiempo real](HU-083-canales-privados-de-tiempo-real.md) | Se suscribe a los canales privados. |
| Depende de | [TT-04 · Esqueleto de la app Flutter para Android y web](../E-01-cimientos-y-calidad-continua/TT-04-esqueleto-de-la-app-flutter-para-android-y-web.md) | Vive en `lib/core/` de la app. |
| Depende de | [HU-005 · Ingresar con Google en Android y web](../E-02-identidad-y-acceso/HU-005-ingresar-con-google-en-android-y-web.md) | Abre los canales al iniciar sesión. |
| Habilita | [HU-010 · Suspender y reactivar una cuenta](../E-02-identidad-y-acceso/HU-010-suspender-y-reactivar-una-cuenta.md) | HU-010: la app escucha su canal para cerrar la sesión. |
| Habilita | [HU-011 · Cambiar el rol de una cuenta](../E-02-identidad-y-acceso/HU-011-cambiar-el-rol-de-una-cuenta.md) | HU-011: la app escucha `perfil_actualizado`. |
| Habilita | [HU-019 · Ver mi cupo](../E-03-fondo-y-libro-contable/HU-019-ver-mi-cupo.md) | HU-019: se actualiza con el patrón foto y eventos. |
| Habilita | [HU-020 · Ver el resumen del fondo por bolsillos](../E-03-fondo-y-libro-contable/HU-020-ver-el-resumen-del-fondo-por-bolsillos.md) | HU-020: se actualiza con el patrón foto y eventos. |
| Habilita | [HU-030 · Pantalla de mercado en vivo](../E-04-datos-de-mercado/HU-030-pantalla-de-mercado-en-vivo.md) | HU-030: consume el canal `mercado` y usa el reloj corregido. |
| Habilita | [HU-048 · Pantalla Oportunidades con la explicación de cada evaluación](../E-06-ia-contexto-y-decision/HU-048-pantalla-oportunidades-con-la-explicacion-de-cada-evaluacion.md) | HU-048: se actualiza con el patrón foto y eventos. |
| Habilita | [HU-061 · Mis sugerencias: bandeja y detalle con explicación](../E-07-sugerencias-y-decisiones/HU-061-mis-sugerencias-bandeja-y-detalle-con-explicacion.md) | HU-061: se actualiza con el patrón foto y eventos. |
| Habilita | [HU-064 · Bandeja de riesgo del Analista](../E-07-sugerencias-y-decisiones/HU-064-bandeja-de-riesgo-del-analista.md) | HU-064: se actualiza con el canal `supervision`. |
| Habilita | [HU-086 · Bandeja de notificaciones](HU-086-bandeja-de-notificaciones.md) | HU-086: la bandeja se actualiza con el patrón foto y eventos. |

## Notas técnicas

Los eventos avisan, no informan: el dato siempre se lee por la API, donde aplica RLS (09 §4). Al renovarse el token no hay que volver a suscribirse.

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
