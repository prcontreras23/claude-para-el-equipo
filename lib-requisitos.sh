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

# Comprueba quién firmó una app. La salida de codesign se guarda antes de buscar:
# con `codesign | grep -q` y pipefail, grep corta la tubería al encontrar y
# codesign muere por SIGPIPE, así que la prueba fallaba siempre aunque la firma
# fuera buena.
firmado_por() {
  local salida; salida="$(codesign -dv --verbose=2 "$1" 2>&1)"
  [[ "$salida" == *"Authority=$2"* ]]
}

# ------------------------------------------------------------------ git

# En macOS git viene con las Command Line Tools de Xcode. Instalarlas abre un
# diálogo del sistema que la persona tiene que aceptar.
instalar_git() {
  ruta_extendida
  xcode-select -p >/dev/null 2>&1 && tiene git && return 0

  printf '\033[33m  ! Falta git. Se va a abrir una ventana de macOS para instalarlo.\033[0m\n'
  printf '\033[33m  ! Dale a "Instalar" y espera a que termine (unos minutos).\033[0m\n'
  printf '\033[33m  ! Si la ventana da error o prefieres seguir sin git, presiona Enter aquí.\033[0m\n'
  xcode-select --install >/dev/null 2>&1

  # Se espera hasta 20 minutos, pero Enter corta la espera: Apple a veces
  # responde "no está disponible en el servidor de actualizaciones" (macOS viejo)
  # y Claude Code funciona igual sin git.
  local i
  for i in $(seq 1 240); do
    xcode-select -p >/dev/null 2>&1 && tiene git && return 0
    if : < /dev/tty 2>/dev/null; then
      read -t 5 -r _ < /dev/tty && break
    else
      sleep 5
    fi
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

  firmado_por "$app" "Developer ID Application: Anthropic PBC" || { rm -rf "$tmp"; return 4; }

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

# ------------------------------------------------------------------ Google Chrome

tiene_chrome() {
  [[ -d "/Applications/Google Chrome.app" || -d "$HOME/Applications/Google Chrome.app" ]]
}

# Descarga oficial de Google. Se verifica que la app venga firmada por Google.
instalar_chrome() {
  tiene_chrome && return 0
  local tmp; tmp="$(mktemp -d)"
  curl -fL --max-time 900 "https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg" \
    -o "$tmp/chrome.dmg" 2>/dev/null || { rm -rf "$tmp"; return 1; }
  hdiutil attach -nobrowse -quiet -mountpoint "$tmp/vol" "$tmp/chrome.dmg" 2>/dev/null || { rm -rf "$tmp"; return 1; }
  local app="$tmp/vol/Google Chrome.app" r=0
  if ! firmado_por "$app" "Developer ID Application: Google"; then
    r=4
  else
    local destino="/Applications"
    [[ -w "$destino" ]] || { destino="$HOME/Applications"; mkdir -p "$destino"; }
    ditto "$app" "$destino/Google Chrome.app" 2>/dev/null || r=1
  fi
  hdiutil detach -quiet "$tmp/vol" 2>/dev/null
  rm -rf "$tmp"
  [[ $r -ne 0 ]] && return $r
  tiene_chrome
}

# ------------------------------------------------------------------ Extensión de Claude en Chrome

CHROME_EXT_ID="fcoeoabgfenejglbffodgkkbkcdhcgfn"   # «Claude» en la Chrome Web Store
CHROME_EXT_URL="https://chromewebstore.google.com/detail/$CHROME_EXT_ID"

# Chrome no deja instalar extensiones desde fuera sin permisos de administrador;
# la persona le da a «Añadir a Chrome». Aquí solo se comprueba que quedó.
tiene_ext_chrome() {
  compgen -G "$HOME/Library/Application Support/Google/Chrome/*/Extensions/$CHROME_EXT_ID" >/dev/null
}

# ------------------------------------------------------------------ Sesiones y configuración

# Claude Code guarda la cuenta en ~/.claude.json cuando ya se entró.
tiene_sesion_claude_code() { grep -qs '"oauthAccount"' "$HOME/.claude.json"; }
tiene_config_equipo()      { [[ -f "$HOME/.claude/.claude-para-el-equipo" ]]; }
