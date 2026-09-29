# 02 · Lógica de negocio

Este documento define **cómo se mueve el dinero** y **qué reglas lo
gobiernan**. Todo número que muestre la app debe poder reconstruirse con lo
que está aquí. Las reglas llevan identificador (`RN-xx`, `RR-xx`) para
citarlas en historias de usuario y pruebas.

---

## 1. El fondo y sus tres bolsillos

RiTech tiene **un único fondo** en USD. El fondo se divide en tres bolsillos
con porcentajes objetivo configurables (por defecto 50 / 25 / 25):

```
                         FONDO  USD 10.000
        ┌───────────────────────┼────────────────────────┐
   RESERVA 50 %          ARRIESGADAS 25 %           USUARIOS 25 %
   USD 5.000             USD 2.500                  USD 2.500
   No se invierte.       La IA propone,             Se reparte en cupos
   Solo el admin         los analistas              individuales. Cada
   la mueve.             aprueban.                  empleado opera el suyo.
```

| Bolsillo | Para qué existe | Quién decide sobre él | Qué se compra |
|---|---|---|---|
| **Reserva** | Colchón de liquidez y protección del capital. | Solo el Administrador, y solo por **rebalanceo** o **retiro**. | Nada. Siempre efectivo. |
| **Arriesgadas** | Tomar riesgo mayor buscando más rendimiento. | **Analistas** (uno, o dos si supera el umbral). | Lista blanca de Arriesgadas (por defecto los ~100 componentes del NASDAQ-100 y TQQQ ×3). |
| **Usuarios** | Que los empleados participen en la inversión. | **Cada empleado sobre su cupo.** | Lista blanca de Usuarios (por defecto QLD ×2 y QQQ). |

