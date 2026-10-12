# Especificación — Plataforma de inversión asistida por IA · RiTech SAS

Versión 3.1 · Septiembre 2026 · Historial en [13 §4](13-decisiones-pendientes-riesgos.md#4-historial-de-la-especificación)

Esta carpeta es la **fuente de verdad de toda la aplicación**. Describe qué
hace el sistema, cómo se reparte el dinero, quién puede hacer qué, cómo está
construido, cómo decide la IA, qué pasa en cada caso borde y cómo se prueba.
Si algo no está aquí, no está decidido: primero se documenta y luego se
implementa (reglas en [`CLAUDE.md`](../CLAUDE.md)).

---

## El producto en un párrafo

RiTech SAS tiene un fondo de inversión cerrado (capital de referencia:
**USD 10.000**, en **paper trading**) cuyo desempeño depende del **doble del
comportamiento del NASDAQ-100**. El fondo se divide en tres bolsillos:
**Reserva 50 %**, **Arriesgadas 25 %** y **Usuarios 25 %**. Una **IA
principal** recopila y verifica los datos del NASDAQ-100; **DeepSeek** explica
el contexto a partir de noticias reales; **JEV** (TypeSafe AI) decide con
probabilidades calibradas cuál es la mejor opción. El sistema emite
**sugerencias** (comprar, vender, rebalancear) y **alertas**, y **una persona
siempre aprueba o rechaza**. Los **Analistas** deciden sobre Arriesgadas, los
**Usuarios** (empleados) sobre su **cupo**, y el **Administrador** gobierna el
dinero, las cuentas y los parámetros. Es un **MVP** hecho con herramientas
gratuitas (solo se pagan las IAs) para probar si el enfoque funciona.

---

## Cómo leer esta carpeta

| # | Documento | Responde |
|---|---|---|
| 01 | [Visión y alcance](01-vision-y-alcance.md) | Qué problema resolvemos, qué entra en el MVP y qué no |
| 02 | [Lógica de negocio](02-logica-de-negocio.md) | Bolsillos, cupos, aportes, ganancias, pérdidas, rebalanceo, reglas de riesgo, parámetros |
| 03 | [Roles y permisos](03-roles-y-permisos.md) | Qué puede hacer y qué ve cada rol, y cómo se hace cumplir |
| 04 | [Autenticación y OAuth](04-autenticacion-oauth.md) | Google Workspace, invitaciones, sesiones, suspensión |
| 05 | [Arquitectura](05-arquitectura.md) | Componentes, conexiones, Supabase gratuito, entornos, estructura del repositorio |
| 06 | [Modelo de datos](06-modelo-de-datos.md) | Tablas, libro contable, RLS, funciones RPC, códigos de error |
| 07 | [Agente de IA](07-agente-ia.md) | IA principal + DeepSeek + JEV: qué ve cada uno, cómo se decide y se explica |
| 08 | [Estados y flujos](08-estados-y-flujos.md) | Máquinas de estado y flujos de punta a punta; estado en la app |
| 09 | [Tiempo real y notificaciones](09-tiempo-real-y-notificaciones.md) | Qué se actualiza en vivo, canales, push |
| 10 | [Integración con la bolsa](10-integracion-bolsa.md) | Alpaca paper, órdenes, protecciones, conciliación, noticias, proveedores simulados |
| 11 | [Seguridad y auditoría](11-seguridad-y-auditoria.md) | Amenazas, secretos, bitácora inmutable, privacidad, respaldos |
| 12 | [Casos borde](12-casos-borde.md) | Situaciones anómalas y la respuesta esperada |
| 13 | [Decisiones, pendientes y riesgos](13-decisiones-pendientes-riesgos.md) | Decisiones, preguntas abiertas, riesgos, historial de la especificación |
| 14 | [Mapa para el backlog](14-mapa-para-backlog.md) | Épicas, entregas por valor, plantilla de historia, definición de terminado |
| 15 | [Calidad, pruebas y CI/CD](15-calidad-pruebas-y-ci-cd.md) | Cómo el sistema queda siempre funcionando de punta a punta |
| 16 | [Arranque del repositorio](16-arranque-del-repositorio.md) | Conexiones, secretos, GitHub y **el backlog pendiente de crear** |
| 17 | [Mapa de módulos](17-mapa-de-modulos.md) | Qué leer para cada historia sin analizar todo el proyecto |
| — | [Errores conocidos](errores-conocidos.md) | Problemas ya resueltos, para no repetirlos |

**Para empezar**: 01 → 02 → 07 → 03 → 08 → 05.
**Para implementar una historia**: `CLAUDE.md` → 17 → solo las secciones de
los módulos afectados.

---

## Glosario

| Término | Significado |
|---|---|
| **Fondo** | Todo el dinero de RiTech administrado por la plataforma. Hay uno solo. |
| **Bolsillo** | División lógica del fondo: **Reserva** (50 %), **Arriesgadas** (25 %), **Usuarios** (25 %). |
| **Subcuenta** | Unidad contable con saldo propio: `reserva`, `arriesgadas`, `usuarios_comun`, `cupo` (una por empleado), `externa` y `resultados` (técnicas). |
| **Cupo** | Subcuenta de un empleado (rol Usuario) dentro del bolsillo de Usuarios. |
| **Bolsa común de usuarios** | `usuarios_comun`: la parte del 25 % aún no asignada a nadie. |
| **Efectivo / Retenido / Disponible** | Dinero no invertido / apartado por órdenes aprobadas sin llenar / `efectivo − retenido`. |
| **Posición** | Tenencia de un símbolo en una subcuenta: cantidad y costo promedio. |
| **Patrimonio** | `efectivo + valor de mercado de las posiciones`. |
| **Ganancia realizada / no realizada** | Al vender / de posiciones abiertas. Solo la realizada se reparte. |
| **Reparto 50/25/25** | Distribución de cada aporte y de cada ganancia realizada entre los bolsillos. |
| **Universo** | Los ~100 componentes del NASDAQ-100 más QQQ, QLD y TQQQ. |
| **Candidata** | Símbolo que la IA principal evalúa en un ciclo: las mejores de Arriesgadas por puntaje cuantitativo, los ETFs de Usuarios y los símbolos con posiciones. |
| **IA principal** | El orquestador: código que recopila y verifica datos, calcula métricas, consulta a JEV, compone el puntaje, elige y explica. |
| **Contexto** | Explicación de lo que pasa alrededor de una acción, escrita por DeepSeek a partir de noticias reales, con fuentes y vigencia. |
| **JEV** | Modelo de TypeSafe AI ("Sistema 1") que responde preguntas tipadas (Choice, Score, Noul) con probabilidades calibradas y confianza. No escribe texto ni hace cuentas. |
| **Confianza** | Qué tan seguro está JEV de una respuesta (0–1). Decide si se actúa (compuerta de confianza). |
| **Puntaje compuesto** | Combinación en código (0–1) de rendimiento, contexto, sentimiento, sector, volatilidad, riesgo de evento y de reversión, con pesos por bolsillo. |
| **Configuración de decisión** | Versión de preguntas, etiquetas, pesos y umbrales de JEV. Una activa; puede haber una en **modo sombra** (corre sin publicar, para comparar). |
| **Señal** | Decisión de la IA para un bolsillo ("comprar QLD con 22,5 % del disponible"). |
| **Sugerencia** | Propuesta concreta dirigida a quien la decide, con monto, precio de referencia, protección, vencimiento y explicación. Una señal de Usuarios se reparte en una sugerencia por cupo que califica. |
| **Decisión** | Aprobación o rechazo de una sugerencia por una persona. |
| **Doble aprobación** | Compras de Arriesgadas sobre un monto necesitan dos analistas distintos. |
| **Orden** | Instrucción enviada al broker. |
| **Protección** | Stop-loss y take-profit. **Nativa** en el broker; **virtual** vigilada por el sistema. |
| **Motor de políticas** | Reglas deterministas (`RR-xx`) que toda operación debe cumplir. |
| **Interruptores** | `ia_activa` y `trading_activo`. |
| **Conciliación** | Comparación periódica entre el libro y el broker. |
| **Paper trading** | Broker real, precios reales, dinero ficticio. El MVP solo opera así. |
| **Proveedor simulado** | Implementación de prueba de una integración (mercado, broker, noticias, DeepSeek, JEV, push) con la misma interfaz que la real. |
| **Módulo** | Parte del sistema con responsabilidad propia (`M-xx`), usada para investigar solo lo necesario ([17](17-mapa-de-modulos.md)). |
| **QQQ / QLD / TQQQ** | ETFs sobre el NASDAQ-100: ×1 (referencia del índice), ×2 diario (núcleo de RiTech), ×3 diario. |

---

## Convenciones de identificadores

| Prefijo | Qué identifica | Dónde vive |
|---|---|---|
| `RN-xx` | Regla de negocio | [02](02-logica-de-negocio.md), [03](03-roles-y-permisos.md) |
| `RR-xx` | Regla de riesgo del motor de políticas | [02 §9](02-logica-de-negocio.md#9-motor-de-políticas-reglas-de-riesgo) |
| `PM-xx` | Permiso | [03](03-roles-y-permisos.md) |
| `CB-xx` | Caso borde | [12](12-casos-borde.md) |
| `D-xx` | Decisión tomada | [13](13-decisiones-pendientes-riesgos.md) |
| `Q-xx` | Pregunta abierta para el cliente | [13](13-decisiones-pendientes-riesgos.md) |
| `RSG-xx` | Riesgo | [13](13-decisiones-pendientes-riesgos.md) |
| `E-xx` | Épica | [14](14-mapa-para-backlog.md) |
| `E2E-xx` | Escenario de prueba de punta a punta | [15 §4](15-calidad-pruebas-y-ci-cd.md#4-escenarios-e2e-obligatorios) |
| `M-xx` | Módulo | [17](17-mapa-de-modulos.md) |
| `EC-xxx` | Error conocido | [errores-conocidos](errores-conocidos.md) |
| `FR-xxx` | Requisito funcional | `backlog/requisitos-funcionales/` |
| `HU-xxx` | Historia de usuario | `backlog/`, en la carpeta de su épica |
| `TT-xx` | Tarea técnica de E-01 | `backlog/E-01-cimientos-y-calidad-continua/` |

- Un identificador **nunca se reutiliza**. Si una regla deja de aplicar, se
  marca como *retirada* y su número queda libre para siempre (p. ej. RN-15,
  RN-31, CB-20, CB-42, Q-11, Q-17, RSG-09 y E-14 se retiraron en la v3.1 al
  quitar el dinero real).
- Parámetros configurables: por su clave, p. ej. `sugerencias.minutos_vencimiento`
  (catálogo en [02 §10](02-logica-de-negocio.md#10-parámetros-configurables)).
- `scripts/verificar_docs.py` comprueba en CI que todo identificador citado
  esté definido y que todo enlace y ancla exista. No revisa `FR`, `HU` ni
  `TT`, que viven en `backlog/`.

## Idioma y nombres

- Documentación, interfaz y **modelo de datos** en español (lenguaje del
  negocio), sin tildes ni eñes en identificadores: `ordenes`, `anio`.
- Las preguntas a JEV y el contexto que recibe van **en inglés** (su
  precisión es mayor); todo lo que ve una persona, en español.
- Dinero siempre en **USD**, con 2 decimales. Horas guardadas en UTC,
  mostradas en hora de Bogotá; la lógica de mercado usa hora de Nueva York.

## Cómo se mantiene esta documentación

1. **Documentación primero**: si una historia pide algo que no está aquí o lo
   contradice, se actualiza `docs/` (con aprobación) antes de implementar.
2. **En ambos sentidos**: si cambia una historia, cambia `docs/`; si cambia
   `docs/`, se revisan las historias que citan lo cambiado.
3. Todo cambio de regla o decisión se anota en el historial de 13 §4.
4. La **wiki** del repositorio se genera sola desde esta carpeta; nunca se
   edita a mano.
