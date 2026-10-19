# HU-093 · Ver el historial de operaciones

| Campo | Valor |
|---|---|
| Épica | [E-10 · Cartera y reportes](README.md) |
| Entrega (hito) | R4 · Decidir y operar en paper |
| Rol | Usuario |
| Prioridad | Media |
| Módulos afectados | M-15 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-10` · `M-15` · `prioridad-media` |

## Historia

**Como** Usuario,  
**quiero** ver el historial de movimientos, órdenes y decisiones de mi cupo,  
**para** revisar qué pasó con mi dinero y cuándo.

## Requisitos funcionales

- [FR-201 · Historial de operaciones](../requisitos-funcionales/FR-201-historial-de-operaciones.md)

## Reglas

PM-10 · PM-31 · 01 §4 · 03 §4.3

## Criterios de aceptación

- **CA-1** Dado un Usuario, cuando abre el historial de Mi cupo, entonces ve en orden cronológico sus movimientos (asignaciones, compras, ventas y repartos), sus órdenes con su estado final y sus decisiones.
- **CA-2** Dado un Analista o un Administrador, cuando abre el historial, entonces ve el de todo el fondo y puede filtrarlo por subcuenta.
- **CA-3** Dada cualquier fila del historial, cuando se muestra, entonces la hora está en hora de Bogotá y el monto en USD con dos decimales.
- **CA-4** (aislamiento) Dado un Usuario, cuando consulta `movimientos` y `asientos`, entonces solo ve los que tocan su cupo.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] App: historial en `lib/features/cupo/` y en `lib/features/fondo/`, con paginación.
- [ ] Consultas del historial sobre `movimientos`, `ordenes` y `decisiones` respetando RLS.
- [ ] Pruebas de widget y pgTAP de la lectura por rol.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-074 · Sincronizar órdenes y aplicar llenados](../E-08-ejecucion-y-broker/HU-074-sincronizar-ordenes-y-aplicar-llenados.md) | El historial incluye compras, ventas y órdenes. |
| Depende de | [HU-023 · Reparto de la ganancia realizada y absorción de pérdidas](../E-03-fondo-y-libro-contable/HU-023-reparto-de-la-ganancia-realizada-y-absorcion-de-perdidas.md) | El historial incluye los repartos de ganancia. |
| Depende de | [HU-019 · Ver mi cupo](../E-03-fondo-y-libro-contable/HU-019-ver-mi-cupo.md) | Extiende la pantalla Mi cupo. |
| Habilita | [HU-095 · Exportar reportes en CSV](HU-095-exportar-reportes-en-csv.md) | HU-095: exporta el historial. |

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
