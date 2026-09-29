# 10 · Integración con la bolsa

## 1. El broker: Alpaca

| Criterio | Alpaca |
|---|---|
| Paper trading | Gratis, con precios reales |
| API | REST + WebSocket, pensada para operar desde código |
| Fracciones de acción | Sí (no en todos los activos: ver `fractionable`) |
| Protecciones en el broker | Órdenes *bracket*, OCO, OTO, trailing stop (solo acciones enteras) |
| Datos de mercado | Plan gratuito con feed IEX en tiempo real |
| Noticias | News API (Benzinga), gratuita con límites (§11) |
| Calendario y reloj del mercado | Endpoints `/v2/calendar` y `/v2/clock` |

> **Alcance: solo paper trading.** El MVP existe para probar si el sistema
> funciona. Operar con dinero real sería otra etapa (producción) que no se
> planifica todavía, y no hay nada de ella en esta especificación.

El código habla con Alpaca a través de **adaptadores** con interfaz propia
(`_shared/broker/`: `enviarOrden`, `consultarOrden`, `cancelarOrden`,
`posiciones`, `cuenta`, `calendario`; `_shared/mercado/`: `snapshots`,
`barras`; `_shared/noticias/`: `noticias`). Cada adaptador tiene una
implementación **simulada** para pruebas y demostraciones (§9).

### URLs y llaves

| Uso | URL | Llaves |
|---|---|---|
| Trading paper | `https://paper-api.alpaca.markets` | Par de llaves de la cuenta **paper** |
| Datos de mercado y noticias | `https://data.alpaca.markets` | Las mismas llaves |

Cada proyecto en la nube que opere contra Alpaca tiene **su propia cuenta
paper** y sus propias llaves.

---

## 2. Qué diferencias tiene paper trading con la realidad

Según la documentación de Alpaca, paper trading **no simula**: impacto de
mercado de nuestras órdenes, deslizamiento por latencia, dividendos,
posición en la cola de órdenes ni tarifas regulatorias. Los llenados se
hacen contra el mejor precio vigente.

Consecuencias para RiTech:

- Los resultados en paper serán **algo mejores** que los que se obtendrían
  con dinero. Los reportes lo advierten.
- No se contabilizan dividendos ni tarifas.
- Alpaca paper **no llena órdenes fuera del horario de mercado**: las pruebas
  automáticas y las demostraciones fuera de horario usan el broker simulado
  (§9).

---

## 3. Una cuenta, muchas subcuentas

Alpaca ve **una sola cuenta** con efectivo y posiciones agregadas. Las
subcuentas (bolsillos y cupos) existen solo en nuestro libro contable.
(Cifras ilustrativas; los "…" representan el resto de cupos.)

```
            NUESTRO LIBRO                               ALPACA
 ┌─────────────────────────────────────┐      ┌─────────────────────────┐
 │ reserva        efectivo 5.006,50    │      │ efectivo      9.212,40  │
 │ arriesgadas    efectivo 1.313,25    │      │                         │
 │                TQQQ 12              │ ───► │ TQQQ          12        │
 │ usuarios_comun efectivo   500,00    │  Σ   │ QLD            4        │
 │ cupo Ana       efectivo   289,80    │      │                         │
 │                QLD 1                │      │                         │
 │ cupo Pedro     efectivo   103,00    │      │                         │
 │                QLD 3                │      │                         │
 │ …                                   │      │                         │
 └─────────────────────────────────────┘      └─────────────────────────┘
```

Consecuencias:

- Cada orden en Alpaca pertenece a **una** subcuenta (lo sabemos por su
  `client_order_id`). Nunca se mezclan dos subcuentas en una orden.
- La cantidad de un símbolo en Alpaca debe ser igual a la suma de las
  posiciones abiertas de ese símbolo en todas las subcuentas. Lo verifica la
  conciliación (§8).
- Las patas de las protecciones nativas "apartan" acciones en Alpaca. Para
  vender acciones de un cupo hay que cancelar **sus** patas antes (08 §3).
