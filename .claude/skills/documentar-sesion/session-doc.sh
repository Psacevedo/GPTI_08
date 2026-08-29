#!/usr/bin/env bash
# session-doc.sh — scaffold + validador de docs/sesiones/sesion-<fecha>/
# Subcomandos: new [YYYY-MM-DD]   check [YYYY-MM-DD]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Raíz del repo: git si está disponible, si no, subir 3 niveles desde este script
# (.claude/skills/documentar-sesion/session-doc.sh -> raíz).
if REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)"; then
  :
else
  REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
fi

SESIONES_DIR="$REPO_ROOT/docs/sesiones"
MASTER_INDEX="$SESIONES_DIR/README.md"

cmd="${1:-}"
fecha="${2:-$(date +%F)}"

if [[ ! "$fecha" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "Fecha inválida: '$fecha' (formato esperado YYYY-MM-DD)" >&2
  exit 1
fi

sesion_dir="$SESIONES_DIR/sesion-$fecha"
resumen_file="$sesion_dir/00_RESUMEN_SESION.md"
readme_file="$sesion_dir/README.md"

usage() {
  echo "Uso: $(basename "$0") new [YYYY-MM-DD]" >&2
  echo "     $(basename "$0") check [YYYY-MM-DD]" >&2
  exit 1
}

ensure_master_index() {
  if [[ ! -f "$MASTER_INDEX" ]]; then
    mkdir -p "$SESIONES_DIR"
    cat > "$MASTER_INDEX" <<'EOF'
# Índice de sesiones

Registro de todas las sesiones de trabajo documentadas en este proyecto.
Cada fila enlaza a la carpeta `sesion-<fecha>/` correspondiente.

| Fecha | Carpeta | Resumen |
|---|---|---|
EOF
  fi
}

add_row_to_master_index() {
  ensure_master_index
  local row="| $fecha | [sesion-$fecha/](sesion-$fecha/) | _pendiente de completar_ |"
  if ! grep -qF "sesion-$fecha/" "$MASTER_INDEX" 2>/dev/null; then
    echo "$row" >> "$MASTER_INDEX"
  fi
}

new_resumen_template() {
  cat <<EOF
# Resumen de sesión — $fecha

## Qué se hizo

_(Describir en orden lo realizado durante la sesión.)_

## Causa raíz / hallazgos

_(Cada hallazgo con su evidencia: log, query, medición, comando ejecutado.)_

## Cambios / fixes

| Cambio | Archivo(s) | Motivo |
|---|---|---|
|  |  |  |

## Estado al cierre

_(Qué quedó funcionando, qué quedó pendiente de verificar.)_

## Pendientes

- [ ]

## Decisiones tomadas

_(Decisión + por qué, para no tener que re-discutirla en la próxima sesión.)_
EOF
}

new_readme_template() {
  cat <<EOF
# Sesión $fecha — índice

TL;DR: _(una o dos líneas resumiendo la sesión)_

| Archivo | Contenido |
|---|---|
| [00_RESUMEN_SESION.md](00_RESUMEN_SESION.md) | Resumen general de la sesión |
EOF
}

cmd_new() {
  if [[ -d "$sesion_dir" ]]; then
    echo "= existe (no se toca): $sesion_dir"
  else
    mkdir -p "$sesion_dir"
    new_resumen_template > "$resumen_file"
    new_readme_template > "$readme_file"
    echo "+ creado: $sesion_dir"
    echo "  - $resumen_file"
    echo "  - $readme_file"
  fi
  add_row_to_master_index
  echo "índice maestro actualizado: $MASTER_INDEX"
}

cmd_check() {
  local status="PASS"
  local fail=0

  if [[ ! -d "$sesion_dir" ]]; then
    echo "FAIL: no existe $sesion_dir"
    exit 1
  fi

  if [[ ! -f "$resumen_file" ]]; then
    echo "FAIL: falta 00_RESUMEN_SESION.md en $sesion_dir"
    fail=1
  fi

  if [[ ! -f "$readme_file" ]]; then
    echo "FAIL: falta README.md en $sesion_dir"
    fail=1
  fi

  if [[ ! -f "$MASTER_INDEX" ]]; then
    echo "WARN: no existe el índice maestro $MASTER_INDEX"
    status="WARN"
  elif ! grep -qF "sesion-$fecha/" "$MASTER_INDEX"; then
    echo "WARN: sesion-$fecha/ no está referenciada en $MASTER_INDEX"
    status="WARN"
  fi

  # archivos fuera de la convención NN_TEMA.md / README.md
  while IFS= read -r -d '' f; do
    base="$(basename "$f")"
    if [[ "$base" != "README.md" && ! "$base" =~ ^[0-9]{2}_[A-Z0-9_]+\.md$ ]]; then
      echo "WARN: archivo fuera de convención NN_TEMA.md: $f"
      status="WARN"
    fi
  done < <(find "$sesion_dir" -maxdepth 1 -type f -print0 2>/dev/null)

  # fechas relativas prohibidas
  if grep -rniE '\b(hoy|ayer|mañana|manana|la semana pasada|este mes)\b' "$sesion_dir" 2>/dev/null; then
    echo "WARN: se encontraron referencias de fecha relativa (usar YYYY-MM-DD)"
    status="WARN"
  fi

  if [[ "$fail" -eq 1 ]]; then
    echo "RESULT: FAIL"
    exit 1
  fi

  echo "RESULT: $status"
}

case "$cmd" in
  new) cmd_new ;;
  check) cmd_check ;;
  *) usage ;;
esac
