# HU-045 · Adaptador de JEV y estado en etiquetas

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
**quiero** que el sistema consulte a JEV con etiquetas en inglés y una versión fijada del modelo, por TypeSafe o por Cloudflare,  
**para** obtener decisiones tipadas con confianza calibrada sin depender de un solo proveedor.

## Requisitos funcionales

- [FR-105 · Estado en etiquetas para JEV](../requisitos-funcionales/FR-105-estado-en-etiquetas-para-jev.md)
- [FR-106 · Sin datos personales hacia las IAs](../requisitos-funcionales/FR-106-sin-datos-personales-hacia-las-ias.md)
- [FR-107 · Consulta a JEV](../requisitos-funcionales/FR-107-consulta-a-jev.md)
- [FR-108 · Reacción a fallos de JEV](../requisitos-funcionales/FR-108-reaccion-a-fallos-de-jev.md)

## Reglas

07 §4.3 · 07 §4.5 · 07 §5 · 07 §6.1 · 07 §10 · D-40 · D-43 · RSG-15

## Criterios de aceptación

- **CA-1** Dadas las métricas de una candidata, cuando se arma el estado, entonces contiene solo etiquetas semánticas en inglés (por ejemplo "strong gain") y ninguna cifra ni fecha para comparar.
- **CA-2** Dados el estado y el contexto, cuando los revisa la prueba automática, entonces no contienen correos, nombres ni identificadores de personas o de subcuentas.
- **CA-3** Dada una candidata, cuando se consulta a JEV, entonces va una sola llamada con todas las preguntas y con `ia.modelo_jev` fijado, y se guarda el `model` que devuelve.
- **CA-4** (caso borde) CB-90: Dado `JEV_PROVEEDOR=cloudflare`, cuando se consulta, entonces el adaptador usa Cloudflare Workers AI con la misma interfaz.
- **CA-5** Dada una respuesta 429 o 529, cuando ocurre, entonces el adaptador reintenta con espera exponencial y, si falla, la candidata se omite; y si JEV no responde en `ia.timeout_jev_seg` segundos, corta la espera.

## Casos borde

CB-89, CB-90

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercitan E2E-06 y E2E-07.

## Tareas

- [ ] Funciones: adaptador de JEV en `_shared/ia/` con `typesafe.ts`, `cloudflare.ts` y `simulado.ts` (respuestas deterministas a partir de las etiquetas, con escenarios de confianza baja, contradicción y sin respuesta).
- [ ] Funciones: armado del estado con una lista cerrada de campos y con los cortes de etiquetas de la configuración de decisión.
- [ ] Migración: parámetros `ia.modelo_jev` e `ia.timeout_jev_seg`.
- [ ] Registro de la salud de `jev` con `_shared/salud.ts`.
- [ ] Pruebas `deno test`: etiquetas, ausencia de datos personales, reintentos y los dos proveedores con respuestas grabadas.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-044 · Calidad de datos, métricas y puntaje cuantitativo](HU-044-calidad-de-datos-metricas-y-puntaje-cuantitativo.md) | Las etiquetas se derivan de las métricas. |
| Depende de | [TT-05 · Base de proveedores simulados, reloj controlable y datos de prueba](../E-01-cimientos-y-calidad-continua/TT-05-base-de-proveedores-simulados-reloj-controlable-y-datos-de-prueba.md) | El proveedor de JEV se elige con `_shared/proveedores.ts`. |
| Depende de | [HU-035 · Salud de las integraciones](../E-05-motor-de-politicas-y-configuracion/HU-035-salud-de-las-integraciones.md) | Registra la salud de `jev`. |
| Habilita | [HU-047 · Puntaje compuesto y elección de la mejor opción](HU-047-puntaje-compuesto-y-eleccion-de-la-mejor-opcion.md) | HU-047: usa las respuestas de JEV. |
| Habilita | [HU-052 · Opinión de la IA sobre una orden manual](HU-052-opinion-de-la-ia-sobre-una-orden-manual.md) | HU-052: consulta a JEV con el mismo adaptador. |

## Notas técnicas

JEV no hace cuentas ni compara números o fechas: por eso recibe etiquetas (D-40). La versión va fijada (`jev-1.13.0`, no `jev-latest`); cambiarla es un cambio de configuración probado en sombra (CB-89). JEV es muy nuevo (RSG-15): el simulado permite desarrollar sin depender del acceso.

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