- Rebalancear, asignar cupos o repartir ganancias **no toca Alpaca**: es
  mover saldo entre subcuentas en nuestro libro.

---

## 4. De dónde sale el dinero

### 4.1 Aportes

1. El administrador entra al panel de Alpaca y **reinicia la cuenta paper con
   el monto del fondo** (p. ej. USD 10.000). Por defecto trae USD 100.000.
2. En la app registra el aporte con referencia `paper-inicial`.
3. La conciliación lo confirma y se reparte 50/25/25 (02 §3).

Si la cuenta paper tiene más dinero que el registrado, la diferencia aparece
como **"excedente no asignado"** en la conciliación y no se usa jamás (las
órdenes solo gastan disponible de subcuentas). Si tiene menos, el aporte no
se confirma.

### 4.2 Retiros

Solo contables (02 §4): el efectivo sigue en la cuenta paper y pasa a ser
excedente no asignado.

---

## 5. Órdenes que usamos

| Caso | Clase | Tipo | TIF | Cantidad | Precio |
|---|---|---|---|---|---|
| Compra con ≥ 1 acción entera | `bracket` | `limit` | `gtc` | Acciones enteras | Límite = referencia × (1 + banda); stop-loss = `stop` a mercado; take-profit = `limit` |
| Compra fraccional (no alcanza para 1 acción) | `simple` | `limit` | `day` | Fraccional (hasta 9 decimales) | Límite = referencia × (1 + banda) |
| Venta sugerida o manual | `simple` | `limit` | `day` | La de la sugerencia | Límite = precio actual × (1 − banda) |
| Venta por protección virtual | `simple` | `market` | `day` | Toda la posición protegida | — |
| Venta de liquidación | `simple` | `market` | `day` | Toda la posición | — |

Detalles:

- **Límite marcable**: una orden límite con precio un poco peor que el
  actual se llena de inmediato como una de mercado, pero **nunca** a un
  precio peor que el aprobado (RN-24).
- **Por qué `gtc` en el bracket**: para que las patas de protección sigan
  vivas los días siguientes. La **entrada** no se deja viva: si no se llena
  en `ejecucion.minutos_max_llenado`, el sistema la cancela.
- **Vencimiento de 90 días**: Alpaca cancela las órdenes `gtc` a los 90
  días. `cierre-diario` **renueva** las patas de protección nativas que
  cumplan 80 días (cancela y vuelve a crear con los mismos precios).
- **Activos no fraccionables**: la lista blanca guarda los atributos
  `fraccionable` y `negociable` del activo en Alpaca (se sincronizan a
  diario). Si el monto no alcanza para una acción entera y el activo no es
  fraccionable, esa sugerencia no se crea para ese cupo.
- **Solo horario regular** en el MVP (RR-18), aunque Alpaca permite
  fracciones en horario extendido.

Ejemplo de orden bracket enviada por el ejecutor:

```json
POST /v2/orders
{
  "client_order_id": "3b7e5c0a-…-orden-id",
  "symbol": "QLD",
  "qty": "1",
  "side": "buy",
  "type": "limit",
  "limit_price": "111.10",
  "time_in_force": "gtc",
  "order_class": "bracket",
  "take_profit": { "limit_price": "123.20" },
  "stop_loss":   { "stop_price": "103.40" }
}
```

---

## 6. Protecciones: stop-loss y take-profit

| | Nativa | Virtual |
|---|---|---|
| Cuándo | La compra fue de acciones enteras | La compra fue fraccional |
| Implementación | Patas del bracket en Alpaca | Fila en `protecciones`, evaluada con cada precio en `publicar_cotizaciones` |
| Latencia de disparo | La del broker | ≤ ~15 s (intervalo de precios) |
| Si nuestro sistema cae | Sigue funcionando | No protege hasta que vuelva (RSG-05) |
| Precio de ejecución | Stop a mercado: puede ejecutarse por debajo del stop en caídas bruscas | Orden a mercado tras detectar el cruce: igual |

