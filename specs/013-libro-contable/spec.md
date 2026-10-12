# Especificación de funcionalidad (Feature Specification): HU-013 · Libro contable de doble partida

**Feature Branch**: `013-libro-contable`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-013 · Libro contable de doble partida", en [`backlog/E-03-fondo-y-libro-contable/HU-013-libro-contable-de-doble-partida.md`](../../backlog/E-03-fondo-y-libro-contable/HU-013-libro-contable-de-doble-partida.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Libro contable de doble partida (Prioridad: P1)

**Como** Administrador, **quiero** que todo el dinero del fondo se lleve en un libro de doble partida que nadie puede editar, **para** reconstruir cualquier saldo y confiar en que cada peso tiene origen y destino.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R2 · El fondo existe. El dinero se cuenta en un solo lugar: un libro de doble partida donde nada se edita y todo se registra (`docs/01` §2, P4). Existe un solo fondo (RN-01), todo cambio de saldo es un movimiento cuyos asientos suman cero (RN-04) y ningún efectivo queda en negativo (RN-05). Habilita cuatro historias: HU-014 (el aporte se contabiliza en el libro al confirmarse), HU-017 (el cupo es una subcuenta del libro), HU-021 (la foto se toma de los saldos del libro) y HU-022 (el ajuste es un movimiento del libro).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas de base de datos del libro que nombra la historia: sus cinco invariantes, los saldos no negativos, la inmutabilidad y la lectura por rol. No tiene escenario E2E propio; la ejercita E2E-04. Entrega el libro donde cada peso tiene origen y destino.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** el fondo recién creado, **cuando** se consulta, **entonces** existe un solo fondo con las subcuentas `reserva`, `arriesgadas`, `usuarios_comun`, `externa` y `resultados`, todas en 0 y con los interruptores apagados.
2. **CA-2** · **Dado** un movimiento cuyos asientos no suman cero, **cuando** se intenta registrar, **entonces** `private.registrar_movimiento` lo rechaza y la verificación diferida lo vuelve a impedir al confirmar la transacción.
3. **CA-3** · **Dado** un movimiento que dejaría en negativo el efectivo de una subcuenta de bolsillo o de cupo, o el retenido por encima del efectivo, **cuando** se registra, **entonces** la base de datos lo rechaza.
4. **CA-4** (permiso) · **Dado** cualquier rol, incluida la llave secreta, **cuando** intenta un `UPDATE` o un `DELETE` sobre `asientos` o `movimientos`, **entonces** el trigger lo rechaza.
5. **CA-5** · **Dado** un saldo guardado que difiere de la suma de sus asientos, **cuando** corre la verificación diaria, **entonces** se genera una alerta.

---

### Casos borde (Edge Cases)

HU-013 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-038**: El sistema debe mantener un único fondo en USD con las subcuentas `reserva`, `arriesgadas`, `usuarios_comun`, una de `cupo` por Usuario, `externa` y `resultados`, cada una con efectivo, invertido y retenido. *(Fondo único con subcuentas · actores: Sistema · fuente: RN-01 · 02 §2 · 06 §4 · D-02)*
- **FR-039**: El sistema debe registrar todo cambio de saldo como un movimiento cuyos asientos suman exactamente cero, a través de una única función, y rechazar todo movimiento que no sume cero. *(Movimientos de doble partida · actores: Sistema · fuente: RN-04 · 06 §4.1 (L1, L2))*
- **FR-040**: El sistema debe impedir que el efectivo de una subcuenta de bolsillo o de cupo sea negativo y que su retenido supere a su efectivo. *(Saldos nunca negativos · actores: Sistema · fuente: RN-05 · 06 §4)*
- **FR-041**: El sistema debe rechazar toda modificación o borrado de asientos y movimientos; una corrección se hace con un movimiento nuevo de ajuste. *(Libro inmutable · actores: Sistema · fuente: 06 §4.1 (L3) · 11 §2)*
- **FR-042**: El sistema debe recalcular cada día los saldos de cada subcuenta desde sus asientos y generar una alerta si difieren de los saldos guardados. *(Verificación diaria del libro · actores: Sistema · fuente: 06 §4.1 (L2))*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia agrega cuatro entidades, definidas en `docs/06` §4:

- **Fondo**: el único fondo de RiTech, en USD, con sus dos interruptores (IA y trading), que nacen apagados.
- **Subcuenta**: el lugar donde está el dinero del fondo: reserva, arriesgadas, bolsa común de Usuarios, un cupo por Usuario, externa y resultados. Atributos clave: efectivo, invertido y retenido.
- **Movimiento**: un cambio del libro: aporte, retiro, asignación o reducción de cupo, compra, venta, reparto de ganancia, rebalanceo o ajuste. Guarda su descripción, quién lo creó y los parámetros con que se hizo.
- **Asiento**: cada línea de un movimiento: la subcuenta, el concepto (efectivo o invertido) y el monto. Los asientos de un movimiento suman cero.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Cualquier saldo se puede reconstruir sumando sus asientos.
- **SC-002**: Ningún movimiento cuyos asientos no suman cero queda registrado.
- **SC-003**: Ningún efectivo de bolsillo o de cupo queda en negativo, ni un retenido por encima de su efectivo.
- **SC-004**: Nadie logra modificar ni borrar un asiento o un movimiento.
- **SC-005**: Si un saldo guardado deja de coincidir con sus asientos, la verificación diaria lo avisa.

## Supuestos (Assumptions)

- Depende de HU-001 · Perfiles, rol actual y lecturas por rol: las subcuentas de cupo y las políticas dependen de `perfiles` y de `private.rol_actual()`.
- Depende de HU-085 · Alertas del sistema por audiencia: la verificación diaria crea una alerta.
- El dinero se lleva en USD con dos decimales.
- El retenido no forma parte del libro (invariante L5).
- Las ganancias no realizadas no son contables: se calculan al vuelo (RN-06).
- **S3** (`docs/01` §5): Moneda única USD (la del broker). Si resulta falso: agregar TRM para mostrar COP como referencia; nunca para contabilidad.
