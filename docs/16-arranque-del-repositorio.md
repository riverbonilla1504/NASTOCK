# 16 · Arranque del repositorio

Todo lo que hay que hacer **antes de escribir la primera línea de código**:
crear el repositorio, conectar los servicios, cargar los secretos, preparar
GitHub y dejar anotado el backlog.

---

## 1. Pasar este paquete al repositorio nuevo

Este paquete (la carpeta `repo-nuevo/` del repositorio v2) contiene la raíz
completa del repositorio nuevo: `CLAUDE.md`, `README.md`, `docs/`,
`.github/`, `scripts/`, `.gitignore`, `.gitattributes` y `.env.example`.

```bash
gh repo create <dueño>/ritech-inversiones --public --clone --description "Plataforma de inversión asistida por IA · RiTech SAS (MVP)"
cp -a ritech-sas-inversiones/repo-nuevo/. ritech-inversiones/
cd ritech-inversiones
git add -A
git update-index --chmod=+x scripts/verificar.sh scripts/github/preparar-github.sh
git commit -m "Especificación v3.1, reglas para agentes, CI/CD y plantillas"
git push -u origin main
```

(`--public` o `--private` según §2.)

---

## 2. Decisiones antes de crear el repositorio

| Tema | Público (plan gratuito) | Privado (plan gratuito) | Privado con GitHub Pro |
|---|---|---|---|
| Wiki | ✅ | ❌ (requiere plan pago) | ✅ |
| Reglas de protección de rama (exigir CI verde para integrar) | ✅ | ❌ | ✅ |
| Minutos de Actions | Ilimitados | 2.000 al mes | 3.000 al mes |
| GitHub Projects | ✅ | ✅ | ✅ |
| Código y documentación visibles para cualquiera | Sí | No | No |
| Costo | 0 | 0 | 0 con el **GitHub Student Developer Pack**; si no, pago |

**Recomendación**: repositorio **público** si RiTech acepta que el código y
la especificación sean visibles (los secretos nunca están en el repositorio);
si no, **privado con GitHub Pro** a través del paquete de estudiantes. Un
privado en plan gratuito pierde la wiki y la protección de rama. Pregunta
abierta: Q-18.

---

## 3. Cuentas y conexiones

Todas gratuitas salvo DeepSeek y TypeSafe (pago por uso).

### 3.1 GitHub

- [ ] Repositorio creado (§1) y wiki habilitada: `gh repo edit --enable-wiki`.
- [ ] **Primera página de la wiki creada a mano** (una sola vez, desde la pestaña Wiki: cualquier texto). Sin ella, `wiki.yml` no puede publicar.
- [ ] `gh auth refresh -s project` (permiso para GitHub Projects).
- [ ] `scripts/github/preparar-github.sh` ejecutado (§5).
- [ ] Secretos y variables cargados (§4).
- [ ] Dependabot activo (ya configurado en `.github/dependabot.yml`).

### 3.2 Supabase

- [ ] Organización y proyecto **`ritech-mvp`** (plan gratuito), región Este de EE. UU. (Q-10). Guardar la contraseña de la base de datos.
- [ ] (Opcional) segundo proyecto **`ritech-demo`** para demostraciones con proveedores simulados.
- [ ] Llaves de API del proyecto: la **publicable** (va en la app) y la **secreta** (solo Edge Functions; Supabase la inyecta sola).
- [ ] Token de acceso personal para la CLI y CI (`SUPABASE_ACCESS_TOKEN`).
- [ ] En local: `supabase login` y `supabase link --project-ref <ref>`.
- [ ] Auth → Providers: Google habilitado (§3.3); **correo deshabilitado**. Auth → URL Configuration. Duración del JWT: 900 s. Hooks registrados cuando existan las migraciones (04 §3).
- [ ] Vault (una vez, por SQL): `select vault.create_secret('https://<ref>.supabase.co/functions/v1', 'url_funciones');` y `select vault.create_secret('<secreto aleatorio>', 'secreto_interno');`
- [ ] Extensiones `pg_cron`, `pg_net`, `pgmq`: las activan las migraciones de E-01.

### 3.3 Google Cloud + Firebase (un solo proyecto)

Un mismo proyecto de Google Cloud sirve para OAuth y Firebase.

