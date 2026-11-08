#!/usr/bin/env bash
# Corre localmente lo mismo que CI. Obligatorio antes de dar un cambio por
# terminado (CLAUDE.md, regla de oro 6).
#
#   scripts/verificar.sh            todo, incluido el E2E de backend y de la app
#   scripts/verificar.sh --rapido   sin el E2E de la app (solo para iterar)
#
# Cada bloque se ejecuta solo si esa parte del proyecto ya existe, así el
# script sirve desde el primer commit (solo documentación).
set -euo pipefail

RAPIDO=false
[[ "${1:-}" == "--rapido" ]] && RAPIDO=true

cd "$(dirname "$0")/.."
RAIZ="$(pwd)"
PIDS=()
limpiar() {
  for p in "${PIDS[@]:-}"; do [[ -n "$p" ]] && kill "$p" 2>/dev/null || true; done
  rm -f "$RAIZ/supabase/.temp/env.e2e"  # copia temporal de .env.e2e con el secreto interno de prueba
}
trap limpiar EXIT

paso() { printf '\n\033[1m▶ %s\033[0m\n' "$1"; }
ok()   { printf '\033[32m✔ %s\033[0m\n' "$1"; }

# 1. Documentación ------------------------------------------------------------
paso "Documentación"
python scripts/verificar_docs.py docs
ok "docs/ consistente"

# 2. Reglas de arquitectura ---------------------------------------------------
paso "Reglas de arquitectura"
if [[ -d supabase/functions ]]; then
  for f in agente contexto-ia opinion-ia; do
    if [[ -d "supabase/functions/$f" ]] && grep -rqE "_shared/broker" "supabase/functions/$f"; then
      echo "ERROR: supabase/functions/$f importa _shared/broker (la IA no ejecuta)"; exit 1
    fi
  done
fi
# Solo _shared/bd.ts importa el cliente de Postgres (D-66): así toda llamada a la base
# pasa por una sola puerta que solo ejecuta funciones de private.
if [[ -d supabase/functions ]] \
  && grep -rnE "(from|import)[[:space:]]*\(?[[:space:]]*[\"'](npm:|jsr:@db/|https://deno\.land/x/)?postgres([@/\"']|$)" \
       --include='*.ts' supabase/functions | grep -v '^supabase/functions/_shared/bd\.ts:'; then
  echo "ERROR: un archivo de supabase/functions, fuera de _shared/bd.ts, importa el cliente de Postgres (D-66)"; exit 1
fi
if [[ -d lib ]] && grep -rqiE "service_role|sb_secret_" lib; then
  echo "ERROR: la app menciona la llave secreta de Supabase"; exit 1
fi
if [[ -d lib ]] && grep -rqE "ALPACA_(KEY_ID|SECRET_KEY)|DEEPSEEK_API_KEY|TYPESAFE_API_KEY|CLOUDFLARE_API_TOKEN|FCM_CUENTA_SERVICIO|SECRETO_INTERNO" lib; then
  echo "ERROR: la app menciona llaves de proveedores o el secreto interno"; exit 1
fi
# HU-004 · CA-4: ningún usuario ni contraseña de administrador en el código. El de la v2 era
# admin@admin.com / 1234; el primer administrador sale de ADMIN_INICIAL_EMAIL (docs/04 §9). Los usuarios
# de prueba de local y CI viven solo en supabase/seed.sql.
if grep -rniE "admin@admin\.com" lib supabase/migrations supabase/functions .github 2>/dev/null; then
  echo "ERROR: hay un usuario de administrador fijo en el código"; exit 1
fi
if [[ -d supabase/migrations ]] && grep -rniE "encrypted_password|crypt[[:space:]]*\(" supabase/migrations; then
  echo "ERROR: una migración guarda una contraseña"; exit 1
fi
if git ls-files | grep -qE '(^|/)\.env$'; then
  echo "ERROR: hay un archivo .env versionado"; exit 1
