# HU-094 · Ver el rendimiento y compararlo con el NASDAQ-100

| Campo | Valor |
|---|---|
| Épica | [E-10 · Cartera y reportes](README.md) |
| Entrega (hito) | R6 · Medir y mejorar |
| Rol | Usuario |
| Prioridad | Media |
| Módulos afectados | M-15 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-10` · `M-15` · `prioridad-media` |

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** ver el rendimiento de mi cupo o del fondo y compararlo con el NASDAQ-100 y con ×2 teórico,  
**para** saber si las decisiones están agregando valor.

## Requisitos funcionales

- [FR-202 · Rendimiento y comparación](../requisitos-funcionales/FR-202-rendimiento-y-comparacion.md)

## Reglas

RN-44 · RN-45 · 01 §4 · 02 §13

## Criterios de aceptación

- **CA-1** Dado un Usuario, cuando abre el rendimiento de su cupo, entonces ve el TWR calculado con las fotos diarias, no la ganancia sobre el capital inicial.
- **CA-2** Dado un Analista o un Administrador, cuando abre el rendimiento del fondo, entonces ve el TWR del fondo y de cada bolsillo y su comparación con QQQ y con ×2 teórico en el mismo periodo.
- **CA-3** Dado un valor en vivo, cuando se muestra junto al oficial, entonces queda indicado que el oficial es el de la foto diaria.
- **CA-4** (aislamiento) Dado un Usuario, cuando abre el rendimiento, entonces solo ve el de su cupo y los agregados.

## Casos borde

—

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] App: gráfica de rendimiento en `lib/features/cupo/` y en `lib/features/fondo/` con los datos de `patrimonio_diario`.
- [ ] App: comparación con QQQ y con ×2 teórico, reutilizando el motor de la v2.
- [ ] Pruebas de widget y pgTAP de la lectura de `patrimonio_diario` por rol.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-021 · Foto diaria de patrimonio y rendimiento TWR](../E-03-fondo-y-libro-contable/HU-021-foto-diaria-de-patrimonio-y-rendimiento-twr.md) | Usa las fotos diarias y el TWR. |
| Depende de | [HU-031 · Comparación de QQQ, QLD y ×2 teórico](../E-04-datos-de-mercado/HU-031-comparacion-de-qqq-qld-y-x2-teorico.md) | Reutiliza la comparación con QQQ y ×2 teórico. |
| Depende de | [HU-091 · Ver mis posiciones y sus protecciones](HU-091-ver-mis-posiciones-y-sus-protecciones.md) | Extiende la pantalla Mi cupo con posiciones. |
| Habilita | [HU-095 · Exportar reportes en CSV](HU-095-exportar-reportes-en-csv.md) | HU-095: exporta el desempeño. |

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
