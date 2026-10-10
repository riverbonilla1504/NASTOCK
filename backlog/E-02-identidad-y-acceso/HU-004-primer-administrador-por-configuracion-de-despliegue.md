# HU-004 · Primer administrador por configuración de despliegue

| Campo | Valor |
|---|---|
| Épica | [E-02 · Identidad y acceso](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Rol | Administrador |
| Prioridad | Alta |
| Módulos afectados | M-01 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-02` · `M-01` · `prioridad-alta` |

## Historia

**Como** Administrador,  
**quiero** que mi primera invitación la cree el despliegue a partir de un correo configurado,  
**para** poder entrar sin que existan credenciales de administrador en el código.

## Requisitos funcionales

- [FR-017 · Primer administrador por configuración de despliegue](../requisitos-funcionales/FR-017-primer-administrador-por-configuracion-de-despliegue.md)

## Reglas

04 §9 · 11 §10 · Q-08

## Criterios de aceptación

- **CA-1** Dado que no existe ningún Administrador y `ADMIN_INICIAL_EMAIL` tiene un correo, cuando se aplica la migración de arranque, entonces existe una invitación pendiente de Administrador para ese correo con vencimiento a 7 días.
- **CA-2** Dado que ya existe al menos un Administrador, cuando la migración se aplica otra vez, entonces no crea ninguna invitación.
- **CA-3** Dada esa invitación, cuando la persona ingresa con Google, entonces queda como Administrador activo.
- **CA-4** Dado el código de la app y del repositorio, cuando se revisa, entonces no contiene ningún usuario ni contraseña de administrador.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Migración de arranque idempotente: lee `ADMIN_INICIAL_EMAIL` de la configuración del entorno y crea la invitación con `creada_por` nulo.
- [ ] Configurar `ADMIN_INICIAL_EMAIL` en local y en el proyecto MVP con el correo definido en Q-08.
- [ ] Pruebas pgTAP: crea la invitación cuando no hay administradores y no hace nada cuando ya hay uno.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-002 · Alta solo con invitación vigente](HU-002-alta-solo-con-invitacion-vigente.md) | Usa la tabla `invitaciones` y el alta por invitación. |

## Notas técnicas

Reemplaza el usuario fijo de la v2 (`admin@admin.com`). `invitaciones.creada_por` es nulo solo para esta invitación (06 §5.1).

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
