# Especificación de funcionalidad (Feature Specification): HU-032 · Aviso de dato desactualizado

**Feature Branch**: `032-aviso-dato-desactualizado`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-032 · Aviso de dato desactualizado", en [`backlog/E-04-datos-de-mercado/HU-032-aviso-de-dato-desactualizado.md`](../../backlog/E-04-datos-de-mercado/HU-032-aviso-de-dato-desactualizado.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Aviso de dato desactualizado (Prioridad: P1)

**Como** Usuario, Analista o Administrador, **quiero** que la app me avise cuando un precio está desactualizado, **para** no decidir con un dato viejo.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R1 · Ver el mercado en vivo. Ninguna operación se hace con un precio viejo: la cotización debe tener menos de 60 segundos por defecto (RR-11). La app marca el dato desactualizado y deshabilita aprobar, aunque el servidor igual lo rechazaría (`docs/08` §9.4). Habilita una historia: HU-061 (deshabilita la decisión con el dato desactualizado).

**Prueba independiente (Independent Test)**: Se demuestra sola con el escenario E2E-03, que esta historia extiende: al detener la ingesta simulada, la app marca el dato como desactualizado. Lo acompañan las pruebas de pantalla con el reloj controlado. Entrega el aviso que evita decidir con un dato viejo.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** un precio con más de `mercado.max_antiguedad_cotizacion_seg` segundos, **cuando** se muestra, **entonces** lleva la marca "dato desactualizado".
2. **CA-2** (caso borde CB-52) · **Dada** una suspensión general del mercado, **cuando** los precios se congelan, **entonces** todos quedan marcados como desactualizados.
3. **CA-3** · **Dado** un precio desactualizado, **cuando** la persona está en una pantalla con botones de aprobar o de comprar, **entonces** esos botones quedan deshabilitados.
4. **CA-4** · **Dado** que llegan precios nuevos, **cuando** se reciben, **entonces** la marca desaparece.
5. **CA-5** (caso borde CB-69) · **Dado** que el trabajo programado deja de correr, **cuando** el precio supera la antigüedad máxima, **entonces** la app muestra "dato desactualizado" por la antigüedad del precio.

---

### Casos borde (Edge Cases)

- **CB-52** · Suspensión general del mercado (*circuit breaker*). Precios se congelan → "dato desactualizado" → aprobaciones y compras bloqueadas; órdenes vivas vencen por tiempo (`docs/12` §6; fuente: RR-11). Lo comprueba CA-2.
- **CB-69** · El cron deja de correr (proyecto pausado, error de plataforma). La app muestra "dato desactualizado" por la antigüedad del precio. Se recomienda un monitor externo de disponibilidad que consulte un endpoint de salud y avise por correo (`docs/12` §8; fuente: RSG-07). Lo comprueba CA-5.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-075**: La app debe marcar "dato desactualizado" junto a todo precio con más de `mercado.max_antiguedad_cotizacion_seg` segundos y deshabilitar aprobar y comprar mientras dure. *(Dato desactualizado · actores: Usuario, Analista y Administrador · fuente: 09 §2 · 08 §9.4 · RR-11 · CB-52)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa una, definida en `docs/06` §5.2:

- **Cotización**: el último precio conocido de cada símbolo, con la hora del dato. De ella sale su antigüedad.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Todo precio con más antigüedad que la máxima configurada (60 segundos por defecto) se muestra con la marca "dato desactualizado".
- **SC-002**: Mientras un precio está desactualizado, los botones de aprobar y de comprar quedan deshabilitados.
- **SC-003**: Cuando llegan precios nuevos, la marca desaparece.
- **SC-004**: El indicador "Escenarios E2E en verde en `main`: 100 % siempre" de `docs/01` §6 se cumple con E2E-03.

## Supuestos (Assumptions)

- Depende de HU-030 · Pantalla de mercado en vivo: la marca se muestra junto a los precios de la pantalla de mercado.
- El servidor rechaza igual la operación con un precio desactualizado (RR-11, en HU-037); la marca en la app evita el intento.
- También es la señal visible de que el trabajo programado dejó de correr (CB-69).
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.
