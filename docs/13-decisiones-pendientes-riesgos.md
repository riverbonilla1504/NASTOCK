# 13 · Decisiones, pendientes y riesgos

## 1. Registro de decisiones

**Origen**: *Cliente* = lo decidió RiTech en las sesiones de definición del
28-09-2026. *Propuesta* = lo propone esta especificación (el cliente delegó
la decisión o no se discutió); puede cambiarse, idealmente antes de escribir
las historias afectadas. *Supuesto* = se asumió por el contexto.

| ID | Decisión | Origen | Dónde impacta |
|---|---|---|---|
| D-01 | Tres roles: Usuario, Analista, Administrador. **Un rol por persona.** | Cliente | 03 |
| D-02 | Un único fondo con bolsillos 50/25/25; el 25 % de Usuarios se reparte en **cupos individuales** que asigna el admin. | Propuesta (el cliente delegó) | 02 §1–§5 |
| D-03 | El 50/25/25 se aplica al capital que entra **y** a las ganancias realizadas. | Cliente | 02 §3, §7 |
| D-04 | El 25 % de ganancia de Usuarios vuelve al cupo que la generó; si viene de Arriesgadas, va a la bolsa común. | Cliente | RN-26 |
| D-05 | Arriesgadas: aprueba 1 analista; sobre un monto, 2 analistas distintos. | Cliente | RR-13, 08 §1 |
| D-06 | Lista blanca de símbolos por bolsillo; QLD (×2) como instrumento núcleo. | Cliente | 02 §1, 10 |
| D-07 | Paper trading en broker real (Alpaca). | Cliente | 10 |
| D-08 | La IA sugiere comprar, vender, rebalancear (lo aprueba el admin) y emite alertas. | Cliente | 07 |
| D-09 | La compra aprobada incluye su stop-loss y take-profit. | Cliente | 10 §6 |
| D-10 | La Reserva solo la mueve el admin, por rebalanceo o retiro. | Cliente | RN-03, RN-37 |
| D-11 | Las sugerencias vencen por tiempo o por movimiento de precio. | Cliente | 07 §7.5, RR-12 |
| D-12 | Ingreso solo con Google Workspace. | Cliente | 04 |
| D-13 | DeepSeek como proveedor de IA. **Precisada por D-37**: DeepSeek aporta el contexto; JEV decide. | Cliente | 07 |
| D-14 | Avisos en la app en tiempo real + push. | Cliente | 09 |
| D-15 | Los empleados aprueban sugerencias **y** crean órdenes manuales, con opinión previa de la IA. | Cliente | 07 §8 |
| D-16 | Se mantiene Flutter (móvil + web). | Supuesto | 05 §9 |
| D-17 | USD como única moneda contable. | Supuesto | 02 |
| D-18 | Riverpod + go_router en la app, reemplazando los singletons `ChangeNotifier`. | Propuesta | 05 §9 |
| D-19 | Reparto de ganancias **por operación cerrada**, no neto por periodo. | Propuesta | RN-29, Q-01 |
| D-20 | El admin **no aprueba** compras ni ventas (separación de funciones). | Propuesta | 03 |
| D-21 | Los analistas no crean órdenes manuales en Arriesgadas; piden análisis a la IA. | Propuesta | PM-22, Q-05 |
| D-22 | Los Usuarios ven el fondo solo en agregados, nunca cupos ajenos. | Propuesta | PM-30, Q-04 |
| D-23 | La lógica de dinero vive en Postgres; las integraciones en Edge Functions; sin servidores propios en el MVP. | Propuesta | 05 §2 |
| D-24 | Precios por consulta cada 15 s, no por WebSocket, en el MVP. | Propuesta | 09 §1 |
| D-25 | Protección **nativa** (bracket) si la compra es de acciones enteras; **virtual** si es fraccional (Alpaca no admite bracket con fracciones). | Propuesta | 10 §6 |
| D-26 | El tamaño de la orden prefiere acciones enteras; el sobrante queda en efectivo. | Propuesta | RN-21 |
| D-27 | La liquidación del cupo de un empleado la aprueban analistas, no el admin. | Propuesta | 02 §11 |
| D-28 | Cualquier analista puede frenar la IA o el trading; solo el admin reanuda. | Propuesta | PM-56, PM-57 |
| D-29 | Modelo de datos en español (lenguaje del negocio). | Propuesta | 06 |
| D-30 | Se eliminan documento de identidad y celular del perfil (datos mínimos). | Propuesta | 11 §6 |
| D-31 | Se permite reincorporar una cuenta de baja, con cupo nuevo. | Propuesta | CB-06 |
| D-32 | Los eventos de tiempo real solo avisan qué cambió (sin montos); el dato se lee por la API con RLS. | Propuesta | 09 §4 |
| D-33 | En doble aprobación, la retención de fondos ocurre en la aprobación final. | Propuesta | 08 §1 |
| D-34 | Una sugerencia fuera de banda se invalida sin importar si el precio mejoró o empeoró. | Propuesta | 08 §1 |
| D-35 | No se decide desde la notificación; siempre en la app con biometría. | Propuesta | 09 §5.2 |
| D-36 | *Reemplazada por D-39* (antes: sin noticias en el MVP). | — | — |
| D-37 | Enfoque de IA en tres piezas: **IA principal** (código que recopila y verifica datos, calcula y compone), **DeepSeek** (contexto a partir de noticias) y **JEV** de TypeSafe (decisión con probabilidades calibradas). | Cliente | 07 |
| D-38 | La IA principal es código determinista, no otro modelo (lo recomienda la documentación de JEV: usar código siempre que se pueda). | Propuesta | 07 §1 |
| D-39 | DeepSeek solo interpreta **noticias reales** que le entrega el sistema (Alpaca News), citando cuáles usó; su API no busca en internet. | Propuesta | 07 §4.2 |
| D-40 | A JEV se le envían **etiquetas**, no cifras ni fechas, y preguntas en inglés; una llamada por candidata con todas sus preguntas. | Propuesta (por limitaciones documentadas de JEV) | 07 §4.3, §6.1 |
| D-41 | La mejor opción se elige en código con un **puntaje compuesto** (riesgo y ganancia con igual peso en Usuarios, 55/45 en Arriesgadas) y **compuerta de confianza**. | Propuesta | 07 §6 |
| D-42 | La explicación de cada decisión la arma el código con piezas verificables (JEV no genera texto). | Propuesta | 07 §14 |
| D-43 | Versión de JEV **fijada** (`jev-1.13.0`) y configuración de decisión versionada con modo sombra. | Propuesta | 07 §5, §11 |
| D-44 | **Solo MVP en paper trading.** Nada de dinero real en esta especificación. | Cliente | 01, 10 |
| D-45 | **Herramientas gratuitas** salvo las IAs (DeepSeek y JEV): Supabase gratuito, Firebase Spark, GitHub, Alpaca paper. | Cliente | 05 §3, §14 |
| D-46 | App para **Android y web**; iOS fuera del MVP (publicar exige cuenta paga de Apple). | Propuesta (por D-45) | 05 §3.1 |
| D-47 | Cada integración tiene **proveedor simulado**; el E2E corre siempre contra simulados; proyecto de demostración opcional. | Propuesta | 10 §9, 15 §3 |
| D-48 | En local y CI se permite correo + contraseña para usuarios de prueba; en la nube, solo Google. | Propuesta | 04 §5 |
| D-49 | La documentación de `docs/` es la **fuente de verdad**; se sincroniza en ambos sentidos con las historias; la wiki es un espejo generado. | Cliente | `CLAUDE.md`, 14 §7 |
| D-50 | Registro de errores conocidos compartido entre sesiones de agentes. | Cliente | `errores-conocidos.md` |
| D-51 | Ningún cambio se da por terminado sin el E2E completo en verde. | Cliente | 15 §1 |
| D-52 | Investigación acotada por módulos al empezar cada historia. | Cliente | 17 |
| D-53 | Entregas por valor: algo tangible desde la primera, cortes verticales. | Cliente | 14 §1 |
| D-54 | Repositorio nuevo; backlog como issues con GitHub CLI en GitHub Projects; documentación en la wiki. | Cliente | 16 |
| D-55 | Respaldo diario cifrado desde GitHub Actions (el plan gratuito de Supabase no respalda). | Propuesta | 11 §7 |
| D-56 | Desarrollo guiado por especificaciones con **spec-kit** (versión fijada): una spec por historia en `specs/`, generada desde `backlog/` por entrega. `docs/` sigue siendo la fuente de verdad y la constitución del kit remite a `CLAUDE.md` y a `docs/`. Los issues salen del backlog, no del kit. | Propuesta | `CLAUDE.md`, 05 §12, 15 §7, 16 §3.7–§3.8, 17 |
| D-57 | El latido de `ping()` vive en una **tabla propia `latido` de una sola fila**, con RLS activo y sin políticas; solo `public.ping()` la actualiza. Deja en la base la hora del último latido para saber si el flujo diario contra la pausa del plan gratuito sigue llegando. No se reutilizan `salud_integraciones`, `parametros` ni `auditoria` porque mezclarían el latido con sus reglas. | Propuesta | 06 §5.6, §7, §10 · 03 §4.3 |
| D-58 | **MVP corto.** Por falta de tiempo se entrega primero lo mínimo: iniciar sesión, manejar usuarios, ver las acciones, comprar y vender en paper y la IA que analiza y sugiere. Son 61 de los 125 ítems abiertos, sumando las dependencias de cada historia. R5, R6 y el resto quedan para la fase siguiente, con su especificación intacta. | Propuesta (aprobada por el equipo el 2026-11-05) | 01 §4 · 14 §4.1 · 15 §4 |
| D-59 | MVP corto **sin noticias ni DeepSeek**: toda candidata se evalúa "sin contexto"; la IA decide con métricas y JEV. Ahorra tres historias y el costo de DeepSeek. | Propuesta (aprobada por el equipo el 2026-11-05) | 07 §4.2 · 05 §6 |
| D-60 | MVP corto **sin opinión de la IA** antes de una orden manual. La orden igual pasa por el motor de políticas. | Propuesta (aprobada por el equipo el 2026-11-05) | 07 §8 · 08 §7.5 · 02 §6 |
| D-61 | MVP corto **sin biometría**: las decisiones y los movimientos de dinero se confirman con un diálogo que repite monto y símbolo; sin bloqueo de la app. La sesión sigue en almacenamiento seguro. | Propuesta (aprobada por el equipo el 2026-11-05) | 04 §8 · 11 §2 |
| D-62 | MVP corto **sin bandeja de notificaciones ni push**: cada pantalla muestra su estado en vivo; las alertas del sistema siguen en la app. | Propuesta (aprobada por el equipo el 2026-11-05) | 09 §5 · 05 §6 |
| D-63 | MVP corto **solo con acciones enteras**: sin compras fraccionales, así toda compra lleva protección nativa (RR-08) y no se construye la protección virtual. | Propuesta (aprobada por el equipo el 2026-11-05) | 02 §6.1 · 10 §5 |
| D-64 | En el MVP corto **el bolsillo de Arriesgadas no opera**: la IA no le crea sugerencias, queda en efectivo y el Analista solo supervisa. Evita construir la bandeja de riesgo y la doble aprobación. | Propuesta (aprobada por el equipo el 2026-11-05) | 02 §6 · 07 §7.2 |
| D-65 | MVP corto **sin sugerencias de la IA**: la IA analiza y recomienda en Oportunidades, y la persona compra y vende con órdenes manuales. Salen seis historias (bandeja, aprobar, rechazar, vencimiento y reparto de señales en cupos) y el MVP corto queda en 55 ítems. | Propuesta (aprobada por el equipo el 2026-11-05) | 07 §7 · 08 §1 · 02 §6 · 06 §5.4 · 14 §4.1 · 15 §4 |
| D-66 | Las Edge Functions se conectan **directo a Postgres** con `SUPABASE_DB_URL` (la da la plataforma, en local y en la nube) y **solo ejecutan funciones de `private`**, desde un único archivo, `_shared/bd.ts`. `private` sigue sin exponerse por la API de datos. La llave secreta de Supabase queda solo para la administración de usuarios de Auth (`admin-usuarios`). El secreto interno viaja en la cabecera `x-secreto-interno`. Reemplaza lo que decían 05 §4 y 06 §7 (supabase-js con la llave secreta), que no se podía cumplir: supabase-js pasa por la API de datos, que solo expone `public` y `graphql_public` (03 §4.2, 11 §2). | Propuesta (aprobada por Javier el 2026-11-05, al construir HU-026) | 05 §1, §4, §6, §10.1 · 06 §7, §8.2 · 11 §5 · 15 §2 · 03 §4.5 · 04 §10 |
| D-67 | **Diseño visual nuevo.** La interfaz de la v2 no se copia: solo es referencia de contenido (qué pantallas, datos y flujos había) y antirreferencia visual. HU-116 crea un mundo visual nuevo con impeccable, sin conservar la paleta, los widgets ni la fuente Poppins de la v2. `DESIGN.md`, en la raíz y escrito con impeccable, manda en lo visual (tokens, color, tipografía, componentes, movimiento y tono visual); `docs/` sigue mandando en reglas de negocio, flujos, permisos, datos y textos de error, y si chocan en algo que no es visual manda `docs/`. `PRODUCT.md` se deriva de 01 a 04 sin agregar nada. `.impeccable/config.json` y los demás archivos que impeccable pide versionar van al repositorio. HU-116 entra al MVP corto como "Identidad visual y sistema de diseño" y el MVP corto queda en 56 ítems. Toda historia con pantallas usa `/impeccable shape` antes de construir, los componentes del sistema y `/impeccable audit` + `polish` al final, revisando en Chrome y en el emulador. | Propuesta (aprobada por Javier el 2026-11-06, al refinar HU-116; eligió un diseño nuevo en vez de partir de la v2) | 05 §9, §11, §12 · 14 §2, §4.1 · 15 §12 · 01 §7 · `CLAUDE.md` |

