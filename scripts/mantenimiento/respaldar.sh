#!/usr/bin/env bash
# Respaldo cifrado de la base del proyecto MVP (docs/11 §7, D-55, FR-010).
#
# El plan gratuito de Supabase no respalda, así que `mantenimiento.yml` corre esto a
# diario: vuelca el esquema y los datos (`public` y `auth`), los empaca y los cifra con
# GPG (AES-256, clave simétrica). El archivo resultante es lo único que sale del
# ejecutor; si el repositorio es público, los artefactos pueden verse, por eso va cifrado.
#
#   SUPABASE_DB_URL=… RESPALDO_CLAVE_GPG=… scripts/mantenimiento/respaldar.sh [carpeta]
#
# Deja `respaldo-AAAAMMDD.tar.gz.gpg` en `carpeta` (por defecto, la actual). Para
# abrirlo: scripts/mantenimiento/descifrar-respaldo.sh. Necesita `supabase` (la misma
# versión que local), `gpg`, `tar` y Docker (la CLI corre `pg_dump` en un contenedor).
#
# Fuera del volcado quedan los secretos de Vault y los de las Edge Functions: se
# vuelven a cargar desde los secretos de GitHub con `despliegue.yml` (docs/16 §4).
set -euo pipefail
umask 077

: "${SUPABASE_DB_URL:?Falta SUPABASE_DB_URL (cadena de conexión del Session pooler)}"
: "${RESPALDO_CLAVE_GPG:?Falta RESPALDO_CLAVE_GPG}"

destino="${1:-.}"
mkdir -p "$destino"
destino="$(cd "$destino" && pwd)"
archivo="$destino/respaldo-$(date -u +%Y%m%d).tar.gz.gpg"

# Un secreto pegado a mano puede traer salto de línea final; se quita igual aquí y al descifrar.
clave="$(printf '%s' "$RESPALDO_CLAVE_GPG" | tr -d '\r\n')"
[[ -n "$clave" ]] || { echo "ERROR: RESPALDO_CLAVE_GPG está vacía" >&2; exit 1; }

trabajo="$(mktemp -d)"
trap 'rm -rf "$trabajo"' EXIT

echo "Volcando el esquema…"
supabase db dump --db-url "$SUPABASE_DB_URL" -f "$trabajo/esquema.sql"
echo "Volcando los datos de public y auth…"
supabase db dump --db-url "$SUPABASE_DB_URL" --data-only --schema public,auth -f "$trabajo/datos.sql"

# Un volcado vacío o sin la estructura esperada no es un respaldo: se falla antes de cifrarlo.
[[ -s "$trabajo/esquema.sql" && -s "$trabajo/datos.sql" ]] \
  || { echo "ERROR: el volcado salió vacío" >&2; exit 1; }
grep -q 'CREATE TABLE' "$trabajo/esquema.sql" \
  || { echo "ERROR: el esquema no contiene tablas; el volcado no sirve" >&2; exit 1; }

tar -C "$trabajo" -czf "$trabajo/respaldo.tar.gz" esquema.sql datos.sql

# La clave entra por un descriptor de archivo, no por la línea de comandos.
cifrar() {
  gpg --batch --yes --quiet --pinentry-mode loopback --passphrase-fd 3 \
    --symmetric --cipher-algo AES256 \
    --s2k-mode 3 --s2k-digest-algo SHA512 --s2k-count 65011712 \
    -o "$1" "$trabajo/respaldo.tar.gz" 3<<<"$clave"
}
cifrar "$archivo"

# Comprobación en el mismo ejecutor: con la clave se abre y trae los dos archivos;
# con otra clave no se abre. Así un respaldo ilegible no pasa por bueno.
contenido="$(gpg --batch --quiet --pinentry-mode loopback --passphrase-fd 3 \
  --decrypt "$archivo" 3<<<"$clave" | tar -tz)"
grep -qx 'esquema.sql' <<<"$contenido" && grep -qx 'datos.sql' <<<"$contenido" \
  || { echo "ERROR: el respaldo cifrado no se pudo leer de vuelta" >&2; rm -f "$archivo"; exit 1; }
if gpg --batch --quiet --pinentry-mode loopback --passphrase-fd 3 \
     --decrypt "$archivo" 3<<<"clave-equivocada" >/dev/null 2>&1; then
  echo "ERROR: el respaldo se abrió con una clave equivocada" >&2; rm -f "$archivo"; exit 1
fi

echo "Respaldo listo: $(basename "$archivo") ($(wc -c <"$archivo") bytes)"
