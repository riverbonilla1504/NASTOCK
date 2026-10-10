# HU-027 · Calendario, reloj y estado del mercado

| Campo | Valor |
|---|---|
| Épica | [E-04 · Datos de mercado](README.md) |
| Entrega (hito) | R1 · Ver el mercado en vivo |
| Rol | Usuario |
| Prioridad | Alta |
| Módulos afectados | M-05 |
| Estimación | Por definir al refinar |
| Etiquetas | `historia` · `E-04` · `M-05` · `prioridad-alta` |

## Historia

**Como** Usuario, Analista o Administrador,  
**quiero** saber si el mercado está abierto y cuánto falta para que abra o cierre,  
**para** entender cuándo se puede operar.

## Requisitos funcionales

- [FR-063 · Calendario y reloj de mercado](../requisitos-funcionales/FR-063-calendario-y-reloj-de-mercado.md)
- [FR-064 · Estado del mercado](../requisitos-funcionales/FR-064-estado-del-mercado.md)
- [FR-065 · Atributos de los activos](../requisitos-funcionales/FR-065-atributos-de-los-activos.md)

## Reglas

RN-41 · RN-42 · RN-43 · 08 §6 · 10 §12

## Criterios de aceptación

- **CA-1** Dado el calendario sincronizado, cuando se llama `estado_mercado()`, entonces devuelve el estado (cerrado, preapertura, abierto sin compras, abierto o cierre próximo), la próxima apertura o cierre, la ventana de compras y la frescura de los datos.
- **CA-2** (caso borde) CB-49: Dado un feriado de EE. UU., cuando se consulta, entonces el mercado está cerrado todo el día.
- **CA-3** (caso borde) CB-50: Dada una media jornada, cuando se consulta, entonces el cierre es a las 13:00 de Nueva York y la ventana de compras se calcula con ese cierre.
- **CA-4** (caso borde) CB-51: Dado el cambio de horario de verano en EE. UU., cuando se consulta, entonces las horas guardadas en UTC siguen correctas sin intervención.
- **CA-5** Dado un símbolo que deja de ser negociable en Alpaca, cuando corre la sincronización diaria, entonces queda desactivado en la lista blanca.

## Casos borde

CB-49, CB-50, CB-51

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-03.

## Tareas

- [ ] Funciones: `_shared/broker/` con la operación `calendario` (interfaz, `alpaca.ts` y `simulado.ts` con reloj de mercado configurable: siempre abierto, cerrado o a 10 minutos del cierre).
- [ ] Migración: tabla `calendario_mercado` (06 §5.2) con RLS de lectura.
- [ ] Migración: `private.mercado_abierto()`, `private.mercado_en_ventana(margen)` y `private.ventana_compras_abierta()` sobre `private.ahora()`, y parámetros `mercado.minutos_tras_apertura` y `mercado.minutos_antes_cierre`.
- [ ] RPC `estado_mercado()`.
- [ ] Función `calendario-mercado`: sincroniza calendario, reloj y los atributos `fraccionable` y `negociable` de la lista blanca; trabajo `calendario` de `pg_cron` (diario, 10:00 UTC).
- [ ] Pruebas: pgTAP de las funciones de horario con el reloj fijado (feriado, media jornada y ventana) y `deno test` de `calendario-mercado`.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-026 · Universo del NASDAQ-100 y carga histórica de barras](HU-026-universo-del-nasdaq-100-y-carga-historica-de-barras.md) | Sincroniza los atributos de los símbolos de la lista blanca. |
| Depende de | [TT-05 · Base de proveedores simulados, reloj controlable y datos de prueba](../E-01-cimientos-y-calidad-continua/TT-05-base-de-proveedores-simulados-reloj-controlable-y-datos-de-prueba.md) | Usa el reloj controlable y el broker simulado. |
| Habilita | [HU-015 · Confirmar el aporte por conciliación y repartirlo 50/25/25](../E-03-fondo-y-libro-contable/HU-015-confirmar-el-aporte-por-conciliacion-y-repartirlo-50-25-25.md) | HU-015: reutiliza el adaptador del broker y el horario de mercado. |
| Habilita | [HU-028 · Ingesta de precios cada 15 segundos](HU-028-ingesta-de-precios-cada-15-segundos.md) | HU-028: solo consulta con el mercado en ventana. |
| Habilita | [HU-029 · Barra diaria tras el cierre y retención de barras de minuto](HU-029-barra-diaria-tras-el-cierre-y-retencion-de-barras-de-minuto.md) | HU-029: sabe si el mercado ya cerró por el calendario. |
| Habilita | [HU-043 · Vigencia y regeneración del contexto](../E-06-ia-contexto-y-decision/HU-043-vigencia-y-regeneracion-del-contexto.md) | HU-043: la preapertura se calcula con el calendario. |
| Habilita | [HU-046 · Ciclo del agente: programación, uno a la vez y omisiones](../E-06-ia-contexto-y-decision/HU-046-ciclo-del-agente-programacion-uno-a-la-vez-y-omisiones.md) | HU-046: solo corre en la ventana de compras. |
| Habilita | [HU-085 · Alertas del sistema por audiencia](../E-09-tiempo-real-y-notificaciones/HU-085-alertas-del-sistema-por-audiencia.md) | HU-085: conecta la alerta de símbolo no negociable. |

## Notas técnicas

El estado del mercado se calcula, no se guarda (08 §6). El calendario nunca se programa a mano (RN-41). La alerta al Administrador por un símbolo que deja de ser negociable se conecta en [HU-085](../E-09-tiempo-real-y-notificaciones/HU-085-alertas-del-sistema-por-audiencia.md).

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
