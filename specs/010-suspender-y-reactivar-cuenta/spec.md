# Especificación de funcionalidad (Feature Specification): HU-010 · Suspender y reactivar una cuenta

**Feature Branch**: `010-suspender-y-reactivar-cuenta`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-010 · Suspender y reactivar una cuenta", en [`backlog/E-02-identidad-y-acceso/HU-010-suspender-y-reactivar-una-cuenta.md`](../../backlog/E-02-identidad-y-acceso/HU-010-suspender-y-reactivar-una-cuenta.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Suspender y reactivar una cuenta (Prioridad: P1)

**Como** Administrador, **quiero** suspender una cuenta y reactivarla después, **para** cortar su acceso al instante cuando hay un riesgo y devolvérselo cuando pase.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R2 · El fondo existe. Suspender y reactivar cuentas es un permiso exclusivo del Administrador (PM-52). Suspender corta el acceso a los datos al instante, cierra la sesión abierta y bloquea la cuenta (`docs/04` §10, RN-57). Siempre debe quedar un Administrador activo y nadie puede suspenderse a sí mismo (RN-50, RN-51). Habilita ocho historias: HU-012 (extiende la función `admin-usuarios` y el bloqueo en Auth), HU-065 (anula la primera aprobación al suspender), HU-067 (invalida las sugerencias del titular suspendido), HU-069 (el flujo empieza con la cuenta suspendida), HU-087 (borra los dispositivos al suspender), HU-098 (usa la función `admin-usuarios`), HU-108 (el escenario audita una suspensión) y HU-109 (extiende el escenario E2E-05).

**Prueba independiente (Independent Test)**: Se demuestra sola con el escenario E2E-05, que esta historia agrega: al suspender a un Usuario, pierde el acceso al instante. Lo acompañan las pruebas de base de datos (último administrador, acción sobre uno mismo y rol sin permiso) y las de la función. Entrega al Administrador la forma de cortar y devolver el acceso de una cuenta.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dada** una cuenta activa, **cuando** el Administrador la suspende, **entonces** su estado pasa a suspendido, queda bloqueada en Auth, se registra `cuenta.suspendida` y sus consultas dejan de devolver datos aunque su token siga vigente.
2. **CA-2** (caso borde CB-07) · **Dada** esa persona con la app abierta, **cuando** se la suspende, **entonces** recibe `sesion_revocada`, la app cierra la sesión y muestra el motivo.
3. **CA-3** (caso borde CB-09) · **Dado** el último Administrador activo, **cuando** alguien intenta suspenderlo, **entonces** recibe `ULTIMO_ADMIN`; y si un Administrador intenta suspenderse a sí mismo, `AUTO_ACCION`.
4. **CA-4** · **Dada** una cuenta suspendida, **cuando** el Administrador la reactiva, **entonces** vuelve a activo, se desbloquea en Auth, se registra `cuenta.reactivada` y su cupo sigue como quedó.
5. **CA-5** (permiso) · **Dado** un Usuario o un Analista, **cuando** llama la función `admin-usuarios`, **entonces** recibe `NO_AUTORIZADO`.

---

### Casos borde (Edge Cases)

- **CB-07** · Se suspende a alguien con la app abierta. RLS le corta los datos al instante; evento `sesion_revocada` cierra su sesión; su cupo queda congelado (`docs/12` §1; fuente: 04 §10). Lo comprueba CA-2.
- **CB-09** · Intento de suspender, dar de baja o cambiar de rol al último admin, o de aplicarse la acción a sí mismo. `ULTIMO_ADMIN` / `AUTO_ACCION` (`docs/12` §1; fuente: RN-50, RN-51). Lo comprueba CA-3.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-029**: El sistema debe permitir al Administrador suspender una cuenta: cambiar su estado a suspendido, invalidar sus sugerencias vivas, borrar sus dispositivos de push, bloquearla en Auth y publicar `sesion_revocada` en su canal. *(Suspensión de una cuenta · actores: Administrador · fuente: PM-52 · 04 §10 · RN-57 · CB-07)*
- **FR-030**: Mientras una cuenta está suspendida, el sistema no debe crearle sugerencias ni aceptarle órdenes, y debe mantener activas las protecciones de sus posiciones. *(Cupo congelado durante la suspensión · actores: Sistema · fuente: 02 §11 · RR-17 · CB-46)*
- **FR-031**: El sistema debe permitir al Administrador reactivar una cuenta suspendida: desbloquearla en Auth y devolver su estado a activo, con su cupo tal como quedó. *(Reactivación de una cuenta · actores: Administrador · fuente: PM-52 · 04 §10 · 02 §11)*
- **FR-032**: El sistema debe rechazar con `ULTIMO_ADMIN` suspender, dar de baja o cambiar de rol al último Administrador activo, y con `AUTO_ACCION` que una persona se aplique esas acciones a sí misma. *(Protección del último administrador y de la acción sobre uno mismo · actores: Administrador · fuente: RN-50 · RN-51 · CB-09)*
- **FR-035**: Al recibir `sesion_revocada`, la app debe cerrar sus canales y su sesión y mostrar el motivo. *(Cierre de la sesión revocada · actores: Usuario, Analista y Administrador · fuente: 04 §10 · 09 §7 · CB-07)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa una, definida en `docs/06` §5.1:

- **Perfil**: la persona dentro de la plataforma, con su correo, su nombre, su rol y su estado (activo, suspendido o baja). Suspender y reactivar cambian su estado.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Una persona suspendida deja de ver datos al instante y, si tiene la app abierta, ve cerrarse su sesión con el motivo.
- **SC-002**: Una persona suspendida no puede volver a entrar hasta que la reactivan.
- **SC-003**: Al reactivarla recupera el acceso y encuentra su cupo como quedó.
- **SC-004**: Nadie logra suspender al último Administrador activo ni suspenderse a sí mismo.
- **SC-005**: El indicador "Escenarios E2E en verde en `main`: 100 % siempre" de `docs/01` §6 se cumple con E2E-05.

## Supuestos (Assumptions)

- Depende de HU-001 · Perfiles, rol actual y lecturas por rol: cambia `perfiles.estado`, que corta el acceso por RLS.
- Depende de HU-083 · Canales privados de tiempo real: publica `sesion_revocada` en el canal de la persona.
- Depende de HU-084 · Gestor de tiempo real en la app: la app escucha su canal para cerrar la sesión.
- Depende de HU-107 · Bitácora inmutable con cadena de hash: registra `cuenta.suspendida` y `cuenta.reactivada`.
- Al suspender también se invalidan las sugerencias vivas de la persona, se anulan sus primeras aprobaciones y se borran sus dispositivos de push (`docs/04` §10). Eso llega después: HU-067, HU-065 y HU-087 completan la función.
- Las protecciones de sus posiciones siguen activas (`docs/02` §11).
- La pantalla está en HU-098.
