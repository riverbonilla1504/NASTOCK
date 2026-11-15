#!/usr/bin/env bash
# Sirve las Edge Functions en local con los proveedores simulados (sin llaves).
# Necesita la base local arriba (`supabase start`). Se queda corriendo: déjalo
# en su propia terminal y detenlo con Ctrl+C.
#
#   scripts/local/funciones.sh
#
# Igual que scripts/verificar.sh: a supabase/functions/.env.e2e le suma el
# secreto interno de prueba que siembra supabase/seed.sql en Vault (solo local
# y CI), en un archivo temporal que git ignora.
set -euo pipefail
cd "$(dirname "$0")/../.."

mkdir -p supabase/.temp
{ cat supabase/functions/.env.e2e; printf '\nSECRETO_INTERNO=solo-local-no-es-secreto\n'; } \
  > supabase/.temp/env.e2e

exec supabase functions serve --env-file supabase/.temp/env.e2e
