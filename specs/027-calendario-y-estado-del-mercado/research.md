# Investigación (Research): HU-027 · Calendario, reloj y estado del mercado

Cada decisión indica de dónde sale. Lo que `docs/` no fija se marca como **propuesta** y se confirma en el informe.

## D1 · Las horas del calendario se guardan en UTC y el horario de verano se resuelve al convertir

- **Decisión**: Alpaca `GET /v2/calendar` entrega, por día, `date`, `open` y `close` como hora local de Nueva York (`"09:30"`, `"16:00"`, `"13:00"` en media jornada). El adaptador los convierte a UTC con `Intl` (zona `America/New_York`) y la base guarda `timestamptz`. Nada más convierte horas: SQL solo compara instantes.
- **Por qué**: `docs/06` §5.2 ("ya en UTC, con horario de verano resuelto") y CB-51. Al estar en UTC, el cambio de horario no requiere ninguna intervención (CA-4).
- **Alternativas**: guardar hora local y convertir al consultar (descartada: es lo que CB-51 evita).

## D2 · Semántica de las funciones de horario

- **Decisión**: `abierto` ⇔ `apertura <= ahora < cierre` del día de mercado. `mercado_en_ventana(margen)` ⇔ `apertura − margen <= ahora < cierre` (el cron de `ingesta_mercado` la llama con 10 minutos: "mercado abierto o hasta 10 min antes de abrir", `docs/05` §7). La hora es siempre `private.ahora()`.
- **Fuente**: `docs/05` §7, `docs/06` §8.2, `docs/08` §6.
- **Estados** (`docs/08` §6): `cerrado` → `pre_apertura` (10 min antes) → `abierto_sin_compras` (primeros 5 min) → `abierto` → `cierre_proximo` (últimos 15 min, sin compras) → `cerrado`. En feriado no hay fila y el estado es `cerrado` todo el día; en media jornada el cierre sale de la fila (13:00 NY), así que la ventana de compras se corre sola (CB-50).

## D3 · Tipo de sesión

- **Decisión**: `sesion = 'media_jornada'` si el cierre local es anterior a las 16:00; `'regular'` en otro caso.
- **Fuente**: `docs/06` §5.2 (`regular` | `media_jornada`), RN-41 (media jornada: cierre 13:00).
- **Propuesta**: el umbral "antes de las 16:00" no está escrito; es la lectura natural de RN-41.

## D4 · Qué rango del calendario se sincroniza y qué pasa con lo que ya no está

- **Decisión (propuesta)**: cada ejecución pide al broker de hoy (fecha de Nueva York según `private.ahora()`) a 60 días. `private.sincronizar_calendario(desde, hasta, datos)` inserta o actualiza cada día recibido y borra los días de ese rango que el broker ya no lista (un cierre no programado). Los días pasados no se tocan.
- **Por qué**: RN-41 ("se sincroniza a diario") y la prueba de humo de `docs/15` §5 ("el calendario tiene los próximos 10 días"). 60 días cubre cualquier feriado vecino. Repetir la ejecución no cambia nada (idempotente).

## D5 · Reloj del broker

- **Decisión**: `reloj()` devuelve `{ahora, abierto, proximaApertura, proximoCierre}` de `GET /v2/clock`. La función solo lo contrasta con `private.mercado_abierto()` y devuelve `coincide` en la respuesta y un aviso en el registro si no coincide. No cambia datos.
- **Fuente**: `docs/05` §6 ("Calendario, reloj y atributos"), `docs/10` §1.
- **Propuesta**: qué hacer ante una discrepancia no está definido; solo se informa.

## D6 · Atributos de los activos

- **Decisión**: `activos(simbolos)` consulta `GET /v2/assets/{simbolo}` de la API de trading, en tandas de 10 en paralelo. `negociable = status == "active" && tradable`; `fraccionable = fractionable`. Un 404 significa que Alpaca no lo conoce: `negociable = false`, `fraccionable = false`.
- `private.sincronizar_activos(datos)` guarda ambos atributos y `sincronizado_en = private.ahora()` en todas las filas de ese símbolo y pone `activo = false` en las negociables que pasaron a `false`. Devuelve los símbolos desactivados (la alerta al Administrador es de HU-085, `docs/10` §10). **Un símbolo desactivado no se reactiva solo**: la lista blanca la mantiene el Administrador (HU-036).
- **Fuente**: FR-065, `docs/10` §10 y §12, `docs/06` §5.2.

## D7 · Broker simulado con reloj configurable

- **Decisión**: `BrokerSimulado` recibe el modo en el constructor y `crearBroker()` lo lee de `RELOJ_SIMULADO`: `calendario` (por defecto: de lunes a viernes, 9:30–16:00 de Nueva York, sin feriados salvo los que se le inyecten), `siempre_abierto` (la sesión de hoy contiene a `ahora`), `cerrado` (hoy no hay sesión) o `cierre_en_10_min` (hoy cierra 10 minutos después de `ahora`). El simulado recibe `ahora` de `private.ahora()` igual que el mercado simulado.
- **Fuente**: `docs/10` §9 ("siempre abierto", "cerrado", "a 10 min del cierre"); tarea de la historia.
- **Propuesta**: el nombre de la variable `RELOJ_SIMULADO` es nuestro. TT-06 puede pasarlo a `pruebas.escenarios` (`docs/15` §3) cuando exista el E2E.

## D8 · Orquestación y errores de `calendario-mercado`

- **Decisión**: la función corre cuatro pasos independientes: calendario, reloj, atributos e historia de barras. Si un paso falla por el proveedor, los demás igual corren y la respuesta es `502 INTEGRACION_CAIDA` con el resultado de cada paso; si todo sale bien, `200`. El resultado de la carga histórica se mantiene en la raíz del cuerpo para no romper lo de HU-026. El presupuesto de la carga de barras es lo que queda de los 100 s.
- **Por qué**: el calendario y los atributos usan la API de trading y las barras la de datos de Alpaca; que una caiga no debe impedir lo que la otra puede hacer.
