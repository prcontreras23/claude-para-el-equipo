#!/bin/bash
# Programas que se bajan de la fuente oficial de cada proyecto, ya compilados,
# en vez de Homebrew. Terminan antes (Homebrew baja también sus dependencias: el
# yt-dlp de Homebrew trae un Python entero, y Node varias librerías), quedan en la
# versión que publica el autor y no piden la contraseña de la Mac: todo va a
# ~/.local, cuyo bin ya está en el PATH (lo deja el instalador de Claude Code).
#
#   yt-dlp    → binario yt-dlp_macos de su GitHub, verificado con SHA2-256SUMS
#   pandoc    → .zip de su GitHub (arm64 o x86_64), binario firmado por el autor
#   Node LTS  → .tar.gz de nodejs.org, verificado con SHASUMS256.txt
#   exiftool  → .tar.gz que enlaza exiftool.org (alojado en SourceForge),
#               verificado con su checksums.txt (es Perl; macOS trae Perl)
#   LibreOffice → .dmg de documentfoundation.org (en lib-intel.sh, para las dos
#               arquitecturas), firmado por The Document Foundation
#
# Lo que no tiene binario oficial para Mac (poppler, qpdf, tesseract, ffmpeg,
# ImageMagick, whisper) sigue por Homebrew, o por MacPorts en Intel.
# Lo carga "Instalar en Mac.command", después de lib-herramientas.sh.

LOCAL_BIN="$HOME/.local/bin"
LOCAL_OPT="$HOME/.local/opt"

arq_mac() { [[ "$(uname -m)" == "arm64" ]] && echo arm64 || echo x86_64; }

