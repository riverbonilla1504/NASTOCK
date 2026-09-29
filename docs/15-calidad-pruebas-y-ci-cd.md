# 15 · Calidad, pruebas y CI/CD

## 1. Principio

> **El sistema siempre queda funcionando de punta a punta.**

- Ninguna historia, cambio o corrección se da por terminada sin que
  `scripts/verificar.sh` pase **completo en local, incluido el E2E**, y sin
  que CI esté en verde.
- Nada se integra a `main` con CI en rojo.
- **Nunca** se desactiva, se salta o se relaja una prueba para que pase. Si
  una prueba está mal, se corrige la prueba en el mismo PR y se explica por
  qué.
- Cada entrega agrega escenarios E2E (§4) y los anteriores siguen pasando.

---

## 2. Tipos de prueba

| Capa | Herramienta | Qué cubre | Dónde vive | Tiempo objetivo |
|---|---|---|---|---|
| Documentación | `scripts/verificar_docs.py` | Enlaces, anclas e identificadores (`RN`, `RR`, `PM`, `CB`, `D`, `Q`, `RSG`, `E`, `M`, `EC`, `E2E`) de `docs/` | `scripts/` | < 5 s |
| Arquitectura | `scripts/verificar.sh` (búsquedas) | `agente`, `contexto-ia` y `opinion-ia` no importan `_shared/broker/`; no hay llaves en el código; ningún archivo de la app usa la llave secreta | `scripts/` | < 5 s |
| Unitarias Dart | `flutter test` | Modelos, formato, motor ×2, lógica de presentación, providers con repositorios falsos | `test/` | < 1 min |
| Base de datos | pgTAP (`supabase test db`) | RLS por tabla, RPC (rol, dueño, estado), invariantes del libro, máquinas de estado, motor de políticas, hooks de Auth | `supabase/tests/*.sql` | < 2 min |
| Funciones | `deno test` | Adaptadores (con respuestas grabadas), indicadores, etiquetas, puntaje compuesto, validación de contexto, esquemas | `supabase/functions/**/*_test.ts` | < 1 min |
| **E2E de backend** | `deno test` contra Supabase local con **funciones servidas** y **proveedores simulados** | Flujos de negocio completos a través de RPC y funciones, actuando como distintos usuarios | `supabase/tests/e2e/` | < 5 min |
| **E2E de la app** | Flutter `integration_test` en Chrome (`flutter drive -d web-server`) | Flujos clave en la interfaz real, contra el mismo backend local | `integration_test/` | < 8 min |
| Humo | `deno test` contra el proyecto MVP | Después de cada despliegue: salud, configuración, proveedores reales, seguridad de Auth | `supabase/tests/humo/` | < 1 min |

---

## 3. Modo simulado y datos de prueba

Las pruebas E2E no pueden depender del horario del mercado, de noticias
reales, del costo de las IAs ni del ingreso con Google. Por eso:

