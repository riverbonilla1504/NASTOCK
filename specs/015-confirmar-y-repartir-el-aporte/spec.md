# Especificación de funcionalidad (Feature Specification): HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25

**Feature Branch**: `015-confirmar-y-repartir-el-aporte`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25", en [`backlog/E-03-fondo-y-libro-contable/HU-015-confirmar-el-aporte-por-conciliacion-y-repartirlo-50-25-25.md`](../../backlog/E-03-fondo-y-libro-contable/HU-015-confirmar-el-aporte-por-conciliacion-y-repartirlo-50-25-25.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Confirmar el aporte por conciliación y repartirlo 50/25/25 (Prioridad: P1)

**Como** Administrador, **quiero** que el sistema confirme mi aporte contra el efectivo real de la cuenta paper y lo reparta solo, **para** que nunca se asigne dinero que el broker no tiene.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R2 · El fondo existe. Un aporte solo reparte dinero cuando está confirmado contra el broker: nunca se asigna dinero que el broker no tiene (RN-07). Se reparte con los porcentajes vigentes al confirmarse (RN-08), truncando a centavos y dejando el resto en la Reserva (RN-09). El 50/25/25 se aplica al capital que entra (D-03). Habilita nueve historias: HU-016 (solo hay dinero que retirar después de un aporte confirmado), HU-018 (`usuarios_comun` recibe dinero con el aporte confirmado), HU-020 (hay saldos por bolsillo desde el primer aporte confirmado), HU-034 (solo se enciende con un aporte confirmado), HU-035 (la función `conciliacion` también registra su salud), HU-072 (extiende el adaptador que ya tiene `calendario` y `cuenta`), HU-080 (extiende la conciliación de efectivo), HU-086 (avisa `aporte_confirmado`) y HU-099 (muestra la confirmación del aporte).

**Prueba independiente (Independent Test)**: Se demuestra sola con el escenario E2E-04, que esta historia agrega: aporte, confirmación por conciliación y reparto 50/25/25. Lo acompañan las pruebas de base de datos (redondeo y porcentajes vigentes) y las de la conciliación. Entrega el fondo con capital, repartido en sus tres bolsillos.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dados** un aporte registrado de 10.000 y la cuenta paper con 10.000 de efectivo, **cuando** corre la conciliación, **entonces** el aporte pasa a confirmado y el libro registra externa −10.000, reserva +5.000, arriesgadas +2.500 y usuarios_comun +2.500.
2. **CA-2** (caso borde CB-12) · **Dado** un aporte de 1.000,03, **cuando** se confirma, **entonces** Arriesgadas recibe 250,00, Usuarios 250,00 y la Reserva 500,03.
3. **CA-3** (caso borde CB-11) · **Dado** un aporte registrado y un broker sin ese efectivo, **cuando** corre la conciliación, **entonces** el aporte sigue registrado y a la hora se alerta al Administrador.
4. **CA-4** · **Dado** un cambio de los porcentajes de reparto antes de la confirmación, **cuando** el aporte se confirma, **entonces** usa los porcentajes vigentes en ese momento y los guarda en `movimientos.parametros`.
5. **CA-5** · **Dada** la confirmación, **cuando** ocurre, **entonces** se registra `capital.aporte_confirmado` y se publica `resumen_cambio` en el canal `fondo`.

---

### Casos borde (Edge Cases)

- **CB-11** · Aporte registrado pero el broker no tiene el dinero. Queda `registrado`; la conciliación no lo confirma; alerta al admin a la hora. El admin espera o lo anula (`docs/12` §2; fuente: RN-07). Lo comprueba CA-3.
- **CB-12** · Aporte que no se divide exacto en centavos (1.000,03). Arriesgadas y Usuarios truncados; la Reserva recibe el resto (`docs/12` §2; fuente: RN-09). Lo comprueba CA-2.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-045**: El sistema debe confirmar un aporte registrado cuando el efectivo del broker cubre el efectivo del libro más el aporte; cuando no lo cubre, debe dejarlo registrado y alertar al Administrador a la hora. *(Confirmación del aporte por conciliación · actores: Sistema (conciliación) y Broker (Alpaca paper) · fuente: RN-07 · 08 §4 · 10 §4.1 · CB-11)*
- **FR-046**: Al confirmarse un aporte, el sistema debe repartirlo entre `reserva`, `arriesgadas` y `usuarios_comun` con los porcentajes vigentes, guardarlos en el movimiento, truncar a centavos las partes de Arriesgadas y Usuarios y asignar el resto a la Reserva. *(Reparto del aporte confirmado · actores: Sistema · fuente: RN-08 · RN-09 · CB-12 · D-03)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa estas (`docs/06` §4 y §4.3):

- **Movimiento de capital**: un aporte o un retiro. Atributos clave: monto, estado (registrado, confirmado o anulado), referencia, nota, quién lo registró y cuándo. La conciliación lo pasa de registrado a confirmado.
- **Movimiento y asientos**: el aporte confirmado es un movimiento del libro que guarda los porcentajes con que se repartió.
- **Subcuenta**: reciben el reparto la reserva, arriesgadas y la bolsa común de Usuarios.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Un aporte registrado pasa a confirmado en la siguiente conciliación, cuando la cuenta del broker tiene ese efectivo.
- **SC-002**: El reparto suma exactamente el aporte: de 1.000,03 van 250,00 a Arriesgadas, 250,00 a Usuarios y 500,03 a la Reserva.
- **SC-003**: Si el broker no tiene el dinero, el aporte sigue registrado y el Administrador recibe una alerta a la hora.
- **SC-004**: Indicador de `docs/01` §6: "Descuadres de conciliación sin explicar: 0".
- **SC-005**: El indicador "Escenarios E2E en verde en `main`: 100 % siempre" de `docs/01` §6 se cumple con E2E-04.

## Supuestos (Assumptions)

- Depende de HU-014 · Registrar y anular aportes: confirma los aportes registrados.
- Depende de HU-027 · Calendario, reloj y estado del mercado: reutiliza el adaptador del broker y el horario de mercado.
- Depende de HU-085 · Alertas del sistema por audiencia: alerta al Administrador si el aporte no se confirma.
- Depende de TT-06 · Arnés E2E de backend y de la app: agrega el escenario E2E-04.
- La conciliación de posiciones y de órdenes y la pausa automática llegan con HU-080.
- El efectivo del broker que supera al del libro es excedente no asignado y no se usa (`docs/10` §4.1).
- En paper trading, el Administrador reinicia la cuenta de Alpaca con el monto del fondo fuera de la app.
- **Q-07** (`docs/13` §2, abierta): Monto real del fondo y cómo se reparten los cupos iniciales (¿iguales para todos?). Valor provisional: USD 10.000; cupos que defina el admin.