- [ ] Proyecto de Google Cloud dentro de la organización de Workspace de RiTech (o, si no hay organización, pantalla **Externa en modo prueba**: 04 §1).
- [ ] Pantalla de consentimiento (Interna), alcances `openid`, `email`, `profile`.
- [ ] Clientes OAuth: **Web** (redirección `https://<ref>.supabase.co/auth/v1/callback`) y **Android** (paquete `com.ritech.inversiones` + SHA-1 de las llaves debug y release).
- [ ] Firebase agregado al mismo proyecto, plan **Spark** (gratis): app Android y app Web.
- [ ] Cloud Messaging habilitado; cuenta de servicio con permiso de envío → `FCM_CUENTA_SERVICIO`.
- [ ] Hosting habilitado (sitio web de la app).
- [ ] App Distribution: grupo de testers `ritech-equipo` con los correos del equipo.
- [ ] Crashlytics habilitado.
- [ ] Cuenta de servicio para CI con roles de Hosting y App Distribution → `FIREBASE_SERVICE_ACCOUNT`.
- [ ] Llave de firma de Android (keystore) generada y guardada fuera del repositorio → secretos `ANDROID_*`.

### 3.4 Alpaca

- [ ] Cuenta y **cuenta paper**; reiniciarla con el monto del fondo (p. ej. USD 10.000).
- [ ] Par de llaves de la cuenta paper.
- [ ] Verificar acceso a noticias (si responde 403, ver Q-19):

```bash
curl -s -H "APCA-API-KEY-ID: $ALPACA_KEY_ID" -H "APCA-API-SECRET-KEY: $ALPACA_SECRET_KEY" \
  "https://data.alpaca.markets/v1beta1/news?symbols=AAPL&limit=1"
```

### 3.5 DeepSeek

- [ ] Cuenta en la plataforma de DeepSeek, saldo mínimo cargado, llave de API.
- [ ] Verificar:

```bash
curl -s https://api.deepseek.com/chat/completions \
  -H "Authorization: Bearer $DEEPSEEK_API_KEY" -H "Content-Type: application/json" \
  -d '{"model":"deepseek-flash","messages":[{"role":"user","content":"Responde en json: {\"ok\": true}"}],"response_format":{"type":"json_object"}}'
```

### 3.6 TypeSafe JEV

- [ ] Cuenta en `console.typesafe.ai` y **solicitud de acceso anticipado** (hacerlo el primer día: hay lista de espera).
- [ ] Llave de API (`TYPESAFE_API_KEY`).
- [ ] Alternativa mientras llega el acceso: cuenta de Cloudflare con Workers AI, `CLOUDFLARE_ACCOUNT_ID` y un token con permiso de Workers AI (`JEV_PROVEEDOR=cloudflare`).
- [ ] Verificar:

```bash
curl -s -X POST https://api.typesafe.ai/v1/systemone \
  -H "Authorization: Bearer $TYPESAFE_API_KEY" -H "Content-Type: application/json" \
  -d '{"state":"Quick connectivity test.","model":"jev-1.13.0","questions":{"is_test":{"type":"noul","instructions":"Is this a test message?"}}}'
```

### 3.7 Herramientas locales

| Herramienta | Para qué |
|---|---|
| Flutter (canal estable) y Android Studio (SDK de Android, Java 17) | App |
| Docker Desktop | Supabase local |
| Supabase CLI | Base de datos, funciones, pruebas |
| Deno 2 | Edge Functions y E2E de backend |
| Python 3.12+ | `scripts/verificar_docs.py`, `scripts/publicar_wiki.py` |
| Google Chrome + chromedriver | E2E de la app |
| GitHub CLI (`gh`) | Backlog, proyecto, secretos |
| Node LTS + `firebase-tools` | Despliegue manual de hosting o distribución, si hace falta |
| GPG | Descifrar respaldos |

### 3.8 Claude Code

- [ ] `CLAUDE.md` en la raíz (ya incluido): Claude lo lee al empezar cada sesión.
- [ ] Skill de TypeSafe para que el agente conozca la API de JEV:
  `claude plugin marketplace add typesafe-ai/skills` y
  `claude plugin install typesafe@typesafe-ai`.
- [ ] (Opcional) servidor MCP de Supabase en **modo solo lectura** y limitado
  al proyecto, para consultar esquema y registros. Nunca con permisos de
  escritura sobre la nube: los cambios van por migraciones.
- [ ] `gh` autenticado en la máquina, para que el agente pueda leer y
  actualizar issues.

---

## 4. Secretos y variables

### 4.1 GitHub Actions

