# HU-032 · Aviso de dato desactualizado

| Campo | Valor |
|---|---|
| Épica | [E-04 · Datos de mercado](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-05 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-04` · `M-05` · `prioridad-alta` |

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** que la app me avise cuando un precio está desactualizado,  
**para** no decidir con un dato viejo.

## Requisitos funcionales

- [FR-075 · Dato desactualizado](../requisitos-funcionales/FR-075-dato-desactualizado.md)

## Reglas

RR-11 · 09 §2 · 08 §9.4

## Criterios de aceptación

- **CA-1** Dado un precio con más de `mercado.max_antiguedad_cotizacion_seg` segundos, cuando se muestra, entonces lleva la marca "dato desactualizado".
- **CA-2** (caso borde) CB-52: Dada una suspensión general del mercado, cuando los precios se congelan, entonces todos quedan marcados como desactualizados.
- **CA-3** Dado un precio desactualizado, cuando la persona está en una pantalla con botones de aprobar o de comprar, entonces esos botones quedan deshabilitados.
- **CA-4** Dado que llegan precios nuevos, cuando se reciben, entonces la marca desaparece.
- **CA-5** (caso borde) CB-69: Dado que el trabajo programado deja de correr, cuando el precio supera la antigüedad máxima, entonces la app muestra "dato desactualizado" por la antigüedad del precio.

## Casos borde

CB-52, CB-69

## Escenario E2E

E2E-03 (actualizado)

## Tareas

- [ ] Migración: parámetro `mercado.max_antiguedad_cotizacion_seg`.
- [ ] App: antigüedad por símbolo en `cotizacionesProvider` y marca visual junto al precio.
- [ ] App: condición reutilizable que deshabilita las acciones de decisión cuando el dato está desactualizado.
- [ ] Pruebas de widget con el reloj controlado.
- [ ] E2E-03 actualizado: al detener la ingesta simulada, la app marca el dato como desactualizado.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-030 · Pantalla de mercado en vivo](HU-030-pantalla-de-mercado-en-vivo.md) | La marca se muestra junto a los precios de la pantalla de mercado. |
| Habilita | [HU-061 · Mis sugerencias: bandeja y detalle con explicación](../E-07-sugerencias-y-decisiones/HU-061-mis-sugerencias-bandeja-y-detalle-con-explicacion.md) | HU-061: deshabilita la decisión con el dato desactualizado. |

## Notas técnicas

El servidor rechaza igual la operación con `DATO_DESACTUALIZADO` (RR-11, en [HU-037](../E-05-motor-de-politicas-y-configuracion/HU-037-motor-de-politicas-reglas-de-la-propuesta.md)); la marca en la app evita el intento. También es la señal visible de que el cron dejó de correr (CB-69).

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
