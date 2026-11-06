# Contrato: proveedor de mercado (`_shared/mercado/`)

Interfaz de `docs/10` §1 (`snapshots` y `barras`) con una implementación real (`alpaca.ts`) y una simulada (`simulado.ts`). Se elige con `elegirProveedor("mercado", …)` de `_shared/proveedores.ts` (TT-05).

```ts
export interface Barra {
  simbolo: string;
  fecha: string;       // AAAA-MM-DD, día de mercado en Nueva York
  apertura: number; maximo: number; minimo: number; cierre: number;
  volumen: number;     // entero
}

export interface Cotizacion {
  simbolo: string;
  precio: number;
  bid: number | null; ask: number | null;
  cierreAnterior: number | null;
  volumenDia: number | null;
  momento: string;     // ISO 8601 UTC: hora del dato según el proveedor
}

export interface ResultadoDeBarras { barras: Barra[]; descartadas: number }

export interface ProveedorDeMercado {
  /** Última cotización de cada símbolo. `ahora` sale de private.ahora(); el real lo ignora. */
  snapshots(simbolos: readonly string[], ahora: Date): Promise<Cotizacion[]>;
  /**
   * Barras diarias de [desde, hasta] (AAAA-MM-DD, ambos incluidos), ordenadas por símbolo y
   * fecha. Las incoherentes no se devuelven y se cuentan en `descartadas`.
   */
  barras(consulta: { simbolos: readonly string[]; desde: string; hasta: string }): Promise<ResultadoDeBarras>;
}

export class ErrorDeProveedor extends Error { readonly estado?: number }
export function crearProveedorDeMercado(leer?: LeerVariable): ProveedorDeMercado;
```

## `alpaca.ts`

| Operación | Llamada |
|---|---|
| `barras` | `GET {ALPACA_DATA_URL}/v2/stocks/bars?symbols=…&timeframe=1Day&start=…&end=…&limit=10000&adjustment=split&feed=iex&sort=asc[&page_token=…]`. Sigue `next_page_token` hasta que sea nulo. |
| `snapshots` | `GET {ALPACA_DATA_URL}/v2/stocks/snapshots?symbols=…&feed=iex`. `precio` = `latestTrade.p`, `bid`/`ask` = `latestQuote.bp`/`ap`, `cierreAnterior` = `prevDailyBar.c`, `volumenDia` = `dailyBar.v`, `momento` = `latestTrade.t`. |

- Cabeceras `APCA-API-KEY-ID` y `APCA-API-SECRET-KEY` (de `ALPACA_KEY_ID` y `ALPACA_SECRET_KEY`); nunca en la URL ni en los mensajes de error.
- Toda respuesta se valida con zod (`docs/05` §2, A5). Una barra incoherente (máximo menor que el cierre, precio no positivo…) se descarta y se cuenta; no rompe el lote.
- Tiempo de espera de 15 s por solicitud. Un estado distinto de 2xx lanza `ErrorDeProveedor` con el estado; sin reintentos a ciegas.
- `fecha` = día en `America/New_York` de la marca `t` de la barra.

## `simulado.ts`

Función pura de `(símbolo, fecha)`: mismo resultado para el mismo par, sin importar el rango pedido. Solo lunes a viernes.

- Semilla del símbolo: `s = Σ código(letra_i) · 31^(n−1−i) mod 2147483647`.
- Para el día `d` (días desde 2000-01-01): `x0 = (s·131 + d·7919 + 12345) mod 2147483647` y `x(k+1) = 48271 · x(k) mod 2147483647`; `u_k = x_k / 2147483647`, con `u1…u5` de `x1…x5`.
- Retorno diario del símbolo: `r = (u1 − 0.5) · 2 · sigma`. `sigma` = 0,012 para QQQ, 0,015 para el resto de los símbolos. QLD usa `2 · r(QQQ)` y TQQQ `3 · r(QQQ)` del mismo día.
- `cierre(d) = base · exp(Σ r)` desde el ancla 2020-01-01. `base` = 400 (QQQ), 80 (QLD), 60 (TQQQ), y `30 + (s mod 370)` para el resto.
- `apertura(d) = cierre(d−1) · exp((u2 − 0.5) · 0.01)` (el primer día, `base`). `maximo = max(apertura, cierre) · (1 + u3 · 0.01)`; `minimo = min(apertura, cierre) · (1 − u4 · 0.01)`; `volumen = floor(1 000 000 · (0.5 + u5))`.
- Precios redondeados a 4 decimales al final (sin redondear los intermedios).
- `snapshots`: cierre del día hábil anterior a `ahora` más un paso determinista por minuto de sesión (09:30–16:00, hora de Nueva York); fuera de sesión, el último precio de la sesión anterior. `bid`/`ask` = precio ∓ 0,01.

**Valores conocidos** (los comparten `simulado_test.ts` y `02_universo_y_barras_test.sql`; los dos algoritmos deben dar exactamente esto):

| Símbolo | Fecha | Apertura | Máximo | Mínimo | Cierre | Volumen |
|---|---|---|---|---|---|---|
| QQQ | 2026-06-01 | 389.8220 | 390.4826 | 387.4463 | 388.5635 | 1156260 |
| AAPL | 2026-06-01 | 128.0763 | 129.3337 | 126.8377 | 127.0639 | 919189 |
| TQQQ | 2025-11-03 | 62.3450 | 62.6551 | 60.4177 | 60.8589 | 1467833 |

## Pruebas

- `alpaca_test.ts`: respuestas grabadas (una página, dos páginas, vacía, con una barra incoherente, error 401/403/429/500), cabeceras, lotes y fecha en Nueva York.
- `simulado_test.ts`: determinismo, independencia del rango, solo días hábiles, coherencia de cada barra, QLD = 2 × QQQ, valores conocidos, `snapshots` estables para la misma hora.
