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
limpiar() { for p in "${PIDS[@]:-}"; do [[ -n "$p" ]] && kill "$p" 2>/dev/null || true; done; }
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
if [[ -d lib ]] && grep -rqiE "service_role|sb_secret_" lib; then
  echo "ERROR: la app menciona la llave secreta de Supabase"; exit 1
fi
if git ls-files | grep -qE '(^|/)\.env$'; then
  echo "ERROR: hay un archivo .env versionado"; exit 1
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
    deno fmt --check supabase/functions
    deno lint supabase/functions
    deno test --allow-all supabase/functions
  fi
  ok "base de datos y funciones"

  # 5. E2E de backend -----------------------------------------------------------
  if [[ -d supabase/tests/e2e ]]; then
    paso "E2E de backend (proveedores simulados)"
    supabase functions serve --env-file supabase/functions/.env.e2e >/tmp/funciones-e2e.log 2>&1 &
    PIDS+=($!)
    # Espera a que el servidor de funciones responda. E-01 debe reemplazar esta
    # espera genérica por una consulta a una función de salud con respuesta 200.
    for _ in $(seq 1 60); do
      grep -q "Serving functions" /tmp/funciones-e2e.log 2>/dev/null && break
      sleep 1
    done
    eval "$(supabase status -o env | sed 's/^/export /')"
    deno test --allow-all supabase/tests/e2e
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
