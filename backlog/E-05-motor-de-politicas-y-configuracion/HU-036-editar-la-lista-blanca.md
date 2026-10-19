# HU-036 · Editar la lista blanca

| Campo | Valor |
|---|---|
| Épica | [E-05 · Motor de políticas y configuración](README.md) |
| Entrega (hito) | R3 · La IA analiza |
| Rol | Administrador |
| Prioridad | Media |
| Módulos afectados | M-08, M-05 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-05` · `M-08` · `M-05` · `prioridad-media` |

## Historia

**Como** Administrador,  
**quiero** agregar, activar y desactivar símbolos de la lista blanca de cada bolsillo,  
**para** controlar qué se puede comprar y mantener el universo al día.

## Requisitos funcionales

- [FR-084 · Edición de la lista blanca](../requisitos-funcionales/FR-084-edicion-de-la-lista-blanca.md)

## Reglas

PM-55 · RR-01 · 06 §5.2 · 10 §12

## Criterios de aceptación

- **CA-1** Dado un Administrador, cuando agrega un símbolo a Arriesgadas con su nombre, entonces queda activo en la lista y se registra `lista_blanca.cambiada`.
- **CA-2** (caso borde) CB-47: Dado un símbolo con posiciones abiertas, cuando el Administrador lo desactiva, entonces no se compra más y sus posiciones y protecciones siguen.
- **CA-3** (caso borde) CB-88: Dada la reconstitución anual del NASDAQ-100, cuando el Administrador actualiza la lista, entonces los símbolos que salen quedan desactivados y se tratan igual.
- **CA-4** Dado el bolsillo Reserva, cuando se intenta agregar un símbolo, entonces la base de datos lo rechaza.
- **CA-5** (permiso) Dado un Usuario o un Analista, cuando llama `actualizar_lista_blanca`, entonces recibe `NO_AUTORIZADO`; ambos pueden leer la lista.

## Casos borde

CB-47, CB-88

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] RPC `actualizar_lista_blanca(bolsillo, simbolo, nombre, activo, notas)` con auditoría.
- [ ] Pruebas pgTAP: alta, activación, desactivación con posiciones, bolsillo Reserva y permisos.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-026 · Universo del NASDAQ-100 y carga histórica de barras](../E-04-datos-de-mercado/HU-026-universo-del-nasdaq-100-y-carga-historica-de-barras.md) | Edita la tabla `lista_blanca` sembrada con el universo. |
| Depende de | [HU-107 · Bitácora inmutable con cadena de hash](../E-12-seguridad-auditoria-y-cumplimiento/HU-107-bitacora-inmutable-con-cadena-de-hash.md) | Registra `lista_blanca.cambiada`. |
| Habilita | [HU-067 · Invalidación por precio y por cambio de situación](../E-07-sugerencias-y-decisiones/HU-067-invalidacion-por-precio-y-por-cambio-de-situacion.md) | HU-067: invalida al desactivar un símbolo. |
| Habilita | [HU-102 · Pantalla de lista blanca](../E-11-administracion/HU-102-pantalla-de-lista-blanca.md) | HU-102: edita la lista blanca. |

## Notas técnicas

Las sugerencias vivas de un símbolo que sale de la lista pasan a invalidadas (CB-76): eso se implementa en [HU-067](../E-07-sugerencias-y-decisiones/HU-067-invalidacion-por-precio-y-por-cambio-de-situacion.md). La pantalla está en [HU-102](../E-11-administracion/HU-102-pantalla-de-lista-blanca.md). 14 §4 no ubica esta capacidad en una entrega; va en R3 porque la lista de Arriesgadas es el universo que evalúa la IA.

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
