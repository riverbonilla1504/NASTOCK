# Especificación de funcionalidad (Feature Specification): HU-107 · Bitácora inmutable con cadena de hash

**Feature Branch**: `107-bitacora-inmutable`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-107 · Bitácora inmutable con cadena de hash", en [`backlog/E-12-seguridad-auditoria-y-cumplimiento/HU-107-bitacora-inmutable-con-cadena-de-hash.md`](../../backlog/E-12-seguridad-auditoria-y-cumplimiento/HU-107-bitacora-inmutable-con-cadena-de-hash.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Bitácora inmutable con cadena de hash (Prioridad: P1)

**Como** Administrador, **quiero** que toda acción sensible quede en una bitácora que nadie puede alterar, **para** poder demostrar después quién hizo qué y cuándo.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R1 · Ver el mercado en vivo. Todo queda auditado: cada decisión, cambio de parámetro y movimiento de dinero queda en una bitácora inmutable (`docs/01` §2, P6). Nadie puede escribir en ella por fuera de su mecanismo ni cambiarla, y cada registro se encadena con el anterior (`docs/11` §4.3). Habilita trece historias: HU-002 (el alta registra `cuenta.activada`), HU-010 (registra `cuenta.suspendida` y `cuenta.reactivada`), HU-011 (registra `cuenta.rol_cambiado`), HU-014 (registra `capital.aporte_registrado` y `capital.aporte_anulado`), HU-022 (registra `ajuste.registrado`), HU-033 (registra `parametro.cambiado`), HU-034 (registra el encendido y el apagado), HU-035 (registra `integracion.caida` e `integracion.recuperada`), HU-036 (registra `lista_blanca.cambiada`), HU-050 (registra `ia.presupuesto_agotado`), HU-054 (registra `prompt.creado` y `prompt.activado`), HU-096 (incluye el último hash de la bitácora) y HU-108 (consulta la tabla `auditoria`).

**Prueba independiente (Independent Test)**: Se demuestra sola con las pruebas de base de datos que nombra la historia: encadenado, concurrencia, inmutabilidad y lectura por rol. No tiene escenario E2E propio; la ejercita E2E-14, que llega en R2 con HU-108. Entrega la bitácora donde queda quién hizo qué y cuándo.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dada** una acción del catálogo de 11 §4.1, **cuando** ocurre, **entonces** `private.auditar` agrega un registro con momento, actor, rol, acción, entidad, id, valores anterior y nuevo y origen.
2. **CA-2** · **Dado** un registro nuevo, **cuando** se inserta, **entonces** su `hash` es `sha256(hash_anterior ‖ momento ‖ actor ‖ acción ‖ entidad ‖ id ‖ detalle)`, y dos inserciones simultáneas no usan el mismo `hash_anterior`.
3. **CA-3** (permiso) · **Dado** cualquier rol de la API, incluida la llave secreta, **cuando** intenta un `INSERT`, un `UPDATE` o un `DELETE` directo sobre `auditoria`, **entonces** se rechaza.
4. **CA-4** · **Dado** un registro, **cuando** se revisa, **entonces** no contiene llaves, tokens ni respuestas de Google.
5. **CA-5** (aislamiento) · **Dado** un Usuario o un Analista, **cuando** consulta `auditoria`, **entonces** no recibe filas.

---

### Casos borde (Edge Cases)

HU-107 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-218**: El sistema debe registrar en la bitácora cada acción del catálogo (cuentas, capital, cupos, decisiones, operación, configuración y control) con actor, rol, acción, entidad, valores anterior y nuevo y origen, sin llaves ni tokens. *(Bitácora de acciones sensibles · actores: Sistema · fuente: 11 §4.1 · 01 §2 (P6) · 06 §5.6)*
- **FR-219**: El sistema debe aceptar escrituras en la bitácora solo a través de `private.auditar()`, rechazar toda modificación o borrado y encadenar cada registro con el hash del anterior. *(Bitácora inmutable y encadenada · actores: Sistema · fuente: 11 §4.3)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia agrega una entidad, definida en `docs/06` §5.6:

- **Registro de bitácora**: una acción sensible ya ocurrida. Atributos clave: momento, actor, rol, acción, entidad e identificador afectados, valores anterior y nuevo, origen y el hash que lo encadena con el registro anterior.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Cada acción del catálogo de `docs/11` §4.1 deja un registro con quién la hizo, con qué rol, cuándo y qué cambió.
- **SC-002**: Nadie logra agregar, cambiar ni borrar un registro por fuera del mecanismo de la bitácora.
- **SC-003**: La cadena de registros se puede verificar de punta a punta.
- **SC-004**: Ningún registro contiene llaves, tokens ni respuestas de Google.
- **SC-005**: Un Usuario o un Analista no ve la bitácora.

## Supuestos (Assumptions)

- Depende de TT-03 · Base de Supabase: esquema private, extensiones, Vault y ping: usa el esquema `private`.
- Depende de HU-001 · Perfiles, rol actual y lecturas por rol: usa el tipo `rol_app` y `private.rol_actual()` en su política de lectura.
- `docs/14` §4 ubica la bitácora en R2, pero el alta de una cuenta (R1) ya la usa: por eso la base va en R1, y su pantalla y el E2E-14 van en R2 (HU-108).
- No se duplica lo que ya es un registro inmutable propio: sugerencias, órdenes, ciclos y asientos (`docs/11` §4.1).