- Los precios de stop y objetivo se calculan sobre el **precio de
  referencia** al enviar, porque el bracket los exige en ese momento.
- **Ajuste** por el usuario o el analista (PM-14, PM-23): en nativa se
  reemplazan las patas en Alpaca; en virtual se crea una fila nueva.
- **Llenado parcial de la entrada de un bracket**: el comportamiento exacto
  de las patas en Alpaca ante una entrada parcialmente llenada y luego
  cancelada debe confirmarse en un spike (Q-12). Política provisional:
  cancelar las patas del bracket y cubrir lo llenado con una protección
  **virtual** con los mismos precios.

---

## 7. Sincronización de órdenes

`sincronizar-ordenes` corre cada 10 s mientras haya órdenes vivas:

```
1. GET /v2/orders?status=open&nested=true         → estado de las vivas (y sus patas)
2. Para cada orden nuestra viva que ya no aparece:
     GET /v2/orders/{broker_order_id}               → estado final
3. Para cada una con cambios:
     aplicar_llenado(orden, filled_qty, filled_avg_price, status)   (idempotente)
4. Patas de bracket llenadas → orden de venta de protección + protección DISPARADA
5. Entradas vencidas por tiempo máximo → DELETE /v2/orders/{id}
6. Órdenes 'desconocida' → GET /v2/orders:by_client_order_id?client_order_id={id}
```

Uso del límite de la API de trading (200 solicitudes por minuto por cuenta):
~6 por minuto de sincronización + las del ejecutor y la conciliación. Holgado.

---

## 8. Conciliación

Cada `conciliacion.minutos_entre` minutos en horario de mercado y una vez
tras el cierre:

| Se compara | Broker | Libro | Tolerancia |
|---|---|---|---|
| Efectivo | `cash` de `/v2/account` | Σ efectivo de todas las subcuentas de bolsillo y cupos | `conciliacion.tolerancia_usd` |
| Posiciones | `/v2/positions`: cantidad por símbolo | Σ cantidad de posiciones abiertas por símbolo | 0,000000001 |
| Órdenes vivas | `/v2/orders?status=open` | Órdenes en `aceptada` / `parcialmente_llenada` | Deben coincidir |

| Resultado | Condición | Acción |
|---|---|---|
| `ok` | Todo coincide (o el broker tiene excedente de efectivo) | Confirma aportes y retiros pendientes que ya cuadran; registra |
| `diferencia_menor` | Diferencia dentro de la tolerancia | Registra; alerta informativa al admin si se repite 3 veces |
| `descuadre_critico` | Efectivo del broker menor al del libro fuera de tolerancia, cantidad de algún símbolo distinta, o una orden viva en el broker que no conocemos | **Apaga `trading_activo`**, alerta crítica a admins, registra el detalle |

Causas típicas de descuadre y cómo se corrigen (siempre con movimiento de
`ajuste` justificado, nunca editando): llenado que la sincronización aún no
aplicó (se resuelve solo en el siguiente ciclo), *split* (CB-41), orden
creada a mano en el panel de Alpaca (está prohibido y se detecta).

> **Regla operativa**: nadie opera desde el panel web de Alpaca. Toda orden
> nace en la plataforma. Una orden desconocida es, por definición, un
> incidente.

---

## 9. Proveedores simulados

Para que el sistema se pueda probar de punta a punta **a cualquier hora y
sin costo** (las pruebas automáticas corren muchas veces al día y Alpaca
paper no llena órdenes con el mercado cerrado), cada integración tiene una
implementación simulada con la **misma interfaz**:

