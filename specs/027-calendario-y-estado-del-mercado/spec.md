# Especificación de funcionalidad (Feature Specification): HU-027 · Calendario, reloj y estado del mercado

**Feature Branch**: `027-calendario-y-estado-del-mercado`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-027 · Calendario, reloj y estado del mercado", en [`backlog/E-04-datos-de-mercado/HU-027-calendario-reloj-y-estado-del-mercado.md`](../../backlog/E-04-datos-de-mercado/HU-027-calendario-reloj-y-estado-del-mercado.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Calendario, reloj y estado del mercado (Prioridad: P1)

**Como** Usuario, Analista o Administrador, **quiero** saber si el mercado está abierto y cuánto falta para que abra o cierre, **para** entender cuándo se puede operar.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R1 · Ver el mercado en vivo. El mercado opera según el calendario del broker, que se sincroniza a diario y nunca se programa a mano (RN-41). La app muestra siempre la hora de Bogotá con una cuenta regresiva a la apertura o al cierre (RN-42), y fuera de horario no se opera (RN-43). Habilita seis historias: HU-015 (reutiliza el adaptador del broker y el horario de mercado), HU-028 (solo consulta con el mercado en ventana), HU-029 (sabe si el mercado ya cerró por el calendario), HU-043 (la preapertura se calcula con el calendario), HU-046 (solo corre en la ventana de compras) y HU-085 (conecta la alerta de símbolo no negociable).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas que nombra la historia: las de horario con el reloj fijado (feriado, media jornada y ventana) y las de la sincronización del calendario. No tiene escenario E2E propio; la ejercita E2E-03. Entrega la respuesta a si el mercado está abierto y a cuánto falta para que abra o cierre.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** el calendario sincronizado, **cuando** se llama `estado_mercado()`, **entonces** devuelve el estado (cerrado, preapertura, abierto sin compras, abierto o cierre próximo), la próxima apertura o cierre, la ventana de compras y la frescura de los datos.
2. **CA-2** (caso borde CB-49) · **Dado** un feriado de EE. UU., **cuando** se consulta, **entonces** el mercado está cerrado todo el día.
3. **CA-3** (caso borde CB-50) · **Dada** una media jornada, **cuando** se consulta, **entonces** el cierre es a las 13:00 de Nueva York y la ventana de compras se calcula con ese cierre.
4. **CA-4** (caso borde CB-51) · **Dado** el cambio de horario de verano en EE. UU., **cuando** se consulta, **entonces** las horas guardadas en UTC siguen correctas sin intervención.
5. **CA-5** · **Dado** un símbolo que deja de ser negociable en Alpaca, **cuando** corre la sincronización diaria, **entonces** queda desactivado en la lista blanca.
6. **CA-6** · **Dado** el trabajo diario `calendario`, **cuando** corre, **entonces** el calendario queda sincronizado con el del broker, con la apertura y el cierre de cada sesión en UTC.
7. **CA-7** · **Dado** un símbolo de la lista blanca, **cuando** corre la sincronización diaria, **entonces** `lista_blanca` guarda si es negociable y si es fraccionable según Alpaca.

---

### Casos borde (Edge Cases)

- **CB-49** · Feriado en EE. UU. Calendario: cerrado todo el día; sin ingesta ni ciclos (`docs/12` §6; fuente: RN-41). Lo comprueba CA-2.
- **CB-50** · Media jornada (cierre 13:00 NY). Ventana de compras y vencimientos se calculan con el cierre real del calendario (`docs/12` §6; fuente: RN-41). Lo comprueba CA-3.
- **CB-51** · Cambio de horario de verano en EE. UU. Sin efecto: el calendario está en UTC; la app muestra la hora de Bogotá correcta (`docs/12` §6; fuente: RN-42). Lo comprueba CA-4.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-063**: El sistema debe sincronizar a diario el calendario del broker con aperturas y cierres en UTC, incluidos feriados y medias jornadas, y nunca programarlo a mano. *(Calendario y reloj de mercado · actores: Sistema y Broker (Alpaca) · fuente: RN-41 · CB-49 · CB-50 · CB-51)*
- **FR-064**: El sistema debe informar si el mercado está cerrado, en preapertura, abierto sin compras, abierto o en cierre próximo, con la próxima apertura o cierre, la ventana de compras y la frescura de los datos. *(Estado del mercado · actores: Usuario, Analista y Administrador · fuente: 06 §6 · 08 §6)*
- **FR-065**: El sistema debe sincronizar a diario si cada símbolo de la lista blanca es negociable y fraccionable, y debe desactivar y alertar al Administrador el que deje de ser negociable. *(Atributos de los activos · actores: Sistema y Broker (Alpaca) · fuente: 10 §5 · 10 §10 · 10 §12)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia agrega una entidad y completa otra (`docs/06` §5.2):

- **Calendario de mercado**: cada día de mercado, con su apertura y su cierre en UTC y el tipo de sesión (regular o media jornada).
- **Lista blanca**: recibe de la sincronización diaria si cada símbolo es negociable y si es fraccionable; el que deja de ser negociable se desactiva.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Cualquier persona sabe si el mercado está cerrado, en preapertura, abierto sin compras, abierto o en cierre próximo, y cuándo es la próxima apertura o el próximo cierre.
- **SC-002**: En un feriado de EE. UU. el mercado aparece cerrado todo el día, y en una media jornada el cierre es a las 13:00 de Nueva York.
- **SC-003**: El cambio de horario de verano en EE. UU. no exige ninguna intervención.
- **SC-004**: Un símbolo que deja de ser negociable queda desactivado en la lista blanca tras la sincronización diaria.

## Supuestos (Assumptions)

- Depende de HU-026 · Universo del NASDAQ-100 y carga histórica de barras: sincroniza los atributos de los símbolos de la lista blanca.
- Depende de TT-05 · Base de proveedores simulados, reloj controlable y datos de prueba: usa el reloj controlable y el broker simulado.
- El estado del mercado se calcula, no se guarda (`docs/08` §6).
- La alerta al Administrador por un símbolo que deja de ser negociable se conecta en HU-085.
