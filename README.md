# RiTech SAS · Plataforma de inversión asistida por IA (MVP)

Fondo de inversión de RiTech SAS en **paper trading** (dinero ficticio),
dividido en tres bolsillos (Reserva 50 %, Arriesgadas 25 %, Usuarios 25 %),
donde una IA analiza el NASDAQ-100 y recomienda, y **una persona siempre
decide**.

- **IA principal** (código, Edge Function `agente`): verifica los datos del
  mercado, calcula métricas y el puntaje, consulta a JEV y explica.
- **JEV** (TypeSafe AI): responde preguntas cerradas sobre cada candidata con
  probabilidades calibradas.
- **Tres roles**: Usuario (opera su cupo), Analista (supervisa) y
  Administrador (gobierna el dinero, las cuentas y las reglas).

**Stack**: Flutter (Android y web) · Supabase (Postgres, Auth, Realtime, Edge
Functions, `pg_cron`) · Alpaca paper · JEV · Firebase · GitHub Actions. Todo
en planes gratuitos, salvo JEV.

Se construyó con **desarrollo guiado por especificaciones** (SDD) y GitHub
**spec-kit**: la especificación vive en [`docs/`](docs/README.md), la
constitución en [`.specify/memory/constitution.md`](.specify/memory/constitution.md)
y cada historia tiene su `spec.md`, `plan.md` y `tasks.md` en [`specs/`](specs/).

## Estado

El **MVP corto** funciona de punta a punta: entrar con Google por invitación,
administrar invitaciones, ver el mercado en vivo, el fondo y los cupos, la IA
en Oportunidades y operar en paper con órdenes manuales. Lo que falta, los
accesos y cómo continuar están en
**[docs/18 · Estado y traspaso](docs/18-estado-y-traspaso.md)**.

## Requisitos

| Herramienta | Versión |
|---|---|
| Flutter | **3.47.9** (la misma de la CI, EC-038), con Java 17 y el SDK de Android |
| Docker Desktop | Para Supabase local |
| Supabase CLI | 2.122.0 |
| Deno | 2.x |
| Python | 3.12 o más |
| Google Chrome y chromedriver | E2E de la app |

Detalle en [docs/16 §3.7](docs/16-arranque-del-repositorio.md#37-herramientas-locales).

**En Windows**, los comandos de abajo van en **Git Bash** (viene con Git para
Windows), no en PowerShell ni en CMD: los scripts son de Bash.

## Instalación y ejecución en local (todo simulado, sin llaves)

No hace falta ninguna cuenta ni llave: el mercado, el broker y JEV son
simulados. Probado desde un clon limpio el 2026-11-15.

**1. Una sola vez**, con **Docker Desktop abierto**:

```bash
flutter pub get
supabase start                # base local en Docker (la primera vez baja imágenes: tarda)
supabase db reset             # migraciones + usuarios de prueba (supabase/seed.sql)
```

**2. Terminal A**: las funciones, con los proveedores simulados. Se queda
corriendo; se detiene con Ctrl+C.

```bash
scripts/local/funciones.sh
```

**3. Terminal B**: los datos para ver la app con contenido (calendario,
barras históricas, la IA encendida y un ciclo del agente). Tarda unos
segundos. Sin este paso la app abre, pero se ve vacía: sin precios ni
Oportunidades.

```bash
scripts/local/datos.sh
```

**4. Terminal B**: la app en Chrome contra la base local. La primera carga
tarda unos 20 segundos.

```bash
scripts/local/app.sh
```

**5. Entrar** con el formulario "Solo pruebas" de la pantalla de ingreso (no
con Google): `admin@prueba.local`, `analista1@prueba.local` o
`usuario1@prueba.local`, con la contraseña de prueba de `supabase/seed.sql`.

Qué esperar:
- Con la bolsa cerrada (noches y fines de semana), Mercado muestra el precio
  del último cierre y la cuenta regresiva a la apertura; la gráfica 1D dice
  "Sin datos del día". Los precios en vivo solo llegan con el mercado abierto.
- Oportunidades muestra lo que evaluó la IA, con su nivel y lo que respondió
  JEV (simulado).
- El emulador de Android se usa contra la nube, no contra la base local (esta
  va por HTTP sin cifrar).
- `supabase db reset` deja la base como recién creada: después hay que volver
  a correr `scripts/local/datos.sh`.

## Variables de entorno

- En local **no hace falta crear ningún archivo**: los scripts usan
  `supabase/functions/.env.e2e` y leen la llave local de `supabase status`.
- [`.env.example`](.env.example): referencia de los proveedores (`simulado` o
  el real) y las llaves de Alpaca y JEV. Sirve para saber qué variables usa la
  nube; ningún script lee `.env`.
- [`supabase/functions/.env.e2e`](supabase/functions/.env.e2e): lo que usan
  las funciones en local y en la CI, sin secretos.
- La app recibe `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` y
  `GOOGLE_WEB_CLIENT_ID` por `--dart-define`. Para la nube se pasan con
  `--dart-define-from-file=<archivo>.json`, que **no** se versiona.
- Los secretos de la nube y de GitHub Actions se listan en
  [docs/16 §4](docs/16-arranque-del-repositorio.md); nunca van al repositorio.

## Pruebas

```bash
scripts/verificar.sh          # todo lo que corre la CI, incluidos los E2E
scripts/verificar.sh --rapido # sin el E2E de la app (solo para iterar)
```

Resultados y casos probados: **[docs/19 · Registro de pruebas](docs/19-registro-de-pruebas.md)**.

## Demostración del flujo principal

1. El **Administrador** entra con Google, invita a un empleado (Usuarios e
   invitaciones) y registra un aporte en **Capital**; la conciliación lo
   confirma y lo reparte 50/25/25.
2. En **Cupos** le asigna un cupo al empleado y en **Parámetros e
   interruptores** enciende la IA.
3. El **Usuario** entra con su Gmail invitado: ve el **Mercado** en vivo y,
   en **Oportunidades**, lo que la IA evaluó, con su nivel (favorable,
   vigilar, desfavorable), las probabilidades de JEV y la explicación.
4. Desde el detalle de una acción crea una **orden manual**; el motor de
   políticas la valida, va a Alpaca paper y, al llenarse, aparece en
   **Mi cupo** con su posición.

## Decisiones y pendientes

- Decisiones y su historial: [docs/13](docs/13-decisiones-pendientes-riesgos.md).
  El alcance de la entrega y los **Non-Goals** están en **D-73**.
- Pendientes, limitaciones y accesos: [docs/18](docs/18-estado-y-traspaso.md).
- Errores ya resueltos: [docs/errores-conocidos.md](docs/errores-conocidos.md).

## Documentación

| Para… | Lee |
|---|---|
| Entender el producto | [01 Visión](docs/01-vision-y-alcance.md) · [02 Negocio](docs/02-logica-de-negocio.md) · [07 IA](docs/07-agente-ia.md) |
| Continuar el proyecto | [18 Estado y traspaso](docs/18-estado-y-traspaso.md) · [`CLAUDE.md`](CLAUDE.md) · [17 Mapa de módulos](docs/17-mapa-de-modulos.md) |
| Conectar servicios | [16 Arranque](docs/16-arranque-del-repositorio.md) |
| Pruebas y CI/CD | [15 Calidad](docs/15-calidad-pruebas-y-ci-cd.md) · [19 Registro de pruebas](docs/19-registro-de-pruebas.md) |
