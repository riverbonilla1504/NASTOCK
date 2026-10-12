# Especificación de funcionalidad (Feature Specification): HU-033 · Parámetros configurables con rango e historial

**Feature Branch**: `033-parametros-configurables`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-033 · Parámetros configurables con rango e historial", en [`backlog/E-05-motor-de-politicas-y-configuracion/HU-033-parametros-configurables-con-rango-e-historial.md`](../../backlog/E-05-motor-de-politicas-y-configuracion/HU-033-parametros-configurables-con-rango-e-historial.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Parámetros configurables con rango e historial (Prioridad: P1)

**Como** Administrador, **quiero** cambiar los parámetros del sistema dentro de su rango y con su historial, **para** ajustar el comportamiento sin desplegar código y sabiendo quién cambió qué.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R2 · El fondo existe. Cambiar parámetros es un permiso exclusivo del Administrador (PM-54), y todos pueden ver los vigentes (PM-06). Los porcentajes de los bolsillos suman exactamente 100 y cambiarlos no mueve dinero existente (RN-02). Habilita cinco historias: HU-037 (lee los límites del catálogo de parámetros), HU-046 (lee la frecuencia y los umbrales del catálogo), HU-054 (los modelos se cambian como parámetros), HU-101 (cambia los parámetros) y HU-108 (el escenario audita un cambio de parámetro).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas de base de datos que nombra la historia: rango, suma 100, historial, lectura y permisos. No tiene escenario E2E propio. Entrega la forma de ajustar el comportamiento del sistema sin desplegar código y sabiendo quién cambió qué.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** un Administrador, **cuando** cambia `sugerencias.minutos_vencimiento` de 30 a 45 con un motivo, **entonces** el parámetro se actualiza, `parametros_historial` guarda el valor anterior, el nuevo y el motivo, y se registra `parametro.cambiado`.
2. **CA-2** · **Dado** un valor fuera del rango del parámetro, **cuando** se intenta guardar, **entonces** responde `PARAMETRO_FUERA_DE_RANGO`.
3. **CA-3** (caso borde CB-78) · **Dados** unos porcentajes de reparto que no suman 100, **cuando** se intentan guardar, **entonces** responde `PARAMETRO_FUERA_DE_RANGO`: los tres se cambian juntos en una sola operación.
4. **CA-4** (caso borde CB-75) · **Dado** un cambio válido del 50/25/25, **cuando** se guarda, **entonces** no se mueve dinero existente.
5. **CA-5** (permiso) · **Dado** un Usuario o un Analista, **cuando** llama `actualizar_parametro`, **entonces** recibe `NO_AUTORIZADO`; ambos pueden leer los parámetros vigentes, pero no `parametros_historial`.

---

### Casos borde (Edge Cases)

- **CB-75** · Se cambia el 50/25/25. Solo afecta aportes y repartos futuros y la meta del rebalanceo (`docs/12` §9; fuente: RN-02). Lo comprueba CA-4.
- **CB-78** · Porcentajes de reparto que no suman 100. `PARAMETRO_FUERA_DE_RANGO`: los tres se cambian juntos en una sola operación (`docs/12` §9; fuente: RN-02). Lo comprueba CA-3.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-076**: El sistema debe permitir al Administrador cambiar un parámetro del catálogo validando su rango, guardar el valor anterior, el nuevo y el motivo en el historial y en la bitácora, y aplicarlo desde ese momento. *(Cambio de un parámetro · actores: Administrador · fuente: PM-54 · 02 §10 · 06 §5.6)*
- **FR-077**: El sistema debe exigir que los tres porcentajes de reparto se cambien en una sola operación y sumen 100, y el cambio no debe mover dinero existente. *(Porcentajes de reparto consistentes · actores: Administrador · fuente: RN-02 · CB-75 · CB-78)*
- **FR-078**: El sistema debe permitir a todas las personas activas leer los parámetros vigentes. *(Consulta de parámetros vigentes · actores: Usuario, Analista y Administrador · fuente: PM-06 · 03 §4.3)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia agrega una entidad y usa otra (`docs/06` §5.6):

- **Historial de parámetros**: cada cambio de un parámetro: valor anterior, valor nuevo, quién lo cambió, cuándo y el motivo.
- **Parámetro**: un valor configurable del sistema, con su clave, su valor, su rango y su descripción.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Un Administrador cambia un parámetro dentro de su rango, y el valor nuevo rige desde ese momento.
- **SC-002**: De cada cambio quedan el valor anterior, el nuevo, el motivo y quién lo hizo.
- **SC-003**: No se guarda un valor fuera de su rango ni unos porcentajes de reparto que no suman 100.
- **SC-004**: Cambiar el 50/25/25 no mueve dinero existente.
- **SC-005**: Todas las personas activas leen los parámetros vigentes; solo el Administrador ve el historial.

## Supuestos (Assumptions)

- Depende de HU-002 · Alta solo con invitación vigente: la tabla `parametros` nace con el hook de alta.
- Depende de HU-107 · Bitácora inmutable con cadena de hash: registra `parametro.cambiado`.
- Depende de HU-083 · Canales privados de tiempo real: publica `parametro` en el canal `admin`.
- Cada sugerencia y cada orden congela los parámetros con los que se validó (RN-39).
- La lista de modelos permitidos (CB-79) se cubre en HU-054.
- Los tres porcentajes de reparto se cambian juntos, en una sola operación (`docs/06` §8.1).
- La pantalla está en HU-101.