| Nombre | Tipo | De dónde sale | Lo usa |
|---|---|---|---|
| `SUPABASE_PROJECT_REF` | Variable | Panel de Supabase | despliegue, mantenimiento |
| `SUPABASE_URL` | Variable | Panel de Supabase | despliegue (app), mantenimiento |
| `SUPABASE_PUBLISHABLE_KEY` | Variable | Panel de Supabase | despliegue (app), mantenimiento |
| `GOOGLE_WEB_CLIENT_ID` | Variable | Google Cloud | despliegue (app) |
| `FIREBASE_PROJECT_ID`, `FIREBASE_ANDROID_APP_ID` | Variable | Firebase | despliegue |
| `SUPABASE_ACCESS_TOKEN` | Secreto | Cuenta de Supabase | despliegue |
| `SUPABASE_DB_PASSWORD` | Secreto | Creación del proyecto | despliegue |
| `SUPABASE_DB_URL` | Secreto | Panel de Supabase (cadena de conexión) | respaldo |
| `ALPACA_KEY_ID`, `ALPACA_SECRET_KEY` | Secreto | Alpaca (paper) | despliegue (→ funciones), prueba semanal |
| `DEEPSEEK_API_KEY` | Secreto | DeepSeek | despliegue (→ funciones), prueba semanal |
| `TYPESAFE_API_KEY` (o `CLOUDFLARE_ACCOUNT_ID` + `CLOUDFLARE_API_TOKEN`) | Secreto | TypeSafe / Cloudflare | despliegue (→ funciones), prueba semanal |
| `FCM_CUENTA_SERVICIO` | Secreto | Firebase (JSON) | despliegue (→ funciones) |
| `SECRETO_INTERNO` | Secreto | Aleatorio (el mismo que en Vault) | despliegue (→ funciones) |
| `FIREBASE_SERVICE_ACCOUNT` | Secreto | Firebase (JSON) | despliegue (hosting, distribución) |
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | Secreto | Llave de firma | despliegue (APK) |
| `RESPALDO_CLAVE_GPG` | Secreto | Aleatoria (guardar copia fuera de GitHub) | respaldo |

Carga: `gh variable set NOMBRE --body "valor"` y `gh secret set NOMBRE`
(pide el valor sin mostrarlo).

### 4.2 Secretos de las Edge Functions del proyecto MVP

Los sincroniza `despliegue.yml` desde los secretos de GitHub en cada
despliegue: `ENTORNO=mvp`, `PROVEEDOR_*` reales, `ALPACA_*`, `DEEPSEEK_*`,
`TYPESAFE_API_KEY` o los de Cloudflare, `JEV_PROVEEDOR`,
`FCM_CUENTA_SERVICIO`, `SECRETO_INTERNO`.

### 4.3 Local

Copiar `.env.example` a `.env` (ignorado por git). Con los valores por
defecto todo es simulado y no hace falta ninguna llave.

---

## 5. Preparar GitHub con `gh`

`scripts/github/preparar-github.sh <dueño>/<repo>` crea, de forma
idempotente (se puede correr varias veces):

| Qué | Detalle |
|---|---|
| Etiquetas | `historia`, `epica`, `tarea-tecnica`, `error`, `documentacion`, `bloqueada`, `prioridad-alta/media/baja`, una por épica (`E-01` … `E-13`) y una por módulo (`M-01` … `M-20`) |
| Hitos | Uno por entrega (`R1 · Ver el mercado en vivo` … `R6 · Medir y mejorar`) |
| Proyecto | "RiTech SAS · MVP" enlazado al repositorio, con campos `Épica`, `Entrega`, `Prioridad`, `Módulos` y `Estimación` |

Pasos manuales después del script (la CLI no los permite):

- En el proyecto, cambiar las opciones del campo **Status** a: `Backlog`,
  `Listo`, `En curso`, `En revisión`, `Hecho`, y crear las vistas Tablero (por
  Status), Por entrega (agrupada por `Entrega`) y Por épica.
- Si el repositorio es público o tiene Pro: regla de protección de `main`
  que exija los trabajos de `ci.yml` y un PR para integrar.

---

## 6. PENDIENTE: crear el backlog en GitHub

> **Esto es lo siguiente que hay que hacer en el repositorio nuevo.** El
> backlog completo (épicas e historias de usuario) se crea **como issues con
> GitHub CLI**, a partir de esta especificación, se agrega al proyecto, se
> asigna y se organiza por entregas. La documentación se publica en la wiki.

