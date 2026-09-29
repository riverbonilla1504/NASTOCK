# 01 · Visión y alcance

## 1. El problema

> La empresa RiTech SAS tiene algunas inversiones en una bolsa de valores;
> estas inversiones dependen del doble del comportamiento del índice NASDAQ
> 100: si el NASDAQ 100 sube un 2 %, RiTech SAS gana 4 %, pero si baja el
> 2 %, RiTech pierde 4 %. Se les pide un software para tomar decisiones de
> inversión.

Traducido a necesidades concretas:

1. Un instrumento apalancado ×2 **amplifica igual las ganancias y las
   pérdidas**. El momento de entrar y de salir importa más que en una
   inversión normal.
2. RiTech no quiere que la tecnología decida sola con su dinero, pero tampoco
   que sus empleados tengan que vigilar el mercado todo el día.
3. Es una empresa cerrada: pocos participantes, conocidos, con
   responsabilidades distintas (quien administra el dinero no es quien toma
   riesgo).

## 2. La propuesta

Un **sistema de IA que vigila el mercado y propone**, y **personas que
deciden**. Es un **MVP para probar si el enfoque funciona**, operando en
paper trading (broker real, dinero ficticio).

```
  Datos del NASDAQ-100 ─┐
                        ├─► IA principal ─► JEV decide ─► Sugerencia ─► Persona ─► Broker (paper)
  Noticias ─► DeepSeek ─┘   (código)        (con          (monto,       aprueba     ejecuta
              (contexto)                     confianza)    protección,  o rechaza
                                                           vencimiento)
  Ningún modelo toca el broker.
```

Principios que no se negocian en ninguna historia de usuario:

| # | Principio | Consecuencia práctica |
|---|---|---|
| P1 | **La IA propone, una persona decide.** | Ninguna orden de compra o venta discrecional sale sin aprobación humana. Las únicas órdenes automáticas son las protecciones (stop-loss / take-profit) que la persona ya aprobó junto con la compra. |
| P2 | **La IA no tiene llaves.** | Ningún modelo (DeepSeek o JEV) tiene credenciales del broker ni herramientas de ejecución. El sistema escribe propuestas en la base de datos; un ejecutor determinista es el único que habla con el broker. |
| P3 | **Toda operación pasa por el mismo motor de políticas.** | Venga de la IA, de un empleado o de una protección, se valida con las mismas reglas de riesgo deterministas (`RR-xx`). |
| P4 | **El dinero se cuenta en un solo lugar.** | Un libro contable de doble partida en Postgres. Cada peso tiene origen y destino; nada se "edita", todo se registra. |
| P5 | **Separación de funciones.** | Un rol por persona. El administrador mueve dinero y configura; el analista aprueba riesgo; el usuario opera su cupo. Nadie hace las tres cosas. |
| P6 | **Todo queda auditado.** | Cada decisión, cambio de parámetro y movimiento de dinero queda en una bitácora inmutable. |
| P7 | **Ante la duda, no operar.** | Datos viejos, integraciones caídas, descuadres o respuestas inválidas de la IA hacen que el sistema se detenga, no que improvise. |

## 3. Actores

| Rol | Quién es | Qué hace en una frase |
|---|---|---|
| **Administrador** | Gerencia / tesorería de RiTech | Gobierna el dinero (aportes, retiros, cupos, rebalanceo), las cuentas y los parámetros. No aprueba operaciones de mercado. |
| **Analista** | Personal de inversiones | Aprueba o rechaza las sugerencias del bolsillo de Arriesgadas y supervisa todo el fondo. |
| **Usuario** | Empleados de RiTech | Operan su cupo dentro del bolsillo de Usuarios: aprueban o rechazan sugerencias de la IA y pueden crear órdenes propias (con opinión de la IA). |

Actores no humanos: **IA principal** (código que orquesta), **DeepSeek**
(contexto a partir de noticias), **JEV** de TypeSafe AI (decisión),
**Broker** (Alpaca paper), **Datos de mercado y noticias** (Alpaca),
**Google Workspace** (identidad), **Firebase** (push, hosting, distribución).

Detalle completo en [03 · Roles y permisos](03-roles-y-permisos.md).

## 4. Alcance del MVP

### Entra

- Ingreso **solo con Google Workspace** de RiTech, **solo por invitación**.
- Tres roles con permisos aplicados en la base de datos (RLS), no solo en
  pantalla.
- Fondo único con bolsillos 50/25/25, cupos por empleado, libro contable.
- Registro de aportes y retiros de capital por el administrador, conciliados
  contra el broker.
- Reparto automático 50/25/25 de aportes y de ganancias realizadas.
- Datos de mercado casi en tiempo real (cada ~15 s en horario de mercado) de
  los componentes del NASDAQ-100 y sus ETFs.
- Agente de IA (IA principal + DeepSeek + JEV) con ciclos programados, por
  evento y bajo demanda, y pantalla de **Oportunidades** con la explicación
  de cada evaluación.
- App **Android** (APK por Firebase App Distribution) y **web**.
- Proveedores simulados para probar todo de punta a punta a cualquier hora.
- Sugerencias de compra, venta y rebalanceo; alertas informativas.
- Aprobación / rechazo con motivo; doble aprobación en Arriesgadas sobre un
  umbral; vencimiento por tiempo y por precio.
- Órdenes manuales de empleados dentro de su cupo, con opinión previa de la IA.
- Ejecución en **Alpaca Paper Trading** con protecciones (nativas o
  virtuales).
- Sincronización de órdenes, conciliación periódica con el broker.
- Actualización en vivo dentro de la app (Supabase Realtime) y notificaciones
  push (FCM).
