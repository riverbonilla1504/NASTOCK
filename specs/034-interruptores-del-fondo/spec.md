# Especificación de funcionalidad (Feature Specification): HU-034 · Encender y apagar los interruptores del fondo

**Feature Branch**: `034-interruptores-del-fondo`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-034 · Encender y apagar los interruptores del fondo", en [`backlog/E-05-motor-de-politicas-y-configuracion/HU-034-encender-y-apagar-los-interruptores-del-fondo.md`](../../backlog/E-05-motor-de-politicas-y-configuracion/HU-034-encender-y-apagar-los-interruptores-del-fondo.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Encender y apagar los interruptores del fondo (Prioridad: P1)

**Como** Administrador, **quiero** encender la IA y el trading cuando el fondo ya tiene capital, y apagarlos, **para** que el sistema empiece a analizar y a operar solo cuando yo lo decido.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R2 · El fondo existe. Solo el Administrador vuelve a encender la IA o el trading (PM-57). Los dos interruptores nacen apagados y no se encienden antes del primer aporte confirmado (RN-11); sin ellos no se crean sugerencias ni se envían órdenes nuevas (RR-14). Habilita cinco historias: HU-037 (RR-14 mira los interruptores), HU-039 (extiende `activar_freno`), HU-046 (no corre con `ia_activa` apagado ni con el fondo sin capital), HU-101 (enciende y apaga los interruptores) y HU-108 (el escenario audita un interruptor).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas de base de datos que nombra la historia: nacen apagados, fondo sin capital, encender, apagar y permisos. No tiene escenario E2E propio. Entrega al Administrador la decisión de cuándo el sistema empieza a analizar y a operar.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** el fondo recién creado, **cuando** se consulta, **entonces** `ia_activa` y `trading_activo` están apagados.
2. **CA-2** (caso borde CB-80) · **Dado** el fondo sin un aporte confirmado, **cuando** el Administrador intenta encender un interruptor, **entonces** responde `FONDO_SIN_CAPITAL` y la app muestra "Fondo sin capital".
3. **CA-3** · **Dado** un aporte confirmado, **cuando** el Administrador enciende `ia_activa` o `trading_activo`, **entonces** el interruptor queda encendido, se registra `interruptor.encendido` y se publica `interruptor` en el canal `admin`.
4. **CA-4** · **Dado** un Administrador, **cuando** apaga un interruptor con un motivo, **entonces** queda apagado con el motivo, el autor y la hora, y se registra `interruptor.apagado`.
5. **CA-5** (permiso) · **Dado** un Usuario o un Analista, **cuando** llama `reanudar`, **entonces** recibe `NO_AUTORIZADO`.

---

### Casos borde (Edge Cases)

- **CB-80** · Fondo sin capital (antes del primer aporte). Interruptores apagados; la app muestra "Fondo sin capital" y el admin ve la guía de primeros pasos (`docs/12` §9; fuente: RN-11). Lo comprueba CA-2.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-079**: El sistema debe mantener dos interruptores, `ia_activa` y `trading_activo`, que nacen apagados. *(Interruptores del fondo · actores: Sistema · fuente: 06 §4 · RR-14 · 08 §6)*
- **FR-080**: El sistema debe permitir solo al Administrador encender `ia_activa` o `trading_activo`, y debe rechazar el encendido mientras el fondo no tenga un aporte confirmado. *(Encendido de un interruptor · actores: Administrador · fuente: PM-57 · RN-11 · 08 §7.6)*
- **FR-047**: Mientras no exista un aporte confirmado, el sistema debe mantener apagados los interruptores, no correr la IA ni aceptar operaciones, y la app debe mostrar "Fondo sin capital". *(Fondo sin capital · actores: Usuario, Analista y Administrador · fuente: RN-11 · CB-80)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa una, definida en `docs/06` §4:

- **Fondo**: guarda los dos interruptores (IA y trading) y, de la última pausa, el motivo, quién la hizo y cuándo.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: El fondo recién creado tiene la IA y el trading apagados.
- **SC-002**: Mientras no hay un aporte confirmado, ningún interruptor se enciende y la app muestra "Fondo sin capital".
- **SC-003**: Con capital, el Administrador los enciende y los apaga, y cada apagado queda con su motivo, su autor y su hora.
- **SC-004**: Un Usuario o un Analista no logra encender un interruptor.
- **SC-005**: Cada encendido y cada apagado quedan en la bitácora.

## Supuestos (Assumptions)

- Depende de HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25: solo se enciende con un aporte confirmado.
- Depende de HU-107 · Bitácora inmutable con cadena de hash: registra el encendido y el apagado.
- Depende de HU-083 · Canales privados de tiempo real: publica `interruptor` en el canal `admin`.
- El freno para Analistas con botón en la barra y sus efectos sobre sugerencias y órdenes llegan en HU-039; la condición de reanudar con la conciliación en orden, en HU-040.
- La pantalla está en HU-101.
