# HU-101 · Pantalla de parámetros e interruptores

| Campo | Valor |
|---|---|
| Épica | [E-11 · Administración](README.md) |
| Entrega (hito) | R2 · El fondo existe |
| Rol | Administrador |
| Prioridad | Media |
| Módulos afectados | M-16, M-08 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-11` · `M-16` · `M-08` · `prioridad-media` |

## Historia

**Como** Administrador,  
**quiero** ver y cambiar los parámetros y los interruptores del fondo,  
**para** ajustar las reglas y encender o pausar el sistema desde la app.

## Requisitos funcionales

- [FR-211 · Pantalla de parámetros](../requisitos-funcionales/FR-211-pantalla-de-parametros.md)
- [FR-212 · Pantalla de interruptores](../requisitos-funcionales/FR-212-pantalla-de-interruptores.md)

## Reglas

PM-54 · PM-56 · PM-57 · 02 §10 · 06 §4

## Criterios de aceptación

- **CA-1** Dado un Administrador, cuando abre Parámetros, entonces ve cada parámetro con su valor, su rango y su descripción, agrupados por tema.
- **CA-2** Dado un parámetro, cuando lo cambia con un motivo, entonces se guarda y aparece en su historial; un valor fuera de rango muestra el mensaje de `PARAMETRO_FUERA_DE_RANGO`.
- **CA-3** Dados los tres porcentajes de reparto, cuando los edita, entonces la pantalla los cambia juntos y no deja guardar si no suman 100.
- **CA-4** Dado un Administrador, cuando abre Interruptores, entonces ve el estado de `ia_activa` y de `trading_activo` con el motivo, el autor y la hora de la pausa, y puede encenderlos o apagarlos con confirmación.
- **CA-5** (permiso) Dado un Usuario o un Analista, cuando abre esta pantalla, entonces el enrutador lo lleva a `/inicio`.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] App: `lib/features/admin/parametros/` con la lista por tema, la edición con motivo y el historial.
- [ ] App: pantalla de interruptores con su estado y sus acciones.
- [ ] App: actualización con los eventos `parametro` e `interruptor`.
- [ ] Pruebas de widget de la edición, de la suma de porcentajes y de los interruptores.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-097 · Sección de Administración y guía de primeros pasos](HU-097-seccion-de-administracion-y-guia-de-primeros-pasos.md) | Son entradas de la sección de Administración. |
| Depende de | [HU-033 · Parámetros configurables con rango e historial](../E-05-motor-de-politicas-y-configuracion/HU-033-parametros-configurables-con-rango-e-historial.md) | Cambia los parámetros. |
| Depende de | [HU-034 · Encender y apagar los interruptores del fondo](../E-05-motor-de-politicas-y-configuracion/HU-034-encender-y-apagar-los-interruptores-del-fondo.md) | Enciende y apaga los interruptores. |

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
