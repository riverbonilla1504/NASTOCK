# Especificación de funcionalidad (Feature Specification): HU-001 · Perfiles, rol actual y lecturas por rol

**Feature Branch**: `001-perfiles-y-lecturas-por-rol`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-001 · Perfiles, rol actual y lecturas por rol", en [`backlog/E-02-identidad-y-acceso/HU-001-perfiles-rol-actual-y-lecturas-por-rol.md`](../../backlog/E-02-identidad-y-acceso/HU-001-perfiles-rol-actual-y-lecturas-por-rol.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Perfiles, rol actual y lecturas por rol (Prioridad: P1)

**Como** Administrador, **quiero** que cada cuenta tenga un único rol y un estado guardados en la base de datos, y que cada lectura se filtre por ellos, **para** que nadie vea ni cambie lo que no le corresponde, aunque use una app modificada.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R1 · Ver el mercado en vivo. Es la base de todos los permisos: hay tres roles y uno solo por persona (D-01), y los permisos se aplican en el servidor consultando el perfil de la persona, no su sesión (`docs/03` §4.1 y §4.2). Habilita siete historias: HU-002 (el trigger crea la fila de `perfiles`), HU-010 (cambia `perfiles.estado`, que corta el acceso por RLS), HU-011 (cambia `perfiles.rol`), HU-013 (las subcuentas de cupo y las políticas dependen de `perfiles` y de `private.rol_actual()`), HU-083 (las políticas usan `private.rol_actual()` y `private.es_supervisor()`), HU-085 (las audiencias se resuelven con el rol de `perfiles`) y HU-107 (usa el tipo `rol_app` y `private.rol_actual()` en su política de lectura).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas de base de datos que nombra la historia: lectura por rol, cuenta no activa, escritura directa bloqueada y datos de rol y estado en la sesión. No tiene escenario E2E propio; la ejercitan E2E-01 y E2E-05. Entrega una base donde cada cuenta tiene un rol y un estado, y cada lectura se filtra por ellos.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** un perfil con rol analista y estado activo, **cuando** esa persona renueva su sesión, **entonces** su token trae `app_rol = analista` y `app_estado = activo`.
2. **CA-2** · **Dado** un perfil suspendido con un token todavía vigente, **cuando** consulta cualquier tabla, **entonces** `private.rol_actual()` devuelve NULL y no recibe ninguna fila.
3. **CA-3** · **Dado** un Usuario, **cuando** consulta `perfiles`, **entonces** solo ve su propia fila; un Analista o un Administrador ven todas.
4. **CA-4** (permiso) · **Dado** cualquier rol, **cuando** intenta un `INSERT`, `UPDATE` o `DELETE` directo sobre `perfiles`, **entonces** la base de datos lo rechaza.
5. **CA-5** · **Dado** un token de sesión recién emitido, **cuando** se revisa su vencimiento, **entonces** dura 15 minutos (900 s).
6. **CA-6** · **Dado** un perfil cuyo rol cambió en `perfiles` y un token que todavía trae el rol anterior, **cuando** consulta, **entonces** la autorización usa el rol de `perfiles` y no el del token.

---

### Casos borde (Edge Cases)

HU-001 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-018**: El sistema debe agregar al token de sesión los claims `app_rol` y `app_estado` leídos de `perfiles`, con una duración del token de 15 minutos. *(Rol y estado en el token de sesión · actores: Sistema · fuente: 04 §7 · 04 §8 · 03 §4.1)*
- **FR-019**: El sistema debe autorizar cada lectura y cada escritura consultando el rol y el estado en `perfiles`, no los claims del token, y debe negar todo acceso a una cuenta que no esté activa. *(Autorización por perfil activo · actores: Sistema · fuente: 03 §4.2 · 03 §1 (principios))*
- **FR-020**: El sistema debe filtrar cada lectura de las tablas de `public` según la matriz de lectura por rol y dueño, y no debe conceder inserción, actualización ni borrado directo a ningún rol de la API. *(Lecturas filtradas por rol y dueño · actores: Sistema · fuente: 03 §4.3 · 03 §4.4 · 06 §7)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia agrega una entidad, definida en `docs/06` §5.1:

- **Perfil**: la persona dentro de la plataforma. Atributos clave: correo, nombre, rol (usuario, analista o administrador; uno solo por persona) y estado (activo, suspendido o baja). El rol y el estado deciden qué puede leer cada persona.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Una persona con la cuenta suspendida deja de recibir datos al instante, aunque su sesión siga abierta.
- **SC-002**: Un Usuario solo ve su propio perfil; un Analista y un Administrador ven todos.
- **SC-003**: Ningún rol logra crear, cambiar ni borrar un perfil escribiendo directo en la base de datos.
- **SC-004**: Un cambio de rol rige en la consulta siguiente, sin esperar a que la sesión se renueve (hasta 15 minutos).

## Supuestos (Assumptions)

- Depende de TT-03 · Base de Supabase: esquema private, extensiones, Vault y ping: usa el esquema `private` y el proyecto local.
- Los datos de rol y estado que viajan en la sesión son solo para la interfaz: la autorización consulta el perfil en cada operación (`docs/03` §4.1).
- En R1, CA-2 se prueba con una cuenta de prueba ya suspendida, porque suspender una cuenta llega con HU-010 (R2).
