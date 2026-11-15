#!/usr/bin/env bash
# Abre la app en Chrome contra la base LOCAL, con el ingreso por correo de prueba.
#
#   scripts/local/app.sh
#
# Lee la llave publicable de la base local de `supabase status`, así no hay
# que copiarla a mano. No usa ninguna llave de la nube. (El emulador de Android
# se usa contra la nube: la base local va por HTTP sin cifrar.)
set -euo pipefail
cd "$(dirname "$0")/../.."

LLAVE=$(supabase status -o env 2>/dev/null | sed -n 's/^ANON_KEY="\{0,1\}\([^"]*\)"\{0,1\}$/\1/p')
if [[ -z "$LLAVE" ]]; then
  echo "No encuentro la base local. Corre antes: supabase start" >&2
  exit 1
fi

exec flutter run -d chrome \
  --dart-define=MODO_PRUEBAS=true \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$LLAVE"
