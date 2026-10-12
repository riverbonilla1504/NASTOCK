# HU-003 · Invitar a una persona y revocar invitaciones

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
**quiero** invitar a una persona con su correo, su rol y su cupo inicial, y revocar una invitación,  
**para** decidir quién entra a la plataforma y con qué rol.

## Requisitos funcionales

- [FR-015 · Invitación de una persona](../requisitos-funcionales/FR-015-invitacion-de-una-persona.md)
- [FR-016 · Revocación y vencimiento de invitaciones](../requisitos-funcionales/FR-016-revocacion-y-vencimiento-de-invitaciones.md)
- [FR-019 · Autorización por perfil activo](../requisitos-funcionales/FR-019-autorizacion-por-perfil-activo.md)

## Reglas

PM-50 · 03 §4.4 · 04 §4.1 · 08 §5

## Criterios de aceptación

- **CA-1** Dado un Administrador activo, cuando invita un correo con un rol y un cupo inicial, entonces se crea una invitación pendiente que vence en 7 días y se registra `cuenta.invitada`.
- **CA-2** (caso borde) CB-04: Dado un correo con una invitación pendiente, cuando el Administrador lo invita de nuevo, entonces recibe `INVITACION_DUPLICADA`; puede revocar la vigente y crear otra.
- **CA-3** (caso borde) CB-03: Dado un correo que ya tiene cuenta, cuando el Administrador lo invita, entonces recibe `CORREO_YA_REGISTRADO`.
- **CA-4** Dada una invitación pendiente, cuando el Administrador la revoca, entonces pasa a revocada, se registra `cuenta.invitacion_revocada` y ese correo ya no puede ingresar.
- **CA-5** (permiso) Dado un Usuario o un Analista, cuando llama `invitar_usuario` o `revocar_invitacion`, entonces recibe `NO_AUTORIZADO`.
- **CA-6** (caso borde) CB-02: Dada una invitación pendiente con más de 7 días, cuando su correo intenta ingresar, entonces no puede entrar; y cuando el Administrador invita de nuevo ese correo, entonces se crea una invitación nueva.
- **CA-7** (permiso) Dado un Administrador suspendido con un token todavía vigente, cuando llama `invitar_usuario` o `revocar_invitacion`, entonces la función la rechaza por no tener una sesión activa.

## Casos borde

CB-02, CB-03, CB-04

## Escenario E2E

E2E-02 (actualizado)

## Tareas

- [ ] RPC `invitar_usuario(email, rol, cupo_inicial)` y `revocar_invitacion(id)`: validan rol, duplicado y cuenta existente, auditan y publican el evento `invitacion` en el canal `admin`.
- [ ] App: formulario de invitación y lista de invitaciones en `lib/features/admin/usuarios/`.
- [ ] Pruebas pgTAP: invitación válida, duplicada, correo ya registrado, revocación y rol sin permiso.
- [ ] E2E-02 actualizado: invitar, entrar con la invitación y comprobar que una invitación revocada no deja entrar.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-002 · Alta solo con invitación vigente](HU-002-alta-solo-con-invitacion-vigente.md) | Crea la tabla `invitaciones` y el hook que la consulta. |
| Depende de | [HU-083 · Canales privados de tiempo real](../E-09-tiempo-real-y-notificaciones/HU-083-canales-privados-de-tiempo-real.md) | Publica el evento `invitacion` en el canal `admin`. |
| Habilita | [HU-098 · Pantalla de usuarios e invitaciones](../E-11-administracion/HU-098-pantalla-de-usuarios-e-invitaciones.md) | HU-098: incluye el formulario y la lista de invitaciones. |

## Notas técnicas

El sistema no envía correos de invitación: el Administrador avisa por los canales internos (04 §4.1). El cupo inicial es solo una intención hasta que la persona acepta (02 §11). La pantalla completa de cuentas está en [HU-098](../E-11-administracion/HU-098-pantalla-de-usuarios-e-invitaciones.md).

## Documentación a actualizar

08 §5 define que una invitación pasa de pendiente a vencida a los 7 días, pero `docs/` no dice qué proceso la marca como vencida. 06 §5.1 permite una sola invitación pendiente por correo y CB-02 pide que el Administrador cree una nueva. Precisarlo en `docs/` antes de implementar.

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