---

## 2. Preguntas abiertas para RiTech

Ninguna bloquea empezar el backlog: cada una tiene un valor provisional. Pero
conviene cerrarlas antes de refinar las historias que las citan.

| ID | Pregunta | Valor provisional | Afecta |
|---|---|---|---|
| Q-01 | ¿La ganancia se reparte **por cada operación** o **neta por periodo** (p. ej. mensual, compensando pérdidas antes de repartir)? Por operación es simple pero un cupo que pierde y luego gana termina con menos (CB-19). | Por operación | RN-29 |
| Q-02 | ¿Desde qué monto una compra de Arriesgadas necesita dos analistas? | USD 400 | RR-13 |
| Q-03 | ¿Son aceptables los límites de riesgo propuestos (máximos por operación y por símbolo, rangos de stop, pérdida diaria máxima)? | Tabla de 02 §9 | RR-04, RR-05, RR-08, RR-19 |
| Q-04 | ¿Los empleados deben ver el patrimonio agregado del fondo por bolsillo? | Sí, solo agregados | PM-30 |
| Q-05 | ¿Los analistas deben poder crear órdenes manuales en Arriesgadas? | No | D-21 |
| Q-06 | Cuando un empleado se retira, ¿se liquidan sus posiciones o se transfieren al bolsillo común? | Se liquidan | 02 §11 |
| Q-07 | Monto real del fondo y cómo se reparten los cupos iniciales (¿iguales para todos?) | USD 10.000; cupos que defina el admin | 02 §3, §5 |
| Q-08 | Dominio de Google Workspace y correo del primer administrador | — | 04 §9 |
| Q-09 | ¿Un empleado puede **cobrar** (retirar como bonificación) lo que su cupo acumula por ganancias? | No: se reinvierte | 01 §4 |
| Q-10 | Región del proyecto Supabase | Este de EE. UU. | 11 §6 |
| Q-11 | *Retirada* (era sobre dinero real). | — | — |
| Q-12 | **Spike técnico**: comportamiento de las patas de un bracket de Alpaca ante una entrada llenada parcialmente y luego cancelada. | Cubrir lo llenado con protección virtual | 10 §6 |
| Q-13 | ¿El universo de Arriesgadas son los ~100 componentes del NASDAQ-100 completos o un subconjunto? | Los ~100 + TQQQ | 02 §1, 07 §4.1 |
| Q-14 | ¿Se necesita operar en horario extendido? | No | RR-18 |
| Q-15 | ¿Qué reportes necesita contabilidad (formato, periodicidad, PDF)? | CSV mensual | 01 §4 |
| Q-16 | ¿Cada 15 minutos es una buena frecuencia para el agente? | 15 min | 07 §2 |
| Q-17 | *Retirada* (era sobre dinero real). | — | — |
| Q-18 | ¿Repositorio **público** o **privado con GitHub Pro** (paquete de estudiantes)? Un privado gratuito pierde la wiki y la protección de rama. | Público | 16 §2 |
| Q-19 | Si Alpaca News no da acceso con la cuenta gratuita, ¿qué fuente gratuita de noticias se usa? | Evaluar Finnhub (capa gratuita, noticias por empresa) u otra; mientras tanto, "sin contexto" | 07 §4.2, 10 §11 |
| Q-20 | ¿El bolsillo de Usuarios también debe poder comprar acciones individuales del NASDAQ-100, o solo QLD y QQQ? | Solo QLD y QQQ | 07 §6.4 |
| Q-21 | ¿Son adecuados los pesos del puntaje y los umbrales iniciales de JEV (confianza 0,65, puntaje 0,60)? Se ajustan con datos de R3. | Los de 07 §6 | 07 §6 |
| Q-22 | ¿RiTech tiene organización de Google Workspace, o se usa la pantalla Externa en modo prueba? | Workspace | 04 §1 |