- **RN-01** Existe un solo fondo. Todo el dinero de la plataforma pertenece a
  él y está en una sola cuenta del broker (modelo "ómnibus", ver
  [10 §3](10-integracion-bolsa.md#3-una-cuenta-muchas-subcuentas)).
- **RN-02** Los porcentajes objetivo de los bolsillos suman exactamente 100.
  Cambiarlos **no mueve dinero existente**: afecta los aportes y repartos
  futuros y la meta de los rebalanceos.
- **RN-03** La Reserva nunca tiene posiciones. Ninguna orden puede usar la
  Reserva (ver RR-02).

### Por qué el instrumento núcleo es QLD

El NASDAQ-100 no se compra directamente. Se opera a través de ETFs:

| ETF | Qué replica | Uso en la plataforma |
|---|---|---|
| **QQQ** | El NASDAQ-100 ×1 | Referencia del índice en gráficas e insumo de la IA. Permitido en Usuarios. |
| **QLD** | **El NASDAQ-100 ×2, diario** | Instrumento núcleo: es literalmente "RiTech gana el doble del NASDAQ". Permitido en Usuarios. |
| **TQQQ** | El NASDAQ-100 ×3, diario | Más riesgo. Solo en Arriesgadas. |

> **Advertencia que la app debe mostrar.** QLD duplica el movimiento **de
> cada día**, no el del periodo. En periodos volátiles, el resultado de varios
> días puede ser menor que el doble del resultado del índice (efecto de
> composición). Por eso el dashboard muestra tres líneas: QQQ, QLD real y
> "×2 teórico" (dos veces la variación acumulada de QQQ, la fórmula de la v2).

---

## 2. Subcuentas: cómo se lleva la cuenta

Un bolsillo es una idea de negocio. En la base de datos el dinero vive en
**subcuentas**, cada una con su saldo:

| Subcuenta | Cuántas | Bolsillo | Descripción |
|---|---|---|---|
| `reserva` | 1 | Reserva | Solo efectivo. |
| `arriesgadas` | 1 | Arriesgadas | Efectivo + posiciones de riesgo. |
| `usuarios_comun` | 1 | Usuarios | La parte del 25 % que **aún no está asignada** a ningún empleado. No opera: es una bolsa de espera. |
| `cupo` | 1 por Usuario | Usuarios | El dinero asignado a un empleado. Efectivo + sus posiciones. |
| `externa` | 1 | — | Técnica. Contrapartida de aportes y retiros (el "mundo exterior"). |
| `resultados` | 1 | — | Técnica. Contrapartida de ganancias y pérdidas realizadas ("lo que pagó o cobró el mercado"). |

Cada subcuenta tiene dos saldos contables:

- **efectivo**: dinero no invertido.
- **invertido**: costo de las posiciones abiertas (al costo, no a valor de
  mercado).

Y un saldo operativo:

- **retenido**: efectivo apartado por órdenes aprobadas aún no llenadas.

```
disponible  = efectivo − retenido                       (lo que se puede invertir)
patrimonio  = efectivo + Σ (cantidad × precio actual)    (lo que vale hoy)
```

- **RN-04** Todo cambio de saldo se registra como un **movimiento** de doble
  partida: un conjunto de asientos cuya suma es exactamente cero. Nunca se
  actualiza un saldo "a mano". Detalle en [06 §4](06-modelo-de-datos.md#4-libro-contable).
- **RN-05** El efectivo de una subcuenta nunca es negativo y el retenido nunca
  supera al efectivo. La base de datos lo impide con restricciones.
- **RN-06** Las ganancias no realizadas **no son contables**: se calculan al
  vuelo con el último precio. Solo cuando se vende hay movimiento.

---

## 3. De dónde sale el dinero: aportes

El dinero entra al fondo **únicamente** por un **aporte de capital** que
registra el Administrador.

### 3.1 Flujo

```
1. El dinero está en la cuenta paper del broker: el admin la configura con el
   monto del fondo (por defecto Alpaca trae USD 100.000; se recomienda
   reiniciarla con el monto del fondo, p. ej. USD 10.000).

2. El admin registra el aporte en la app: monto, fecha, referencia
   ("paper-inicial" o una nota), nota.                → estado REGISTRADO

3. La conciliación verifica que el efectivo del broker cubre el efectivo del
   libro más el aporte nuevo.                         → estado CONFIRMADO
   (si no alcanza, queda REGISTRADO y se avisa al admin)

4. Al confirmarse, el sistema reparte automáticamente 50/25/25:
     externa        −10.000,00
     reserva         +5.000,00
     arriesgadas     +2.500,00
     usuarios_comun  +2.500,00
```

- **RN-07** Un aporte solo reparte dinero cuando está **confirmado** contra
  el broker. Nunca se asigna dinero que el broker no tiene.
- **RN-08** El aporte se reparte con los porcentajes **vigentes al
  confirmarse**, que quedan guardados en el movimiento.
- **RN-09** Redondeo: Arriesgadas y Usuarios se calculan truncando a
  centavos; la Reserva recibe el resto. Así la suma siempre cuadra.
  *Ejemplo:* aporte de USD 1.000,03 → Arriesgadas 250,00; Usuarios 250,00;
  Reserva 500,03.
- **RN-10** Un aporte registrado y no confirmado se puede **anular** (queda en
  la bitácora). Un aporte confirmado no se anula: se corrige con un retiro.
- **RN-11** El **primer aporte** crea el fondo operativo. Antes de él, la IA
  no corre y nadie puede operar (el sistema muestra "Fondo sin capital").

---

## 4. Retiros de capital

- **RN-12** Solo el Administrador registra retiros.
- **RN-13** Por defecto un retiro sale de la **Reserva**. El admin puede
  elegir otra subcuenta de bolsillo (`arriesgadas`, `usuarios_comun`), nunca
  un cupo directamente (primero se reduce el cupo, ver §5).
- **RN-14** No se puede retirar más que el **disponible** de la subcuenta
  origen.
- **RN-15** *Retirada* (aplicaba a dinero real, fuera del alcance).

En el MVP (paper trading) un retiro es **solo contable**: se confirma al
registrarse y la cuenta paper conserva el efectivo, que la conciliación
reporta como "excedente no asignado" (nunca se usa).

---

## 5. Cupos de los empleados

El 25 % de Usuarios llega primero a `usuarios_comun`. El Administrador lo
reparte en cupos.

- **RN-16** Asignar cupo: mueve dinero de `usuarios_comun` al cupo del
  empleado. No puede superar el disponible de `usuarios_comun`.
- **RN-17** Reducir cupo: mueve dinero del cupo a `usuarios_comun`. Solo
  hasta el **disponible** del cupo (no se venden posiciones para reducir un
  cupo; para eso está la liquidación, §11).
- **RN-18** Al aceptar la invitación, el empleado recibe su subcuenta de cupo
  con saldo 0, o con el cupo inicial que el admin indicó en la invitación si
  `usuarios_comun` lo cubre (si no lo cubre, queda en 0 y se avisa al admin).
- **RN-19** Opcional: `cupos.maximo_usd` limita el cupo de una persona.
- **RN-20** Un empleado ve y opera **solo su cupo**.

*Ejemplo:* 5 empleados con USD 400 cada uno → cupos 2.000; `usuarios_comun`
queda con 500.

---

## 6. Compras

Una compra puede nacer de:

| Origen | Subcuenta | Quién la aprueba |
|---|---|---|
| Sugerencia de la IA | `arriesgadas` | 1 analista, o 2 si `monto ≥ aprobacion.umbral_doble_usd` |
| Sugerencia de la IA | `cupo` | El dueño del cupo |
| Orden manual del empleado | `cupo` | El mismo empleado (al crearla), con opinión previa de la IA |

### 6.1 Tamaño de la orden

La señal trae un **porcentaje del disponible** que calcula el código a partir
de la confianza de JEV ([07 §7.1](07-agente-ia.md#71-tamaño-stop-y-objetivo-código));
el sistema lo convierte en dinero y cantidad. Ningún modelo fija montos.

```
monto_objetivo   = disponible × porcentaje_propuesto          (truncado a centavos)
cantidad_entera  = piso(monto_objetivo / precio_referencia)

si cantidad_entera ≥ 1:
    se compra cantidad_entera ACCIONES ENTERAS   → protección NATIVA en el broker
    el sobrante queda como efectivo
si no, y el activo es fraccionable:
    se compra una FRACCIÓN de acción            → protección VIRTUAL (la vigila el guardián)
si no:
    no se puede comprar: la sugerencia no se crea para esa subcuenta
```

- **RN-21** Se prefieren acciones enteras porque solo así el broker acepta la
  protección nativa (orden *bracket*). Detalle técnico en
  [10 §6](10-integracion-bolsa.md#6-protecciones-stop-loss-y-take-profit).
- **RN-22** La sugerencia muestra **exactamente** lo que se va a comprar
  ("1 acción de QLD ≈ USD 110,00"), no el porcentaje.
- **RN-23** Al aprobar se **retiene** `cantidad × precio_referencia × (1 +
  banda)` para cubrir el peor precio aceptable. Al llenarse la orden se
  libera la retención y se descuenta el costo real.
- **RN-24** Las compras se envían como **orden límite marcable**: precio
  límite = `precio_referencia × (1 + banda)`. Si el precio se fue más allá de
  la banda, la orden no se ejecuta a un precio peor que el aprobado.

### 6.2 Costo promedio

Cada posición lleva **costo promedio ponderado**.

```
Tengo 6 acciones a 50,00 (costo 300,00). Compro 4 a 60,00 (costo 240,00).
Nueva posición: 10 acciones, costo 540,00, costo promedio 54,00.
```

- **RN-25** Una venta no cambia el costo promedio de lo que queda.

---

## 7. Ventas, ganancias y pérdidas

Una venta puede nacer de: sugerencia de venta de la IA (aprobada), orden
manual del empleado, **protección disparada** (stop-loss o take-profit,
aprobada de antemano con la compra) o **liquidación** (§11).

### 7.1 Cálculo del resultado

```
resultado_realizado = (precio_venta_promedio − costo_promedio) × cantidad_vendida − comisiones
```

### 7.2 Reparto 50/25/25 de la ganancia

- **RN-26** Toda **ganancia realizada** (> 0) se reparte **en el momento de
  la venta** con los porcentajes vigentes:

| Parte | Destino si la venta fue en un **cupo** | Destino si la venta fue en **Arriesgadas** |
|---|---|---|
| 50 % | Reserva | Reserva |
| 25 % | Arriesgadas | Arriesgadas (se queda) |
| 25 % | **El mismo cupo** que la generó | `usuarios_comun` (el admin decide a quién asignarla) |

- **RN-27** El **costo** de lo vendido siempre vuelve completo a la subcuenta
  que vendió. Solo la **ganancia** se reparte.
- **RN-28** Una **pérdida** realizada la absorbe completa la subcuenta que
  vendió. No se reparte ni se compensa con otras subcuentas.
- **RN-29** El reparto es **por operación cerrada**, no neto por periodo
  (decisión D-19, pendiente de validar: Q-01).
- **RN-30** Redondeo del reparto: igual que RN-09 (las partes de 25 % se
  truncan, la Reserva recibe el resto).

### 7.3 Ejemplo completo en un cupo

Ana tiene un cupo de USD 400,00.

```
1. La IA sugiere: comprar QLD con 30 % del disponible. Stop −6 %, objetivo +12 %.
   Monto objetivo 120,00. Precio de referencia 110,00 → 1 acción entera.
   Ana aprueba. Se retienen 110,00 × 1,01 = 111,10.

2. La orden se llena a 110,20.
     cupo Ana  efectivo   −110,20   → 289,80
     cupo Ana  invertido  +110,20
   Posición: 1 QLD a 110,20. Protección nativa: stop 103,40 · objetivo 123,20
   (calculados sobre el precio de referencia al enviar).

3a. Días después se toca el objetivo: vende 1 a 123,20.
     cupo Ana  efectivo   +123,20
     cupo Ana  invertido  −110,20
     resultados           −13,00        (ganancia realizada 13,00)
   Reparto:
     cupo Ana  efectivo   −9,75         (se queda con 3,25)
     reserva   efectivo   +6,50
     arriesgadas efectivo +3,25
   Cupo de Ana: 289,80 + 123,20 − 9,75 = 403,25

3b. (Alternativa) Se toca el stop: vende 1 a 103,40.
     cupo Ana  efectivo   +103,40
     cupo Ana  invertido  −110,20
     resultados           +6,80         (pérdida realizada 6,80)
   Sin reparto. Cupo de Ana: 289,80 + 103,40 = 393,20
```

### 7.4 Eventos corporativos

- **RN-31** *Retirada* (dividendos: paper trading no los simula, así que no
  se contabilizan en el MVP).
- **RN-32** Un *split* o agrupación cambia cantidad y costo promedio de las
  posiciones sin cambiar su costo total. Lo detecta la conciliación y lo
  aplica el admin con un movimiento de ajuste (ver
  [12 · CB-41](12-casos-borde.md)).

---

## 8. Rebalanceo

Con el tiempo los bolsillos se alejan del 50/25/25: la Reserva crece con los
repartos, Arriesgadas sube o baja con el mercado.

- **RN-33** Después de cada cierre de mercado el sistema calcula el peso de
  cada bolsillo sobre el **patrimonio** del fondo. Si alguno se desvía más de
  `rebalanceo.desviacion_pp` puntos (por defecto 5), genera una **sugerencia
  de rebalanceo** para el Administrador.
- **RN-34** El rebalanceo **solo mueve efectivo disponible** entre `reserva`,
  `arriesgadas` y `usuarios_comun`. Nunca vende posiciones y nunca toca cupos
  individuales.
- **RN-35** Si el efectivo no alcanza para llegar al objetivo, se propone el
  movimiento parcial posible y se explica.
- **RN-36** El rebalanceo es un movimiento **interno** del libro: no genera
  órdenes en el broker (todo está en la misma cuenta).
- **RN-37** Es la **única** forma, además del retiro, de que salga dinero de
  la Reserva, y siempre la aprueba el Administrador.

*Ejemplo:* patrimonio del fondo 10.000 → Reserva 5.400 (54 %), Arriesgadas
1.900 (19 %), Usuarios 2.700 (27 %). Arriesgadas está 6 pp por debajo →
sugerencia: "Mover 600,00 de Reserva a Arriesgadas". Usuarios (+2 pp) está
dentro de la tolerancia y no se toca.

---

## 9. Motor de políticas (reglas de riesgo)

Reglas **deterministas** que se evalúan en la base de datos
(`validar_operacion`, ver [06 §8](06-modelo-de-datos.md#8-funciones-rpc)) en
**cuatro momentos**: al crear la propuesta (IA o manual), al aprobar, justo
antes de enviar al broker y, para las ventas por protección, al dispararse.
Si una regla falla, la operación no sigue y queda registrada la regla
violada.

| ID | Regla | Valor por defecto | Aplica a |
|---|---|---|---|
| **RR-01** | El símbolo está en la lista blanca activa del bolsillo. | — | Compras |
| **RR-02** | Ninguna orden usa la Reserva ni `usuarios_comun`. | — | Todas |
| **RR-03** | El monto no supera el **disponible** de la subcuenta. | — | Compras |
| **RR-04** | Monto por operación ≤ % del patrimonio de la subcuenta. | Arriesgadas 20 % · Cupo 50 % | Compras |
| **RR-05** | Concentración: valor en un símbolo tras la compra ≤ % del patrimonio. | Arriesgadas 40 % · Cupo 100 % | Compras |
| **RR-06** | Monto mínimo de orden. | USD 10 | Compras y ventas |
| **RR-07** | Mercado en horario regular; compras solo entre apertura + 5 min y cierre − 15 min. | — | Compras; ventas en todo el horario regular |
| **RR-08** | Stop-loss obligatorio en toda compra, dentro de un rango. | Arriesgadas 3–20 % · Cupo 2–15 % | Compras |
| **RR-09** | Confianza de JEV en la decisión ≥ mínima (y el resto de reglas de decisión de [07 §6.3](07-agente-ia.md#63-reglas-de-decisión-código-con-compuerta-de-confianza)). | 0,65 | Sugerencias de la IA |
| **RR-10** | Sin duplicados: no puede haber otra sugerencia u orden viva para la misma subcuenta, símbolo y lado. | — | Compras y ventas |
| **RR-11** | Cotización fresca: el último precio tiene menos de N segundos. | 60 s | Todas |
| **RR-12** | Banda de precio: el precio actual no se alejó más de X % del de referencia. | 1,0 % | Al aprobar y al enviar |
| **RR-13** | Doble aprobación si el monto ≥ umbral. Si hay menos de 2 analistas activos, la IA recorta el monto al umbral. | USD 400 | Arriesgadas |
| **RR-14** | Interruptores: `ia_activa` para crear sugerencias; `trading_activo` para enviar órdenes nuevas (las protecciones y liquidaciones siguen). | — | Todas |
| **RR-15** | Solo se vende lo que se tiene (sin cortos). | — | Ventas |
| **RR-16** | Máximo de sugerencias por cupo por día. | 3 | Sugerencias de la IA a cupos |
| **RR-17** | El destinatario está **activo** (no suspendido ni de baja). | — | Todas menos protecciones y liquidaciones |
| **RR-18** | Sin margen, sin cortos, sin opciones, sin horario extendido. | — | Todas |
| **RR-19** | Pérdida diaria máxima: si Arriesgadas pierde más de X % de su patrimonio en el día, no se aceptan compras nuevas hasta el día siguiente. | 5 % | Compras en Arriesgadas |
| **RR-20** | Enfriamiento: tras una venta por stop-loss en un símbolo, no se recompra ese símbolo en esa subcuenta durante N horas. | 24 h | Compras |
| **RR-21** | Salud: broker y datos de mercado en estado `ok` o `degradado`. Con `caido` no se crean ni ejecutan operaciones. | — | Todas menos protecciones nativas |
| **RR-22** | Conciliación sin descuadre crítico abierto. | — | Compras |

- **RN-38** El motor de políticas es **uno solo** y está en la base de datos.
  La IA, la app y el ejecutor lo llaman; ninguno reimplementa reglas.
- **RN-39** Cada sugerencia y orden guarda una **copia de los parámetros**
  con los que se validó (igual que en v2 se congelaba el factor). Cambiar un
  parámetro no reescribe decisiones pasadas.

---

## 10. Parámetros configurables

Los cambia **solo el Administrador**, sin desplegar código. Cada cambio se
valida contra su rango, se audita con valor anterior y nuevo, y se aplica a
partir de ese momento.

| Clave | Defecto | Rango | Qué controla |
|---|---|---|---|
| `reparto.pct_reserva` / `pct_arriesgadas` / `pct_usuarios` | 50 / 25 / 25 | 0–100, suman 100 | RN-02, RN-08, RN-26 |
| `aprobacion.umbral_doble_usd` | 400 | ≥ 0 | RR-13 |
| `sugerencias.minutos_vencimiento` | 30 | 5–240 | Vencimiento por tiempo |
| `sugerencias.banda_precio_pct` | 1,0 | 0,2–5 | RR-12, RN-23, RN-24 |
| `sugerencias.max_por_cupo_dia` | 3 | 1–20 | RR-16 |
| `sugerencias.aviso_previo_min` | 5 | 1–30 | Push "por vencer" |
| `riesgo.arriesgadas.max_pct_operacion` | 20 | 1–100 | RR-04 |
| `riesgo.arriesgadas.max_pct_simbolo` | 40 | 1–100 | RR-05 |
| `riesgo.arriesgadas.stop_min_pct` / `stop_max_pct` | 3 / 20 | 0,5–50 | RR-08 |
| `riesgo.arriesgadas.perdida_diaria_max_pct` | 5 | 1–50 | RR-19 |
| `riesgo.cupo.max_pct_operacion` | 50 | 1–100 | RR-04 |
| `riesgo.cupo.max_pct_simbolo` | 100 | 1–100 | RR-05 |
| `riesgo.cupo.stop_min_pct` / `stop_max_pct` | 2 / 15 | 0,5–50 | RR-08 |
| `riesgo.cupo.stop_defecto_pct` / `objetivo_defecto_pct` | 8 / 15 | 0,5–100 | Valores precargados en órdenes manuales |
| `riesgo.orden_minima_usd` | 10 | 1–1.000 | RR-06 |
| `riesgo.enfriamiento_horas` | 24 | 0–168 | RR-20 |
| `mercado.minutos_tras_apertura` / `minutos_antes_cierre` | 5 / 15 | 0–60 | RR-07 |
| `mercado.max_antiguedad_cotizacion_seg` | 60 | 15–600 | RR-11 |
| `ejecucion.minutos_max_llenado` | 5 | 1–60 | Cancelación de entradas no llenadas |
| `ia.minutos_entre_ciclos` | 15 | 5–120 | Frecuencia del agente |
| `ia.umbral_evento_qqq_pct` | 1,5 | 0,5–10 | Ciclo extra por movimiento brusco |
| `ia.modelo_contexto` / `ia.modelo_jev` | `deepseek-flash` / `jev-1.13.0` | lista permitida | [07 §5](07-agente-ia.md#5-modelos-y-cuándo-se-usa-cada-uno) |
| `ia.candidatos_max` | 10 | 1–30 | Candidatas de Arriesgadas evaluadas por JEV en cada ciclo |
| `ia.contexto_max_minutos` | 90 | 15–480 | Vigencia del contexto de DeepSeek |
| `ia.noticias_horas` | 72 | 6–168 | Ventana de noticias para el contexto |
| `ia.timeout_contexto_seg` / `ia.timeout_jev_seg` | 60 / 10 | 5–120 | Espera máxima a cada proveedor |
| `ia.pct_base.usuarios` / `ia.pct_base.arriesgadas` | 30 / 15 | 1–100 | Porcentaje del disponible antes del factor de confianza ([07 §7.1](07-agente-ia.md#71-tamaño-stop-y-objetivo-código)) |
| `ia.stop_atr_multiplo` / `ia.relacion_objetivo_stop` | 2,0 / 2,0 | 0,5–5 | Cálculo de stop y objetivo |
| `ia.horizonte.usuarios` / `ia.horizonte.arriesgadas` | semanas / días | intradía, días, semanas | Horizonte de decisión y de evaluación |
| `jev.confianza_minima` / `jev.confianza_venta` | 0,65 / 0,65 | 0,50–0,95 | RR-09 y ventas |
| `jev.puntaje_minimo` | 0,60 | 0–1 | Puntaje compuesto mínimo |
| `jev.umbral_contradiccion` | 0,5 | 0,1–0,9 | Contradicción datos/contexto |
| `ia.presupuesto_mensual_usd` | 20 | ≥ 0 | Suma DeepSeek + JEV. Al superarse, el agente se pausa y avisa |
| `rebalanceo.desviacion_pp` | 5 | 1–50 | RN-33 |
| `conciliacion.tolerancia_usd` | 1,00 | 0–100 | Descuadre aceptable |
| `conciliacion.minutos_entre` | 5 | 1–60 | Frecuencia de conciliación |
| `cupos.maximo_usd` | sin límite | ≥ 0 | RN-19 |
| `auth.dominios_permitidos` | `["<dominio de RiTech>"]` | lista de dominios | Hook de alta ([04 §5](04-autenticacion-oauth.md#5-hook-antes-de-crear-usuario)) |
| `auth.proveedores_permitidos` | `["google"]` (local/CI: `["google","email"]`) | lista | Hook de alta; en la nube solo Google |
| `app.minutos_bloqueo` | 5 | 1–60 | Bloqueo biométrico al volver de segundo plano ([04 §8](04-autenticacion-oauth.md#8-sesión-en-la-app)) |

Además, fuera de la tabla de parámetros: la **lista blanca** por bolsillo y
los **interruptores** `ia_activa` y `trading_activo`.

---

## 11. El empleado y su dinero a lo largo del tiempo

| Situación | Qué pasa con el cupo |
|---|---|
| **Invitado** | Aún no hay cupo. El monto de la invitación es solo una intención. |
| **Activo** | Opera normalmente. |
| **Suspendido** | El cupo queda **congelado**: no recibe sugerencias, sus sugerencias pendientes se invalidan, no puede crear órdenes. **Sus protecciones siguen activas** (su dinero sigue protegido). Si una protección vende, el dinero vuelve a su cupo normalmente. |
| **Reactivado** | Todo sigue donde quedó. |
| **Liquidación** (antes de la baja) | El admin solicita liquidar el cupo. Se genera una **sugerencia de venta total por posición** dirigida a los **Analistas** (el admin no aprueba operaciones). Al venderse todo, el efectivo vuelve a `usuarios_comun` (con el reparto normal de ganancias). |
| **Baja** | Solo es posible con el cupo **sin posiciones ni órdenes vivas**. El efectivo restante vuelve a `usuarios_comun`, la subcuenta se cierra, la cuenta queda bloqueada. El historial se conserva. |
| **Reincorporación** | Si la persona vuelve a RiTech, el admin la reincorpora: la cuenta vuelve a `activo` con un **cupo nuevo en 0**. El cupo anterior sigue cerrado con su historial. |

- **RN-40** Nunca se borra un empleado que operó: su historial es parte de la
  contabilidad del fondo.

---

## 12. Horarios

- **RN-41** El mercado opera de **9:30 a 16:00, hora de Nueva York**, en días
  hábiles según el **calendario del broker** (feriados y medias jornadas con
  cierre a las 13:00 incluidos). El calendario se sincroniza a diario; nunca
  se programa a mano.
- **RN-42** En hora de Bogotá (sin horario de verano) eso es **8:30–15:00**
  mientras EE. UU. está en horario de verano (marzo–noviembre) y
  **9:30–16:00** el resto del año. La app siempre muestra la hora local de
  Bogotá y una cuenta regresiva a la apertura o al cierre.
- **RN-43** Fuera de horario: no hay ciclos de IA, no se crean compras, las
  sugerencias vivas vencen al cierre y las órdenes manuales se rechazan con
  el mensaje "El mercado está cerrado. Abre a las HH:MM".

---

## 13. Cifras que muestra la app

| Cifra | Fórmula | Fuente |
|---|---|---|
| Patrimonio de subcuenta/bolsillo/fondo | `efectivo + Σ cantidad × último precio` | Calculada al vuelo; oficial en foto diaria |
| Ganancia no realizada de una posición | `(último precio − costo promedio) × cantidad` | Al vuelo |
| Resultado realizado | Suma de `resultado_realizado` de las ventas | Libro |
| Peso del bolsillo | `patrimonio del bolsillo / patrimonio del fondo` | Al vuelo |
| **Rendimiento** (fondo, bolsillo, cupo) | Rendimiento ponderado en el tiempo (TWR) con fotos diarias: `r_día = (P_fin − P_ini − flujos) / P_ini`; `TWR = Π(1 + r_día) − 1`. Flujos = aportes, retiros, asignaciones, repartos y rebalanceos. | Fotos diarias (`patrimonio_diario`) |
| ×2 teórico | `2 × variación acumulada de QQQ` desde el inicio del periodo (fórmula v2) | Barras diarias |

- **RN-44** El rendimiento **no** es "ganancia / capital inicial": con
  aportes, retiros y repartos de por medio esa cuenta engaña. Se usa TWR.
- **RN-45** Los valores en vivo son indicativos; los reportes oficiales usan
  la **foto diaria** tomada tras el cierre.

---

## 14. Resumen de flujos de dinero

| Movimiento | De | A | Lo inicia | Lo aprueba |
|---|---|---|---|---|
| Aporte | externa | reserva / arriesgadas / usuarios_comun | Admin | Conciliación (automática) |
| Retiro | reserva (u otra de bolsillo) | externa | Admin | Admin |
| Asignar cupo | usuarios_comun | cupo | Admin | Admin |
| Reducir cupo | cupo | usuarios_comun | Admin | Admin |
| Compra | efectivo de la subcuenta | invertido de la subcuenta | IA o empleado | Analista(s) o dueño del cupo |
| Venta | invertido | efectivo (+ resultados) | IA, empleado, protección o liquidación | Dueño / analista(s) / aprobada con la compra |
| Reparto de ganancia | subcuenta que vendió | reserva / arriesgadas / cupo o común | Automático al vender | — |
| Rebalanceo | reserva / arriesgadas / usuarios_comun | reserva / arriesgadas / usuarios_comun | Sistema (tras el cierre) | Admin |
| Ajuste (evento corporativo, corrección de conciliación) | cualquiera | cualquiera | Admin | Admin, con justificación obligatoria |
