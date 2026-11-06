# Especificación de funcionalidad (Feature Specification): HU-116 · Identidad visual y sistema de diseño

**Feature Branch**: `116-tema-y-estilos-de-la-v2`

**Created**: 2026-10-12 · **Actualizada**: 2026-11-06 (D-67: cambia el alcance y entra al MVP corto)

**Status**: Draft

**Input**: Historia de usuario: "HU-116 · Identidad visual y sistema de diseño", en [`backlog/E-13-transicion-desde-la-v2/HU-116-tema-estilos-widgets-y-fuentes-de-la-v2.md`](../../backlog/E-13-transicion-desde-la-v2/HU-116-tema-estilos-widgets-y-fuentes-de-la-v2.md)

> **Entra al MVP corto con otro alcance** (D-67, [`docs/14` §4.1](../../docs/14-mapa-para-backlog.md#41-mvp-corto-lo-que-se-entrega-primero-d-58)): ya no copia la interfaz de la v2. Construye con impeccable un diseño visual nuevo; la v2 solo es referencia de contenido y antirreferencia visual. El nombre de la rama y de la carpeta se conservan.

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Identidad visual y sistema de diseño (Prioridad: P1)

**Como** Usuario, Analista o Administrador, **quiero** que la app tenga una identidad visual propia, **para** reconocer la plataforma y que todas las pantallas se vean consistentes.

**Por qué esta prioridad (Why this priority)**: Pertenece a la entrega R1 · Ver el mercado en vivo y es la base visual de todas las pantallas del MVP corto. La interfaz de la v2 no se copia: solo es referencia de contenido (`docs/05` §11, D-67). Toda historia con pantallas usa este sistema (`docs/15` §12).

**Prueba independiente (Independent Test)**: Se demuestra sola con el catálogo de componentes (solo en debug o con `MODO_PRUEBAS`), sus pruebas de widget y las revisiones de impeccable en Chrome y en el emulador. No tiene escenario E2E propio.

**Escenarios de aceptación (Acceptance Scenarios)**:

Los criterios CA-1 a CA-3 de la versión anterior se retiraron por D-67 (describían la copia del código de la v2). Sus identificadores no se reutilizan.

1. **CA-4** · **Dados** `docs/01` a `docs/04`, **cuando** se escribe `PRODUCT.md` con impeccable, **entonces** describe los usuarios, el propósito y el tono sin agregar nada que no esté en esos documentos.
2. **CA-5** · **Dada** la dirección visual aprobada por el equipo, **cuando** se documenta, **entonces** `DESIGN.md`, en la raíz, define los tokens (color, tipografía, espaciado, forma y elevación), los componentes, el movimiento y el tono visual, y `.impeccable/config.json` queda en el repositorio.
3. **CA-6** · **Dado** el tema de `lib/app/tema.dart`, **cuando** se construye cualquier pantalla, **entonces** toma colores, tipografía y medidas de los tokens de `DESIGN.md`.
4. **CA-7** · **Dados** los componentes de `lib/shared/widgets/` (botón primario y secundario, tarjeta, campo, aviso en línea, aviso temporal, estados vacío, de carga y de error, selector de fecha y calendario, cifra en USD con variación y chip de estado), **cuando** se usan, **entonces** cada uno tiene su prueba de widget.
5. **CA-8** · **Dado** un aviso o un estado (información, éxito, advertencia, error o dato desactualizado), **cuando** se muestra, **entonces** su significado se entiende también sin color, por su texto y su ícono o su forma.
6. **CA-9** · **Dado** un error capturado, **cuando** lo muestra un componente del sistema, **entonces** el texto pasa por la traducción de errores de `lib/core/errores/` y nunca muestra el texto crudo de la excepción.
7. **CA-10** · **Dada** la app en modo debug o con `MODO_PRUEBAS`, **cuando** se abre el catálogo de componentes, **entonces** muestra todos los componentes juntos; en una compilación sin debug y sin `MODO_PRUEBAS`, el catálogo no existe.
8. **CA-11** · **Dado** el sistema terminado, **cuando** corren `/impeccable audit` y `/impeccable polish`, **entonces** lo que encuentran queda corregido y revisado en Chrome y en el emulador de Android.
9. **CA-12** · **Dadas** las fuentes y el código del sistema, **cuando** corren `flutter analyze` y `flutter test`, **entonces** no dejan advertencias ni fallos, y las fuentes están en `assets/fonts/` con su licencia libre, sin cargarse de un servicio externo.

---

### Casos borde (Edge Cases)

HU-116 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

HU-116 no cita requisitos funcionales. La historia dice: "Ninguno: este ítem no agrega un requisito funcional del producto."

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no maneja entidades de datos.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-004**: El producto y el sistema visual están escritos (`PRODUCT.md` y `DESIGN.md`) y el tema de la app sale de los tokens documentados.
- **SC-005**: Cada componente común tiene su prueba de widget y se puede revisar junto a los demás en el catálogo.
- **SC-006**: Ningún aviso ni estado depende solo del color para entenderse.
- **SC-007**: El análisis estático y las pruebas no dejan advertencias ni fallos.

Los criterios SC-001 a SC-003 de la versión anterior se retiraron por D-67.

## Supuestos (Assumptions)

- Depende de TT-04 · Esqueleto de la app Flutter para Android y web: se construye dentro del esqueleto de la app.
- No agrega un requisito funcional: es la base visual que usan todas las pantallas.
- `DESIGN.md` manda en lo visual y `docs/` en las reglas de negocio, los flujos, los permisos, los datos y los textos de error; si chocan en algo que no es visual, manda `docs/` (D-67).
- **S2** (`docs/01` §5): La app sigue siendo Flutter (Android + web). Si resulta falso: la arquitectura de backend no cambia; cambia solo el cliente.
