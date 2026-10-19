# Especificación de funcionalidad (Feature Specification): HU-028 · Ingesta de precios cada 15 segundos

**Feature Branch**: `028-ingesta-de-precios`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-028 · Ingesta de precios cada 15 segundos", en [`backlog/E-04-datos-de-mercado/HU-028-ingesta-de-precios-cada-15-segundos.md`](../../backlog/E-04-datos-de-mercado/HU-028-ingesta-de-precios-cada-15-segundos.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Ingesta de precios cada 15 segundos (Prioridad: P1)

**Como** Usuario, Analista o Administrador, **quiero** que los precios del NASDAQ-100 y sus ETFs se actualicen cada 15 segundos mientras el mercado está abierto, **para** ver el mercado casi en tiempo real.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R1 · Ver el mercado en vivo. En el MVP los precios llegan por consulta cada 15 segundos, no por WebSocket (D-24). Es lo que permite ver el mercado en vivo: los precios del universo se actualizan cada ~15 s en horario de mercado (`docs/09` §1). Habilita siete historias: HU-030 (muestra los precios que publica la ingesta), HU-035 (la ingesta es la primera función que registra su salud), HU-037 (RR-07 y RR-11 usan el horario y la última cotización), HU-044 (usa el precio en vivo y su antigüedad), HU-046 (el evento de QQQ se detecta al publicar cotizaciones), HU-067 (la banda se revisa al publicar cotizaciones) y HU-078 (se evalúa con cada lote de cotizaciones).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas que nombra la historia: las de la ingesta (precio inválido y fallo del proveedor) y las de la publicación de cotizaciones. No tiene escenario E2E propio; la ejercita E2E-03. Entrega precios actualizados cada 15 segundos mientras el mercado está abierto.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** el mercado en ventana, **cuando** pasan 15 segundos, **entonces** `ingesta-mercado` consulta todos los símbolos en una sola llamada, actualiza `cotizaciones` y publica el evento `cotizaciones` en el canal `mercado`.
2. **CA-2** (caso borde CB-53) · **Dado** un precio nulo, no numérico o menor o igual a cero, **cuando** llega, **entonces** ese símbolo se descarta y queda registrado, y los demás se guardan.
3. **CA-3** · **Dado** el mercado cerrado, **cuando** corre el trabajo programado, **entonces** no llama al proveedor y la app muestra el cierre anterior.
4. **CA-4** · **Dado** un fallo del proveedor, **cuando** ocurre, **entonces** la app sigue mostrando el último precio con su antigüedad.
5. **CA-5** (permiso) · **Dada** una llamada a `ingesta-mercado` sin el secreto interno, **cuando** llega, **entonces** la función la rechaza.

---

### Casos borde (Edge Cases)

- **CB-53** · Precio inválido del proveedor (0, negativo, vacío). Se descarta ese dato y se registra (`docs/12` §6; fuente: 09 §2). Lo comprueba CA-2.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-066**: Con el mercado en ventana, el sistema debe consultar cada 15 segundos, en una sola llamada, los precios de todo el universo y los ETFs y guardar la última cotización de cada símbolo. *(Ingesta de precios · actores: Sistema y Datos de mercado (Alpaca) · fuente: 09 §2 · 05 §6 · 05 §7 · D-24)*
- **FR-067**: El sistema debe descartar y registrar todo precio nulo, no numérico o menor o igual a cero. *(Descarte de precios inválidos · actores: Sistema · fuente: 09 §2 · CB-53)*
- **FR-068**: Fuera del horario de mercado, el sistema no debe consultar precios y la app debe mostrar el cierre anterior. *(Sin consulta fuera de horario · actores: Sistema · fuente: 09 §2)*
- **FR-069**: El sistema debe publicar cada lote de cotizaciones en el canal `mercado` para todas las personas activas. *(Difusión de precios en vivo · actores: Sistema · fuente: 09 §1 · 09 §3 · 09 §4)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia agrega una entidad, definida en `docs/06` §5.2:

- **Cotización**: el último precio conocido de cada símbolo. Atributos clave: precio, cierre anterior, variación del día, fuente, la hora del dato según el proveedor y la hora en que se recibió. Solo se guarda la última por símbolo.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Con el mercado abierto, los precios del universo y de los ETFs se actualizan cada 15 segundos.
- **SC-002**: El retraso de los precios en pantalla durante el horario de mercado es menor de 30 segundos (indicador de `docs/01` §6).
- **SC-003**: Un precio inválido no llega a guardarse ni a mostrarse, y los demás símbolos se actualizan.
- **SC-004**: Con el mercado cerrado no se consulta al proveedor y se muestra el cierre anterior.

## Supuestos (Assumptions)

- Depende de HU-026 · Universo del NASDAQ-100 y carga histórica de barras: consulta los símbolos del universo.
- Depende de HU-027 · Calendario, reloj y estado del mercado: solo consulta con el mercado en ventana.
- Depende de HU-083 · Canales privados de tiempo real: publica en el canal `mercado`.
- La publicación de cotizaciones crece con otras historias: protecciones virtuales (HU-078), invalidación por banda (HU-067) y evento de QQQ (HU-046).
- El feed gratuito es IEX: puede diferir unos centavos del consolidado (CB-54).
- El registro de la salud de la integración se agrega en HU-035.
- **S5** (`docs/01` §5): Los ~100 símbolos del universo se pueden consultar por REST cada 15 s dentro del límite gratuito (200 solicitudes por minuto; una llamada trae todos). Si resulta falso: bajar la frecuencia o limitar el universo.