sha256_de() { shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'; }

# Baja un archivo y lo compara con el sha256 esperado. Devuelve 3 si no coincide.
bajar_verificado() {
  local url="$1" destino="$2" esperado="$3"
  curl -fL --max-time 1800 "$url" -o "$destino" 2>/dev/null || return 1
  [[ -n "$esperado" && "$(sha256_de "$destino")" == "$esperado" ]] || { rm -f "$destino"; return 3; }
}

ultimo_tag_github() {
  curl -fsSL --max-time 30 "https://api.github.com/repos/$1/releases/latest" 2>/dev/null \
    | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/'
}

# ------------------------------------------------------------------ yt-dlp

instalar_ytdlp_oficial() {
  ruta_extendida; tiene yt-dlp && ytdlp_reciente && return 0
  local tag base tmp sum r
  tag="$(ultimo_tag_github yt-dlp/yt-dlp)"; [[ -n "$tag" ]] || return 1
  base="https://github.com/yt-dlp/yt-dlp/releases/download/$tag"
  sum="$(curl -fsSL --max-time 30 "$base/SHA2-256SUMS" 2>/dev/null | awk '$2 == "yt-dlp_macos" {print $1}')"
  tmp="$(mktemp -d)"
  bajar_verificado "$base/yt-dlp_macos" "$tmp/yt-dlp" "$sum"; r=$?
  if [[ $r -eq 0 ]]; then
    mkdir -p "$LOCAL_BIN"
    install -m 755 "$tmp/yt-dlp" "$LOCAL_BIN/yt-dlp" && xattr -d com.apple.quarantine "$LOCAL_BIN/yt-dlp" 2>/dev/null
  fi
  rm -rf "$tmp"
  [[ $r -ne 0 ]] && return $r
  hash -r; ruta_extendida; tiene yt-dlp
}

# Un yt-dlp con más de 90 días suele fallar con YouTube («The page needs to be
# reloaded»). Si el que hay es viejo, se pone el oficial delante en el PATH.
ytdlp_reciente() {
  local v; v="$(yt-dlp --version 2>/dev/null)" || return 1
  [[ "$v" =~ ^([0-9]{4})\.([0-9]{2})\.([0-9]{2}) ]] || return 1
  local fecha="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"
  local limite; limite="$(date -v-90d +%Y%m%d 2>/dev/null)" || return 0
  [[ "$fecha" -ge "$limite" ]]
}

# ------------------------------------------------------------------ pandoc

instalar_pandoc_oficial() {
  ruta_extendida; tiene pandoc && return 0
  local tag a url tmp
  tag="$(ultimo_tag_github jgm/pandoc)"; [[ -n "$tag" ]] || return 1
  a="$(arq_mac)"
  url="https://github.com/jgm/pandoc/releases/download/$tag/pandoc-$tag-$a-macOS.zip"
  tmp="$(mktemp -d)"
  curl -fL --max-time 900 "$url" -o "$tmp/pandoc.zip" 2>/dev/null \
    && ditto -x -k "$tmp/pandoc.zip" "$tmp/x" 2>/dev/null || { rm -rf "$tmp"; return 1; }
  local bin; bin="$(find "$tmp/x" -type f -name pandoc -path '*/bin/*' | head -1)"
  [[ -n "$bin" ]] || { rm -rf "$tmp"; return 1; }
  firmado_por "$bin" "Developer ID Application: John Macfarlane (5U2WKE6DES)" || { rm -rf "$tmp"; return 4; }
  mkdir -p "$LOCAL_BIN"
  install -m 755 "$bin" "$LOCAL_BIN/pandoc" && xattr -d com.apple.quarantine "$LOCAL_BIN/pandoc" 2>/dev/null
  rm -rf "$tmp"
  hash -r; tiene pandoc
}

# ------------------------------------------------------------------ Node LTS

instalar_node_oficial() {
  ruta_extendida; tiene node && return 0
  local v a nombre base tmp sum r
  # index.tab: la primera fila con nombre de LTS en la columna 10 es la LTS más nueva.
  v="$(curl -fsSL --max-time 30 https://nodejs.org/dist/index.tab 2>/dev/null \
    | awk -F'\t' 'NR > 1 && $10 != "-" { print $1; exit }')"
  [[ -n "$v" ]] || return 1
  a="$(arq_mac)"; [[ "$a" == x86_64 ]] && a=x64
  nombre="node-$v-darwin-$a"
  base="https://nodejs.org/dist/$v"
  sum="$(curl -fsSL --max-time 30 "$base/SHASUMS256.txt" 2>/dev/null | awk -v f="$nombre.tar.gz" '$2 == f {print $1}')"
  tmp="$(mktemp -d)"
  bajar_verificado "$base/$nombre.tar.gz" "$tmp/node.tar.gz" "$sum"; r=$?
  if [[ $r -eq 0 ]]; then
    mkdir -p "$LOCAL_OPT" "$LOCAL_BIN"
    rm -rf "$LOCAL_OPT/node"
    tar -xzf "$tmp/node.tar.gz" -C "$LOCAL_OPT" && mv "$LOCAL_OPT/$nombre" "$LOCAL_OPT/node" || r=1
  fi
  rm -rf "$tmp"
  [[ $r -ne 0 ]] && return $r
  local p; for p in node npm npx; do ln -sf "$LOCAL_OPT/node/bin/$p" "$LOCAL_BIN/$p"; done
  # npm -g instala en ~/.local (bin ya en el PATH), no dentro de la carpeta de Node.
  "$LOCAL_BIN/npm" config set prefix "$HOME/.local" >/dev/null 2>&1
  hash -r; tiene node
}

# ------------------------------------------------------------------ exiftool

instalar_exiftool_oficial() {
  ruta_extendida; tiene exiftool && return 0
  local v sum tmp r
  v="$(curl -fsSL --max-time 30 https://exiftool.org/ver.txt 2>/dev/null | tr -d '[:space:]')"
  [[ "$v" =~ ^[0-9.]+$ ]] || return 1
  sum="$(curl -fsSL --max-time 30 https://exiftool.org/checksums.txt 2>/dev/null \
    | grep -F "SHA2-256(Image-ExifTool-$v.tar.gz)" | awk '{print $2}')"
  tmp="$(mktemp -d)"
  # exiftool.org enlaza la descarga a SourceForge; el checksum sale de exiftool.org.
  bajar_verificado "https://sourceforge.net/projects/exiftool/files/Image-ExifTool-$v.tar.gz/download" "$tmp/exiftool.tar.gz" "$sum"; r=$?
  if [[ $r -eq 0 ]]; then
    mkdir -p "$LOCAL_OPT" "$LOCAL_BIN"
    rm -rf "$LOCAL_OPT/exiftool"
    tar -xzf "$tmp/exiftool.tar.gz" -C "$LOCAL_OPT" && mv "$LOCAL_OPT/Image-ExifTool-$v" "$LOCAL_OPT/exiftool" || r=1
  fi
  rm -rf "$tmp"
  [[ $r -ne 0 ]] && return $r
  ln -sf "$LOCAL_OPT/exiftool/exiftool" "$LOCAL_BIN/exiftool"
  hash -r; tiene exiftool
}

# ------------------------------------------------------------------ Paso completo

# Cada pieza dice si quedó o, si no, por qué. Nada se salta en silencio.
herramientas_oficiales() {
  local r
  instalar_ytdlp_oficial; r=$?
  case $r in 0) verde "yt-dlp $(yt-dlp --version 2>/dev/null)" ;;
    3) rojo "yt-dlp: la descarga no coincidió con su checksum; no se instaló." ;;
    *) rojo "yt-dlp no quedó instalado (revisa el internet y vuelve a correr el instalador)." ;; esac

  instalar_pandoc_oficial; r=$?
  case $r in 0) verde "pandoc" ;; 4) rojo "pandoc no venía firmado por su autor; no se instaló." ;;
    *) rojo "pandoc no quedó instalado (bájalo a mano: https://pandoc.org/installing.html)." ;; esac

  instalar_node_oficial; r=$?
  case $r in 0) verde "Node $(node --version 2>/dev/null)" ;;
    3) rojo "Node: la descarga no coincidió con su checksum; no se instaló." ;;
    *) rojo "Node no quedó instalado (bájalo a mano: https://nodejs.org)." ;; esac

  instalar_exiftool_oficial; r=$?
  case $r in 0) verde "exiftool" ;;
    3) rojo "exiftool: la descarga no coincidió con su checksum; no se instaló." ;;
    *) rojo "exiftool no quedó instalado (bájalo a mano: https://exiftool.org)." ;; esac
}
