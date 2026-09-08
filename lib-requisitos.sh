#!/bin/bash
# Funciones para instalar lo que Claude Code necesita en macOS: git, Claude Code
# y Claude Desktop. Sin Homebrew y sin contraseña de administrador, salvo el
# diálogo de macOS para las Command Line Tools (git), que es del sistema.
#
# Lo cargan instalar.sh e "Instalar en Mac.command".

ruta_extendida() {
  local d
  for d in "$HOME/.local/bin" "/opt/homebrew/bin" "/usr/local/bin"; do
    [[ -d "$d" && ":$PATH:" != *":$d:"* ]] && PATH="$d:$PATH"
  done
  export PATH
}

tiene() { command -v "$1" >/dev/null 2>&1; }

# ------------------------------------------------------------------ git

# En macOS git viene con las Command Line Tools de Xcode. Instalarlas abre un
# diálogo del sistema que la persona tiene que aceptar.
instalar_git() {
  ruta_extendida
  xcode-select -p >/dev/null 2>&1 && tiene git && return 0

  printf '\033[33m  ! Falta git. Se va a abrir una ventana de macOS para instalarlo.\033[0m\n'
  printf '\033[33m  ! Dale a "Instalar" y espera a que termine (unos minutos).\033[0m\n'
  xcode-select --install >/dev/null 2>&1

  local i
  for i in $(seq 1 240); do   # hasta 20 minutos
    xcode-select -p >/dev/null 2>&1 && tiene git && return 0
    sleep 5
  done
  ruta_extendida
  tiene git
}

# ------------------------------------------------------------------ Claude Code

instalar_claude() {
  ruta_extendida
  tiene claude && return 0
  # Instalador oficial de Anthropic: deja claude en ~/.local/bin y se actualiza solo.
  curl -fsSL https://claude.ai/install.sh 2>/dev/null | bash >/dev/null 2>&1
  ruta_extendida
  tiene claude
}

# ------------------------------------------------------------------ Claude Desktop

tiene_claude_desktop() {
  [[ -d "/Applications/Claude.app" || -d "$HOME/Applications/Claude.app" ]]
}

# Descarga la app oficial desde downloads.claude.ai (dominio de Anthropic).
# La versión y el sha256 salen del índice público de Homebrew, que se puede
# consultar sin tener Homebrew. Se verifica el checksum y la firma de Anthropic.
instalar_claude_desktop() {
  tiene_claude_desktop && return 0

  local meta url sha
  meta="$(curl -fsSL --max-time 30 'https://formulae.brew.sh/api/cask/claude.json' 2>/dev/null)" || return 1
  url="$(printf '%s' "$meta" | python3 -c "import json,sys;print(json.load(sys.stdin).get('url',''))" 2>/dev/null)"
  sha="$(printf '%s' "$meta" | python3 -c "import json,sys;print(json.load(sys.stdin).get('sha256',''))" 2>/dev/null)"
  [[ -z "$url" ]] && return 1

  local tmp; tmp="$(mktemp -d)"
  curl -fL --max-time 900 "$url" -o "$tmp/Claude.zip" 2>/dev/null || { rm -rf "$tmp"; return 1; }

  if [[ -n "$sha" && "$sha" != "no_check" ]]; then
    local real; real="$(shasum -a 256 "$tmp/Claude.zip" | awk '{print $1}')"
    [[ "$real" == "$sha" ]] || { rm -rf "$tmp"; return 3; }
  fi

  ditto -x -k "$tmp/Claude.zip" "$tmp/extraido" 2>/dev/null || { rm -rf "$tmp"; return 1; }
  local app; app="$(find "$tmp/extraido" -maxdepth 2 -name "Claude.app" -print -quit 2>/dev/null)"
  [[ -z "$app" ]] && { rm -rf "$tmp"; return 1; }

  codesign -dv --verbose=2 "$app" 2>&1 | grep -q "Authority=Developer ID Application: Anthropic" \
    || { rm -rf "$tmp"; return 4; }

  local destino="/Applications"
  [[ -w "$destino" ]] || { destino="$HOME/Applications"; mkdir -p "$destino"; }
  rm -rf "$destino/Claude.app"
  ditto "$app" "$destino/Claude.app" 2>/dev/null || { rm -rf "$tmp"; return 1; }
  xattr -dr com.apple.quarantine "$destino/Claude.app" 2>/dev/null
  rm -rf "$tmp"
  tiene_claude_desktop
}

# ------------------------------------------------------------------ PATH persistente

persistir_ruta() {
  local rc="$HOME/.zshrc"
  [[ "${SHELL:-}" == *bash* ]] && rc="$HOME/.bash_profile"
  grep -qsF '.local/bin' "$rc" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
}
