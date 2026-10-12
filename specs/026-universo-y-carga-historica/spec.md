# Especificación de funcionalidad (Feature Specification): HU-026 · Universo del NASDAQ-100 y carga histórica de barras

**Feature Branch**: `026-universo-y-carga-historica`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-026 · Universo del NASDAQ-100 y carga histórica de barras", en [`backlog/E-04-datos-de-mercado/HU-026-universo-del-nasdaq-100-y-carga-historica-de-barras.md`](../../backlog/E-04-datos-de-mercado/HU-026-universo-del-nasdaq-100-y-carga-historica-de-barras.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Universo del NASDAQ-100 y carga histórica de barras (Prioridad: P1)

**Como** Analista, **quiero** que el sistema tenga la lista de los componentes del NASDAQ-100 y sus ETFs con dos años de historia, **para** que el mercado y la IA trabajen sobre un universo conocido y con datos suficientes.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R1 · Ver el mercado en vivo. La lista blanca por bolsillo es una decisión del cliente (D-06) y define qué se compra en cada uno: QLD y QQQ en Usuarios, y TQQQ y los componentes del NASDAQ-100 en Arriesgadas (`docs/02` §1). Los dos años de barras diarias hacen falta para la media de 200 días y el máximo de 52 semanas (`docs/10` §12). Habilita cinco historias: HU-027 (sincroniza los atributos de los símbolos de la lista blanca), HU-028 (consulta los símbolos del universo), HU-029 (guarda las barras de los símbolos del universo), HU-036 (edita la tabla `lista_blanca` sembrada con el universo) y HU-041 (descarga noticias de los símbolos del universo).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas de funciones que nombra la historia, con respuestas grabadas y con el proveedor simulado. No tiene escenario E2E propio. Entrega el universo de símbolos con su historia, sobre el que trabajan el mercado y la IA.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dada** la base recién creada, **cuando** se consulta `lista_blanca`, **entonces** Usuarios tiene QLD y QQQ, y Arriesgadas tiene TQQQ y los componentes del NASDAQ-100 con su nombre y su sector.
2. **CA-2** · **Dada** la carga inicial, **cuando** termina, **entonces** cada símbolo del universo tiene dos años de barras diarias en `barras_diarias`.
3. **CA-3** · **Dado** que la carga inicial corre otra vez, **cuando** termina, **entonces** no duplica barras.
4. **CA-4** (permiso) · **Dada** cualquier persona activa, **cuando** lee `lista_blanca` y `barras_diarias`, **entonces** las ve; y cuando intenta escribir directo, la base de datos lo rechaza.

---

### Casos borde (Edge Cases)

HU-026 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-061**: El sistema debe mantener la lista blanca por bolsillo sembrada con QLD y QQQ en Usuarios y con TQQQ y los componentes del NASDAQ-100, con su sector, en Arriesgadas. *(Universo de símbolos · actores: Sistema · fuente: 06 §5.2 · 10 §12 · D-06 · Q-13 · Q-20)*
- **FR-062**: Al conectar el proyecto, el sistema debe cargar dos años de barras diarias de cada símbolo del universo. *(Carga histórica de barras · actores: Sistema y Datos de mercado (Alpaca) · fuente: 10 §12)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia agrega dos entidades, definidas en `docs/06` §5.2:

- **Lista blanca**: los símbolos que se pueden ver y operar en cada bolsillo. Atributos clave: bolsillo, símbolo, nombre, sector, si pertenece al NASDAQ-100 y si está activo.
- **Barra diaria**: el resumen de un día de mercado de un símbolo: apertura, máximo, mínimo, cierre y volumen. Se guarda siempre.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: El bolsillo de Usuarios tiene QLD y QQQ, y el de Arriesgadas tiene TQQQ y los componentes del NASDAQ-100, cada uno con su nombre y su sector.
- **SC-002**: Cada símbolo del universo tiene dos años de barras diarias.
- **SC-003**: Repetir la carga inicial no duplica barras.
- **SC-004**: Cualquier persona activa puede consultar la lista blanca y las barras, y nadie puede escribirlas directo.

## Supuestos (Assumptions)

- Depende de TT-03 · Base de Supabase: esquema private, extensiones, Vault y ping: crea tablas y funciones sobre el proyecto base.
- Depende de TT-05 · Base de proveedores simulados, reloj controlable y datos de prueba: el proveedor de mercado se elige con `_shared/proveedores.ts`.
- QQQ se ingiere siempre, aunque no esté activo en ningún bolsillo: es la referencia del índice.
- Alpaca no informa qué acciones componen el índice: la lista la mantiene el Administrador (HU-036).
- **S6** (`docs/01` §5): El plan gratuito de Supabase alcanza para el MVP (límites y cómo se manejan en 05 §3.4). Si resulta falso: pasar a un plan pago requiere aprobación (D-45).
- **Q-13** (`docs/13` §2, abierta): ¿El universo de Arriesgadas son los ~100 componentes del NASDAQ-100 completos o un subconjunto? Valor provisional: Los ~100 + TQQQ.
- **Q-20** (`docs/13` §2, abierta): ¿El bolsillo de Usuarios también debe poder comprar acciones individuales del NASDAQ-100, o solo QLD y QQQ? Valor provisional: Solo QLD y QQQ.
