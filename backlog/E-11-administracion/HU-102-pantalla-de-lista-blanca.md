# HU-102 · Pantalla de lista blanca

| Campo | Valor |
|---|---|
| Épica | [E-11 · Administración](README.md) |
| Entrega (hito) | R3 · La IA analiza |
| Rol | Administrador |
| Prioridad | Media |
| Módulos afectados | M-16, M-08 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-11` · `M-16` · `M-08` · `prioridad-media` |

## Historia

**Como** Administrador,  
**quiero** ver y editar los símbolos permitidos en cada bolsillo,  
**para** mantener al día el universo que se puede comprar.

## Requisitos funcionales

- [FR-213 · Pantalla de lista blanca](../requisitos-funcionales/FR-213-pantalla-de-lista-blanca.md)

## Reglas

PM-55 · PM-07 · 06 §5.2 · 10 §12

## Criterios de aceptación

- **CA-1** Dado un Administrador, cuando abre Lista blanca, entonces ve por bolsillo cada símbolo con su nombre, su sector, si está activo y si es negociable y fraccionable.
- **CA-2** Dado un símbolo, cuando lo activa o lo desactiva, entonces el cambio se guarda; si tiene posiciones abiertas, la pantalla avisa que no se comprará más y que sus posiciones y protecciones siguen.
- **CA-3** Dado el formulario, cuando agrega un símbolo, entonces queda en la lista del bolsillo elegido; la Reserva no aparece como opción.
- **CA-4** (permiso) Dado un Usuario o un Analista, cuando abre esta pantalla, entonces el enrutador lo lleva a `/inicio`.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] App: pantalla de lista blanca en `lib/features/admin/` con filtros por bolsillo y por sector.
- [ ] App: formulario para agregar, activar y desactivar símbolos sobre `actualizar_lista_blanca`.
- [ ] Pruebas de widget de la lista y del formulario.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-097 · Sección de Administración y guía de primeros pasos](HU-097-seccion-de-administracion-y-guia-de-primeros-pasos.md) | Es una entrada de la sección de Administración. |
| Depende de | [HU-036 · Editar la lista blanca](../E-05-motor-de-politicas-y-configuracion/HU-036-editar-la-lista-blanca.md) | Edita la lista blanca. |

## Notas técnicas

Sin notas adicionales.

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
