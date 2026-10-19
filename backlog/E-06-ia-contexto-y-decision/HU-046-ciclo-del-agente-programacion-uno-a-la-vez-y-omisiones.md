# HU-046 · Ciclo del agente: programación, uno a la vez y omisiones

| Campo | Valor |
|---|---|
| Épica | [E-06 · IA: contexto y decisión](README.md) |
| Entrega (hito) | R3 · La IA analiza |
| Rol | Analista |
| Prioridad | Alta |
| Módulos afectados | M-07 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-06` · `M-07` · `prioridad-alta` |

## Historia

**Como** Analista,  
**quiero** que la IA corra un ciclo de decisión a intervalos regulares, uno a la vez, y que se omita cuando no debe correr,  
**para** que el análisis sea constante y nunca corra en condiciones en las que no debe.

## Requisitos funcionales

- [FR-109 · Ciclo programado del agente](../requisitos-funcionales/FR-109-ciclo-programado-del-agente.md)
- [FR-110 · Ciclo por evento de mercado](../requisitos-funcionales/FR-110-ciclo-por-evento-de-mercado.md)
- [FR-111 · Omisión del ciclo](../requisitos-funcionales/FR-111-omision-del-ciclo.md)
- [FR-112 · Ciclo manual](../requisitos-funcionales/FR-112-ciclo-manual.md)

## Reglas

PM-58 · 07 §2 · 07 §3 · 05 §6 · 05 §7 · 08 §6

## Criterios de aceptación

- **CA-1** Dados la ventana de compras abierta, `ia_activa` encendido y `ia.minutos_entre_ciclos` minutos desde el último ciclo, cuando el trabajo programado pregunta, entonces despierta a `agente` y se registra un ciclo `en_curso`.
- **CA-2** Dado un ciclo `en_curso` de menos de 5 minutos, cuando se intenta otro, entonces no empieza; (caso borde) CB-62: si el ciclo en curso tiene más de 5 minutos, se marca `fallido` y el nuevo sigue.
- **CA-3** Dado el mercado cerrado, `ia_activa` apagado, el fondo sin capital o los datos desactualizados, cuando llega el ciclo, entonces queda `omitido` con su motivo.
- **CA-4** (caso borde) CB-55: Dado que QQQ se movió al menos `ia.umbral_evento_qqq_pct` desde el último ciclo y este fue hace más de 3 minutos, cuando se publican las cotizaciones, entonces se dispara un ciclo extra.
- **CA-5** (permiso) Dado un Administrador, cuando llama `lanzar_ciclo()`, entonces corre un ciclo con disparador `manual`; un Usuario o un Analista reciben `NO_AUTORIZADO`.

## Casos borde

CB-55, CB-62

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercitan E2E-06 y E2E-07.

## Tareas

- [ ] Migración: tipos `disparador_ciclo` y `estado_ciclo`, tabla `ciclos_agente` (06 §5.3) con RLS para Analista y Administrador, y `private.registrar_ciclo(...)` y `private.cerrar_ciclo(...)` con el bloqueo contra ciclos simultáneos.
- [ ] Función `agente`: prechequeos (mercado, `ia_activa`, capital, salud y datos frescos), autenticación con el secreto interno o con el JWT de un Analista o Administrador, y cierre con métricas, costos y conteos.
- [ ] Migración: trabajo `ciclo_agente` de `pg_cron` y parámetros `ia.minutos_entre_ciclos` e `ia.umbral_evento_qqq_pct`.
- [ ] Migración: detección del evento de QQQ en `private.publicar_cotizaciones`.
- [ ] RPC `lanzar_ciclo()` para el Administrador.
- [ ] Pruebas: pgTAP de `registrar_ciclo` (simultáneos y colgados) y `deno test` de los prechequeos.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-044 · Calidad de datos, métricas y puntaje cuantitativo](HU-044-calidad-de-datos-metricas-y-puntaje-cuantitativo.md) | El ciclo empieza por la verificación de calidad. |
| Depende de | [HU-034 · Encender y apagar los interruptores del fondo](../E-05-motor-de-politicas-y-configuracion/HU-034-encender-y-apagar-los-interruptores-del-fondo.md) | No corre con `ia_activa` apagado ni con el fondo sin capital. |
| Depende de | [HU-033 · Parámetros configurables con rango e historial](../E-05-motor-de-politicas-y-configuracion/HU-033-parametros-configurables-con-rango-e-historial.md) | Lee la frecuencia y los umbrales del catálogo. |
| Depende de | [HU-027 · Calendario, reloj y estado del mercado](../E-04-datos-de-mercado/HU-027-calendario-reloj-y-estado-del-mercado.md) | Solo corre en la ventana de compras. |
| Depende de | [HU-028 · Ingesta de precios cada 15 segundos](../E-04-datos-de-mercado/HU-028-ingesta-de-precios-cada-15-segundos.md) | El evento de QQQ se detecta al publicar cotizaciones. |
| Habilita | [HU-047 · Puntaje compuesto y elección de la mejor opción](HU-047-puntaje-compuesto-y-eleccion-de-la-mejor-opcion.md) | HU-047: la decisión corre dentro del ciclo. |
| Habilita | [HU-050 · Presupuesto mensual de IA](HU-050-presupuesto-mensual-de-ia.md) | HU-050: el ciclo se omite al agotarse el presupuesto. |

## Notas técnicas

`agente` no importa `_shared/broker/` (invariante). El contexto va separado del ciclo: el ciclo nunca espera a DeepSeek. La omisión por presupuesto se agrega en [HU-050](HU-050-presupuesto-mensual-de-ia.md). Publica el evento `ciclo_agente` en el canal `supervision`.

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
