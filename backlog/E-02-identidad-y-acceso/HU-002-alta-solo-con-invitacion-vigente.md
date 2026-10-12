# HU-002 · Alta solo con invitación vigente

| Campo | Valor |
|---|---|
| Épica | [E-02 · Identidad y acceso](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Rol | Administrador |
| Prioridad | Alta |
| Módulos afectados | M-01, M-02 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-02` · `M-01` · `M-02` · `prioridad-alta` |

## Historia

**Como** Administrador,  
**quiero** que solo pueda crearse una cuenta para un correo del dominio de RiTech que tenga una invitación vigente,  
**para** que nadie ajeno a la empresa o sin invitar entre a la plataforma.

## Requisitos funcionales

- [FR-013 · Alta solo con invitación vigente](../requisitos-funcionales/FR-013-alta-solo-con-invitacion-vigente.md)
- [FR-014 · Perfil activo al aceptar la invitación](../requisitos-funcionales/FR-014-perfil-activo-al-aceptar-la-invitacion.md)
- [FR-025 · Sincronización del correo cambiado en Workspace](../requisitos-funcionales/FR-025-sincronizacion-del-correo-cambiado-en-workspace.md)
- [FR-007 · Usuarios de prueba solo en local y CI](../requisitos-funcionales/FR-007-usuarios-de-prueba-solo-en-local-y-ci.md)

## Reglas

PM-01 · RN-58 · 04 §5 · 04 §6 · 15 §3 · D-12 · D-48

## Criterios de aceptación

- **CA-1** Dado un correo con una invitación pendiente y no vencida, cuando esa persona ingresa por primera vez, entonces se crea su perfil activo con el rol de la invitación, la invitación queda aceptada y se registra `cuenta.activada`.
- **CA-2** (caso borde) CB-01: Dado un correo del dominio sin invitación, cuando intenta ingresar, entonces el usuario no se crea y recibe "Tu correo no tiene una invitación vigente. Pídele una al administrador."
- **CA-3** (caso borde) CB-02: Dada una invitación con más de 7 días, cuando su correo intenta ingresar, entonces ocurre lo mismo que sin invitación.
- **CA-4** Dado un correo de un dominio que no está en `auth.dominios_permitidos`, cuando intenta ingresar, entonces el usuario no se crea y recibe "Solo se admiten cuentas corporativas de RiTech."
- **CA-5** (caso borde) CB-92: Dado `auth.proveedores_permitidos` con solo `google`, cuando alguien intenta darse de alta con correo y contraseña, entonces el usuario no se crea y recibe "Solo puedes ingresar con tu cuenta de Google de RiTech."
- **CA-6** (caso borde) CB-05: Dado que Workspace cambió el correo de una cuenta, cuando esa persona vuelve a ingresar, entonces `perfiles.email` se actualiza y el cambio queda en la bitácora.
- **CA-7** Dado el entorno local o de CI con la semilla aplicada, cuando un usuario de prueba ingresa con correo y contraseña, entonces el ingreso se acepta.

## Casos borde

CB-01, CB-02, CB-05, CB-92

## Escenario E2E

E2E-02 (nuevo)

## Tareas

- [ ] Migración: tipo `estado_invitacion` y tabla `invitaciones` (06 §5.1) con el índice único de una invitación pendiente por correo y RLS de lectura solo para el Administrador.
- [ ] Migración: tabla `parametros` (06 §5.6) con RLS de lectura y las claves `auth.dominios_permitidos` y `auth.proveedores_permitidos`.
- [ ] Migración: `private.error_auth` y hook `private.antes_de_crear_usuario` con sus permisos para `supabase_auth_admin`.
- [ ] Migración: trigger `private.al_crear_usuario` (perfil activo, invitación aceptada y auditoría); el cupo lo agrega [HU-017](../E-03-fondo-y-libro-contable/HU-017-cupo-al-aceptar-la-invitacion.md).
- [ ] Migración: trigger que sincroniza `perfiles.email` cuando cambia en `auth.users` y lo audita.
- [ ] `seed.sql`: un usuario de prueba por rol con correo y contraseña, y `email` agregado a `auth.proveedores_permitidos` solo en la semilla.
- [ ] Pruebas pgTAP `auth_*`: hook con y sin invitación, dominio, proveedor y vencimiento.
- [ ] E2E-02 de backend: el invitado entra; el no invitado y el proveedor no permitido son rechazados con su mensaje.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-001 · Perfiles, rol actual y lecturas por rol](HU-001-perfiles-rol-actual-y-lecturas-por-rol.md) | El trigger crea la fila de `perfiles`. |
| Depende de | [HU-107 · Bitácora inmutable con cadena de hash](../E-12-seguridad-auditoria-y-cumplimiento/HU-107-bitacora-inmutable-con-cadena-de-hash.md) | El alta registra `cuenta.activada`. |
| Depende de | [TT-05 · Base de proveedores simulados, reloj controlable y datos de prueba](../E-01-cimientos-y-calidad-continua/TT-05-base-de-proveedores-simulados-reloj-controlable-y-datos-de-prueba.md) | Los usuarios de prueba viven en `seed.sql`. |
| Depende de | [TT-06 · Arnés E2E de backend y de la app](../E-01-cimientos-y-calidad-continua/TT-06-arnes-e2e-de-backend-y-de-la-app.md) | Agrega el escenario E2E-02. |
| Habilita | [HU-003 · Invitar a una persona y revocar invitaciones](HU-003-invitar-a-una-persona-y-revocar-invitaciones.md) | HU-003: crea la tabla `invitaciones` y el hook que la consulta. |
| Habilita | [HU-004 · Primer administrador por configuración de despliegue](HU-004-primer-administrador-por-configuracion-de-despliegue.md) | HU-004: usa la tabla `invitaciones` y el alta por invitación. |
| Habilita | [HU-005 · Ingresar con Google en Android y web](HU-005-ingresar-con-google-en-android-y-web.md) | HU-005: el primer ingreso depende del hook y del trigger de alta. |
| Habilita | [HU-017 · Cupo al aceptar la invitación](../E-03-fondo-y-libro-contable/HU-017-cupo-al-aceptar-la-invitacion.md) | HU-017: extiende el trigger de alta. |
| Habilita | [HU-033 · Parámetros configurables con rango e historial](../E-05-motor-de-politicas-y-configuracion/HU-033-parametros-configurables-con-rango-e-historial.md) | HU-033: la tabla `parametros` nace con el hook de alta. |

## Notas técnicas

Tablas `invitaciones` y `parametros`. El hook y el trigger se registran en `supabase/config.toml` y, en la nube, en Authentication → Hooks (04 §3, paso 7). La migración nunca agrega `email` a los proveedores permitidos.

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
