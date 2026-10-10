# HU-083 · Canales privados de tiempo real

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
**quiero** que cada persona solo pueda escuchar los canales en vivo de su rol y que los eventos no lleven montos,  
**para** ver los cambios al instante sin que nadie reciba información que no le toca.

## Requisitos funcionales

- [FR-186 · Canales privados por rol](../requisitos-funcionales/FR-186-canales-privados-por-rol.md)
- [FR-187 · Eventos sin montos](../requisitos-funcionales/FR-187-eventos-sin-montos.md)

## Reglas

09 §3 · 09 §4 · 03 §4.6 · D-14 · D-32

## Criterios de aceptación

- **CA-1** Dada una persona activa, cuando se suscribe a `mercado`, a `fondo` y a `usuario:{su id}`, entonces la suscripción se acepta.
- **CA-2** (aislamiento) Dado un Usuario, cuando intenta suscribirse a `usuario:{otro id}`, a `supervision` o a `admin`, entonces la suscripción se rechaza; un Analista entra a `supervision` y solo un Administrador entra a `admin`.
- **CA-3** (permiso) Dado un cliente con sesión, cuando intenta publicar en cualquier canal, entonces se rechaza: solo la base de datos publica.
- **CA-4** Dado un evento de entidad, cuando se publica, entonces su carga trae solo tabla, id, versión y estado, sin montos.
- **CA-5** Dada una cuenta suspendida, cuando intenta suscribirse, entonces todas las suscripciones se rechazan.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercitan E2E-03 y E2E-08.

## Tareas

- [ ] Migración: política `canales_permitidos` sobre `realtime.messages` (09 §3), sin política de `INSERT`.
- [ ] Migración: `private.publicar_evento(topico, evento, carga)` como envoltura de `realtime.send`.
- [ ] Convención de la carga de los eventos de entidad (`tabla`, `id`, `version` y `estado`) para los triggers de las demás historias.
- [ ] Pruebas pgTAP `realtime_*`: cada canal por rol, cuenta no activa y publicación de clientes bloqueada.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-001 · Perfiles, rol actual y lecturas por rol](../E-02-identidad-y-acceso/HU-001-perfiles-rol-actual-y-lecturas-por-rol.md) | Las políticas usan `private.rol_actual()` y `private.es_supervisor()`. |
| Habilita | [HU-003 · Invitar a una persona y revocar invitaciones](../E-02-identidad-y-acceso/HU-003-invitar-a-una-persona-y-revocar-invitaciones.md) | HU-003: publica el evento `invitacion` en el canal `admin`. |
| Habilita | [HU-010 · Suspender y reactivar una cuenta](../E-02-identidad-y-acceso/HU-010-suspender-y-reactivar-una-cuenta.md) | HU-010: publica `sesion_revocada` en el canal de la persona. |
| Habilita | [HU-014 · Registrar y anular aportes](../E-03-fondo-y-libro-contable/HU-014-registrar-y-anular-aportes.md) | HU-014: publica el evento `capital` en el canal `admin`. |
| Habilita | [HU-028 · Ingesta de precios cada 15 segundos](../E-04-datos-de-mercado/HU-028-ingesta-de-precios-cada-15-segundos.md) | HU-028: publica en el canal `mercado`. |
| Habilita | [HU-033 · Parámetros configurables con rango e historial](../E-05-motor-de-politicas-y-configuracion/HU-033-parametros-configurables-con-rango-e-historial.md) | HU-033: publica `parametro` en el canal `admin`. |
| Habilita | [HU-034 · Encender y apagar los interruptores del fondo](../E-05-motor-de-politicas-y-configuracion/HU-034-encender-y-apagar-los-interruptores-del-fondo.md) | HU-034: publica `interruptor` en el canal `admin`. |
| Habilita | [HU-084 · Gestor de tiempo real en la app](HU-084-gestor-de-tiempo-real-en-la-app.md) | HU-084: se suscribe a los canales privados. |
| Habilita | [HU-085 · Alertas del sistema por audiencia](HU-085-alertas-del-sistema-por-audiencia.md) | HU-085: publica el evento `alerta`. |

## Notas técnicas

Cada historia que cambia algo visible en vivo publica su evento con `private.publicar_evento` en el canal que le corresponde (14 §6). Supabase borra los mensajes a las 72 horas.

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
