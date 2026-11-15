# Especificación de funcionalidad (Feature Specification): HU-075 · Crear una orden manual en mi cupo

**Feature Branch**: `075-crear-una-orden-manual`

**Created**: 2026-11-14

**Status**: Implementada (#193; especificación escrita después de construir)

**Input**: Historia de usuario: "HU-075 · Crear una orden manual en mi cupo", en [`backlog/E-08-ejecucion-y-broker/HU-075-crear-una-orden-manual-en-mi-cupo.md`](../../backlog/E-08-ejecucion-y-broker/HU-075-crear-una-orden-manual-en-mi-cupo.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Crear una orden manual en mi cupo (Prioridad: P1)

**Como** Usuario, **quiero** crear una orden de compra o de venta en mi cupo, viendo antes la opinión de la IA, **para** operar por iniciativa propia dentro de las reglas de riesgo.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R4 · Decidir y operar en paper. Cambios del MVP corto ([docs/14 §4.1](../../docs/14-mapa-para-backlog.md#41-mvp-corto-lo-que-se-entrega-primero-d-58)): - CA-1: sin la opinión de la IA antes de confirmar (D-60). - CA-2: se confirma en el **diálogo** que repite monto y símbolo (D-61) y la orden se guarda sin `opinion_id`. - Solo acciones enteras (D-63): una compra por menos de una acción se rechaza. El código de error está pendiente en "Documentación a actualizar". - Tareas: `crear_orden_manual` sin el parámetro `opinion_id`; la app no llama a `opinion-ia` ni muestra veredicto. E2E-11 va sin opinión (15 §4). - **Sin sugerencias (D-65):** la orden manual es la única forma de comprar o vender, y esta historia crea E2E-08: orden manual de compra → envío → llenado → posición y protección → venta por objetivo → reparto visible en los tres bolsillos. Antes lo creaba HU-062. - Con el precio desactualizado, el botón de comprar queda deshabilitado (CA-3 de HU-032). Antes lo hacía la bandeja de sugerencias (HU-061), que sale del MVP corto (D-65). - Las dependencias de HU-052 y HU-009 no aplican. Habilita HU-074 · Sincronizar órdenes y aplicar llenados, HU-076 · Ver mis órdenes y cancelar una que no se ha llenado.

**Prueba independiente (Independent Test)**: E2E-11 (nuevo). En el MVP corto también E2E-08 (nuevo, D-65).

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** un Usuario con disponible, **cuando** arma una compra de USD 150 de QQQ, **entonces** el stop y el objetivo vienen precargados con `riesgo.cupo.stop_defecto_pct` y `riesgo.cupo.objetivo_defecto_pct`, y ve la opinión de la IA antes de confirmar.
2. **CA-2** · **Dada** la confirmación biométrica, **cuando** envía la orden, **entonces** se valida con el motor de políticas, se retienen los fondos, se crea la orden con origen `manual` y su `opinion_id`, se encola y se registra `orden.manual_creada`.
3. **CA-3** · **Dado** un reintento de la app con el mismo id, **cuando** llega, **entonces** devuelve la misma orden sin duplicarla.
4. **CA-4** · **Dado** el mercado cerrado, **cuando** intenta crear la orden, **entonces** recibe `MERCADO_CERRADO` con la hora de apertura.
5. **CA-5** · **Dada** una orden que viola una regla de riesgo, **cuando** se envía, **entonces** recibe `REGLA_RR_xx` con el texto de la regla.
6. **CA-6** (permiso) · **Dado** un Analista o un Administrador, **cuando** llama `crear_orden_manual`, **entonces** recibe `NO_AUTORIZADO`; un Usuario solo puede operar su propio cupo.

---

### Casos borde (Edge Cases)

Ninguno propio.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-169**: El sistema debe permitir al Usuario crear una orden manual de compra o de venta en su cupo, con stop y objetivo precargados con los valores por defecto, validada por el motor de políticas, con retención y encolado, y rechazarla con el mercado cerrado. *(Orden manual · actores: Usuario · fuente: PM-12 · 08 §7.5 · RN-43 · 02 §10)*
- **FR-170**: El sistema debe usar el id generado en la app como clave de idempotencia de la orden manual: reintentar con el mismo id devuelve la misma orden. *(Orden manual sin duplicados · actores: Usuario · fuente: 08 §7.5 · 08 §9.3)*
- **FR-092**: El sistema debe guardar en cada sugerencia y en cada orden una copia de los parámetros con los que se validó; un cambio posterior de parámetros no debe alterar las ya creadas. *(Copia congelada de parámetros · actores: Sistema · fuente: RN-39 · CB-73 · CB-74)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

- **Orden** (`ordenes`) con origen `manual`, cantidad entera, límite fijado por la banda de precio, stop y objetivo; nace `creada` y entra a la cola de envío (HU-073).
- **Retención**: el disponible del cupo que la orden aparta hasta llenarse o cancelarse (RN-23).

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: El stop y el objetivo vienen precargados con `riesgo.cupo.stop_defecto_pct` y `riesgo.cupo.objetivo_defecto_pct`, y ve la opinión de la IA antes de confirmar (CA-1).
- **SC-002**: Se valida con el motor de políticas, se retienen los fondos, se crea la orden con origen `manual` y su `opinion_id`, se encola y se registra `orden.manual_creada` (CA-2).
- **SC-003**: Devuelve la misma orden sin duplicarla (CA-3).
- **SC-004**: Recibe `MERCADO_CERRADO` con la hora de apertura (CA-4).
- **SC-005**: Recibe `REGLA_RR_xx` con el texto de la regla (CA-5).
- **SC-006**: Recibe `NO_AUTORIZADO`; un Usuario solo puede operar su propio cupo (CA-6).

## Supuestos (Assumptions)

- Depende de HU-073 · Enviar al broker las órdenes aprobadas: La orden manual se envía con el mismo ejecutor.
- Depende de HU-032 · Aviso de dato desactualizado: En el MVP corto deshabilita la compra con el dato desactualizado, como hacía HU-061 (D-65).
- Depende de HU-019 · Ver mi cupo: Opera sobre el disponible del cupo.
- Depende de TT-06 · Arnés E2E de backend y de la app: Agrega el escenario E2E-11.
- Solo acciones enteras (D-63): la orden se arma por cantidad, no por monto; el diálogo estima el monto con el precio actual.
- Confirmación con diálogo que repite símbolo y monto, sin biometría (D-61).
- Sin opinión de la IA (D-60): la orden no lleva `opinion_id`.
- Pendientes (`docs/18` §3): E2E-11, ver y cancelar la orden en "Mis órdenes" (HU-076) y bloquear la compra con el precio desactualizado (HU-032).
