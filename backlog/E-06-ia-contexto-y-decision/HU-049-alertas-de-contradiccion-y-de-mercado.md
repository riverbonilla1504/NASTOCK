# HU-049 · Alertas de contradicción y de mercado

| Campo | Valor |
|---|---|
| Épica | [E-06 · IA: contexto y decisión](README.md) |
| Entrega (hito) | R3 · La IA analiza |
| Rol | Analista |
| Prioridad | Media |
| Módulos afectados | M-07, M-18 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-06` · `M-07` · `M-18` · `prioridad-media` |

## Historia

**Como** Analista,  
**quiero** que el sistema me avise cuando los números de una acción fuerte dicen una cosa y las noticias otra, y cuando el mercado entra en riesgo,  
**para** no pasar por alto una señal que los datos solos no muestran.

## Requisitos funcionales

- [FR-121 · Alerta de contradicción entre datos y contexto](../requisitos-funcionales/FR-121-alerta-de-contradiccion-entre-datos-y-contexto.md)
- [FR-122 · Alertas de mercado](../requisitos-funcionales/FR-122-alertas-de-mercado.md)

## Reglas

07 §6.3 · 07 §7.6 · 07 §15 · 09 §5.1

## Criterios de aceptación

- **CA-1** (caso borde) CB-84: Dada una candidata entre las 3 mejores por números con `data_context_conflict` mayor o igual a 0,5, cuando termina el ciclo, entonces no se propone y se crea una alerta para Analistas que explica la contradicción.
- **CA-2** Dada una contradicción entre 0,3 y 0,5 en una candidata que sí se propone, cuando se crea la señal, entonces lleva una advertencia visible.
- **CA-3** (caso borde) CB-55: Dada una caída del NASDAQ-100 de 3 % o más en el día, cuando se detecta, entonces se crea una alerta crítica para todos.
- **CA-4** Dado `broad_selloff_risk` o `major_event_today` mayor o igual a 0,8 sobre el estado del mercado, cuando JEV lo responde, entonces se crea la alerta correspondiente para todos.
- **CA-5** Dada una alerta ya activa con la misma clave, cuando el ciclo siguiente detecta lo mismo, entonces no se crea otra.

## Casos borde

CB-55, CB-84

## Escenario E2E

E2E-06 (actualizado)

## Tareas

- [ ] Función `agente`: regla de contradicción de 07 §6.3 y preguntas de mercado `broad_selloff_risk` y `major_event_today`.
- [ ] Alertas de código: caída del NASDAQ-100 de 3 % o más, datos desactualizados y contexto sin generar por una falla.
- [ ] Claves de deduplicación por tipo y símbolo, y parámetro `jev.umbral_contradiccion`.
- [ ] Pruebas `deno test` de cada alerta con el JEV simulado en el escenario de contradicción.
- [ ] E2E-06 actualizado: una contradicción genera la alerta a Analistas.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-047 · Puntaje compuesto y elección de la mejor opción](HU-047-puntaje-compuesto-y-eleccion-de-la-mejor-opcion.md) | La contradicción se evalúa al decidir. |
| Depende de | [HU-048 · Pantalla Oportunidades con la explicación de cada evaluación](HU-048-pantalla-oportunidades-con-la-explicacion-de-cada-evaluacion.md) | Extiende el escenario E2E-06 y muestra la advertencia. |
| Depende de | [HU-085 · Alertas del sistema por audiencia](../E-09-tiempo-real-y-notificaciones/HU-085-alertas-del-sistema-por-audiencia.md) | Guarda y muestra las alertas por audiencia. |

## Notas técnicas

Las alertas críticas de mercado salen además por push desde R5 ([HU-088](../E-09-tiempo-real-y-notificaciones/HU-088-recibir-avisos-por-push.md)).

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
