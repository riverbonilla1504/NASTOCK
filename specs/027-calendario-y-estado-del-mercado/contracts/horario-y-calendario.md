# Contratos: HU-027 · Calendario, reloj y estado del mercado

## 1. Interfaz del broker (`_shared/broker/interfaz.ts`)

Solo operaciones de lectura; las de órdenes llegan con E-08. La implementan `alpaca.ts` (real) y `simulado.ts`; `crearBroker()` elige con `PROVEEDOR_BROKER` (`elegirProveedor("broker", …)`).

```ts
export interface DiaDeCalendario {
  fecha: string;            // AAAA-MM-DD, día de mercado en Nueva York
  apertura: string;         // ISO 8601 en UTC
  cierre: string;           // ISO 8601 en UTC
  sesion: "regular" | "media_jornada";
}
export interface RelojDelBroker {
  ahora: string;            // ISO 8601 en UTC
  abierto: boolean;
  proximaApertura: string;  // ISO 8601 en UTC
  proximoCierre: string;    // ISO 8601 en UTC
}
export interface ActivoDelBroker {
  simbolo: string;
  negociable: boolean;      // status == "active" && tradable
  fraccionable: boolean;
}
export interface Broker {
  /** Días de mercado entre desde y hasta, ambos incluidos. */
  calendario(consulta: { desde: string; hasta: string }, ahora: Date): Promise<DiaDeCalendario[]>;
  reloj(ahora: Date): Promise<RelojDelBroker>;
  activos(simbolos: readonly string[]): Promise<ActivoDelBroker[]>;
}
```

`ErrorDeProveedor` (de `_shared/mercado/interfaz.ts`) es el error de los dos proveedores.

### Alpaca (`ALPACA_TRADING_URL`, `ALPACA_KEY_ID`, `ALPACA_SECRET_KEY`)

| Operación | Llamada | Conversión |
|---|---|---|
| `calendario` | `GET /v2/calendar?start=&end=` → `[{date, open, close}]` | `open` y `close` son hora de Nueva York: se pasan a UTC con `Intl`. `sesion = media_jornada` si `close < 16:00`. Se descarta un día incoherente (cierre ≤ apertura o formato inválido). |
| `reloj` | `GET /v2/clock` → `{timestamp, is_open, next_open, next_close}` | Fechas con desfase a UTC. |
| `activos` | `GET /v2/assets/{simbolo}` → `{symbol, status, tradable, fractionable}`; un 404 es `negociable=false`, `fraccionable=false` | Tandas de 10 en paralelo. |

Las llaves viajan solo en las cabeceras `APCA-API-KEY-ID` y `APCA-API-SECRET-KEY`; los errores no las copian. Cada respuesta se valida con zod.

### Simulado (`RELOJ_SIMULADO`)

| Modo | `calendario` | `reloj` |
|---|---|---|
| `calendario` (por defecto) | Lunes a viernes, 9:30–16:00 NY; días de excepción inyectables (feriado, media jornada) | Según ese calendario y `ahora` |
| `siempre_abierto` | El día de `ahora` en NY con la sesión alrededor de `ahora` (1 h antes, 6 h después) | `abierto = true` |
| `cerrado` | Sin sesión el día de `ahora` | `abierto = false` |
| `cierre_en_10_min` | El día de `ahora` con cierre 10 minutos después | `abierto = true` |

## 2. Funciones de `private`

Firmas en `data-model.md`. Errores: argumento nulo o con forma inválida → `raise exception 'sincronizar_calendario: …'` (patrón de `guardar_barras_diarias`).

## 3. Edge Function `calendario-mercado` (amplía el contrato de HU-026)

`POST /functions/v1/calendario-mercado` con `x-secreto-interno`. Autenticación y códigos como en HU-026.

### Pasos

1. `ahora = private.ahora()`. `hoy` = fecha de Nueva York.
2. **Calendario**: `broker.calendario({desde: hoy, hasta: hoy + 60})` → `private.sincronizar_calendario(desde, hasta, días)`.
3. **Reloj**: `broker.reloj(ahora)`; compara con `private.mercado_abierto()`.
4. **Activos**: símbolos de `private.simbolos_del_universo()` → `broker.activos` → `private.sincronizar_activos`.
5. **Historia**: `cargarHistoria` de HU-026, con lo que quede del presupuesto de 100 s.

### Respuesta `200`

```json
{ "desde": "2024-11-06", "hasta": "2026-11-05", "simbolos_consultados": 0, "barras_recibidas": 0,
  "barras_nuevas": 0, "barras_descartadas": 0, "sin_datos": [], "pendientes": [],
  "calendario": { "desde": "2026-11-06", "hasta": "2027-01-05", "dias_recibidos": 41, "dias_guardados": 41, "dias_eliminados": 0 },
  "reloj": { "abierto_broker": false, "abierto_bd": false, "coincide": true },
  "activos": { "consultados": 104, "actualizados": 104, "desactivados": [] } }
```

Si un paso falla por el proveedor, los demás corren y la respuesta es `502 {"codigo":"INTEGRACION_CAIDA", …}` con el resultado de cada paso y `error` en el que falló. Cualquier otro fallo es `500`, sin detalles internos.

## 4. Trabajo `pg_cron`

`calendario`, `0 10 * * *` (10:00 UTC): `select private.despertar_funcion('calendario-mercado');` (`docs/05` §7).

## 5. RPC `estado_mercado()`

Ver `data-model.md`. Se construye al final (plan, puntos abiertos 1 y 3).