| Proveedor | Simulación |
|---|---|
| Mercado | Reproduce barras históricas guardadas como datos de prueba y genera precios intradía con una caminata aleatoria **determinista** (semilla fija, la misma idea del simulador de la v2). Reloj de mercado configurable: "siempre abierto", "cerrado", "a 10 min del cierre". |
| Broker | Acepta órdenes, las llena con el siguiente precio si cumple el límite, ejecuta las patas del bracket cuando el precio las cruza y permite forzar escenarios: llenado parcial, rechazo, sin respuesta, *halt*. |
| Noticias | Titulares de prueba por símbolo. |
| DeepSeek | Contextos pregrabados por símbolo (incluye uno con afirmaciones sin respaldo, para probar la validación). |
| JEV | Respuestas deterministas calculadas a partir de las etiquetas del estado, con escenarios forzables: confianza baja, contradicción, sin respuesta. |
| FCM | Guarda los push en una tabla de pruebas en lugar de enviarlos. |

- Se eligen por variable de entorno por proveedor (`PROVEEDOR_BROKER=simulado|alpaca`,
  `PROVEEDOR_MERCADO`, `PROVEEDOR_NOTICIAS`, `PROVEEDOR_CONTEXTO`,
  `PROVEEDOR_JEV`, `PROVEEDOR_PUSH`).
- **Local y CI**: todo simulado por defecto.
- **Proyecto de demostración** (opcional, segundo proyecto gratuito de
  Supabase): todo simulado, para mostrar el sistema fuera del horario de
  mercado.
- **Proyecto MVP en la nube**: todo real (Alpaca paper, DeepSeek, JEV, FCM).
  La función de arranque se niega a usar un proveedor simulado si
  `ENTORNO=mvp`, para que nunca se mezclen llenados simulados con la cuenta
  paper.

Detalle de cómo lo usan las pruebas en [15](15-calidad-pruebas-y-ci-cd.md).

---

## 10. Errores del broker y cómo se manejan

| Error | Ejemplo | Respuesta |
|---|---|---|
| Fondos insuficientes (403) | Poder de compra menor al esperado | Orden `rechazada`, sugerencia `fallida`, alerta al admin (señal de descuadre) |
| Parámetros inválidos (422) | Cantidad fraccional en activo no fraccionable | `error_envio`; se registra; se corrige la regla que lo dejó pasar |
| Límite de solicitudes (429) | Ráfaga de órdenes | Reintento con espera; la cola lo garantiza |
| Error del servidor (5xx) o sin respuesta | Caída de Alpaca | `desconocida` → se consulta por `client_order_id` antes de reintentar; salud → `degradado`/`caido` |
| Mercado cerrado | Aprobación en el último segundo | `fallida` con motivo "El mercado cerró" |
| Activo suspendido (*halt*) | Negociación detenida | Orden queda aceptada sin llenarse → vence por tiempo máximo; alerta |
| Activo no negociable | Deslistado | Se desactiva de la lista blanca en la sincronización diaria de activos; alerta al admin |

---

## 11. Noticias (Alpaca News)

| Tema | Detalle |
|---|---|
| Fuente | Benzinga, a través de Alpaca |
| Endpoint | `GET https://data.alpaca.markets/v1beta1/news?symbols=…&start=…&limit=…` |
| Costo | Gratis, con el límite del plan de datos (200 solicitudes por minuto) |
| Uso | `contexto-ia` descarga las noticias de las candidatas de las últimas `ia.noticias_horas` y las guarda en `noticias` (07 §4.2) |
| Riesgo | Hay reportes de cuentas gratuitas que reciben 403 en este endpoint. Se verifica al conectar la cuenta (16 §3). Si ocurre, el sistema sigue funcionando "sin contexto" y se activa la alternativa de Q-19. |

## 12. Universo del NASDAQ-100

Alpaca no informa qué acciones componen el índice. La lista de Arriesgadas
se siembra con los componentes del NASDAQ-100 vigentes al iniciar el
proyecto (con su sector) y la mantiene el administrador (el índice se
reconstituye cada diciembre). Para cada símbolo, `calendario-mercado`
sincroniza a diario si es negociable y fraccionable, y `cierre-diario` agrega
la barra diaria. Al conectar el proyecto se cargan **dos años de barras
diarias** del universo (necesarias para la media de 200 días y el máximo de
52 semanas).
