# Especificación de funcionalidad (Feature Specification): HU-014 · Registrar y anular aportes

**Feature Branch**: `014-registrar-y-anular-aportes`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-014 · Registrar y anular aportes", en [`backlog/E-03-fondo-y-libro-contable/HU-014-registrar-y-anular-aportes.md`](../../backlog/E-03-fondo-y-libro-contable/HU-014-registrar-y-anular-aportes.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Registrar y anular aportes (Prioridad: P1)

**Como** Administrador, **quiero** registrar un aporte de capital y anularlo si aún no se confirma, **para** que el dinero entre al fondo solo por una vía controlada y corregible.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R2 · El fondo existe. Registrar y anular aportes es un permiso exclusivo del Administrador (PM-40). Un aporte registrado no mueve el libro hasta confirmarse contra el broker (RN-07), y mientras no se confirme se puede anular (RN-10). Habilita dos historias: HU-015 (confirma los aportes registrados) y HU-099 (registra y anula aportes).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas de base de datos que nombra la historia: registro, anulación, anulación de un aporte confirmado y permisos. No tiene escenario E2E propio; la ejercita E2E-04. Entrega la única vía por la que entra dinero al fondo.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** un Administrador, **cuando** registra un aporte de 10.000 con la referencia `paper-inicial`, **entonces** queda en estado registrado, el libro no cambia y se registra `capital.aporte_registrado`.
2. **CA-2** · **Dado** un aporte registrado y no confirmado, **cuando** el Administrador lo anula con un motivo, **entonces** pasa a anulado, se guarda quién y cuándo lo anuló y se registra `capital.aporte_anulado`.
3. **CA-3** · **Dado** un aporte confirmado, **cuando** se intenta anular, **entonces** responde `ESTADO_INVALIDO`: se corrige con un retiro.
4. **CA-4** · **Dado** un monto menor o igual a 0, **cuando** se intenta registrar, **entonces** la base de datos lo rechaza.
5. **CA-5** (permiso) · **Dado** un Usuario o un Analista, **cuando** llama `registrar_aporte` o `anular_aporte`, **entonces** recibe `NO_AUTORIZADO`.

---

### Casos borde (Edge Cases)

HU-014 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-043**: El sistema debe permitir al Administrador registrar un aporte con monto, referencia y nota, que queda en estado registrado sin mover el libro. *(Registro de un aporte · actores: Administrador · fuente: PM-40 · RN-07 · 02 §3.1 · 08 §4)*
- **FR-044**: El sistema debe permitir al Administrador anular con motivo un aporte registrado y no confirmado, y rechazar la anulación de un aporte confirmado. *(Anulación de un aporte no confirmado · actores: Administrador · fuente: PM-40 · RN-10 · 08 §4)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia agrega una entidad, definida en `docs/06` §4.3:

- **Movimiento de capital**: un aporte o un retiro. Atributos clave: monto, estado (registrado, confirmado o anulado), referencia, nota, quién lo registró y cuándo. Si se anula, guarda quién lo anuló, cuándo y el motivo.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Un Administrador registra un aporte y queda registrado sin que cambie ningún saldo.
- **SC-002**: Un aporte no confirmado se anula con un motivo, y queda quién y cuándo lo anuló.
- **SC-003**: Un aporte confirmado no se puede anular.
- **SC-004**: Un Usuario o un Analista no logra registrar ni anular un aporte.
- **SC-005**: Cada registro y cada anulación quedan en la bitácora.

## Supuestos (Assumptions)

- Depende de HU-013 · Libro contable de doble partida: el aporte se contabiliza en el libro al confirmarse.
- Depende de HU-107 · Bitácora inmutable con cadena de hash: registra `capital.aporte_registrado` y `capital.aporte_anulado`.
- Depende de HU-083 · Canales privados de tiempo real: publica el evento `capital` en el canal `admin`.
- Un aporte registrado no mueve el libro (RN-07): lo mueve su confirmación, en HU-015.
- La pantalla está en HU-099.
- **Q-07** (`docs/13` §2, abierta): Monto real del fondo y cómo se reparten los cupos iniciales (¿iguales para todos?). Valor provisional: USD 10.000; cupos que defina el admin.
