# HU-109 · Aislamiento verificado por tabla y por función

| Campo | Valor |
|---|---|
| Épica | [E-12 · Seguridad, auditoría y cumplimiento](README.md) |
| Entrega (hito) | R2 · El fondo existe |
| Rol | Administrador |
| Prioridad | Alta |
| Módulos afectados | M-02, M-20 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-12` · `M-02` · `M-20` · `prioridad-alta` |

## Historia

**Como** Administrador,  
**quiero** una batería de pruebas que demuestre que nadie ve ni cambia lo que no le corresponde,  
**para** confiar en el aislamiento entre personas antes de poner el dinero a operar.

## Requisitos funcionales

- [FR-222 · Aislamiento verificado por tabla y por función](../requisitos-funcionales/FR-222-aislamiento-verificado-por-tabla-y-por-funcion.md)
- [FR-020 · Lecturas filtradas por rol y dueño](../requisitos-funcionales/FR-020-lecturas-filtradas-por-rol-y-dueno.md)

## Reglas

03 §4 · 06 §7 · 11 §9 · 14 §6

## Criterios de aceptación

- **CA-1** Dada cada tabla de `public`, cuando corre la suite, entonces hay un caso que demuestra que un Usuario no ve filas de otro y que ningún rol escribe directo.
- **CA-2** Dada cada función llamable desde la app, cuando corre la suite, entonces hay un caso que demuestra que rechaza al rol equivocado y al dueño equivocado.
- **CA-3** Dada una tabla nueva de `public` sin RLS, cuando corre CI, entonces la verificación falla.
- **CA-4** Dado el asesor de seguridad de Supabase, cuando corre en CI, entonces no deja advertencias.
- **CA-5** (aislamiento) Dado un Usuario, cuando intenta leer el cupo de otro o escribir directo en una tabla de dinero, entonces no recibe filas y la escritura se rechaza.

## Casos borde

—

## Escenario E2E

E2E-05 (actualizado)

## Tareas

- [ ] Pruebas pgTAP `rls_*` con la matriz de lectura de 03 §4.3 para las tablas existentes.
- [ ] Prueba que recorre el catálogo y falla si una tabla de `public` no tiene RLS activo.
- [ ] Pruebas pgTAP por cada RPC existente: rol equivocado y dueño equivocado.
- [ ] Revisar `supabase db lint` en CI.
- [ ] E2E-05 actualizado: un Usuario no ve cupos ajenos ni escribe directo.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-010 · Suspender y reactivar una cuenta](../E-02-identidad-y-acceso/HU-010-suspender-y-reactivar-una-cuenta.md) | Extiende el escenario E2E-05. |
| Depende de | [HU-018 · Asignar y reducir cupos](../E-03-fondo-y-libro-contable/HU-018-asignar-y-reducir-cupos.md) | Prueba el aislamiento entre cupos. |
| Depende de | [TT-07 · Integración continua completa en cada PR](../E-01-cimientos-y-calidad-continua/TT-07-integracion-continua-completa-en-cada-pr.md) | La suite corre en cada PR. |
| Habilita | [HU-114 · Lista de verificación antes de abrir el MVP al equipo](HU-114-lista-de-verificacion-antes-de-abrir-el-mvp-al-equipo.md) | HU-114: exige RLS activo en todas las tablas. |

## Notas técnicas

Es transversal: cada historia que crea una tabla o una función agrega su caso a esta suite (14 §6).

## Documentación a actualizar

Ninguna.

## Definición de terminado

Lista de `docs/14` §6, la misma del formulario de historia:

- [ ] Criterios de aceptación y casos borde cumplidos
- [ ] `scripts/verificar.sh` completo en verde (incluye E2E) y CI en verde
- [ ] Escenario E2E agregado o actualizado
- [ ] RLS y pruebas pgTAP si toca datos; escrituras solo por RPC
- [ ] `docs/` actualizada (y historial 13 §4) si cambió una regla
- [ ] `docs/17` actualizado si cambiaron rutas, tablas o funciones
- [ ] Error no trivial registrado en `docs/errores-conocidos.md`
- [ ] Desplegada en el proyecto MVP con la prueba de humo en verde