### 6.1 Qué hay que crear

1. **Épicas** E-01 a E-13 como issues con el formulario `epica.yml`
   (etiquetas `epica` + `E-xx`), a partir de [14 §2](14-mapa-para-backlog.md#2-épicas).
2. **Historias de usuario** de cada épica con el formulario
   `historia-de-usuario.yml`, citando reglas, casos borde, módulos y
   escenario E2E ([14 §5](14-mapa-para-backlog.md#5-plantilla-de-historia-de-usuario)).
   Empezar por las de **R1** con todo el detalle; las de entregas posteriores
   pueden quedar más gruesas y refinarse al acercarse.
3. **Tareas técnicas** de E-01 (arranque, CI/CD, simulados, E2E).
4. Cada historia como **sub-issue** de su épica.
5. Todo agregado al **proyecto**, con `Épica`, `Entrega`, `Prioridad` y
   `Módulos`, y con su **hito**.
6. **Asignaciones** según el equipo.

### 6.2 Comandos de referencia

```bash
R=<dueño>/<repo>; OWNER=<dueño>; P=<número del proyecto>

# Épica
gh issue create -R $R --title "E-07 · Sugerencias y decisiones" \
  --body-file backlog/epicas/E-07.md --label epica --label E-07

# Historia (el cuerpo sigue el formulario historia-de-usuario.yml)
gh issue create -R $R --title "Aprobar una sugerencia de mi cupo" \
  --body-file backlog/historias/HU-042.md \
  --label historia --label E-07 --label M-09 --label M-08 \
  --milestone "R4 · Decidir y operar en paper" --assignee <usuario>

# Historia como sub-issue de su épica (usa el id interno, no el número)
HU_ID=$(gh api repos/$R/issues/<n_historia> --jq .id)
gh api -X POST repos/$R/issues/<n_epica>/sub_issues -F sub_issue_id=$HU_ID

# Agregar al proyecto y fijar campos
gh project item-add $P --owner $OWNER --url https://github.com/$R/issues/<n>
gh project field-list $P --owner $OWNER --format json      # ids de campos y opciones
gh project item-list  $P --owner $OWNER --format json      # id del ítem
gh project item-edit --project-id <PROJECT_ID> --id <ITEM_ID> \
  --field-id <FIELD_ID_ENTREGA> --single-select-option-id <OPCION_R4>

# Asignar después
gh issue edit <n> -R $R --add-assignee <usuario>
```

Conviene escribir los cuerpos en archivos `backlog/**/*.md` y crear los
issues con un pequeño script que lea esa carpeta, para poder revisar el
backlog completo en un PR antes de publicarlo.

### 6.3 Documentación en la wiki

- La fuente de verdad es `docs/` en el repositorio.
- `wiki.yml` publica `docs/` en la wiki en cada cambio a `main` (requiere la
  primera página creada a mano, §3.1). **Nunca se edita la wiki
  directamente**: se perdería en la siguiente publicación.
- Enlazar la wiki desde la descripción del proyecto de GitHub.

---

## 7. Orden sugerido del día 1

1. Decidir visibilidad (§2) → crear el repositorio → copiar el paquete →
   primer push. `ci.yml` corre y valida la documentación.
2. Solicitar acceso a TypeSafe JEV (tiene lista de espera).
3. Habilitar la wiki y crear la primera página → la wiki se publica sola.
4. `gh auth refresh -s project` → `scripts/github/preparar-github.sh` →
   pasos manuales del proyecto.
5. Crear cuentas y proyectos: Supabase, Google Cloud + Firebase, Alpaca,
   DeepSeek (y Cloudflare si JEV demora).
6. Cargar secretos y variables (§4) y probar las conexiones con los `curl`
   de §3.
7. Abrir el repositorio con Claude Code e instalar la skill de TypeSafe.
8. **Crear el backlog** (§6).
9. Empezar E-01. Los trabajos de CI/CD se activan solos a medida que aparece
   el código.

---

## 8. Qué no hacer

- Operar desde el panel web de Alpaca (la conciliación lo detecta como
  incidente).
- Editar la base de datos de la nube a mano o la wiki directamente.
- Poner llaves en la app, en el repositorio o en issues.
- Habilitar correo + contraseña o proveedores simulados en la nube.
- Agregar servicios pagos sin aprobación (el MVP solo paga DeepSeek y JEV).
