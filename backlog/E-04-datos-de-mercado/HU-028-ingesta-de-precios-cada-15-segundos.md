# HU-028 · Ingesta de precios cada 15 segundos

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
**quiero** que los precios del NASDAQ-100 y sus ETFs se actualicen cada 15 segundos mientras el mercado está abierto,  
**para** ver el mercado casi en tiempo real.

## Requisitos funcionales

- [FR-066 · Ingesta de precios](../requisitos-funcionales/FR-066-ingesta-de-precios.md)
- [FR-067 · Descarte de precios inválidos](../requisitos-funcionales/FR-067-descarte-de-precios-invalidos.md)
- [FR-068 · Sin consulta fuera de horario](../requisitos-funcionales/FR-068-sin-consulta-fuera-de-horario.md)
- [FR-069 · Difusión de precios en vivo](../requisitos-funcionales/FR-069-difusion-de-precios-en-vivo.md)

## Reglas

09 §1 · 09 §2 · 05 §6 · 05 §7 · D-24

## Criterios de aceptación

- **CA-1** Dado el mercado en ventana, cuando pasan 15 segundos, entonces `ingesta-mercado` consulta todos los símbolos en una sola llamada, actualiza `cotizaciones` y publica el evento `cotizaciones` en el canal `mercado`.
- **CA-2** (caso borde) CB-53: Dado un precio nulo, no numérico o menor o igual a cero, cuando llega, entonces ese símbolo se descarta y queda registrado, y los demás se guardan.
- **CA-3** Dado el mercado cerrado, cuando corre el trabajo programado, entonces no llama al proveedor y la app muestra el cierre anterior.
- **CA-4** Dado un fallo del proveedor, cuando ocurre, entonces la app sigue mostrando el último precio con su antigüedad.
- **CA-5** (permiso) Dada una llamada a `ingesta-mercado` sin el secreto interno, cuando llega, entonces la función la rechaza.

## Casos borde

CB-53

## Escenario E2E

Sin escenario propio en el catálogo de 15 §4. Lo ejercita E2E-03.

## Tareas

- [ ] Migración: tabla `cotizaciones` (06 §5.2) con RLS de lectura.
- [ ] Migración: `private.publicar_cotizaciones(datos)`: guarda cotizaciones y barras de minuto y emite el broadcast `cotizaciones`.
- [ ] Función `ingesta-mercado`: `snapshots` del universo y los ETFs (feed IEX), validación con zod y llamada a `publicar_cotizaciones`; autenticación con el secreto interno.
- [ ] Migración: trabajo `ingesta_mercado` de `pg_cron` cada 15 segundos, condicionado a `private.mercado_en_ventana(interval '10 minutes')`.
- [ ] Pruebas `deno test` de `ingesta-mercado` (precio inválido y fallo del proveedor) y pgTAP de `publicar_cotizaciones`.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-026 · Universo del NASDAQ-100 y carga histórica de barras](HU-026-universo-del-nasdaq-100-y-carga-historica-de-barras.md) | Consulta los símbolos del universo. |
| Depende de | [HU-027 · Calendario, reloj y estado del mercado](HU-027-calendario-reloj-y-estado-del-mercado.md) | Solo consulta con el mercado en ventana. |
| Depende de | [HU-083 · Canales privados de tiempo real](../E-09-tiempo-real-y-notificaciones/HU-083-canales-privados-de-tiempo-real.md) | Publica en el canal `mercado`. |
| Habilita | [HU-030 · Pantalla de mercado en vivo](HU-030-pantalla-de-mercado-en-vivo.md) | HU-030: muestra los precios que publica la ingesta. |
| Habilita | [HU-035 · Salud de las integraciones](../E-05-motor-de-politicas-y-configuracion/HU-035-salud-de-las-integraciones.md) | HU-035: la ingesta es la primera función que registra su salud. |
| Habilita | [HU-037 · Motor de políticas: reglas de la propuesta](../E-05-motor-de-politicas-y-configuracion/HU-037-motor-de-politicas-reglas-de-la-propuesta.md) | HU-037: RR-07 y RR-11 usan el horario y la última cotización. |
| Habilita | [HU-044 · Calidad de datos, métricas y puntaje cuantitativo](../E-06-ia-contexto-y-decision/HU-044-calidad-de-datos-metricas-y-puntaje-cuantitativo.md) | HU-044: usa el precio en vivo y su antigüedad. |
| Habilita | [HU-046 · Ciclo del agente: programación, uno a la vez y omisiones](../E-06-ia-contexto-y-decision/HU-046-ciclo-del-agente-programacion-uno-a-la-vez-y-omisiones.md) | HU-046: el evento de QQQ se detecta al publicar cotizaciones. |
| Habilita | [HU-067 · Invalidación por precio y por cambio de situación](../E-07-sugerencias-y-decisiones/HU-067-invalidacion-por-precio-y-por-cambio-de-situacion.md) | HU-067: la banda se revisa al publicar cotizaciones. |
| Habilita | [HU-078 · Protección virtual en compras fraccionales](../E-08-ejecucion-y-broker/HU-078-proteccion-virtual-en-compras-fraccionales.md) | HU-078: se evalúa con cada lote de cotizaciones. |

## Notas técnicas

`publicar_cotizaciones` crece con otras historias: protecciones virtuales ([HU-078](../E-08-ejecucion-y-broker/HU-078-proteccion-virtual-en-compras-fraccionales.md)), invalidación por banda ([HU-067](../E-07-sugerencias-y-decisiones/HU-067-invalidacion-por-precio-y-por-cambio-de-situacion.md)) y evento de QQQ ([HU-046](../E-06-ia-contexto-y-decision/HU-046-ciclo-del-agente-programacion-uno-a-la-vez-y-omisiones.md)). El feed gratuito es IEX: puede diferir unos centavos del consolidado (CB-54). El registro en `salud_integraciones` se agrega en [HU-035](../E-05-motor-de-politicas-y-configuracion/HU-035-salud-de-las-integraciones.md).

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
