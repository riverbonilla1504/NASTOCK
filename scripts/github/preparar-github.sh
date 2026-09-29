#!/usr/bin/env bash
# Prepara GitHub para el backlog: etiquetas, hitos (entregas) y el proyecto de
# GitHub Projects con sus campos. Es idempotente: se puede correr varias veces.
#
# Uso:       scripts/github/preparar-github.sh <dueño>/<repo>
# Requisito: gh autenticado con permiso de proyectos:  gh auth refresh -s project
#
# Detalle y pasos manuales posteriores: docs/16-arranque-del-repositorio.md §5.
set -euo pipefail

REPO="${1:?Uso: $0 <dueño>/<repo>}"
OWNER="${REPO%%/*}"
TITULO_PROYECTO="RiTech SAS · MVP"

etiqueta() {
  gh label create "$1" --repo "$REPO" --color "$2" --description "$3" --force >/dev/null
  echo "  etiqueta: $1"
}

hito() {
  local titulo="$1" descripcion="$2"
  if gh api "repos/$REPO/milestones?state=all&per_page=100" --jq '.[].title' | grep -Fxq "$titulo"; then
    echo "  hito ya existe: $titulo"
  else
    gh api "repos/$REPO/milestones" -f title="$titulo" -f description="$descripcion" >/dev/null
    echo "  hito creado: $titulo"
  fi
}

echo "Etiquetas de tipo y prioridad…"
etiqueta historia        1D76DB "Historia de usuario"
etiqueta epica           5319E7 "Épica (agrupa historias como sub-issues)"
etiqueta tarea-tecnica   0E8A16 "Tarea técnica sin valor directo para el usuario"
etiqueta error           D73A4A "Algo no funciona como dice docs/"
etiqueta documentacion   0075CA "Cambio en docs/ (fuente de verdad)"
etiqueta bloqueada       B60205 "Espera una decisión o una dependencia"
etiqueta prioridad-alta  E99695 "Prioridad alta"
etiqueta prioridad-media FBCA04 "Prioridad media"
etiqueta prioridad-baja  C2E0C6 "Prioridad baja"

echo "Etiquetas de épicas (docs/14 §2)…"
for n in $(seq -w 1 13); do etiqueta "E-$n" D4C5F9 "Épica E-$n"; done

echo "Etiquetas de módulos (docs/17)…"
for n in $(seq -w 1 20); do etiqueta "M-$n" C5DEF5 "Módulo M-$n"; done

echo "Hitos (entregas por valor, docs/14 §4)…"
hito "R1 · Ver el mercado en vivo"       "Ingreso con Google por invitación y NASDAQ-100 en vivo, publicado en web y Android."
hito "R2 · El fondo existe"              "Capital, reparto 50/25/25, cupos y bitácora."
hito "R3 · La IA analiza"                "Contexto (DeepSeek) + decisión (JEV) visibles en Oportunidades, con explicación."
hito "R4 · Decidir y operar en paper"    "Sugerencias, aprobaciones, órdenes manuales, ejecución y protecciones en Alpaca paper."
hito "R5 · Protegido y avisado"          "Push, conciliación con pausa automática, freno de emergencia, alertas."
hito "R6 · Medir y mejorar"              "Calibración y modo sombra, rebalanceo, liquidación, reportes, endurecimiento."

echo "Proyecto de GitHub…"
NUM="$(gh project list --owner "$OWNER" --format json \
  --jq ".projects[] | select(.title == \"$TITULO_PROYECTO\") | .number" | head -n1)"
if [[ -z "$NUM" ]]; then
  NUM="$(gh project create --owner "$OWNER" --title "$TITULO_PROYECTO" --format json --jq '.number')"
  echo "  proyecto creado: #$NUM"
else
  echo "  proyecto ya existe: #$NUM"
fi
gh project link "$NUM" --owner "$OWNER" --repo "$REPO" >/dev/null 2>&1 \
  && echo "  proyecto enlazado al repositorio" \
  || echo "  (el proyecto ya estaba enlazado)"

campo() {
  local nombre="$1"; shift
  if gh project field-list "$NUM" --owner "$OWNER" --format json --jq '.fields[].name' | grep -Fxq "$nombre"; then
    echo "  campo ya existe: $nombre"
  else
    gh project field-create "$NUM" --owner "$OWNER" --name "$nombre" "$@" >/dev/null
    echo "  campo creado: $nombre"
  fi
}

EPICAS="$(seq -w 1 13 | sed 's/^/E-/' | paste -sd, -)"
campo "Épica"      --data-type SINGLE_SELECT --single-select-options "$EPICAS"
campo "Entrega"    --data-type SINGLE_SELECT --single-select-options "R1,R2,R3,R4,R5,R6"
campo "Prioridad"  --data-type SINGLE_SELECT --single-select-options "Alta,Media,Baja"
campo "Módulos"    --data-type TEXT
campo "Estimación" --data-type NUMBER

cat <<EOF

Listo. Pasos manuales (la CLI no los permite), ver docs/16 §5:
  1. En el proyecto #$NUM, cambiar las opciones de "Status" a:
     Backlog, Listo, En curso, En revisión, Hecho.
  2. Crear las vistas: Tablero (por Status), Por entrega, Por épica.
  3. Si el repositorio es público o tiene Pro: proteger "main" exigiendo CI.
Siguiente: crear el backlog (docs/16 §6).
EOF
