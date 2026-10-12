# HU-001 · Perfiles, rol actual y lecturas por rol

| Campo | Valor |
|---|---|
| Épica | [E-02 · Identidad y acceso](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Rol | Administrador |
| Prioridad | Alta |
| Módulos afectados | M-02 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-02` · `M-02` · `prioridad-alta` |

## Historia

**Como** Administrador,  
**quiero** que cada cuenta tenga un único rol y un estado guardados en la base de datos, y que cada lectura se filtre por ellos,  
**para** que nadie vea ni cambie lo que no le corresponde, aunque use una app modificada.

## Requisitos funcionales

- [FR-018 · Rol y estado en el token de sesión](../requisitos-funcionales/FR-018-rol-y-estado-en-el-token-de-sesion.md)
- [FR-019 · Autorización por perfil activo](../requisitos-funcionales/FR-019-autorizacion-por-perfil-activo.md)
- [FR-020 · Lecturas filtradas por rol y dueño](../requisitos-funcionales/FR-020-lecturas-filtradas-por-rol-y-dueno.md)

## Reglas

03 §4.1 a §4.4 · 04 §7 · 04 §8 · D-01

## Criterios de aceptación

- **CA-1** Dado un perfil con rol analista y estado activo, cuando esa persona renueva su sesión, entonces su token trae `app_rol = analista` y `app_estado = activo`.
- **CA-2** Dado un perfil suspendido con un token todavía vigente, cuando consulta cualquier tabla, entonces `private.rol_actual()` devuelve NULL y no recibe ninguna fila.
- **CA-3** Dado un Usuario, cuando consulta `perfiles`, entonces solo ve su propia fila; un Analista o un Administrador ven todas.
- **CA-4** (permiso) Dado cualquier rol, cuando intenta un `INSERT`, `UPDATE` o `DELETE` directo sobre `perfiles`, entonces la base de datos lo rechaza.
- **CA-5** Dado un token de sesión recién emitido, cuando se revisa su vencimiento, entonces dura 15 minutos (900 s).
- **CA-6** Dado un perfil cuyo rol cambió en `perfiles` y un token que todavía trae el rol anterior, cuando consulta, entonces la autorización usa el rol de `perfiles` y no el del token.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercitan E2E-01 y E2E-05.

## Tareas

- [ ] Migración: tipos `rol_app` y `estado_cuenta` y tabla `perfiles` (06 §5.1) con RLS activo.
- [ ] Migración: `private.rol_actual()` y `private.es_supervisor()`, `security definer` con `search_path = ''`.
- [ ] Migración: política de lectura de `perfiles` (la propia; los supervisores, todas) y ninguna política de escritura.
- [ ] Migración: hook `private.token_personalizado`, su registro en Auth y la duración del JWT en 900 s.
- [ ] App: `perfilProvider` en `lib/core/`, que lee los claims y la fila de `perfiles`.
- [ ] Pruebas pgTAP `rls_*` y `roles_*`: lectura por rol, cuenta no activa, escritura directa bloqueada y claims del token.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [TT-03 · Base de Supabase: esquema private, extensiones, Vault y ping](../E-01-cimientos-y-calidad-continua/TT-03-base-de-supabase-esquema-private-extensiones-vault-y-ping.md) | Usa el esquema `private` y el proyecto local. |
| Habilita | [HU-002 · Alta solo con invitación vigente](HU-002-alta-solo-con-invitacion-vigente.md) | HU-002: el trigger crea la fila de `perfiles`. |
| Habilita | [HU-010 · Suspender y reactivar una cuenta](HU-010-suspender-y-reactivar-una-cuenta.md) | HU-010: cambia `perfiles.estado`, que corta el acceso por RLS. |
| Habilita | [HU-011 · Cambiar el rol de una cuenta](HU-011-cambiar-el-rol-de-una-cuenta.md) | HU-011: cambia `perfiles.rol`. |
| Habilita | [HU-013 · Libro contable de doble partida](../E-03-fondo-y-libro-contable/HU-013-libro-contable-de-doble-partida.md) | HU-013: las subcuentas de cupo y las políticas dependen de `perfiles` y de `private.rol_actual()`. |
| Habilita | [HU-083 · Canales privados de tiempo real](../E-09-tiempo-real-y-notificaciones/HU-083-canales-privados-de-tiempo-real.md) | HU-083: las políticas usan `private.rol_actual()` y `private.es_supervisor()`. |
| Habilita | [HU-085 · Alertas del sistema por audiencia](../E-09-tiempo-real-y-notificaciones/HU-085-alertas-del-sistema-por-audiencia.md) | HU-085: las audiencias se resuelven con el rol de `perfiles`. |
| Habilita | [HU-107 · Bitácora inmutable con cadena de hash](../E-12-seguridad-auditoria-y-cumplimiento/HU-107-bitacora-inmutable-con-cadena-de-hash.md) | HU-107: usa el tipo `rol_app` y `private.rol_actual()` en su política de lectura. |

## Notas técnicas

Tabla `perfiles`. Funciones `private.rol_actual`, `private.es_supervisor` y `private.token_personalizado`. Los claims son solo para la interfaz: la autorización real consulta `perfiles` en cada operación (03 §4.1).

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
