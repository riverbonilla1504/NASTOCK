# Especificación de funcionalidad (Feature Specification): HU-117 · Exportador de reportes de la v2 con sus pruebas

**Feature Branch**: `117-exportador-de-reportes`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-117 · Exportador de reportes de la v2 con sus pruebas", en [`backlog/E-13-transicion-desde-la-v2/HU-117-exportador-de-reportes-de-la-v2-con-sus-pruebas.md`](../../backlog/E-13-transicion-desde-la-v2/HU-117-exportador-de-reportes-de-la-v2-con-sus-pruebas.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Exportador de reportes de la v2 con sus pruebas (Prioridad: P1)

**Como** Administrador, **quiero** que el exportador de reportes de la v2 quede disponible con sus pruebas, **para** que la exportación CSV parta de código ya probado.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Baja y pertenece a la entrega R1 · Ver el mercado en vivo. La exportación CSV entra en el MVP (`docs/01` §4) y parte del exportador de la versión anterior, que se copia con su prueba (`docs/05` §11). Habilita dos historias: HU-095 (usa el exportador copiado de la v2) y HU-108 (exporta con el exportador de la v2).

**Prueba independiente (Independent Test)**: Se demuestra sola con la prueba que viene con el exportador, que debe pasar en la app nueva. No tiene escenario E2E propio. Entrega el exportador que después usan los reportes CSV (HU-095) y la exportación de la bitácora (HU-108).

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dado** `report_exporter.dart` con su prueba, **cuando** se copia, **entonces** queda en `lib/features/reportes/` y su prueba pasa.
2. **CA-2** · **Dado** un conjunto de filas, **cuando** se exporta, **entonces** el CSV sale con encabezados y con los montos en el formato de la app.
3. **CA-3** · **Dado** el exportador, **cuando** se usa en web y en Android, **entonces** genera el archivo en las dos plataformas.

---

### Casos borde (Edge Cases)

HU-117 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-203**: El sistema debe permitir exportar reportes en CSV: al Usuario los de su cupo y a Analistas y Administradores los del fondo. *(Exportación CSV · actores: Usuario, Analista y Administrador · fuente: PM-33 · 01 §4 · Q-15)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no maneja entidades de datos de `docs/06`: convierte filas en un archivo CSV.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: El exportador copiado genera un CSV con encabezados y con los montos en el formato de la app.
- **SC-002**: El archivo se genera tanto en la web como en Android.
- **SC-003**: La prueba que viene con el exportador pasa en la app nueva.

## Supuestos (Assumptions)

- Depende de TT-04 · Esqueleto de la app Flutter para Android y web: se copia dentro del esqueleto de la app.
- Lo usan la exportación de la bitácora (HU-108) y los reportes CSV (HU-095).
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.
- **Q-15** (`docs/13` §2, abierta): ¿Qué reportes necesita contabilidad (formato, periodicidad, PDF)? Valor provisional: CSV mensual.
