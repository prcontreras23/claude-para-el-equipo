#!/bin/bash
# Aplica la configuración del equipo a ~/.claude (y encima, si se pidió, un perfil).
# Común a Mac; el equivalente para Windows está en lib-config.ps1.
#
# Reglas:
#  - Lo que ya exista en ~/.claude se respalda en ~/.claude/respaldo-<fecha>/ antes de tocarlo.
#  - config/ es la base para todos. perfiles/<nombre>/ se copia encima y gana.
#  - Dentro de skills/, commands/ y agents/ se agregan carpetas; no se borran las que
#    la persona ya tenga.

aplicar_config() {
  local fuente="$1" perfil="${2:-}"
  local destino="$HOME/.claude"
  local respaldo="$destino/respaldo-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$destino"

  _copiar_capa "$fuente/config" "$destino" "$respaldo"

  if [[ -n "$perfil" ]]; then
    if [[ -d "$fuente/perfiles/$perfil" ]]; then
      _copiar_capa "$fuente/perfiles/$perfil" "$destino" "$respaldo"
    else
      printf '\033[33m  ! No existe el perfil "%s"; se aplicó solo la configuración base.\033[0m\n' "$perfil"
      perfil=""
    fi
  fi

  # Marcar de dónde salió, para saber qué versión tiene cada máquina.
  {
    echo "repo: $REPO"
    echo "perfil: ${perfil:-base}"
    echo "fecha: $(date '+%Y-%m-%d %H:%M')"
  } > "$destino/.claude-para-el-equipo"
}

_copiar_capa() {
  local capa="$1" destino="$2" respaldo="$3"
  [[ -d "$capa" ]] || return 0
  local f rel
  while IFS= read -r -d '' f; do
    rel="${f#"$capa"/}"
    [[ "$rel" == README.md ]] && continue
    # Se respalda solo la primera vez: así el original de la persona no lo pisa la capa siguiente.
    if [[ -e "$destino/$rel" && ! -e "$respaldo/$rel" ]]; then
      mkdir -p "$respaldo/$(dirname "$rel")"
      cp -p "$destino/$rel" "$respaldo/$rel"
    fi
    mkdir -p "$destino/$(dirname "$rel")"
    cp -p "$f" "$destino/$rel"
  done < <(find "$capa" -type f ! -name .DS_Store -print0)
}
