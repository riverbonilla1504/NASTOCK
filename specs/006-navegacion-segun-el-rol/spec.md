# Especificación de funcionalidad (Feature Specification): HU-006 · Navegación y guardas según el rol

**Feature Branch**: `006-navegacion-segun-el-rol`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-006 · Navegación y guardas según el rol", en [`backlog/E-02-identidad-y-acceso/HU-006-navegacion-y-guardas-segun-el-rol.md`](../../backlog/E-02-identidad-y-acceso/HU-006-navegacion-y-guardas-segun-el-rol.md)

> **MVP corto** (D-58, [`docs/14` §4.1](../../docs/14-mapa-para-backlog.md#41-mvp-corto-lo-que-se-entrega-primero-d-58)): el menú de cada rol solo tiene las pantallas del MVP corto, según la tabla de [`docs/03` §3](../../docs/03-roles-y-permisos.md#3-qué-ve-cada-rol-pantallas). Las que no existen no tienen ruta.

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Navegación y guardas según el rol (Prioridad: P1)

**Como** Usuario, Analista o Administrador, **quiero** ver solo los menús y las pantallas de mi rol, **para** encontrar rápido lo que me toca y no llegar a pantallas que no puedo usar.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R1 · Ver el mercado en vivo. Cada rol ve solo las pantallas que le corresponden (`docs/03` §3). La app oculta lo que no toca para que la experiencia sea limpia, pero la seguridad real está en el servidor (`docs/03` §1, principio 3). Habilita ocho historias: HU-008 (la pantalla cuelga del menú por rol), HU-019 (la pantalla cuelga del menú del Usuario), HU-020 (la pantalla cuelga del menú de los tres roles), HU-030 (es la pantalla de inicio de los tres roles), HU-048 (la pantalla cuelga del menú de los tres roles), HU-057 (la pantalla cuelga del menú de Analista y Administrador), HU-085 (la pantalla cuelga del menú de los tres roles) y HU-097 (cuelga de la navegación por rol).

**Prueba independiente (Independent Test)**: Se demuestra sola con el escenario E2E-01, que esta historia agrega: cada rol ve su navegación y las rutas prohibidas redirigen. Lo acompañan las pruebas de pantalla de las guardas para cada rol. Entrega una app en la que cada persona encuentra solo lo de su rol.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dados** un Usuario, un Analista y un Administrador con sesión, **cuando** abren la app, **entonces** cada uno ve el menú de su rol según 03 §3.
2. **CA-2** · **Dado** un Usuario, **cuando** abre un enlace a `/admin/...` o a `/riesgo/...`, **entonces** el enrutador lo lleva a `/inicio`.
3. **CA-3** · **Dada** una persona sin sesión, **cuando** abre cualquier ruta, **entonces** llega a `/ingreso`; y con `app_estado` distinto de activo, a `/cuenta-suspendida`.
4. **CA-4** · **Dado** un Administrador, **cuando** abre `/riesgo/...`, **entonces** entra en modo de solo lectura.

---

### Casos borde (Edge Cases)

HU-006 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-021**: La app debe mostrar solo las pantallas del rol de la sesión, llevar a la pantalla de ingreso cuando no hay sesión, a la de cuenta suspendida cuando la cuenta no está activa y al inicio cuando la ruta no pertenece al rol. *(Navegación según el rol · actores: Usuario, Analista y Administrador · fuente: 03 §3 · 05 §9.3)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades. Usa una, definida en `docs/06` §5.1:

- **Perfil**: la persona dentro de la plataforma. Su rol decide qué menú ve y su estado decide si entra a la app o a la pantalla de cuenta suspendida.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Un Usuario, un Analista y un Administrador abren la app y cada uno ve solo las pantallas de su rol, según la tabla de `docs/03` §3.
- **SC-002**: Quien abre un enlace a una pantalla que su rol no tiene vuelve al inicio; quien no tiene sesión llega a la pantalla de ingreso; y quien no tiene la cuenta activa llega a la de cuenta suspendida.
- **SC-003**: Un Administrador puede abrir la bandeja de riesgo solo para consultarla.
- **SC-004**: El indicador "Escenarios E2E en verde en `main`: 100 % siempre" de `docs/01` §6 se cumple con E2E-01.

## Supuestos (Assumptions)

- Depende de HU-005 · Ingresar con Google en Android y web: necesita una sesión con rol.
- Depende de TT-06 · Arnés E2E de backend y de la app: agrega el escenario E2E-01.
- La navegación es experiencia de uso; la seguridad real está en la base de datos y en sus funciones (`docs/03` §4).
- En R1, CA-3 se prueba con una cuenta de prueba ya suspendida, porque suspender una cuenta llega con HU-010 (R2).
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.
- **Lecturas de `docs/03` §3 para el MVP corto** (se anotan también en el informe): el menú de cada rol son las pantallas con pestaña (Mercado, Oportunidades, Mi cupo, Alertas y Administración); **Nueva orden manual no es pestaña** (la isla de `DESIGN.md` admite cuatro destinos y la acción va en la tarjeta de detalle) y su ruta y regla las crea HU-075. Oportunidades, Mi cupo, Alertas y Administración llevan un **marcador** hasta que su historia construya la pantalla. Las rutas de las pantallas que no existen en el MVP corto (p. ej. `/riesgo/*`) no se crean: llevan a `/inicio`; CA-4 se prueba sobre la política de acceso y su proveedor, que la futura Bandeja de riesgo consulta.
- El estado y el rol salen del token (`docs/03` §4.1), que puede tardar hasta 15 minutos en reflejar un cambio (`docs/04` §8); una sesión sin esos claims se trata como no activa. La seguridad real no depende de la guarda.
- **Pendiente del coordinador:** sembrar una cuenta de prueba suspendida cambia la fila "Usuarios de prueba" de `docs/15` §3. Sin esa aprobación, CA-3 se prueba con un token suspendido en pruebas de widget y con una cuenta suspendida creada dentro del E2E de backend.
