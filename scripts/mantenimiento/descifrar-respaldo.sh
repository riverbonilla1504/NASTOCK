#!/usr/bin/env bash
# Abre un respaldo cifrado de `respaldar.sh` (docs/11 §7, FR-010).
#
#   scripts/mantenimiento/descifrar-respaldo.sh respaldo-AAAAMMDD.tar.gz.gpg [carpeta]
#
# Pide la clave (la de RESPALDO_CLAVE_GPG) sin mostrarla; si ya está en la variable de
# entorno RESPALDO_CLAVE_GPG, la usa. Deja `esquema.sql` y `datos.sql` en `carpeta`
# (por defecto `respaldo-descifrado/`, que git ignora). Son datos reales: no los subas
# a ningún sitio y bórralos al terminar. Necesita `gpg` y `tar`.
set -euo pipefail
umask 077

archivo="${1:?Uso: descifrar-respaldo.sh respaldo-AAAAMMDD.tar.gz.gpg [carpeta]}"
destino="${2:-respaldo-descifrado}"
[[ -f "$archivo" ]] || { echo "ERROR: no existe $archivo" >&2; exit 1; }

if [[ -z "${RESPALDO_CLAVE_GPG:-}" ]]; then
  read -rsp "Clave del respaldo (RESPALDO_CLAVE_GPG): " RESPALDO_CLAVE_GPG
  echo
fi
clave="$(printf '%s' "$RESPALDO_CLAVE_GPG" | tr -d '\r\n')"

mkdir -p "$destino"
gpg --batch --quiet --pinentry-mode loopback --passphrase-fd 3 --decrypt "$archivo" 3<<<"$clave" \
  | tar -xz -C "$destino"
echo "Listo en $destino/: $(cd "$destino" && ls esquema.sql datos.sql | tr '\n' ' ')"
