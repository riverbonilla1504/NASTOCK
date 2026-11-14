# Especificación de funcionalidad (Feature Specification): HU-037 · Motor de políticas: reglas de la propuesta

**Feature Branch**: `037-motor-de-politicas`

**Created**: 2026-11-14

**Status**: Implementada (especificación escrita después de construir)

**Input**: Historia de usuario: "HU-037 · Motor de políticas: reglas de la propuesta", en [`backlog/E-05-motor-de-politicas-y-configuracion/HU-037-motor-de-politicas-reglas-de-la-propuesta.md`](../../backlog/E-05-motor-de-politicas-y-configuracion/HU-037-motor-de-politicas-reglas-de-la-propuesta.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Motor de políticas: reglas de la propuesta (Prioridad: P1)

**Como** Analista, **quiero** que toda propuesta de compra o de venta pase por un único motor de reglas de riesgo en la base de datos, **para** que ninguna operación que viole un límite llegue a una persona ni al broker.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R3 · La IA analiza. Habilita HU-038 · Motor de políticas completo en los cuatro momentos, HU-047 · Puntaje compuesto y elección de la mejor opción, HU-052 · Opinión de la IA sobre una orden manual, HU-058 · Sugerencia de compra para Arriesgadas, HU-062 · Aprobar una sugerencia de mi cupo.

**Prueba independiente (Independent Test)**: Sin escenario propio en el catálogo de 15 §4.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dada** una compra de un símbolo que no está en la lista blanca activa del bolsillo, **cuando** se valida, **entonces** `validar_operacion` devuelve RR-01.
2. **CA-2** · **Dada** una compra que supera el disponible, el máximo por operación o la concentración por símbolo, o cuyo stop-loss falta o está fuera del rango del bolsillo, **cuando** se valida, **entonces** devuelve RR-03, RR-04, RR-05 o RR-08 según el caso.
3. **CA-3** · **Dada** una operación que usa la Reserva o `usuarios_comun`, que está bajo la orden mínima o cuyo destinatario no está activo, **cuando** se valida, **entonces** devuelve RR-02, RR-06 o RR-17.
4. **CA-4** · **Dada** una operación con el mercado cerrado o fuera de la ventana de compras, con la cotización más vieja que el máximo, con el interruptor apagado o con el broker o los datos caídos, **cuando** se valida, **entonces** devuelve RR-07, RR-11, RR-14 o RR-21.
5. **CA-5** · **Dada** una operación que cumple todo, **cuando** se valida, **entonces** la lista de reglas violadas llega vacía.
6. **CA-6** · **Dada** una función que recibe reglas violadas, **cuando** responde a la app, **entonces** usa el código `REGLA_RR_xx` y la app muestra el texto de esa regla.

---

### Casos borde (Edge Cases)

Ninguno propio.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-085**: El sistema debe validar toda operación con una sola función en la base de datos que devuelve la lista de reglas violadas, llamada al crear la propuesta, al aprobar, antes de enviar al broker y al dispararse una protección. *(Motor de políticas único · actores: Sistema · fuente: RN-38 · 02 §9 · 06 §8.2)*
- **FR-086**: El sistema debe rechazar una compra cuyo símbolo no esté en la lista blanca activa del bolsillo (RR-01), cuyo monto supere el disponible (RR-03), el máximo por operación (RR-04) o la concentración por símbolo (RR-05), o cuyo stop-loss falte o esté fuera del rango del bolsillo (RR-08). *(Reglas de riesgo de las compras · actores: Sistema · fuente: RR-01 · RR-03 · RR-04 · RR-05 · RR-08 · Q-03)*
- **FR-087**: El sistema debe rechazar toda operación que use la Reserva o `usuarios_comun` (RR-02), esté bajo la orden mínima (RR-06), tenga un destinatario no activo (RR-17) o use margen, cortos, opciones u horario extendido (RR-18). *(Reglas de riesgo generales · actores: Sistema · fuente: RR-02 · RR-06 · RR-17 · RR-18 · RN-03 · Q-14)*
- **FR-088**: El sistema debe rechazar una operación fuera del horario regular o una compra fuera de la ventana de compras (RR-07), con una cotización más vieja que el máximo (RR-11), con el interruptor correspondiente apagado (RR-14), con el broker o los datos de mercado caídos (RR-21) o, si es compra, con un descuadre crítico abierto (RR-22). *(Reglas de horario, precio y salud · actores: Sistema · fuente: RR-07 · RR-11 · RR-14 · RR-21 · RR-22 · RN-43)*
- **FR-089**: El sistema debe rechazar una sugerencia de la IA cuya confianza sea menor que `jev.confianza_minima`. *(Confianza mínima de las sugerencias de la IA · actores: Sistema · fuente: RR-09 · 07 §6.3)*
- **FR-090**: Cuando una regla falla, el sistema debe detener la operación y devolver el código `REGLA_RR_xx` con el texto de la regla. *(Registro de la regla violada · actores: Sistema · fuente: 02 §9 · 06 §9)*
- **FR-030**: Mientras una cuenta está suspendida, el sistema no debe crearle sugerencias ni aceptarle órdenes, y debe mantener activas las protecciones de sus posiciones. *(Cupo congelado durante la suspensión · actores: Sistema · fuente: 02 §11 · RR-17 · CB-46)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

- **Validación de una operación** (`private.validar_operacion`): devuelve la lista de reglas violadas (`REGLA_RR_xx`); vacía si la operación cumple todo (docs/02 §8).

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: `validar_operacion` devuelve RR-01 (CA-1).
- **SC-002**: Devuelve RR-03, RR-04, RR-05 o RR-08 según el caso (CA-2).
- **SC-003**: Devuelve RR-02, RR-06 o RR-17 (CA-3).
- **SC-004**: Devuelve RR-07, RR-11, RR-14 o RR-21 (CA-4).
- **SC-005**: La lista de reglas violadas llega vacía (CA-5).
- **SC-006**: Usa el código `REGLA_RR_xx` y la app muestra el texto de esa regla (CA-6).

## Supuestos (Assumptions)

- Depende de HU-033 · Parámetros configurables con rango e historial: Lee los límites del catálogo de parámetros.
- Depende de HU-034 · Encender y apagar los interruptores del fondo: RR-14 mira los interruptores.
- Depende de HU-035 · Salud de las integraciones: RR-21 mira la salud del broker y de los datos.
- Depende de HU-028 · Ingesta de precios cada 15 segundos: RR-07 y RR-11 usan el horario y la última cotización.
- Depende de HU-018 · Asignar y reducir cupos: RR-03 a RR-05 usan el disponible y el patrimonio de la subcuenta.
- Lo usan la orden manual (HU-075) y el envío al broker (HU-073); en el MVP no hay señales de la IA que validar (D-65, D-72).
