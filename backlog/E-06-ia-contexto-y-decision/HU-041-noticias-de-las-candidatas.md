# HU-041 · Noticias de las candidatas

| Campo | Valor |
|---|---|
| Épica | [E-06 · IA: contexto y decisión](README.md) |
| Entrega (hito) | R3 · La IA analiza |
| Rol | Analista |
| Prioridad | Alta |
| Módulos afectados | M-06 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-06` · `M-06` · `prioridad-alta` |

## Historia

**Como** Analista,  
**quiero** que el sistema descargue las noticias recientes de cada candidata,  
**para** que el contexto de la IA se base en noticias reales y no en lo que un modelo recuerde.

## Requisitos funcionales

- [FR-096 · Descarga de noticias](../requisitos-funcionales/FR-096-descarga-de-noticias.md)

## Reglas

07 §4.2 · 10 §11 · D-39

## Criterios de aceptación

- **CA-1** Dada una lista de símbolos, cuando corre la descarga, entonces `noticias` tiene las de las últimas `ia.noticias_horas` horas de cada símbolo, con titular, resumen, fuente, enlace y hora de publicación.
- **CA-2** Dada una noticia ya guardada, cuando se descarga otra vez, entonces no se duplica.
- **CA-3** (caso borde) CB-81: Dado que Alpaca News responde 403, cuando ocurre, entonces la salud de `alpaca_noticias` queda degradada, se alerta al Administrador y las candidatas siguen "sin contexto".
- **CA-4** (aislamiento) Dado un Usuario, cuando consulta `noticias`, entonces no recibe filas; un Analista y un Administrador sí.

## Casos borde

CB-81

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4.

## Tareas

- [ ] Migración: tabla `noticias` (06 §5.3) con índice GIN sobre `simbolos`, RLS para Analista y Administrador y `private.guardar_noticias(datos)`.
- [ ] Funciones: `_shared/noticias/` con la interfaz `noticias`, `alpaca.ts` y `simulado.ts` (titulares de prueba por símbolo).
- [ ] Migración: parámetro `ia.noticias_horas` y retención de 30 días en el trabajo `limpieza`.
- [ ] Pruebas `deno test` del adaptador con respuestas grabadas, incluido el 403, y pgTAP de `guardar_noticias`.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-026 · Universo del NASDAQ-100 y carga histórica de barras](../E-04-datos-de-mercado/HU-026-universo-del-nasdaq-100-y-carga-historica-de-barras.md) | Descarga noticias de los símbolos del universo. |
| Depende de | [TT-05 · Base de proveedores simulados, reloj controlable y datos de prueba](../E-01-cimientos-y-calidad-continua/TT-05-base-de-proveedores-simulados-reloj-controlable-y-datos-de-prueba.md) | El proveedor de noticias se elige con `_shared/proveedores.ts`. |
| Depende de | [HU-035 · Salud de las integraciones](../E-05-motor-de-politicas-y-configuracion/HU-035-salud-de-las-integraciones.md) | Registra la salud de `alpaca_noticias`. |
| Habilita | [HU-042 · Contexto de DeepSeek validado contra sus fuentes](HU-042-contexto-de-deepseek-validado-contra-sus-fuentes.md) | HU-042: el contexto se arma con las noticias descargadas. |

## Notas técnicas

Si la cuenta gratuita no tiene acceso a noticias, la alternativa está pendiente en Q-19. La descarga la dispara `contexto-ia` ([HU-042](HU-042-contexto-de-deepseek-validado-contra-sus-fuentes.md)).

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