---

## 3. Riesgos

| ID | Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|---|
| RSG-01 | La IA sugiere operaciones perdedoras de forma sistemática | Media | Alto | Aprobación humana, motor de políticas, stops obligatorios, paper trading primero, evaluación continua (07 §11) y comparación contra no hacer nada |
| RSG-02 | Proveedor de IA extranjero: privacidad, disponibilidad o restricciones de uso | Media | Medio | Ningún dato personal en el contexto; adaptador para cambiar de proveedor; P7 si no responde |
| RSG-03 | DeepSeek o TypeSafe cambian o retiran modelos (ya pasó en DeepSeek) | Alta | Bajo | Nombres como parámetros; versión de JEV fijada; prueba real semanal |
| RSG-04 | Límites de tiempo de las Edge Functions | Media | Medio | Tiempos de espera explícitos, colas, trabajos partidos en pasos |
| RSG-05 | Las protecciones virtuales dependen de que nuestro sistema funcione | Media | Alto | Preferir acciones enteras (protección nativa); alerta si los precios se detienen; evolución a proceso siempre encendido (09 §6) |
| RSG-06 | Datos IEX parciales o distintos del consolidado | Alta | Bajo en paper | Banda de precio y órdenes límite |
| RSG-07 | El cron o la plataforma se detienen sin que nadie se entere | Baja | Alto | Flujo diario de mantenimiento que falla y avisa; antigüedad del precio visible en la app |
| RSG-08 | ETFs apalancados: pérdidas amplificadas y deterioro por volatilidad | Alta | Alto | Explicación en la app, stops, límites de pérdida diaria, reserva del 50 % |
| RSG-09 | *Retirado* (era sobre dinero real). | — | — | — |
| RSG-10 | Los resultados en paper son más optimistas que con dinero | Alta | Medio | Advertencia en los reportes |
| RSG-11 | Mucha lógica en SQL y RLS para un equipo acostumbrado a lógica en la app | Media | Medio | Pruebas pgTAP desde el día uno, plantillas de RPC, revisión en PR |
| RSG-12 | Los empleados no responden a tiempo y todo vence | Media | Medio | Push, aviso previo al vencimiento, métricas de respuesta, ajustar `minutos_vencimiento` |
| RSG-13 | Que la plataforma se interprete como asesoría financiera | Baja | Alto | Uso interno de una empresa, con dinero ficticio (paper); avisos claros |
| RSG-14 | Un solo administrador concentra todo | Media | Medio | Recomendar dos administradores; MFA en todas las consolas; bitácora |
| RSG-15 | **JEV es muy nuevo** (lanzado el 15-09-2026, acceso anticipado, métricas publicadas solo por su fabricante) | Alta | Alto | JEV simulado para desarrollar sin depender del acceso; ruta alternativa por Cloudflare Workers AI; versión fijada; calibración medida con nuestros datos antes de confiar en umbrales; toda decisión pasa por el motor de políticas y por una persona |
| RSG-16 | Contexto de DeepSeek inventado o desactualizado | Media | Medio | Solo noticias entregadas; verificación de fuentes; vigencia; pregunta `context_grounded`; peso máximo 0,25 |
| RSG-17 | Límites del plan gratuito de Supabase (500 MB, pausa, sin respaldos, 150 s por función) | Media | Medio | Retención ajustada, alerta a 350 MB, `ping()` diario, respaldo cifrado, contexto separado del ciclo |
| RSG-18 | Repositorio privado gratuito sin protección de rama: se podría integrar con CI en rojo | Media | Medio | Público o Pro (Q-18); regla explícita en `CLAUDE.md` |
| RSG-19 | Pruebas E2E lentas o intermitentes que frenan el trabajo | Media | Medio | Simulados deterministas, reloj controlado, `--rapido` para iterar, política de intermitentes (15 §8) |

