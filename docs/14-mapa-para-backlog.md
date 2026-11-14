# 14 · Mapa para el backlog

Puente entre esta especificación y el tablero de GitHub Projects. Propone
**épicas**, sus **capacidades** (cada una da una o más historias), las
**dependencias**, un **orden de entregas por valor** y una **definición de
terminado** común. Las historias están en `backlog/` y publicadas como issues
([16 §6](16-arranque-del-repositorio.md#6-crear-el-backlog-en-github)).

---

## 1. Principio: cada entrega aporta valor

- **Desde la primera entrega hay algo tangible**: la app publicada (web y
  APK) que alguien del equipo puede abrir y usar.
- Cada entrega es un **corte vertical**: base de datos + funciones + app +
  pruebas E2E + despliegue. Nada de "primero todo el backend, después las
  pantallas".
- Cada entrega termina **desplegada en el proyecto MVP** con CI en verde y
  una **demostración** escrita (qué se muestra y en qué orden).
- Cada entrega **agrega escenarios E2E** al catálogo de
  [15 §4](15-calidad-pruebas-y-ci-cd.md#4-escenarios-e2e-obligatorios); los
  de entregas anteriores siguen pasando (el sistema nunca queda roto).
- El orden de §4 es una **propuesta inicial**: se refina al crear el backlog,
  sin romper el principio.

---

## 2. Épicas

| ID | Épica | Capacidades principales | Fuente |
|---|---|---|---|
| **E-01** | Cimientos y calidad continua | Repositorio listo ([16](16-arranque-del-repositorio.md)); proyectos Supabase (local, MVP, demo opcional); esquema `private`, extensiones, Vault; esqueleto Flutter (Android + web, `com.ritech.inversiones`, Riverpod, go_router, códigos de error); **proveedores simulados**; **arnés E2E** (backend y app); flujos de CI/CD, wiki y mantenimiento funcionando; despliegue web (Firebase Hosting) y APK (App Distribution); respaldo cifrado; `CLAUDE.md` y registro de errores en uso | [05](05-arquitectura.md), [15](15-calidad-pruebas-y-ci-cd.md) |
| **E-02** | Identidad y acceso | Google Cloud (consentimiento, clientes); ingreso nativo y web; invitaciones y primer admin; hooks y trigger de alta; perfiles, `rol_actual()`, RLS base; guardas de navegación; sesión segura y bloqueo biométrico; suspender, reactivar, baja, reincorporar; cambio de rol | [03](03-roles-y-permisos.md), [04](04-autenticacion-oauth.md) |
| **E-03** | Fondo y libro contable | Libro e invariantes; aportes (con confirmación por conciliación de efectivo) y retiros; cupos; reparto de ganancias; ajustes; `resumen_fondo()`, `mi_cupo()`; fotos diarias y TWR; rebalanceo | [02](02-logica-de-negocio.md), [06 §4](06-modelo-de-datos.md#4-libro-contable) |
| **E-04** | Datos de mercado | Universo NASDAQ-100 (semilla, sectores, carga de 2 años de barras); ingesta cada 15 s; calendario y reloj; atributos de activos; `estado_mercado()`; pantalla de mercado (QQQ vs QLD vs ×2 teórico, universo); dato desactualizado | [09 §2](09-tiempo-real-y-notificaciones.md#2-cómo-llegan-los-precios), [10](10-integracion-bolsa.md) |
| **E-05** | Motor de políticas y configuración | `validar_operacion` (RR-01 a RR-22); parámetros con historial; lista blanca; interruptores y freno; salud de integraciones | [02 §9](02-logica-de-negocio.md#9-motor-de-políticas-reglas-de-riesgo) |
| **E-06** | IA: contexto y decisión | Noticias (Alpaca News); contexto con DeepSeek y su validación; métricas, etiquetas y calidad de datos; adaptador JEV (TypeSafe / Cloudflare / simulado); preguntas, puntaje compuesto y reglas; configuración versionada y modo sombra; pantalla **Oportunidades**; alertas de contradicción; opinión sobre órdenes manuales; análisis bajo demanda; presupuesto; evaluación y calibración | [07](07-agente-ia.md) |
| **E-07** | Sugerencias y decisiones | Señales y reparto en cupos; bandeja del Usuario; bandeja de riesgo; detalle con explicación; aprobar y rechazar; doble aprobación; vencimiento e invalidación; rebalanceo (admin); liquidación (analistas) | [08 §1](08-estados-y-flujos.md#1-sugerencia) |
| **E-08** | Ejecución y broker | Adaptador Alpaca paper y simulado; cola y ejecutor; órdenes manuales; sincronización y `aplicar_llenado`; protecciones nativas y virtuales; ajuste de protección; renovación a los 80 días; conciliación de posiciones y órdenes | [10](10-integracion-bolsa.md), [08 §2](08-estados-y-flujos.md#2-orden) |
| **E-09** | Tiempo real y notificaciones | Canales y políticas; eventos por entidad; gestor de Realtime en la app; bandeja de notificaciones; FCM y dispositivos; preferencias; deep links | [09](09-tiempo-real-y-notificaciones.md) |
| **E-10** | Cartera y reportes | Mi cupo; fondo (resumen y detalle); historial; exportación CSV; reporte diario al admin | [02 §13](02-logica-de-negocio.md#13-cifras-que-muestra-la-app) |
| **E-11** | Administración | Pantallas del admin sobre las capacidades de las demás épicas | [03 §3](03-roles-y-permisos.md#3-qué-ve-cada-rol-pantallas) |
| **E-12** | Seguridad, auditoría y cumplimiento | Bitácora con cadena de hash; pantalla de bitácora; suite RLS transversal; avisos (privacidad, "no es asesoría"); simulacro de restauración; lista de verificación de 11 §10 | [11](11-seguridad-y-auditoria.md) |
| **E-13** | Transición desde la v2 | Copiar del repositorio v2 el motor ×2 y el exportador, con sus pruebas; construir una identidad visual y un sistema de diseño nuevos; de la interfaz de la v2 solo se toma el contenido (D-67) | [05 §11](05-arquitectura.md#11-código-reutilizable-del-repositorio-v2) |
| ~~E-14~~ | *Retirada* (era "paso a dinero real", fuera del alcance) | — | — |

---

## 3. Dependencias

```mermaid
flowchart LR
  E01["E-01 Cimientos"] --> E02["E-02 Identidad"]
  E02 --> E03["E-03 Libro"]
  E01 --> E04["E-04 Mercado"]
  E03 --> E05["E-05 Políticas"]
  E04 --> E05
  E04 --> E06["E-06 IA"]
  E05 --> E06
  E05 --> E07["E-07 Sugerencias"]
  E06 --> E07
  E07 --> E08["E-08 Ejecución"]
  E03 --> E08
  E02 --> E09["E-09 Tiempo real"]
  E03 --> E10["E-10 Cartera"]
  E08 --> E10
  E02 --> E11["E-11 Admin"]
  E12["E-12 Seguridad"] -. transversal .- E03
  E13["E-13 Transición v2"] -. en paralelo .- E01
```

---

## 4. Entregas por valor (propuesta inicial)

| Entrega | Qué puede hacer alguien al final | Contenido | Demostración | E2E que se agregan |
|---|---|---|---|---|
| **R1 · Ver el mercado en vivo** | Entrar con Google (por invitación) a la app web o Android y ver el NASDAQ-100 moverse, con la comparación QQQ / QLD / ×2 teórico | E-01 completa, E-02 (ingreso, invitaciones, roles, navegación), E-04, E-09 (canal de mercado), E-13 | Tres personas entran con roles distintos y ven menús distintos; un correo no invitado es rechazado; los precios se mueven; en la demo fuera de horario, el mercado simulado | E2E-01, E2E-02, E2E-03 |
| **R2 · El fondo existe** | El admin carga el capital y reparte cupos; cada empleado ve su cupo; todos ven el fondo por bolsillos | E-03 (sin rebalanceo), E-05 (parámetros, interruptores), E-11 (capital, cupos, usuarios), E-12 (bitácora) | Aporte de USD 10.000 confirmado contra la cuenta paper y repartido 50/25/25; asignación de cupos; suspender a alguien lo saca al instante | E2E-04, E2E-05, E2E-14 |
| **R3 · La IA analiza** | Ver en **Oportunidades** qué acciones evalúa la IA, con puntaje, confianza, contexto y contradicciones, en cada ciclo | E-06 (sin opinión), E-05 (salud), alertas de E-09 | Un ciclo real: candidatas, respuestas de JEV, la elegida y por qué; una contradicción señalada; costo del ciclo | E2E-06, E2E-07 |
| **R4 · Decidir y operar en paper** | Recibir sugerencias, aprobarlas o rechazarlas, crear órdenes manuales con opinión, y ver la operación ejecutada y protegida en la cuenta paper | E-07, E-08, E-05 (motor completo), E-10 (mi cupo con posiciones) | Aprobar → orden en Alpaca paper → llenado → protección activa → venta por objetivo → reparto visible en los tres bolsillos; doble aprobación en Arriesgadas | E2E-08 a E2E-12 |
| **R5 · Protegido y avisado** | Recibir push, confiar en que el sistema se detiene solo ante problemas | E-09 (push, preferencias), conciliación con pausa automática, freno de emergencia, alertas operativas | Push con enlace directo; un descuadre forzado pausa el trading; un analista frena la IA | E2E-13, E2E-15 |
| **R6 · Medir y mejorar** | Saber si la IA acierta y ajustarla con datos | Evaluación y calibración, modo sombra, rebalanceo, liquidación y baja, reportes CSV, E-12 completa | Pantalla de calibración con datos de R3–R5; una configuración en sombra comparada con la activa; lista de verificación 11 §10 completa | E2E-16 |

> R3 va **antes** de las sugerencias a propósito: permite ver y medir a la
> IA con datos reales durante semanas antes de que una sola orden llegue al
> broker.

### 4.1 MVP corto: lo que se entrega primero (D-58)

**Por qué.** No alcanza el tiempo para construir las seis entregas. El
2026-11-05 el equipo decidió entregar primero un **MVP corto** con cinco
capacidades:

1. Iniciar sesión.
2. Manejar usuarios.
3. Ver las acciones en vivo.
4. Comprar y vender en paper trading.
5. La IA que analiza y sugiere.

Todo sigue siendo **paper trading con dinero ficticio** (D-44): el MVP corto
no toca dinero real.

**Cómo se armó.** Se partió de las historias que dan esas cinco capacidades
y se les sumaron todas sus dependencias, según la sección "Relaciones" de
cada historia. Por ejemplo, comprar necesita el cupo de la persona, el cupo
necesita el libro contable y el libro necesita los perfiles. Con las seis
simplificaciones de abajo quedaban **55 de los 125 ítems abiertos** (TT-01 ya
está hecha). Con HU-116, que entra por D-67, son **56**.

**Qué entra.**

| Capacidad | Ítems |
|---|---|
| Base técnica | TT-02 a TT-09 |
| Inicio de sesión y usuarios | HU-001 a HU-007, HU-010, HU-011, HU-083, HU-084, HU-085, HU-097, HU-098, HU-107 |
| Ver las acciones | HU-026 a HU-030, HU-032 |
| Fondo y cupos (sin ellos no hay con qué comprar) | HU-013, HU-014, HU-015, HU-017, HU-018, HU-019, HU-023, HU-033, HU-034, HU-099, HU-100, HU-101 |
| IA | HU-035, HU-037, HU-044, HU-045, HU-046, HU-047, HU-048 |
| Compra y venta con órdenes manuales | HU-072 a HU-077, HU-091 |
| Identidad visual y sistema de diseño (D-67) | HU-116 |

**Entregas del MVP corto.** Mandan sobre la tabla de §4 mientras dure el
MVP corto.

| Entrega | Qué puede hacer alguien al final | Qué cambia respecto de §4 | E2E |
|---|---|---|---|
| **R1 · Ver el mercado en vivo** | Entrar con Google por invitación y ver el NASDAQ-100 moverse | Sin la comparación QQQ / QLD / ×2 (HU-031), sin "Ver mi perfil" (HU-008) y sin el motor ×2 ni el exportador de la v2 (HU-115, HU-117). Entra HU-116 con otro alcance: identidad visual y sistema de diseño (D-67) | E2E-01, E2E-02, E2E-03 |
| **R2 · El fondo existe** | El admin carga el capital, reparte cupos y maneja usuarios; cada empleado ve su cupo | La pantalla de capital (HU-099) solo registra y confirma aportes. Salen retiros (HU-016), ajustes (HU-022), resumen del fondo (HU-020), foto diaria (HU-021), pantalla de bitácora (HU-108), suite de aislamiento (HU-109) y la confirmación biométrica (HU-009, D-61) | E2E-04, E2E-05 |
| **R3 · La IA analiza** | Ver en **Oportunidades** qué acciones evalúa la IA, con puntaje, confianza y explicación | Sin noticias ni contexto de DeepSeek (D-59). Salen las alertas de contradicción (HU-049), el presupuesto de IA (HU-050), el análisis bajo demanda (HU-051), la lista blanca editable (HU-036, HU-102), la pantalla de salud (HU-103) y la bandeja de notificaciones (HU-086, D-62) | E2E-06 (siempre "sin contexto"), E2E-07 |
| **R4 · Decidir y operar en paper** | Ver en Oportunidades qué recomienda la IA, crear órdenes manuales de compra y de venta en su cupo, y verlas ejecutadas y protegidas en Alpaca paper | Sin sugerencias de la IA (D-65): salen la bandeja, aprobar, rechazar, el vencimiento y el reparto de señales en cupos (HU-058, HU-059, HU-061, HU-062, HU-063, HU-066). Solo opera el bolsillo de Usuarios (D-64), sin opinión de la IA en la orden manual (D-60) y solo acciones enteras (D-63). Se vende con una orden manual o al tocar el stop-loss o el objetivo | E2E-08 (desde una orden manual), E2E-11 (sin opinión) |
| **Después del MVP corto** | — | R5 y R6 completas y los ítems que salen de R1 a R4: 69 en total | E2E-09, E2E-10, E2E-12 a E2E-16 |

**Las siete simplificaciones.** Cada una está anotada donde se define su
regla. La especificación completa se conserva para la fase siguiente.

| Decisión | Qué cambia en el MVP corto | Regla original |
|---|---|---|
| D-59 | Sin noticias ni DeepSeek: toda candidata se evalúa "sin contexto" | [07 §4.2](07-agente-ia.md#42-contexto-deepseek) |
| D-60 | La orden manual no lleva opinión previa de la IA | [07 §8](07-agente-ia.md#8-opinión-sobre-órdenes-manuales), [08 §7.5](08-estados-y-flujos.md#75-orden-manual-con-opinión) |
| D-61 | Confirmar con un diálogo que repite monto y símbolo, sin biometría ni bloqueo de la app | [04 §8](04-autenticacion-oauth.md#8-sesión-en-la-app) |
| D-62 | Sin bandeja de notificaciones ni push: cada pantalla muestra su propio estado | [09 §5](09-tiempo-real-y-notificaciones.md#5-notificaciones) |
| D-63 | Solo acciones enteras: sin compras fraccionales ni protección virtual | [02 §6.1](02-logica-de-negocio.md#61-tamaño-de-la-orden), [10 §5](10-integracion-bolsa.md#5-órdenes-que-usamos) |
| D-64 | El bolsillo de Arriesgadas no opera: queda en efectivo y el Analista solo supervisa | [02 §6](02-logica-de-negocio.md#6-compras), [07 §7.2](07-agente-ia.md#72-compra-en-arriesgadas) |
| D-65 | Sin sugerencias de la IA: la IA analiza y recomienda en Oportunidades, y la persona compra y vende con órdenes manuales | [07 §7](07-agente-ia.md#7-de-la-decisión-a-la-sugerencia), [08 §1](08-estados-y-flujos.md#1-sugerencia) |

**Historias que entran con otro alcance.** Su archivo en `backlog/` se
ajusta a estas decisiones:

- HU-005 toma de HU-009 dos piezas: la sesión en almacenamiento seguro y el
  componente común de confirmación, solo con diálogo.
- HU-047 solo registra las señales; HU-048 las muestra como recomendación en
  Oportunidades. No se convierten en sugerencias (D-65).
- HU-073 crea las tablas de órdenes y la cola de envío, que antes creaba
  HU-062, y envía solo órdenes manuales (D-65).
- HU-075 crea E2E-08, que en el MVP corto empieza con una orden manual, y
  HU-074 depende de HU-075 para extenderlo. HU-075 también depende de
  HU-032: con el precio desactualizado se deshabilita la compra (D-65).
- HU-046, HU-047 y HU-048 trabajan siempre "sin contexto".
- D-72 cierra la IA del MVP: HU-046 sin el ciclo por evento de QQQ (CA-4),
  HU-047 sin señales ni motor de políticas (CA-5 y CA-6), HU-045 sin
  Cloudflare (CA-4) y HU-048 con el nivel favorable, vigilar o desfavorable.
- HU-075, HU-099 y HU-100 confirman con el diálogo.
- HU-073, HU-074 y HU-077 no envían notificaciones. Cada pantalla muestra
  el estado en vivo por sus eventos.
- HU-072, HU-073, HU-074, HU-075 y HU-091 trabajan solo con acciones
  enteras y protección nativa.
- HU-099 solo registra y confirma aportes.
- HU-006 y HU-097 muestran solo las pantallas del MVP corto, según la
  tabla de [03 §3](03-roles-y-permisos.md#3-qué-ve-cada-rol-pantallas).
- HU-116 ya no copia la interfaz de la v2: construye una identidad visual y
  un sistema de diseño nuevos (`PRODUCT.md`, `DESIGN.md`, el tema y los
  componentes comunes); de la v2 solo toma el contenido (D-67). Las demás historias con
  pantallas siguen [15 §12](15-calidad-pruebas-y-ci-cd.md#12-diseño-visual-de-las-pantallas-d-67).

Cada una tiene en `backlog/` una sección **MVP corto** con lo que cambia.
Las dependencias que no aplican están marcadas en su tabla de relaciones
como "Depende de (después del MVP corto)".

---

## 5. Plantilla de historia de usuario

Existe como formulario de GitHub (`.github/ISSUE_TEMPLATE/historia-de-usuario.yml`).
Campos:

```
Épica: E-xx          Entrega: Rx          Módulos afectados: M-xx, M-yy   (17)

Como <Usuario | Analista | Administrador>
quiero <acción>
para <beneficio>.

Reglas: RN-xx, RR-xx, PM-xx
Criterios de aceptación:
  CA-1  Dado … cuando … entonces …
  CA-2  (caso borde) CB-xx: …
  CA-n  (permiso) Un <rol sin permiso> recibe NO_AUTORIZADO.
Escenario E2E: E2E-xx (nuevo / actualizado)
Técnico: RPC / Edge Function · tablas · RLS · evento en tiempo real · auditoría · códigos de error
Documentación a actualizar: secciones de docs/ que cambian
```

El campo **Módulos afectados** es obligatorio: es lo que usa el agente para
investigar solo lo necesario ([17](17-mapa-de-modulos.md)).

---

## 6. Definición de terminado

Una historia está terminada cuando:

- [ ] Cumple sus criterios de aceptación, incluidos los casos borde citados.
- [ ] `scripts/verificar.sh` pasa completo en local, **incluido el E2E**, y CI está en verde.
- [ ] Agregó o actualizó su escenario E2E si cambió un flujo.
- [ ] Si toca datos: RLS y pruebas pgTAP (dueño correcto, rol incorrecto, escritura directa bloqueada).
- [ ] Si escribe: por RPC, validando rol, dueño, estado y motor de políticas cuando aplique.
- [ ] Si cambia algo visible en vivo: evento en el canal correcto, sin montos en la carga.
- [ ] Si es una acción sensible: registro en `auditoria`.
- [ ] Errores con código del catálogo y mensaje en español.
- [ ] Sin secretos en la app ni en el repositorio.
- [ ] **`docs/` actualizada** si la historia cambió o precisó una regla, y registrada en el historial (13 §4).
- [ ] Si se resolvió un error no trivial, quedó en `docs/errores-conocidos.md`.
- [ ] Desplegada en el proyecto MVP con la prueba de humo en verde.

---

## 7. Trazabilidad y sincronía

- Cada historia cita sus reglas (`RN`, `RR`, `PM`), casos borde (`CB`),
  módulos (`M`) y escenario E2E.
- **Si cambia una historia**, se actualiza `docs/` en el mismo PR.
- **Si cambia `docs/`**, el PR lista las historias afectadas (búsqueda de los
  identificadores en los issues) y se actualizan o comentan.
- La wiki se regenera sola desde `docs/`; nunca se edita a mano.

Reglas completas para agentes en `CLAUDE.md`.
