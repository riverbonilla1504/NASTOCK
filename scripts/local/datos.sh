#!/usr/bin/env bash
# Llena la base LOCAL con datos para ver la app funcionando: calendario y
# barras históricas del proveedor simulado, la IA encendida y un ciclo del
# agente para que Oportunidades tenga contenido.
#
#   scripts/local/datos.sh
#
# Necesita la base local (`supabase start`) y las funciones corriendo
# (`scripts/local/funciones.sh`, en otra terminal). Solo toca la base local:
# nunca la nube (CLAUDE.md, "Nunca editar la base de datos de la nube a mano").
set -euo pipefail
cd "$(dirname "$0")/../.."

FUNCIONES="http://127.0.0.1:54321/functions/v1"
SECRETO="solo-local-no-es-secreto"   # el de supabase/seed.sql: solo existe en local y CI
CONTENEDOR="supabase_db_$(sed -n 's/^project_id *= *"\(.*\)"/\1/p' supabase/config.toml)"

paso() { printf '\n\033[1m▶ %s\033[0m\n' "$1"; }
ok()   { printf '\033[32m✔ %s\033[0m\n' "$1"; }
despertar() {
  curl -sS -X POST "$FUNCIONES/$1" -H "Content-Type: application/json" \
    -H "x-secreto-interno: $SECRETO" -d '{}'
}

if ! docker inspect "$CONTENEDOR" >/dev/null 2>&1; then
  echo "No encuentro la base local ($CONTENEDOR). Corre antes: supabase start" >&2
  exit 1
fi

paso "Esperando a las funciones (scripts/local/funciones.sh)"
for _ in $(seq 1 60); do
  codigo=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$FUNCIONES/calendario-mercado" || true)
  [[ "$codigo" == "401" ]] && break
  sleep 2
done
if [[ "$codigo" != "401" ]]; then
  echo "Las funciones no responden. Córrelas en otra terminal: scripts/local/funciones.sh" >&2
  exit 1
fi
ok "funciones arriba"

paso "Calendario y barras históricas (proveedor simulado)"
despertar calendario-mercado >/dev/null
ok "$(docker exec "$CONTENEDOR" psql -U postgres -tAc \
  "select count(*) || ' barras diarias' from public.barras_diarias")"

paso "IA encendida (solo en la base local)"
# En la app real el Administrador la enciende en Parámetros e interruptores, y
# exige un aporte confirmado (RN-11). Aquí se enciende directo para la prueba.
docker exec "$CONTENEDOR" psql -U postgres -qc "update public.fondos set ia_activa = true"
ok "ia_activa encendido"

paso "Un ciclo del agente para Oportunidades"
despertar agente
echo
ok "listo: recarga la app"