| Pieza | En local y CI |
|---|---|
| Proveedores | Todos simulados ([10 §9](10-integracion-bolsa.md#9-proveedores-simulados)), con escenarios forzables (llenado parcial, JEV con confianza baja, contradicción, DeepSeek con afirmaciones sin respaldo, broker sin respuesta…) |
| Reloj | `private.ahora()` es la única fuente de "ahora" para la lógica. En local y CI se puede adelantar con `pruebas.fijar_reloj(...)` para probar vencimientos, ventanas de mercado y cierres. En la nube no existe el esquema `pruebas` y `ahora()` es `now()`. |
| Usuarios de prueba | Uno por rol (`admin@prueba.local`, `analista1@…`, `analista2@…`, `usuario1@…`, `usuario2@…`) con correo + contraseña, creados por `seed.sql`. Solo en local y CI (`auth.proveedores_permitidos` incluye `email` únicamente ahí). |
| Ayudas de prueba | Esquema `pruebas` (fijar reloj, elegir escenario de un proveedor, leer push simulados) creado **solo por `seed.sql`**, que Supabase aplica en local y nunca en `db push` a la nube. |
| Datos | `seed.sql`: parámetros por defecto, lista blanca (NASDAQ-100 + ETFs), un año de barras diarias de prueba, noticias y contextos pregrabados, configuración de decisión v1. |
| Variables | `supabase/functions/.env.e2e` (en el repositorio, sin secretos): `ENTORNO=ci` y todos los `PROVEEDOR_*=simulado`. |

Regla: **nada de lo anterior puede llegar a la nube** (CB-91, CB-92). La
prueba de humo lo verifica en cada despliegue.

---

## 4. Escenarios E2E obligatorios

Se agregan por entrega ([14 §4](14-mapa-para-backlog.md#4-entregas-por-valor-propuesta-inicial)).
Una vez agregado, un escenario **no se borra**: si el flujo cambia, se
actualiza.

| ID | Escenario | Capa | Entrega |
|---|---|---|---|
| E2E-01 | Ingreso por rol: cada rol ve su navegación; rutas prohibidas redirigen | App + backend | R1 |
| E2E-02 | Invitación: el invitado entra; el no invitado y el proveedor no permitido son rechazados con su mensaje | Backend | R1 |
| E2E-03 | Mercado en vivo: la ingesta simulada publica precios, la app los muestra y marca el dato desactualizado cuando se detiene | App + backend | R1 |
| E2E-04 | Aporte → confirmación por conciliación → reparto 50/25/25 → asignación de cupo → "Mi cupo" | App + backend | R2 |
| E2E-05 | Aislamiento: un Usuario no ve cupos ajenos ni escribe directo; al suspenderlo pierde el acceso al instante | Backend | R2 |
| E2E-06 | Ciclo de IA: contexto y JEV simulados → Oportunidades con explicación; contexto viejo → "sin contexto"; contradicción → alerta a analistas | App + backend | R3 |
| E2E-07 | Calidad de datos: candidata con datos incompletos se excluye; sin QQQ el ciclo se omite | Backend | R3 |
| E2E-08 | Sugerencia a un cupo → aprobar → orden → llenado → posición y protección → venta por objetivo → reparto visible en los tres bolsillos | App + backend | R4 |
| E2E-09 | Doble aprobación: dos analistas distintos; el mismo analista no cuenta dos veces; un rechazo basta | Backend | R4 |
| E2E-10 | Vencimiento por tiempo (reloj adelantado) e invalidación por banda de precio | Backend | R4 |
| E2E-11 | Orden manual con opinión de JEV; reintentar con el mismo id no duplica | App + backend | R4 |
| E2E-12 | Protección virtual se dispara en una compra fraccional; la pérdida la absorbe el cupo | Backend | R4 |
| E2E-13 | Descuadre forzado → trading pausado → sugerencias invalidadas salvo liquidaciones → reanudar exige conciliación en `ok` | Backend | R5 |
| E2E-14 | Bitácora: las acciones sensibles quedan auditadas y la cadena de hash se verifica | Backend | R2 |
| E2E-15 | Push: una sugerencia nueva genera push simulado al dispositivo; un token inválido se elimina | Backend | R5 |
| E2E-16 | Liquidación, baja y reincorporación de un empleado | Backend | R6 |

---

## 5. Cuándo corre qué

| Momento | Qué | Dónde |
|---|---|---|
| Mientras se desarrolla | Las pruebas del módulo que se está tocando | Local |
| **Antes de dar por terminado cualquier cambio** | `scripts/verificar.sh` completo (documentación, arquitectura, unitarias, base de datos, funciones, **E2E backend y app**) | Local |
| Cada push a una rama con PR abierto (abrirlo como **borrador** desde el primer push) | `ci.yml` completo | GitHub Actions |
| Merge a `main` | `ci.yml` → si pasa, `despliegue.yml` (migraciones, funciones, secretos, web, APK) → prueba de humo | GitHub Actions |
| Cambios en `docs/` en `main` | `wiki.yml` publica la wiki | GitHub Actions |
| Diario | `mantenimiento.yml`: `ping()` para evitar la pausa, respaldo cifrado | GitHub Actions |
| Semanal | `mantenimiento.yml`: prueba real mínima contra Alpaca paper (solo lectura), DeepSeek y JEV (una llamada cada uno, costo < USD 0,01) | GitHub Actions |

`scripts/verificar.sh --rapido` omite el E2E de la app para iterar más
rápido; **no** sirve para dar un cambio por terminado.

---

## 6. Flujos de GitHub Actions

Los archivos ya están en `.github/workflows/`. Sus trabajos se **activan
solos** a medida que aparece el código (un trabajo `detectar` revisa si
existen `pubspec.yaml`, `supabase/config.toml`, `supabase/tests/e2e/`,
`integration_test/`, `firebase.json`), así que funcionan desde el primer
commit con solo documentación.

### `ci.yml` (cada push a un PR y a `main`)

| Trabajo | Pasos |
|---|---|
| `detectar` | Qué partes del proyecto existen |
| `documentacion` | `python scripts/verificar_docs.py docs` |
| `arquitectura` | Reglas de §2 |
| `app` | `flutter pub get` · `dart format` (verificación) · `flutter analyze` · `flutter test` |
| `backend` | `supabase start` · `supabase db lint` · `supabase test db` · `deno fmt --check` · `deno lint` · `deno test` de funciones |
| `e2e` | `supabase start` · `supabase db reset` · `supabase functions serve --env-file supabase/functions/.env.e2e` · E2E de backend · `chromedriver` + `flutter drive` en Chrome sin ventana |

### `despliegue.yml` (tras CI verde en `main`, o manual)

| Trabajo | Pasos |
|---|---|
| `supabase` | `supabase link` · `supabase db push` · `supabase functions deploy` · sincroniza secretos de funciones desde GitHub |
| `web` | `flutter build web` con `--dart-define` · Firebase Hosting |
| `android` | `flutter build apk --release` firmado · Firebase App Distribution al grupo del equipo |
| `humo` | Pruebas de humo contra el proyecto MVP |

### `wiki.yml` (cambios en `docs/` en `main`)

Copia `docs/` a la wiki con `scripts/publicar_wiki.py` (convierte enlaces,
`README.md` → `Home`, genera la barra lateral y un aviso de "no editar aquí").
Requisito: crear a mano la primera página de la wiki una sola vez.

### `mantenimiento.yml` (diario y semanal)

`ping()` al proyecto MVP; `supabase db dump` cifrado con GPG como artefacto
(7 días); prueba real semanal.

Secretos y variables que necesitan: [16 §4](16-arranque-del-repositorio.md#4-secretos-y-variables).

---

## 7. Ramas y pull requests

- Rama principal: `main`, siempre desplegable.
- Una rama por historia: `hu-<número>-<descripcion-corta>` (p. ej.
  `hu-42-aprobar-sugerencia`). Vida corta: se integra en días, no semanas.
- Commits en español, en imperativo, con la historia: `Agrega la aprobación
  de sugerencias (#42)`.
- PR con la plantilla (`.github/pull_request_template.md`): historia,
  módulos, escenario E2E, documentación actualizada, errores registrados.
- Integración por *squash*.
- Si el repositorio es privado en plan gratuito no hay reglas de protección
  de rama ([16 §2](16-arranque-del-repositorio.md#2-decisiones-antes-de-crear-el-repositorio)):
  la regla "no se integra con CI en rojo" se cumple por disciplina y la
  vigila `CLAUDE.md`.

---

## 8. Pruebas intermitentes y errores

- Una prueba que falla "a veces" es un error, no mala suerte (CB-94). Se
  investiga hasta encontrar la causa (esperas, orden de eventos, reloj,
  datos compartidos entre pruebas).
- Antes de investigar un error, se busca en `docs/errores-conocidos.md`.
- Cuando se resuelve algo que costó más de un intento, se registra ahí con
  síntoma, causa y solución.

---

## 9. Despliegue y reversión

| Pieza | Cómo se despliega | Cómo se revierte |
|---|---|---|
| Migraciones | `supabase db push`, solo hacia adelante | Nueva migración que deshace el cambio (nunca editar una ya aplicada) |
| Funciones | `supabase functions deploy` | Revertir el commit y volver a desplegar |
| Web | Firebase Hosting | Botón de reversión de Firebase Hosting a la versión anterior |
| Android | Firebase App Distribution | Volver a distribuir la versión anterior |
| Configuración de IA | Versiones en `configuraciones_decision` y `prompts_agente` | Activar la versión anterior |

Orden de despliegue: migraciones → funciones → web → APK → humo. Si falla la
prueba de humo, el flujo avisa y el admin apaga `trading_activo` hasta
corregir.

---

## 10. Minutos de GitHub Actions

| Repositorio | Minutos incluidos | Consumo estimado |
|---|---|---|
| Público | Ilimitados en los ejecutores estándar | — |
| Privado, plan gratuito | 2.000 al mes | ~20 min por ejecución completa de CI (los trabajos corren en paralelo y cada uno suma) → ~100 PR o push al mes |
| Privado con GitHub Pro (gratis con el paquete de estudiantes) | 3.000 al mes | ~150 al mes |

Para ahorrar minutos en un repositorio privado: cancelar ejecuciones viejas
de la misma rama (ya configurado con `concurrency`) y correr el E2E de la app
solo en PR y en `main`.

---

## 11. Prueba de humo (después de cada despliegue)

| Verificación | Espera |
|---|---|
| `ping()` responde | OK |
| `estado_mercado()` responde y el calendario tiene los próximos 10 días | OK |
| `ENTORNO=mvp` y ningún `PROVEEDOR_*` simulado | OK (CB-91) |
| `auth.proveedores_permitidos = ["google"]` | OK (CB-92) |
| Cuenta de Alpaca paper accesible (solo lectura) | OK |
| Salud de integraciones sin `caido` | OK o alerta |
| Configuración de decisión y prompt de contexto activos | Exactamente uno de cada uno |
