#!/bin/bash
# Aplica la configuración del equipo a ~/.claude (y encima, si se pidió, un perfil).
# Común a Mac; el equivalente para Windows está en lib-config.ps1.
#
# Reglas:
#  - Un CLAUDE.md o un settings.json que la persona ya tenía no se reemplaza (ver _copiar_capa).
#  - Lo que ya exista en ~/.claude se respalda en ~/.claude/respaldo-<fecha>/ antes de tocarlo.
#  - config/ es la base para todos. perfiles/<nombre>/ se copia encima y gana.
#  - Dentro de skills/, commands/ y agents/ se agregan carpetas; no se borran las que
#    la persona ya tenga.

aplicar_config() {
  local fuente="$1" perfil="${2:-}" es_adose="${3:-n}"
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

  # El contexto de ADOSE (quiénes somos, SIGA) solo va si la persona es del equipo de ADOSE.
  if [[ "$es_adose" == "s" && -f "$fuente/equipo-adose/adose.md" ]]; then
    cp -p "$fuente/equipo-adose/adose.md" "$destino/adose.md"
    grep -qF "@~/.claude/adose.md" "$destino/CLAUDE.md" \
      || printf '\n\n## Contexto de ADOSE\n@~/.claude/adose.md\n' >> "$destino/CLAUDE.md"
  else
    # Si una corrida anterior lo había puesto, se quita.
    if [[ -f "$destino/CLAUDE.md" ]] && grep -qF "@~/.claude/adose.md" "$destino/CLAUDE.md"; then
      grep -vF -e "@~/.claude/adose.md" -e "## Contexto de ADOSE" "$destino/CLAUDE.md" > "$destino/CLAUDE.md.nuevo" && mv "$destino/CLAUDE.md.nuevo" "$destino/CLAUDE.md"
    fi
    rm -f "$destino/adose.md"
  fi

  # Marcar de dónde salió, para saber qué versión tiene cada máquina.
  {
    echo "repo: $REPO"
    echo "perfil: ${perfil:-base}"
    echo "adose: $es_adose"
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
    # Quien ya usaba Claude conserva lo suyo:
    #  - su CLAUDE.md no se reemplaza; el del equipo va a equipo-claude.md y se importa al final.
    #  - su settings.json no se toca; los plugins escriben ahí lo que necesitan.
    if [[ "$rel" == CLAUDE.md && -f "$destino/CLAUDE.md" ]] && ! grep -qF "Claude para el equipo" "$destino/CLAUDE.md"; then
      cp -p "$f" "$destino/equipo-claude.md"
      # Instalaciones anteriores usaban equipo-adose.md (traía el contexto de ADOSE para todos).
      if grep -qF "@~/.claude/equipo-adose.md" "$destino/CLAUDE.md"; then
        grep -vF -e "@~/.claude/equipo-adose.md" -e "## Reglas del equipo de ADOSE" "$destino/CLAUDE.md" > "$destino/CLAUDE.md.nuevo" && mv "$destino/CLAUDE.md.nuevo" "$destino/CLAUDE.md"
        rm -f "$destino/equipo-adose.md"
      fi
      grep -qF "@~/.claude/equipo-claude.md" "$destino/CLAUDE.md" \
        || printf '\n\n## Reglas de Claude para el equipo\n@~/.claude/equipo-claude.md\n' >> "$destino/CLAUDE.md"
      continue
    fi
    [[ "$rel" == settings.json && -f "$destino/settings.json" ]] && continue
    # Se respalda solo la primera vez: así el original de la persona no lo pisa la capa siguiente.
    if [[ -e "$destino/$rel" && ! -e "$respaldo/$rel" ]]; then
      mkdir -p "$respaldo/$(dirname "$rel")"
      cp -p "$destino/$rel" "$respaldo/$rel"
    fi
    mkdir -p "$destino/$(dirname "$rel")"
    cp -p "$f" "$destino/$rel"
  done < <(find "$capa" -type f ! -name .DS_Store -print0)
}
