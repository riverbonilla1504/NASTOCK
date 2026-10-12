# Especificación de funcionalidad (Feature Specification): HU-030 · Pantalla de mercado en vivo

**Feature Branch**: `030-pantalla-de-mercado`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-030 · Pantalla de mercado en vivo", en [`backlog/E-04-datos-de-mercado/HU-030-pantalla-de-mercado-en-vivo.md`](../../backlog/E-04-datos-de-mercado/HU-030-pantalla-de-mercado-en-vivo.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Pantalla de mercado en vivo (Prioridad: P1)

**Como** Usuario, Analista o Administrador, **quiero** ver los precios del NASDAQ-100 y sus ETFs moverse y el estado del mercado, **para** seguir el mercado desde la app.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R1 · Ver el mercado en vivo. Ver el mercado es un permiso de los tres roles (PM-04) y la pantalla de inicio de todos (`docs/03` §3); también lo es consultar la lista blanca (PM-07). La app muestra siempre la hora de Bogotá y una cuenta regresiva a la apertura o al cierre (RN-42). Habilita dos historias: HU-031 (la comparación es parte de la pantalla de mercado) y HU-032 (la marca se muestra junto a los precios de la pantalla de mercado).

**Prueba independiente (Independent Test)**: Se demuestra sola con el escenario E2E-03, que esta historia agrega: la ingesta simulada publica precios y la app los muestra. Lo acompañan las pruebas de pantalla. Entrega la pantalla donde cualquier persona sigue el mercado desde la app.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dada** una persona con sesión, **cuando** abre Inicio / Mercado, **entonces** ve las cotizaciones del universo con su variación del día y el estado del mercado.
2. **CA-2** · **Dado** un evento `cotizaciones`, **cuando** llega, **entonces** los precios cambian en pantalla sin recargar.
3. **CA-3** · **Dado** el mercado abierto, **cuando** la persona mira el encabezado, **entonces** ve la cuenta regresiva al cierre en hora de Bogotá; con el mercado cerrado, ve la cuenta regresiva a la apertura.
4. **CA-4** · **Dada** la lista de símbolos, **cuando** la persona la filtra por bolsillo, **entonces** ve la lista blanca activa de ese bolsillo.

---

### Casos borde (Edge Cases)

HU-030 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-071**: La app debe mostrar las cotizaciones del universo y el estado del mercado con una cuenta regresiva a la apertura o al cierre en hora de Bogotá. *(Pantalla de mercado · actores: Usuario, Analista y Administrador · fuente: PM-04 · RN-42 · 03 §3)*
- **FR-072**: El sistema debe permitir a todas las personas activas consultar la lista blanca activa por bolsillo. *(Consulta de la lista blanca · actores: Usuario, Analista y Administrador · fuente: PM-07 · 03 §4.3)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa estas dos, definidas en `docs/06` §5.2:

- **Cotización**: el último precio conocido de cada símbolo, con su variación del día.
- **Lista blanca**: los símbolos activos de cada bolsillo.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Cualquier persona con sesión ve los precios del universo con su variación del día y el estado del mercado.
- **SC-002**: Los precios cambian en pantalla sin recargar, con un retraso menor de 30 segundos durante el horario de mercado (indicador de `docs/01` §6).
- **SC-003**: El encabezado muestra, en hora de Bogotá, la cuenta regresiva al cierre o a la apertura.
- **SC-004**: La lista se puede filtrar por bolsillo y muestra la lista blanca activa de ese bolsillo.
- **SC-005**: El indicador "Escenarios E2E en verde en `main`: 100 % siempre" de `docs/01` §6 se cumple con E2E-03.

## Supuestos (Assumptions)

- Depende de HU-028 · Ingesta de precios cada 15 segundos: muestra los precios que publica la ingesta.
- Depende de HU-084 · Gestor de tiempo real en la app: consume el canal `mercado` y usa el reloj corregido.
- Depende de HU-006 · Navegación y guardas según el rol: es la pantalla de inicio de los tres roles.
- Depende de TT-06 · Arnés E2E de backend y de la app: agrega el escenario E2E-03.
- Los precios son la única excepción a la regla de eventos sin montos: son públicos dentro de la empresa (`docs/09` §4).
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.
