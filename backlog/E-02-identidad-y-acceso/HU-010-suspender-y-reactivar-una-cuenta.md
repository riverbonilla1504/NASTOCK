# HU-010 · Suspender y reactivar una cuenta

| Campo | Valor |
|---|---|
| Épica | [E-02 · Identidad y acceso](README.md) |
| Entrega (hito) | R2 · El fondo existe |
| Rol | Administrador |
| Prioridad | Alta |
| Módulos afectados | M-02, M-01 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-02` · `M-02` · `M-01` · `prioridad-alta` |

## Historia

**Como** Administrador,  
**quiero** suspender una cuenta y reactivarla después,  
**para** cortar su acceso al instante cuando hay un riesgo y devolvérselo cuando pase.

## Requisitos funcionales

- [FR-029 · Suspensión de una cuenta](../requisitos-funcionales/FR-029-suspension-de-una-cuenta.md)
- [FR-030 · Cupo congelado durante la suspensión](../requisitos-funcionales/FR-030-cupo-congelado-durante-la-suspension.md)
- [FR-031 · Reactivación de una cuenta](../requisitos-funcionales/FR-031-reactivacion-de-una-cuenta.md)
- [FR-032 · Protección del último administrador y de la acción sobre uno mismo](../requisitos-funcionales/FR-032-proteccion-del-ultimo-administrador-y-de-la-accion-sobre-uno-mismo.md)
- [FR-035 · Cierre de la sesión revocada](../requisitos-funcionales/FR-035-cierre-de-la-sesion-revocada.md)

## Reglas

PM-52 · RN-50 · RN-51 · RN-57 · 04 §10 · 02 §11

## Criterios de aceptación

- **CA-1** Dada una cuenta activa, cuando el Administrador la suspende, entonces su estado pasa a suspendido, queda bloqueada en Auth, se registra `cuenta.suspendida` y sus consultas dejan de devolver datos aunque su token siga vigente.
- **CA-2** (caso borde) CB-07: Dada esa persona con la app abierta, cuando se la suspende, entonces recibe `sesion_revocada`, la app cierra la sesión y muestra el motivo.
- **CA-3** (caso borde) CB-09: Dado el último Administrador activo, cuando alguien intenta suspenderlo, entonces recibe `ULTIMO_ADMIN`; y si un Administrador intenta suspenderse a sí mismo, `AUTO_ACCION`.
- **CA-4** Dada una cuenta suspendida, cuando el Administrador la reactiva, entonces vuelve a activo, se desbloquea en Auth, se registra `cuenta.reactivada` y su cupo sigue como quedó.
- **CA-5** (permiso) Dado un Usuario o un Analista, cuando llama la función `admin-usuarios`, entonces recibe `NO_AUTORIZADO`.

## Casos borde

CB-07, CB-09

## Escenario E2E

E2E-05 (nuevo)

## Tareas

- [ ] Migración: `private.suspender_cuenta` y `private.reactivar_cuenta` con el cambio de estado, la auditoría y las reglas RN-50 y RN-51.
- [ ] Función `admin-usuarios`: verifica el JWT y el rol de Administrador, llama la función privada, bloquea o desbloquea en Auth con la API de administración y publica `sesion_revocada`.
- [ ] App: `lib/core/` escucha `sesion_revocada` en `usuario:{id}`, cierra canales y sesión y muestra el motivo.
- [ ] Pruebas pgTAP `roles_*`: último administrador, acción sobre uno mismo y rol sin permiso.
- [ ] Pruebas de función de `admin-usuarios`.
- [ ] E2E-05 de backend: al suspender a un Usuario, pierde el acceso al instante.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-001 · Perfiles, rol actual y lecturas por rol](HU-001-perfiles-rol-actual-y-lecturas-por-rol.md) | Cambia `perfiles.estado`, que corta el acceso por RLS. |
| Depende de | [HU-083 · Canales privados de tiempo real](../E-09-tiempo-real-y-notificaciones/HU-083-canales-privados-de-tiempo-real.md) | Publica `sesion_revocada` en el canal de la persona. |
| Depende de | [HU-084 · Gestor de tiempo real en la app](../E-09-tiempo-real-y-notificaciones/HU-084-gestor-de-tiempo-real-en-la-app.md) | La app escucha su canal para cerrar la sesión. |
| Depende de | [HU-107 · Bitácora inmutable con cadena de hash](../E-12-seguridad-auditoria-y-cumplimiento/HU-107-bitacora-inmutable-con-cadena-de-hash.md) | Registra `cuenta.suspendida` y `cuenta.reactivada`. |
| Habilita | [HU-012 · Dar de baja y reincorporar una cuenta](HU-012-dar-de-baja-y-reincorporar-una-cuenta.md) | HU-012: extiende la función `admin-usuarios` y el bloqueo en Auth. |
| Habilita | [HU-065 · Decidir en Arriesgadas con doble aprobación](../E-07-sugerencias-y-decisiones/HU-065-decidir-en-arriesgadas-con-doble-aprobacion.md) | HU-065: anula la primera aprobación al suspender. |
| Habilita | [HU-067 · Invalidación por precio y por cambio de situación](../E-07-sugerencias-y-decisiones/HU-067-invalidacion-por-precio-y-por-cambio-de-situacion.md) | HU-067: invalida las sugerencias del titular suspendido. |
| Habilita | [HU-069 · Solicitar la liquidación de un cupo](../E-07-sugerencias-y-decisiones/HU-069-solicitar-la-liquidacion-de-un-cupo.md) | HU-069: el flujo empieza con la cuenta suspendida. |
| Habilita | [HU-087 · Registrar mi dispositivo para push](../E-09-tiempo-real-y-notificaciones/HU-087-registrar-mi-dispositivo-para-push.md) | HU-087: borra los dispositivos al suspender. |
| Habilita | [HU-098 · Pantalla de usuarios e invitaciones](../E-11-administracion/HU-098-pantalla-de-usuarios-e-invitaciones.md) | HU-098: usa la función `admin-usuarios`. |
| Habilita | [HU-108 · Consultar y exportar la bitácora](../E-12-seguridad-auditoria-y-cumplimiento/HU-108-consultar-y-exportar-la-bitacora.md) | HU-108: el escenario audita una suspensión. |
| Habilita | [HU-109 · Aislamiento verificado por tabla y por función](../E-12-seguridad-auditoria-y-cumplimiento/HU-109-aislamiento-verificado-por-tabla-y-por-funcion.md) | HU-109: extiende el escenario E2E-05. |

## Notas técnicas

Al suspender también se invalidan las sugerencias vivas de la persona, se anulan sus primeras aprobaciones y se borran sus dispositivos de push (04 §10). Esas tablas llegan después: [HU-067](../E-07-sugerencias-y-decisiones/HU-067-invalidacion-por-precio-y-por-cambio-de-situacion.md), [HU-065](../E-07-sugerencias-y-decisiones/HU-065-decidir-en-arriesgadas-con-doble-aprobacion.md) y [HU-087](../E-09-tiempo-real-y-notificaciones/HU-087-registrar-mi-dispositivo-para-push.md) completan la función. Las protecciones de sus posiciones siguen activas (02 §11). La pantalla está en [HU-098](../E-11-administracion/HU-098-pantalla-de-usuarios-e-invitaciones.md).

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
