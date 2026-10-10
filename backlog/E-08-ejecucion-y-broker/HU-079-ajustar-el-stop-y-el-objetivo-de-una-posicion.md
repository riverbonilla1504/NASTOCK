# HU-079 · Ajustar el stop y el objetivo de una posición

| Campo | Valor |
|---|---|
| Épica | [E-08 · Ejecución y broker](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Usuario |
| Prioridad | Media |
| Módulos afectados | M-11 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-08` · `M-11` · `prioridad-media` |

## Historia

**Como** Usuario,  
**quiero** cambiar el stop y el objetivo de una posición de mi cupo,  
**para** adaptar mi protección cuando el precio se mueve.

## Requisitos funcionales

- [FR-178 · Ajuste de la protección](../requisitos-funcionales/FR-178-ajuste-de-la-proteccion.md)

## Reglas

PM-14 · PM-23 · RR-08 · 08 §3 · 10 §6

## Criterios de aceptación

- **CA-1** Dado un Usuario con una posición con protección virtual, cuando ajusta el stop dentro del rango, entonces la protección anterior queda `reemplazada`, nace una nueva `activa` y se registra `proteccion.ajustada`.
- **CA-2** Dada una protección nativa, cuando se ajusta, entonces se reemplazan las patas en el broker.
- **CA-3** (caso borde) CB-45: Dado un stop por encima del precio actual o fuera del rango del bolsillo, cuando se intenta, entonces se rechaza: el stop debe quedar por debajo del precio actual y dentro del rango de RR-08.
- **CA-4** Dado un Analista, cuando ajusta la protección de una posición de Arriesgadas, entonces funciona igual.
- **CA-5** (permiso) Dado un Usuario sobre una posición ajena, un Analista sobre un cupo o un Administrador, cuando llaman `ajustar_proteccion`, entonces reciben `NO_AUTORIZADO`.

## Casos borde

CB-45

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] RPC `ajustar_proteccion(posicion_id, stop_pct, objetivo_pct)` con dueño o rol, rango de RR-08, stop por debajo del precio actual y auditoría.
- [ ] Funciones: reemplazo de las patas en el broker para la protección nativa.
- [ ] App: acción de ajuste en la posición, en `lib/features/cupo/` para el Usuario y en el detalle del fondo para el Analista.
- [ ] Pruebas pgTAP `protecciones_*` y `deno test` del reemplazo.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-077 · Protección nativa en compras de acciones enteras](HU-077-proteccion-nativa-en-compras-de-acciones-enteras.md) | Ajusta las patas de la protección nativa. |
| Depende de | [HU-078 · Protección virtual en compras fraccionales](HU-078-proteccion-virtual-en-compras-fraccionales.md) | Reemplaza la protección virtual. |
| Habilita | [HU-025 · Ajuste por split o agrupación de acciones](../E-03-fondo-y-libro-contable/HU-025-ajuste-por-split-o-agrupacion-de-acciones.md) | HU-025: recrea las protecciones con precios nuevos. |

## Notas técnicas

Sin notas adicionales.

## Documentación a actualizar

Ni 05 §6 ni 10 §6 dicen qué función reemplaza las patas en el broker al ajustar una protección nativa. Precisarlo en `docs/`.

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
