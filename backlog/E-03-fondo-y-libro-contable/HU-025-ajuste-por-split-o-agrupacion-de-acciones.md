# HU-025 · Ajuste por split o agrupación de acciones

| Campo | Valor |
|---|---|
| Épica | [E-03 · Fondo y libro contable](README.md) |
| Entrega (hito) | R6 · Medir y mejorar |
| Rol | Administrador |
| Prioridad | Baja |
| Módulos afectados | M-04, M-11 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-03` · `M-04` · `M-11` · `prioridad-baja` |

## Historia

**Como** Administrador,  
**quiero** aplicar un split o una agrupación a las posiciones de un símbolo,  
**para** que el libro vuelva a coincidir con el broker después de un evento corporativo.

## Requisitos funcionales

- [FR-060 · Ajuste por evento corporativo](../requisitos-funcionales/FR-060-ajuste-por-evento-corporativo.md)

## Reglas

RN-32 · PM-45 · 10 §8

## Criterios de aceptación

- **CA-1** (caso borde) CB-41: Dado un split de un símbolo con posiciones, cuando corre la conciliación, entonces detecta la cantidad distinta y la reporta como descuadre.
- **CA-2** Dado ese descuadre, cuando el Administrador aplica el ajuste con factor 2, entonces cada posición del símbolo duplica su cantidad, divide su costo promedio entre 2 y conserva su costo total.
- **CA-3** Dadas las protecciones de esas posiciones, cuando se aplica el ajuste, entonces se cancelan y se recrean con los precios ajustados por el factor.
- **CA-4** Dado el ajuste aplicado, cuando corre la siguiente conciliación, entonces el resultado es `ok` y queda registrado `ajuste.registrado` con su justificación.
- **CA-5** (permiso) Dado un Usuario o un Analista, cuando intenta aplicar el ajuste, entonces recibe `NO_AUTORIZADO`.

## Casos borde

CB-41

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Función de base de datos que aplica el factor a `posiciones` (cantidad y costo promedio) con justificación y auditoría.
- [ ] Cancelar y recrear las protecciones nativas (patas en el broker) y las virtuales con los precios ajustados.
- [ ] Pruebas pgTAP: factor de split y de agrupación, costo total sin cambio y permisos.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-080 · Conciliación completa con pausa automática](../E-08-ejecucion-y-broker/HU-080-conciliacion-completa-con-pausa-automatica.md) | La conciliación detecta el evento corporativo. |
| Depende de | [HU-022 · Registrar ajustes contables](HU-022-registrar-ajustes-contables.md) | Es un ajuste justificado del Administrador. |
| Depende de | [HU-079 · Ajustar el stop y el objetivo de una posición](../E-08-ejecucion-y-broker/HU-079-ajustar-el-stop-y-el-objetivo-de-una-posicion.md) | Recrea las protecciones con precios nuevos. |

## Notas técnicas

Sin notas adicionales.

## Documentación a actualizar

06 §8 no nombra la función que ajusta la cantidad y el costo promedio de las posiciones: `registrar_ajuste` solo recibe asientos. Definirla en `docs/` antes de implementar.

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