fi
# El esquema pruebas (reloj, escenarios, push simulados) lo crea solo seed.sql: una
# migración llegaría a la nube con `supabase db push` (docs/15 §3, CB-91).
if [[ -d supabase/migrations ]] && grep -rniE 'create[[:space:]]+(or[[:space:]]+replace[[:space:]]+)?(schema|table|function|view|type|sequence)[[:space:]]+(if[[:space:]]+not[[:space:]]+exists[[:space:]]+)?"?pruebas([^[:alnum:]_]|$)' supabase/migrations; then
  echo "ERROR: una migración crea objetos en el esquema pruebas (solo seed.sql los crea)"; exit 1
fi
ok "arquitectura"

# 3. App Flutter --------------------------------------------------------------
if [[ -f pubspec.yaml ]]; then
  paso "App Flutter"
  flutter pub get
  dart format --output=none --set-exit-if-changed lib test
  flutter analyze
  flutter test
  ok "app"
fi

# 4. Base de datos y funciones ------------------------------------------------
if [[ -f supabase/config.toml ]]; then
  paso "Base de datos y funciones"
  supabase status >/dev/null 2>&1 || supabase start
  supabase db reset
  supabase db lint --level warning --fail-on warning
  supabase test db
  if [[ -d supabase/functions ]]; then
    # Las dependencias de las funciones están en su deno.json, y Deno solo lo
    # encuentra si se ejecuta desde esa carpeta: por eso se le indica aquí.
    DENO_CONFIG=supabase/functions/deno.json
    deno fmt --check --config "$DENO_CONFIG" supabase/functions
    deno lint --config "$DENO_CONFIG" supabase/functions
    deno test --allow-all --config "$DENO_CONFIG" supabase/functions
  fi
  ok "base de datos y funciones"

  # 5. E2E de backend -----------------------------------------------------------
  if [[ -d supabase/tests/e2e ]]; then
    paso "E2E de backend (proveedores simulados)"
    # .env.e2e no lleva secretos (docs/15 §3). Para que las funciones acepten la llamada del
    # E2E se le suma el SECRETO_INTERNO de prueba, el mismo que siembra supabase/seed.sql en
    # Vault (solo local y CI), en un archivo temporal que git ignora.
    export SECRETO_INTERNO="solo-local-no-es-secreto"
    mkdir -p supabase/.temp
    { cat supabase/functions/.env.e2e; printf '\nSECRETO_INTERNO=%s\n' "$SECRETO_INTERNO"; } \
      > supabase/.temp/env.e2e
    supabase functions serve --env-file supabase/.temp/env.e2e >/tmp/funciones-e2e.log 2>&1 &
    PIDS+=($!)
    eval "$(supabase status -o env | sed 's/^/export /')"
    # No hace falta esperar aquí: el propio E2E espera (esperarFunciones) a que las funciones
    # respondan antes de usarlas.
    deno test --allow-all --config supabase/tests/deno.json supabase/tests/e2e
    ok "E2E de backend"
  fi
fi

# 6. E2E de la app ------------------------------------------------------------
if [[ -d integration_test && "$RAPIDO" == false ]]; then
  paso "E2E de la app (Chrome)"
  chromedriver --port=4444 >/tmp/chromedriver.log 2>&1 &
  PIDS+=($!)
  sleep 2
  flutter drive \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/app_test.dart \
    -d web-server \
    --dart-define=MODO_PRUEBAS=true \
    --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
    --dart-define=SUPABASE_PUBLISHABLE_KEY="${ANON_KEY:-${PUBLISHABLE_KEY:-}}"
  ok "E2E de la app"
elif [[ -d integration_test ]]; then
  echo "(--rapido: se omitió el E2E de la app; no sirve para dar el cambio por terminado)"
fi

printf '\n\033[1;32mTodo en verde.\033[0m\n'
