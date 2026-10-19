# HU-104 · Pantalla de conciliaciones

| Campo | Valor |
|---|---|
| Épica | [E-11 · Administración](README.md) |
| Entrega (hito) | R5 · Protegido y avisado |
| Rol | Administrador |
| Prioridad | Media |
| Módulos afectados | M-16, M-12 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-11` · `M-16` · `M-12` · `prioridad-media` |

## Historia

**Como** Administrador,  
**quiero** ver el resultado de cada conciliación y atender los descuadres,  
**para** resolver un incidente con toda la información en una pantalla.

## Requisitos funcionales

- [FR-215 · Pantalla de conciliaciones](../requisitos-funcionales/FR-215-pantalla-de-conciliaciones.md)

## Reglas

PM-34 · PM-58 · 10 §8 · 11 §8

## Criterios de aceptación

- **CA-1** Dado un Administrador, cuando abre las conciliaciones, entonces ve cada una con su hora, su resultado, la diferencia de efectivo y la acción tomada.
- **CA-2** Dado un descuadre crítico, cuando lo abre, entonces ve el detalle por símbolo y puede marcarlo como revisado con una nota.
- **CA-3** Dado un Administrador, cuando pulsa "Conciliar ahora", entonces se lanza una conciliación y la lista se actualiza con el evento `conciliacion`.
- **CA-4** Dado el trading pausado por un descuadre, cuando abre la pantalla, entonces ve el aviso y el acceso a reanudar.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] App: lista y detalle de conciliaciones en `lib/features/admin/salud/`.
- [ ] App: acciones de marcar como revisada y de conciliar ahora.
- [ ] Pruebas de widget de la lista, del detalle y de las acciones.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-103 · Pantalla de salud e integraciones](HU-103-pantalla-de-salud-e-integraciones.md) | Vive junto a la pantalla de salud. |
| Depende de | [HU-081 · Revisar un descuadre y lanzar una conciliación](../E-08-ejecucion-y-broker/HU-081-revisar-un-descuadre-y-lanzar-una-conciliacion.md) | Marca descuadres y lanza conciliaciones. |
| Depende de | [HU-040 · Reanudar el trading solo con la conciliación en ok](../E-05-motor-de-politicas-y-configuracion/HU-040-reanudar-el-trading-solo-con-la-conciliacion-en-ok.md) | Da acceso a reanudar el trading. |

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
