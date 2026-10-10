# HU-030 · Pantalla de mercado en vivo

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
**quiero** ver los precios del NASDAQ-100 y sus ETFs moverse y el estado del mercado,  
**para** seguir el mercado desde la app.

## Requisitos funcionales

- [FR-071 · Pantalla de mercado](../requisitos-funcionales/FR-071-pantalla-de-mercado.md)
- [FR-072 · Consulta de la lista blanca](../requisitos-funcionales/FR-072-consulta-de-la-lista-blanca.md)

## Reglas

PM-04 · PM-07 · RN-42 · 03 §3 · 09 §1

## Criterios de aceptación

- **CA-1** Dada una persona con sesión, cuando abre Inicio / Mercado, entonces ve las cotizaciones del universo con su variación del día y el estado del mercado.
- **CA-2** Dado un evento `cotizaciones`, cuando llega, entonces los precios cambian en pantalla sin recargar.
- **CA-3** Dado el mercado abierto, cuando la persona mira el encabezado, entonces ve la cuenta regresiva al cierre en hora de Bogotá; con el mercado cerrado, ve la cuenta regresiva a la apertura.
- **CA-4** Dada la lista de símbolos, cuando la persona la filtra por bolsillo, entonces ve la lista blanca activa de ese bolsillo.

## Casos borde

—

## Escenario E2E

E2E-03 (nuevo)

## Tareas

- [ ] App: `lib/features/mercado/` con `cotizacionesProvider` (foto de `cotizaciones` y eventos del canal `mercado`) y `estadoMercadoProvider` con temporizador.
- [ ] App: lista del universo con precio, variación del día y filtro por bolsillo.
- [ ] App: encabezado con el estado del mercado y la cuenta regresiva en hora de Bogotá.
- [ ] Pruebas de widget y de los providers con repositorios falsos.
- [ ] E2E-03: la ingesta simulada publica precios y la app los muestra.
- [ ] Verificación: `scripts/verificar.sh` completo en verde.

## Relaciones

| Tipo | Ítem | Motivo |
|---|---|---|
| Depende de | [HU-028 · Ingesta de precios cada 15 segundos](HU-028-ingesta-de-precios-cada-15-segundos.md) | Muestra los precios que publica la ingesta. |
| Depende de | [HU-084 · Gestor de tiempo real en la app](../E-09-tiempo-real-y-notificaciones/HU-084-gestor-de-tiempo-real-en-la-app.md) | Consume el canal `mercado` y usa el reloj corregido. |
| Depende de | [HU-006 · Navegación y guardas según el rol](../E-02-identidad-y-acceso/HU-006-navegacion-y-guardas-segun-el-rol.md) | Es la pantalla de inicio de los tres roles. |
| Depende de | [TT-06 · Arnés E2E de backend y de la app](../E-01-cimientos-y-calidad-continua/TT-06-arnes-e2e-de-backend-y-de-la-app.md) | Agrega el escenario E2E-03. |
| Habilita | [HU-031 · Comparación de QQQ, QLD y ×2 teórico](HU-031-comparacion-de-qqq-qld-y-x2-teorico.md) | HU-031: la comparación es parte de la pantalla de mercado. |
| Habilita | [HU-032 · Aviso de dato desactualizado](HU-032-aviso-de-dato-desactualizado.md) | HU-032: la marca se muestra junto a los precios de la pantalla de mercado. |

## Notas técnicas

Los precios son la única excepción a la regla de eventos sin montos: son públicos dentro de la empresa (09 §4).

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
