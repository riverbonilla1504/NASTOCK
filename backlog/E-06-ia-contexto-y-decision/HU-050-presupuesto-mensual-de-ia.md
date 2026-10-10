# HU-050 · Presupuesto mensual de IA

| Campo | Valor |
|---|---|
| Épica | [E-06 · IA: contexto y decisión](README.md) |
| Entrega (hito) | R3 · La IA analiza |
| Rol | Administrador |
| Prioridad | Media |
| Módulos afectados | M-07, M-18 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-06` · `M-07` · `M-18` · `prioridad-media` |

## Historia

**Como** Administrador,  
**quiero** que el sistema controle cuánto gasta cada mes en DeepSeek y en JEV,  
**para** que el costo de las IAs nunca supere lo aprobado.

## Requisitos funcionales

- [FR-123 · Presupuesto mensual de IA](../requisitos-funcionales/FR-123-presupuesto-mensual-de-ia.md)

## Reglas

07 §9 · 02 §10 · 09 §5.1 · D-45

## Criterios de aceptación

- **CA-1** Dado el gasto del mes, cuando se consulta, entonces es la suma del costo de los contextos (DeepSeek) y de los ciclos y opiniones (JEV).
- **CA-2** Dado que el gasto llega al 80 % de `ia.presupuesto_mensual_usd`, cuando ocurre, entonces se alerta al Administrador.
- **CA-3** (caso borde) CB-61: Dado que el gasto llega al 100 %, cuando llega un ciclo, entonces queda `omitido` con el motivo `presupuesto`, se alerta al Administrador y se registra `ia.presupuesto_agotado`.
- **CA-4** Dado un mes nuevo, cuando empieza, entonces el conteo vuelve a cero y los ciclos corren.

## Casos borde

CB-61

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Cálculo del gasto mensual desde `contextos_ia.costo_usd` y `ciclos_agente.costo_usd`.
- [ ] Prechequeo de presupuesto en `agente` y en `contexto-ia`, y parámetro `ia.presupuesto_mensual_usd`.
- [ ] Alertas al 80 % y al 100 % y auditoría `ia.presupuesto_agotado`.
- [ ] Pruebas pgTAP del cálculo y `deno test` de la omisión.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-046 · Ciclo del agente: programación, uno a la vez y omisiones](HU-046-ciclo-del-agente-programacion-uno-a-la-vez-y-omisiones.md) | El ciclo se omite al agotarse el presupuesto. |
| Depende de | [HU-042 · Contexto de DeepSeek validado contra sus fuentes](HU-042-contexto-de-deepseek-validado-contra-sus-fuentes.md) | Suma el costo de DeepSeek. |
| Depende de | [HU-085 · Alertas del sistema por audiencia](../E-09-tiempo-real-y-notificaciones/HU-085-alertas-del-sistema-por-audiencia.md) | Alerta al Administrador. |
| Depende de | [HU-107 · Bitácora inmutable con cadena de hash](../E-12-seguridad-auditoria-y-cumplimiento/HU-107-bitacora-inmutable-con-cadena-de-hash.md) | Registra `ia.presupuesto_agotado`. |

## Notas técnicas

El costo de las opiniones (`opiniones_ia.costo_usd`) se suma desde [HU-052](HU-052-opinion-de-la-ia-sobre-una-orden-manual.md). Costo estimado del MVP: unos USD 4 al mes (07 §9).

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