- Panel de administración: usuarios, invitaciones, cupos, capital,
  parámetros, lista blanca, interruptores, salud de integraciones, bitácora.
- Reportes: cartera, historial de operaciones, desempeño del fondo vs.
  NASDAQ-100 y vs. ×2 teórico, desempeño de la IA; exportación CSV.

### No entra (fase posterior o descartado)

| Tema | Estado | Por qué |
|---|---|---|
| Dinero real | Fuera del alcance | Sería otra etapa (producción) que no se planifica todavía. El MVP solo opera en paper trading. |
| iOS | Fuera del MVP | Publicar exige la cuenta paga de desarrollador de Apple (el MVP solo usa herramientas gratuitas). El código Flutter queda compatible. |
| Servicios pagos distintos de las IAs | Descartado en el MVP | Solo se pagan DeepSeek y JEV, por uso (D-45). |
| Correo + contraseña | Descartado | Decisión D-12: solo Google Workspace (salvo usuarios de prueba en local y CI, D-48). |
| Autoregistro | Descartado | Empresa cerrada: solo invitación. |
| Aprobar desde la notificación / pantalla bloqueada | Descartado | Se exige abrir la app y confirmar con biometría. |
| Horario extendido (pre/post mercado) | Fase posterior | Menos liquidez, más riesgo; el broker solo acepta órdenes límite ahí. |
| Opciones, cortos, margen, cripto | Descartado | Fuera del modelo de riesgo de RiTech. |
| Pago de ganancias a empleados | Pregunta abierta Q-09 | Hoy el 25 % que le toca a un cupo se queda en el cupo para seguir operando. |
| Canales Telegram / WhatsApp / correo | Fase posterior | Decisión D-14: app + push. |
| Reporte PDF | Fase posterior | CSV en el MVP. |
| Orden agregada (una sola orden para muchos cupos) | Fase posterior | Optimización de ejecución; el MVP envía una orden por cupo. |

## 5. Supuestos

| # | Supuesto | Si resulta falso |
|---|---|---|
| S1 | RiTech usa Google Workspace con dominio propio. | Pantalla de consentimiento Externa en modo prueba (04 §1); el resto no cambia. |
| S2 | La app sigue siendo **Flutter** (Android + web). | La arquitectura de backend no cambia; cambia solo el cliente. |
| S3 | Moneda única **USD** (la del broker). | Agregar TRM para mostrar COP como referencia; nunca para contabilidad. |
| S4 | Pocos usuarios concurrentes (decenas, no miles). | Revisar límites de Realtime y el plan de datos de mercado. |
| S5 | Los ~100 símbolos del universo se pueden consultar por REST cada 15 s dentro del límite gratuito (200 solicitudes por minuto; una llamada trae todos). | Bajar la frecuencia o limitar el universo. |
| S6 | El **plan gratuito** de Supabase alcanza para el MVP (límites y cómo se manejan en [05 §3.4](05-arquitectura.md#34-límites-del-plan-gratuito-de-supabase-y-cómo-se-manejan)). | Pasar a un plan pago requiere aprobación (D-45). |
| S7 | TypeSafe concede acceso a JEV (está en acceso anticipado). | Usar JEV por Cloudflare Workers AI; mientras tanto, JEV simulado (RSG-15). |

## 6. Cómo sabremos que funciona

| Indicador | Meta del MVP |
|---|---|
| Sugerencias con justificación comprensible (encuesta a usuarios) | ≥ 80 % "la entiendo" |
| Tiempo entre aprobación y orden en el broker | < 5 s (p95) |
| Retraso de precios en pantalla durante horario de mercado | < 30 s |
| Descuadres de conciliación sin explicar | 0 |
| Operaciones que violan una regla de riesgo | 0 |
| Sugerencias emitidas con datos desactualizados | 0 |
| Costo mensual total (solo DeepSeek + JEV) | < USD 20 (estimado ~USD 4) |
| Calibración de JEV: acierto real dentro de ±10 puntos de la confianza informada | Medido desde R3 ([07 §11](07-agente-ia.md#11-evaluación-y-mejora-continua)) |
| Escenarios E2E en verde en `main` | 100 % siempre |
| Desempeño de sugerencias aprobadas vs. rechazadas (medido, no meta) | Reportado mensualmente ([07 §11](07-agente-ia.md#11-evaluación-y-mejora-continua)) |

## 7. Relación con la versión anterior

La v3 se construye en un **repositorio nuevo**. La app v2 (repositorio
`ritech-sas-inversiones`) registra inversiones a mano y calcula su valor con la
fórmula ×2 sobre un simulador del índice; recomienda con una regla fija
(±2 % en 30 días). La v3:

- **Conserva** la fórmula ×2 como referencia teórica en el dashboard y en la
  simulación, la bitácora inmutable, la protección del último administrador,
  la deduplicación de alertas y la idea de "congelar" los parámetros vigentes
  en cada operación.
- **Reemplaza** el registro manual de inversiones por operaciones reales en
  el broker (paper), la regla fija por el agente de IA (IA principal + DeepSeek + JEV), el login con contraseña por
  Google, y el estado en memoria por Supabase.
- **Cambia los roles**: los tres roles de v2 (Administrador, Analista,
  Inversionista) se redefinen como Administrador, Analista y Usuario con
  responsabilidades distintas (ver [03](03-roles-y-permisos.md)).

Detalle de qué código se copia del repositorio v2 en
[05 §11](05-arquitectura.md#11-código-reutilizable-del-repositorio-v2).