---

## 4. Historial de la especificación

Cada cambio de `docs/` que altere una regla, un flujo o una decisión se
anota aquí (además del registro de git), con las historias afectadas.

| Versión | Fecha | Cambio | Historias afectadas |
|---|---|---|---|
| 3.0 | 2026-09-28 | Especificación inicial v3: fondo 50/25/25, tres roles, Supabase, Google Workspace, paper trading en Alpaca, agente con DeepSeek. | — (backlog aún no creado) |
| 3.1 | 2026-09-28 | Solo MVP en paper (se retira todo lo de dinero real). Agente rediseñado: IA principal + DeepSeek (contexto con noticias) + JEV (decisión). Herramientas gratuitas salvo las IAs; Android y web. Proveedores simulados, calidad y CI/CD (15), arranque del repositorio (16), mapa de módulos (17), errores conocidos, `CLAUDE.md`. Paquete para el repositorio nuevo. | — (backlog aún no creado) |
| 3.2 | 2026-10-12 | Precisiones de identidad encontradas al revisar las historias de R1. Una invitación pendiente ya vencida no impide invitar de nuevo: `invitar_usuario` la pasa a `vencida` y crea la nueva (08 §5). La tabla de mensajes de ingreso incluye los dos mensajes del hook de alta (04 §11). | HU-002, HU-003, HU-005 |
| 3.3 | 2026-10-12 | Se adopta spec-kit (D-56): flujo y comandos de `CLAUDE.md`, nombre de las ramas (15 §7), herramientas (16 §3.7–§3.8), estructura del repositorio (05 §12) y rutas de M-20 (17). Entran `backlog/` y `specs/` a la estructura, y `FR`, `HU` y `TT` a las convenciones de identificadores. Las rutas de ejemplo de 16 §6.2 son las del backlog real. | Todas: cambia el nombre de la rama y se agrega la spec antes de implementar |
| 3.4 | 2026-10-12 | Cuatro precisiones encontradas al revisar las historias de R2. Códigos de error nuevos `CUPO_SUPERA_MAXIMO` (una asignación supera `cupos.maximo_usd`, RN-19) y `FONDO_SIN_CAPITAL` (encender un interruptor antes del primer aporte confirmado, RN-11), en 06 §9. Los tres porcentajes de reparto se cambian juntos con la clave `reparto` (06 §8.1). Los ajustes contables se registran en la pantalla Capital (03 §3). | HU-018, HU-022, HU-033, HU-034, HU-099 |
| 3.5 | 2026-10-19 | Backlog publicado en GitHub con `scripts/github/publicar-backlog.py` (16 §6). Las épicas no van al tablero del proyecto: quedan como issues padre con sus historias y tareas como sub-issues (16 §6.1 paso 5). `preparar-github.sh` fija también las opciones de Status, que dejan de ser un paso manual (16 §5). Los agentes de IA nunca figuran como autores ni coautores de commits o PR (15 §7). | Ninguna: cambia la organización del tablero, no una regla |
| 3.6 | 2026-10-26 | Se define dónde vive la "fila de latido" que actualiza `ping()`, que §7 de 06 nombraba sin ubicar: tabla `latido` de una sola fila, con RLS y sin políticas, que solo actualiza `ping()` (D-57). Se documenta qué hace, por qué existe, por qué no se reutiliza otra tabla y cómo afecta al proyecto (06 §5.6). Se agrega a la matriz de lecturas (03 §4.3), a la retención (06 §10) y a M-20 (17). | TT-03 (crea la tabla y prueba que `anon` no la toca), HU-109 (la incluye en su revisión por tabla) |
| 3.7 | 2026-11-05 | **MVP corto** (D-58): por falta de tiempo se entrega primero lo mínimo para iniciar sesión, manejar usuarios, ver las acciones, comprar y vender en paper y tener la IA que analiza y sugiere. Entran 61 de los 125 ítems abiertos; R5, R6 y 35 ítems de R1 a R4 quedan para la fase siguiente. Seis simplificaciones (D-59 a D-64): sin DeepSeek, sin opinión en la orden manual, confirmación sin biometría, sin bandeja ni push, solo acciones enteras y Arriesgadas sin operar. Cada una está anotada donde se define su regla (02 §6 y §6.1, 03 §3, 04 §8, 05 §6, 07 §4.2, §7.2 y §8, 08 §7.5, 09 §5, 10 §5, 11 §2). Alcance en 01 §4, entregas en 14 §4.1 y escenarios E2E en 15 §4. | Salen 64 ítems (lista en 14 §4.1). Cambian de alcance (sección "MVP corto" de cada una): HU-005, HU-006, HU-046, HU-047, HU-048, HU-058, HU-059, HU-062, HU-063, HU-066, HU-072, HU-073, HU-074, HU-075, HU-077, HU-091, HU-097, HU-099, HU-100 |
| 3.8 | 2026-11-05 | MVP corto **sin sugerencias de la IA** (D-65): la IA analiza y recomienda en Oportunidades y la persona compra y vende con órdenes manuales. Salen HU-058, HU-059, HU-061, HU-062, HU-063 y HU-066 y el MVP corto queda en 55 ítems. Las tablas de órdenes y su cola pasan a HU-073; `ordenes.sugerencia_id` y `ordenes.opinion_id` quedan sin llave foránea hasta la fase siguiente (06 §5.4); E2E-08 empieza con una orden manual y lo crea HU-075 (15 §4). Anotado en 01 §4, 02 §6, 03 §3, 05 §6, 07 §7, 08 §1, 09 §5 y 14 §4.1. | Salen HU-058, HU-059, HU-061, HU-062, HU-063 y HU-066. Cambian: HU-005, HU-047, HU-048, HU-073, HU-074 y HU-075 |
| 3.9 | 2026-11-05 | Se precisan dos reglas de los proveedores simulados al construir TT-05 (10 §9). `ENTORNO` admite `local`, `ci`, `demo` y `mvp` (los entornos de 05 §10); sin definir cuenta como `local` y un valor desconocido es un error. Un `PROVEEDOR_*` sin definir cuenta como `simulado`, de modo que con `ENTORNO=mvp` una variable olvidada hace que la función no arranque (CB-91). | TT-05 (lo implementa en `_shared/proveedores.ts`), TT-08 (el despliegue define las seis variables `PROVEEDOR_*` y la prueba de humo lo verifica), HU-114 (la lista de verificación se apoya en esa prueba de humo) |
| 3.10 | 2026-11-05 | Herramientas locales de la app (16 §3.7): Android Studio deja de ser obligatorio. Basta el SDK de Android y Java 17, con Android Studio o con VS Code y sus extensiones de Flutter y Dart. Rutas de la app en M-20 y M-01 (17). | TT-04 |
| 3.11 | 2026-11-05 | **Cómo llegan las Edge Functions a las funciones de `private`** (D-66). Lo que decían 05 §4 y 06 §7 (supabase-js con la llave secreta) no funciona: supabase-js pasa por la API de datos, que solo expone `public` y `graphql_public`, y `private` no se expone (03 §4.2, 11 §2). Las Edge Functions se conectan directo a Postgres con `SUPABASE_DB_URL` y solo ejecutan funciones de `private`, desde `_shared/bd.ts`, el único archivo que importa el cliente de Postgres (búsqueda nueva en 15 §2, `verificar.sh` y CI). La llave secreta queda solo para `admin-usuarios`. El secreto interno viaja en la cabecera `x-secreto-interno` (la que ya usa `private.despertar_funcion`). Se agrega la contraseña de la base a la rotación de secretos (11 §5). También se precisa que la lista blanca la siembra una **migración** y no `seed.sql` (05 §12, 15 §3): `seed.sql` no corre en la nube y el universo debe existir allí para la carga inicial de barras (10 §12). `seed.sql` sigue trayendo los parámetros por defecto, la configuración de decisión v1 y un año de barras diarias de prueba. | HU-026 (la primera en necesitarlo), TT-03 (sin cambios: `despertar_funcion` ya envía la cabecera) y toda historia cuya Edge Function escribe en la base: HU-027, HU-028, HU-029, HU-046, HU-073 y HU-074. La semilla de la lista blanca afecta además a HU-036 (edita la tabla ya sembrada) |
| 3.12 | 2026-11-06 | **Calendario, reloj y atributos de los activos** (HU-027). `docs/10` precisa lo que no decía: el adaptador del broker suma las operaciones `reloj` y `activos` (§1), un día es `media_jornada` si cierra antes de las 16:00 de Nueva York, el calendario se sincroniza de hoy a 60 días y el reloj de Alpaca solo se contrasta con el calendario (se informa, no se actúa). Hasta que exista la tabla `parametros` (la crea HU-002), los márgenes de la ventana de compras salen de `private.margenes_de_compra()`, que devuelve los 5 y 15 minutos de 02 §10; HU-033 la cambia para que lea `parametros`. `estado_mercado()` devuelve `datos_actualizados_en` nula hasta que HU-028 tenga `cotizaciones` (06 §6 y §8.2). | HU-027 (la implementa), HU-028 (llena `datos_actualizados_en`), HU-032 (la usa para el aviso), HU-033 (cambia `margenes_de_compra()`), HU-002 (crea `parametros`) |
| 3.13 | 2026-11-06 | **El hash de la bitácora cubre todos los campos del registro** (11 §4.3). La fórmula era `sha256(hash_anterior ‖ momento ‖ actor ‖ acción ‖ entidad ‖ id ‖ detalle)` y dejaba fuera `antes`, `despues`, `actor_rol` y `origen`: alterarlos no rompía la cadena. Ahora es `sha256(hash_anterior ‖ momento ‖ actor ‖ actor_rol ‖ acción ‖ entidad ‖ id ‖ antes ‖ después ‖ detalle ‖ origen)`, con el orden fijo y la escritura de cada campo (separador `U+001F`, momento en UTC, `jsonb` canónico, nulo vacío, 64 ceros en el primer registro). También se corrige el ejemplo de 04 §6 (el id de `auditar` es texto: `new.id::text`) y se precisa la firma de `auditar` en 06 §8.2 (`antes`, `despues` y `origen` opcionales). No se agrega ningún filtro de claves en `detalle`. | HU-107 (CA-2), HU-002, HU-108, HU-110 |
| 3.14 | 2026-11-07 | Cómo obtiene el E2E el secreto interno de prueba (15 §3), al construir TT-06. `.env.e2e` sigue sin secretos; `scripts/verificar.sh` y CI suman el `SECRETO_INTERNO` de prueba de `seed.sql` a una copia temporal con la que sirven las funciones. | Ninguna: precisa cómo se arma el E2E |
| 3.15 | 2026-11-07 | **Identidad visual y sistema de diseño** (D-67). La interfaz de la v2 pasa de "se copia" a "no se copia; solo referencia de contenido" (05 §11): la app nueva tiene un diseño visual nuevo, sin la paleta, los widgets ni Poppins de la v2. `DESIGN.md` (raíz, escrito con impeccable) manda en lo visual y `docs/` en todo lo demás; si chocan en algo que no es visual, manda `docs/`. `PRODUCT.md` se deriva de 01 a 04. Dónde vive el diseño en la app (05 §9) y en el repositorio (05 §12). HU-116 entra al MVP corto con ese alcance y el MVP corto pasa de 55 a 56 ítems (14 §4.1; 14 §2 para E-13). Regla nueva para las historias con pantallas: `/impeccable shape` antes de construir, los componentes del sistema y `/impeccable audit` + `polish` al final, en Chrome y en el emulador (15 §12 y flujo de `CLAUDE.md`). | HU-116 (cambia de alcance, título y criterios; entra al MVP corto). Toda historia que crea o cambia pantallas sigue 15 §12; en el MVP corto, HU-003, HU-005, HU-006, HU-007, HU-010, HU-011, HU-014, HU-018, HU-019, HU-030, HU-032, HU-048, HU-075, HU-076, HU-097, HU-098, HU-099, HU-100 y HU-101 |
| 3.16 | 2026-11-07 | **Isla de navegación en vez de barra de pestañas** (D-67, solo visual). En teléfono, la navegación inferior de `DESIGN.md` pasa de una barra de 80 dp pegada al borde a una cápsula flotante con velo, desenfoque y sombra Flotante; la pestaña actual muestra ícono y rótulo en una píldora y las demás solo el ícono. En ventanas anchas se mantiene el riel de navegación. Aprobado por Javier el 2026-11-07. No cambia ninguna regla de negocio. | HU-116 (componente y catálogo); HU-006 y HU-030 (pantallas que usan la navegación) |
