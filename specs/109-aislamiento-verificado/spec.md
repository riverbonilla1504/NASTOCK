# Especificación de funcionalidad (Feature Specification): HU-109 · Aislamiento verificado por tabla y por función

**Feature Branch**: `109-aislamiento-verificado`

**Created**: 2026-10-12

**Status**: Draft

**Input**: Historia de usuario: "HU-109 · Aislamiento verificado por tabla y por función", en [`backlog/E-12-seguridad-auditoria-y-cumplimiento/HU-109-aislamiento-verificado-por-tabla-y-por-funcion.md`](../../backlog/E-12-seguridad-auditoria-y-cumplimiento/HU-109-aislamiento-verificado-por-tabla-y-por-funcion.md)

## Escenarios de usuario y pruebas (User Scenarios & Testing) *(obligatorio)*

### Historia de usuario 1 (User Story 1) - Aislamiento verificado por tabla y por función (Prioridad: P1)

**Como** Administrador, **quiero** una batería de pruebas que demuestre que nadie ve ni cambia lo que no le corresponde, **para** confiar en el aislamiento entre personas antes de poner el dinero a operar.

**Por qué esta prioridad (Why this priority)**: En el backlog tiene prioridad Alta y pertenece a la entrega R2 · El fondo existe. Los permisos se aplican en el servidor (`docs/03` §4), y las pruebas de seguridad de cada cambio exigen demostrar, por tabla y por función, que nadie ve ni cambia lo ajeno (`docs/11` §9). Habilita una historia: HU-114 (exige RLS activo en todas las tablas).

**Prueba independiente (Independent Test)**: Se demuestra sola con el escenario E2E-05, que esta historia extiende: un Usuario no ve cupos ajenos ni escribe directo. Lo acompañan las pruebas de base de datos por tabla y por función, y la comprobación que falla si una tabla queda sin control de acceso. Entrega la batería que respalda el aislamiento entre personas antes de poner el dinero a operar.

**Escenarios de aceptación (Acceptance Scenarios)**:

1. **CA-1** · **Dada** cada tabla de `public`, **cuando** corre la suite, **entonces** hay un caso que demuestra que un Usuario no ve filas de otro y que ningún rol escribe directo.
2. **CA-2** · **Dada** cada función llamable desde la app, **cuando** corre la suite, **entonces** hay un caso que demuestra que rechaza al rol equivocado y al dueño equivocado.
3. **CA-3** · **Dada** una tabla nueva de `public` sin RLS, **cuando** corre CI, **entonces** la verificación falla.
4. **CA-4** · **Dado** el asesor de seguridad de Supabase, **cuando** corre en CI, **entonces** no deja advertencias.
5. **CA-5** (aislamiento) · **Dado** un Usuario, **cuando** intenta leer el cupo de otro o escribir directo en una tabla de dinero, **entonces** no recibe filas y la escritura se rechaza.

---

### Casos borde (Edge Cases)

HU-109 no cita ningún caso borde (`CB`) de `docs/12`.

## Requisitos (Requirements) *(obligatorio)*

### Requisitos funcionales (Functional Requirements)

Son los del catálogo de `backlog/requisitos-funcionales/`, con su identificador y su descripción. Esta especificación no crea requisitos nuevos.

- **FR-222**: El sistema debe demostrar con pruebas automáticas, por cada tabla, que un Usuario no ve filas ajenas y que ningún rol escribe directo, y por cada función llamable, que rechaza al rol equivocado y al dueño equivocado. *(Aislamiento verificado por tabla y por función · actores: Sistema · fuente: 11 §9 · 06 §7 · 14 §6)*
- **FR-020**: El sistema debe filtrar cada lectura de las tablas de `public` según la matriz de lectura por rol y dueño, y no debe conceder inserción, actualización ni borrado directo a ningún rol de la API. *(Lecturas filtradas por rol y dueño · actores: Sistema · fuente: 03 §4.3 · 03 §4.4 · 06 §7)*

### Entidades clave (Key Entities) *(incluir si la funcionalidad maneja datos)*

La historia no agrega entidades: recorre todas las de `docs/06` para probar su aislamiento.

## Criterios de éxito (Success Criteria) *(obligatorio)*

### Resultados medibles (Measurable Outcomes)

- **SC-001**: Por cada tabla hay una prueba de que un Usuario no ve filas ajenas y de que ningún rol escribe directo.
- **SC-002**: Por cada función que llama la app hay una prueba de que rechaza al rol equivocado y al dueño equivocado.
- **SC-003**: Una tabla nueva sin control de acceso hace fallar la verificación.
- **SC-004**: El asesor de seguridad de la base de datos no deja advertencias.
- **SC-005**: El indicador "Escenarios E2E en verde en `main`: 100 % siempre" de `docs/01` §6 se cumple con E2E-05.

## Supuestos (Assumptions)

- Depende de HU-010 · Suspender y reactivar una cuenta: extiende el escenario E2E-05.
- Depende de HU-018 · Asignar y reducir cupos: prueba el aislamiento entre cupos.
- Depende de TT-07 · Integración continua completa en cada PR: la suite corre en cada PR.
- Es transversal: cada historia que crea una tabla o una función agrega su caso a esta suite (`docs/14` §6).
