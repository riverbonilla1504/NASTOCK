# HU-048 · Pantalla Oportunidades con la explicación de cada evaluación

| Campo | Valor |
|---|---|
| Épica | [E-06 · IA: contexto y decisión](README.md) |
| Entrega (hito) | R3 · La IA analiza |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-07, M-06 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-06` · `M-07` · `M-06` · `prioridad-alta` |

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** ver qué acciones está evaluando la IA y por qué eligió o descartó cada una,  
**para** entender y poder juzgar lo que propone.

## Requisitos funcionales

- [FR-119 · Pantalla Oportunidades](../requisitos-funcionales/FR-119-pantalla-oportunidades.md)
- [FR-120 · Explicación de cada decisión](../requisitos-funcionales/FR-120-explicacion-de-cada-decision.md)

## Reglas

PM-35 · 07 §14 · 06 §6 · 03 §3 · D-42

## Criterios de aceptación

- **CA-1** Dado un ciclo completado, cuando un Analista abre Oportunidades, entonces ve las candidatas de todos los bolsillos con su puntaje, su confianza, los aportes por dimensión, las advertencias y el resumen del contexto.
- **CA-2** (aislamiento) Dado un Usuario, cuando llama `oportunidades('arriesgadas')`, entonces no recibe candidatas: solo ve las del bolsillo de Usuarios.
- **CA-3** Dada la candidata elegida, cuando se abre su detalle, entonces muestra por qué ganó (las tres dimensiones que más aportaron), qué la frena y los titulares usados con su enlace.
- **CA-4** Dada una candidata evaluada "sin contexto", excluida o descartada, cuando se muestra, entonces lleva el motivo visible.
- **CA-5** Dado un ciclo nuevo, cuando termina, entonces Analistas y Administradores ven la pantalla actualizarse con el evento `ciclo_agente`.

## Casos borde

—

## Escenario E2E

E2E-06 (nuevo)

## Tareas

- [ ] RPC `oportunidades(bolsillo)`: candidatas del último ciclo con puntaje, confianza, aportes, advertencias y resumen del contexto; el Usuario solo recibe el bolsillo de Usuarios.
- [ ] Función `agente`: armado de la explicación con las piezas de 07 §14 (qué, por qué ganó, qué la frena, contexto y advertencias), guardada en la evaluación.
- [ ] App: `lib/features/oportunidades/` con la lista por bolsillo y el detalle de cada candidata, incluido el contexto con sus titulares.
- [ ] Pruebas pgTAP de `oportunidades()` por rol y pruebas de widget.
- [ ] E2E-06: ciclo con contexto y JEV simulados → Oportunidades con explicación; contexto viejo → "sin contexto".
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-047 · Puntaje compuesto y elección de la mejor opción](HU-047-puntaje-compuesto-y-eleccion-de-la-mejor-opcion.md) | Muestra las evaluaciones del último ciclo. |
| Depende de | [HU-006 · Navegación y guardas según el rol](../E-02-identidad-y-acceso/HU-006-navegacion-y-guardas-segun-el-rol.md) | La pantalla cuelga del menú de los tres roles. |
| Depende de | [HU-084 · Gestor de tiempo real en la app](../E-09-tiempo-real-y-notificaciones/HU-084-gestor-de-tiempo-real-en-la-app.md) | Se actualiza con el patrón foto y eventos. |
| Depende de | [TT-06 · Arnés E2E de backend y de la app](../E-01-cimientos-y-calidad-continua/TT-06-arnes-e2e-de-backend-y-de-la-app.md) | Agrega el escenario E2E-06. |
| Habilita | [HU-049 · Alertas de contradicción y de mercado](HU-049-alertas-de-contradiccion-y-de-mercado.md) | HU-049: extiende el escenario E2E-06 y muestra la advertencia. |
| Habilita | [HU-051 · Análisis bajo demanda de un símbolo](HU-051-analisis-bajo-demanda-de-un-simbolo.md) | HU-051: el resultado se muestra con la misma explicación. |

## Notas técnicas

JEV no redacta: la explicación la arma el código con piezas verificables (D-42). Las tablas del agente no son legibles para el Usuario: ve lo suyo solo a través de `oportunidades()` (03 §4.3).

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
