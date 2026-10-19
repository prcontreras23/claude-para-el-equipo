#!/bin/bash
# Camino para Mac con procesador Intel (x86_64). El instalador oficial de Homebrew
# ya no funciona ahí («Homebrew on macOS is only supported on Apple Silicon
# processors!», visto en un MacBook Pro i9 con macOS 15.3.1), así que las mismas
# herramientas se instalan por otras vías:
#
#   MacPorts       → poppler, qpdf, tesseract + español, ImageMagick 7, exiftool,
#                    ffmpeg y cmake (para compilar whisper; si no, cmake por pip)
#   .pkg oficiales → pandoc (GitHub de pandoc) y Node LTS (nodejs.org)
#   .dmg oficial   → LibreOffice x86-64 (documentfoundation.org)
#   binario oficial → yt-dlp (lib-oficiales.sh); pip solo si ese falla
#   código fuente  → whisper.cpp (no hay port ni wheel para Intel), con cmake;
#                    deja whisper-cli en ~/.local/bin, igual que en Apple Silicon
#
# Si la Mac Intel ya tiene un Homebrew que funciona, se sigue usando Homebrew.
# Todo comprueba antes de instalar: volver a correrlo solo hace lo que falte.
# Lo carga "Instalar en Mac.command", después de lib-herramientas.sh.

es_intel() { [[ "$(uname -m)" == "x86_64" ]]; }

# En Intel sin Homebrew se va por MacPorts; en lo demás, por Homebrew como siempre.
usar_macports() { es_intel && ! tiene_brew; }

PORT=/opt/local/bin/port
# port:programa — el port se instala solo si el programa no está ya (por cualquier vía).
PORT_PAQUETES=(poppler:pdftotext qpdf:qpdf tesseract:tesseract ImageMagick7:magick
               exiftool:exiftool ffmpeg:ffmpeg)

# ------------------------------------------------------------------ Contraseña (sudo)

# Los .pkg y MacPorts piden la contraseña de la Mac. Se pide una vez y se mantiene
# viva mientras dure el instalador (el bucle muere solo cuando el instalador termina).
SUDO_VIVO=""
pedir_sudo() {
  [[ -n "$SUDO_VIVO" ]] && sudo -n true 2>/dev/null && return 0
  local tty_real="$1"
  [[ -n "$tty_real" ]] || return 1
  sudo -v < "$tty_real" || return 1
  local padre=$$
  ( while kill -0 "$padre" 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done ) >/dev/null 2>&1 &
  SUDO_VIVO=1
}

# ------------------------------------------------------------------ Descargas firmadas

# Un .pkg se instala solo si viene firmado con un certificado de Apple para distribución.
pkg_firmado() {
  local salida; salida="$(pkgutil --check-signature "$1" 2>&1)"
  [[ "$salida" == *"signed by a developer certificate issued by Apple"* ]]
}

# Baja un .pkg, revisa la firma y lo instala. Devuelve 4 si la firma no es válida.
instalar_pkg_url() {
  local url="$1" tmp r=0; tmp="$(mktemp -d)"
  curl -fL --max-time 1800 "$url" -o "$tmp/paquete.pkg" 2>/dev/null || { rm -rf "$tmp"; return 1; }
  if pkg_firmado "$tmp/paquete.pkg"; then
    sudo installer -pkg "$tmp/paquete.pkg" -target / >/dev/null 2>&1 || r=1
  else
    r=4
  fi
  rm -rf "$tmp"
  return $r
}

# ------------------------------------------------------------------ MacPorts

tiene_macports() { [[ -x "$PORT" ]]; }

# Escoge el .pkg de MacPorts de esta versión de macOS (MacPorts-2.x.y-15-Sequoia.pkg).
url_macports() {
  local mayor; mayor="$(sw_vers -productVersion | cut -d. -f1)"
  curl -fsSL --max-time 30 https://api.github.com/repos/macports/macports-base/releases/latest 2>/dev/null \
    | grep -o '"browser_download_url": *"[^"]*\.pkg"' | grep -o 'https://[^"]*' \
    | grep -- "-$mayor-[A-Za-z]*\.pkg$" | head -1
}

instalar_macports() {
  tiene_macports && return 0
  local url; url="$(url_macports)"
  [[ -n "$url" ]] || return 2   # no hay MacPorts para esta versión de macOS
  instalar_pkg_url "$url" || return $?
  tiene_macports || return 1
  sudo "$PORT" -q selfupdate >/dev/null 2>&1
  persistir_macports
}

persistir_macports() {
  local rc="$HOME/.zprofile"
  [[ "${SHELL:-}" == *bash* ]] && rc="$HOME/.bash_profile"
  grep -qsF '/opt/local/bin' "$rc" || echo 'export PATH="/opt/local/bin:/opt/local/sbin:$PATH"   # MacPorts' >> "$rc"
  ruta_extendida
}

ports_faltan() {
  local p
  ruta_extendida
  for p in "${PORT_PAQUETES[@]}"; do tiene "${p#*:}" || echo "${p%%:*}"; done
  tiene pdftoppm || echo poppler
  tiene tesseract && ! tiene_ocr_es && echo tesseract-spa
  return 0
}

instalar_ports() {
  local faltan; faltan="$(ports_faltan | sort -u | tr '\n' ' ')"
  [[ -z "${faltan// /}" ]] && return 0
  gris "Instalando con MacPorts: $faltan"
  # tesseract-spa va después de tesseract, por eso se instala todo junto y el
  # español se repite al final si hizo falta.
  sudo "$PORT" -N -q install $faltan >/dev/null 2>&1
  tiene tesseract && ! tiene_ocr_es && sudo "$PORT" -N -q install tesseract-spa >/dev/null 2>&1
  [[ -z "$(ports_faltan)" ]]
}

# ------------------------------------------------------------------ pandoc y Node (.pkg oficiales)

instalar_pandoc_pkg() {
  ruta_extendida; tiene pandoc && return 0
  local url
  url="$(curl -fsSL --max-time 30 https://api.github.com/repos/jgm/pandoc/releases/latest 2>/dev/null \
    | grep -o 'https://[^"]*x86_64-macOS\.pkg' | head -1)"
  [[ -n "$url" ]] || return 1
  instalar_pkg_url "$url" || return $?
  ruta_extendida; tiene pandoc
}

instalar_node_pkg() {
  ruta_extendida; tiene node && return 0
  local v
  # index.tab: la primera fila con nombre de LTS en la columna 10 es la LTS más nueva.
  v="$(curl -fsSL --max-time 30 https://nodejs.org/dist/index.tab 2>/dev/null \
    | awk -F'\t' 'NR > 1 && $10 != "-" { print $1; exit }')"
  [[ -n "$v" ]] || return 1
  instalar_pkg_url "https://nodejs.org/dist/$v/node-$v.pkg" || return $?
  ruta_extendida; tiene node
}

# El .pkg de Node deja /usr/local/lib/node_modules de root: npm -g fallaría sin sudo.
# Se mueve el prefijo global a ~/.local (cuyo bin ya está en el PATH).
npm_prefijo_propio() {
  tiene npm || return 1
  local pref; pref="$(npm config get prefix 2>/dev/null)"
  [[ -n "$pref" && -w "$pref/lib" ]] && return 0
  mkdir -p "$HOME/.local/lib"
  npm config set prefix "$HOME/.local" >/dev/null 2>&1
}

# ------------------------------------------------------------------ LibreOffice (.dmg oficial)

# Se usa en todas las Mac, no solo en Intel: es el mismo .dmg que baja Homebrew,
# pero sin pasar por Homebrew.

instalar_libreoffice_dmg() {
  tiene_libreoffice && return 0
  local base="https://download.documentfoundation.org/libreoffice/stable" v
  v="$(curl -fsSL --max-time 30 "$base/" 2>/dev/null | grep -o 'href="[0-9][0-9.]*/"' \
    | grep -o '[0-9][0-9.]*[0-9]' | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)"
  [[ -n "$v" ]] || return 1
  # Mismo .dmg oficial en las dos arquitecturas; solo cambia la carpeta y el nombre.
  local carpeta=x86_64 sufijo=x86-64
  [[ "$(uname -m)" == "arm64" ]] && { carpeta=aarch64; sufijo=aarch64; }
  local tmp r=0; tmp="$(mktemp -d)"
  curl -fL --max-time 1800 "$base/$v/mac/$carpeta/LibreOffice_${v}_MacOS_${sufijo}.dmg" -o "$tmp/lo.dmg" 2>/dev/null \
    || { rm -rf "$tmp"; return 1; }
  hdiutil attach -nobrowse -quiet -mountpoint "$tmp/vol" "$tmp/lo.dmg" 2>/dev/null || { rm -rf "$tmp"; return 1; }
  local app="$tmp/vol/LibreOffice.app"
  if ! firmado_por "$app" "Developer ID Application: The Document Foundation"; then
    r=4
  else
    local destino="/Applications"
    [[ -w "$destino" ]] || { destino="$HOME/Applications"; mkdir -p "$destino"; }
    ditto "$app" "$destino/LibreOffice.app" 2>/dev/null || r=1
  fi
  hdiutil detach -quiet "$tmp/vol" 2>/dev/null
  rm -rf "$tmp"
  [[ $r -ne 0 ]] && return $r
  tiene_libreoffice
}

# ------------------------------------------------------------------ yt-dlp (pip)

instalar_ytdlp_pip() {
  ruta_extendida; tiene yt-dlp && return 0
  [[ -x "$HERR_PY/bin/python" ]] || return 1
  uv pip install --quiet --python "$HERR_PY/bin/python" yt-dlp >/dev/null 2>&1
  export PATH="$HERR_PY/bin:$PATH"
  tiene yt-dlp
}

# ------------------------------------------------------------------ whisper.cpp (código fuente)

# Compila la última versión de whisper.cpp con cmake (de MacPorts) y las Command
# Line Tools, y deja whisper-cli en ~/.local/bin. Tarda unos minutos.
instalar_whisper_fuente() {
  ruta_extendida; tiene whisper-cli && return 0
  # cmake: de MacPorts y, si no, por pip en el Python de documentos.
  tiene cmake || { [[ -x "$PORT" ]] && sudo "$PORT" -N -q install cmake >/dev/null 2>&1; ruta_extendida; }
  tiene cmake || { [[ -x "$HERR_PY/bin/python" ]] && uv pip install --quiet --python "$HERR_PY/bin/python" cmake >/dev/null 2>&1; ruta_extendida; }
  tiene cmake && xcode-select -p >/dev/null 2>&1 || return 1
  local tag tmp
  tag="$(curl -fsSL --max-time 30 https://api.github.com/repos/ggml-org/whisper.cpp/releases/latest 2>/dev/null \
    | grep -o '"tag_name": *"[^"]*"' | grep -o 'v[0-9.]*')"
  [[ -n "$tag" ]] || return 1
  tmp="$(mktemp -d)"
  curl -fsSL --max-time 600 "https://github.com/ggml-org/whisper.cpp/archive/refs/tags/$tag.tar.gz" 2>/dev/null \
    | tar -xz -C "$tmp" --strip-components=1 2>/dev/null || { rm -rf "$tmp"; return 1; }
  ( cd "$tmp" \
    && cmake -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DWHISPER_BUILD_TESTS=OFF >/dev/null 2>&1 \
    && cmake --build build -j"$(sysctl -n hw.ncpu)" --config Release --target whisper-cli >/dev/null 2>&1 ) \
    || { rm -rf "$tmp"; return 1; }
  mkdir -p "$HOME/.local/bin"
  cp "$tmp/build/bin/whisper-cli" "$HOME/.local/bin/whisper-cli" 2>/dev/null || { rm -rf "$tmp"; return 1; }
  rm -rf "$tmp"
  tiene whisper-cli
}

# ------------------------------------------------------------------ Paso 5 completo en Intel

# Cada pieza dice si quedó o, si no, por qué. Nada se salta en silencio.
herramientas_intel() {
  local tty_real="$1" r

  if ! pedir_sudo "$tty_real"; then
    rojo "Sin la contraseña de la Mac no se pueden instalar PDF, OCR, LibreOffice, pandoc, ffmpeg, ImageMagick, whisper ni node."
    gris "Vuelve a correr el instalador en la Terminal y escribe la contraseña cuando la pida."
    return 1
  fi

  if ! xcode-select -p >/dev/null 2>&1; then
    rojo "MacPorts necesita las Command Line Tools de Apple (las del paso 1, git) y no están."
    gris "Vuelve a correr el instalador y acepta la ventana de macOS en el paso 1."
  fi
  tiene_macports || gris "Instalando MacPorts (el instalador de programas para Mac Intel)..."
  instalar_macports; r=$?
  case $r in
    0) verde "MacPorts" ;;
    2) rojo "MacPorts no tiene versión para macOS $(sw_vers -productVersion); no se pueden instalar PDF, OCR, ImageMagick, exiftool, ffmpeg ni whisper." ;;
    4) rojo "El paquete de MacPorts no venía firmado; no se instaló." ;;
    *) rojo "MacPorts no quedó instalado (revisa el internet y vuelve a correr el instalador)." ;;
  esac

  if tiene_macports; then
    gris "Programas (en Intel tarda más: 15–40 minutos la primera vez)..."
    if instalar_ports; then verde "poppler, qpdf, tesseract + español, ImageMagick, exiftool, ffmpeg"
    else rojo "No quedaron con MacPorts: $(ports_faltan | sort -u | tr '\n' ' ')"; fi
  fi

  instalar_pandoc_pkg; r=$?
  case $r in 0) verde "pandoc" ;; 4) rojo "pandoc: el paquete no venía firmado; no se instaló." ;;
    *) rojo "pandoc no quedó instalado (bájalo a mano: https://pandoc.org/installing.html)." ;; esac

  instalar_node_pkg; r=$?
  case $r in 0) verde "Node $(node --version 2>/dev/null)" ;; 4) rojo "Node: el paquete no venía firmado; no se instaló." ;;
    *) rojo "Node no quedó instalado (bájalo a mano: https://nodejs.org)." ;; esac

  tiene_libreoffice || gris "Bajando LibreOffice (~350 MB, unos minutos; no cierres esta ventana)..."
  instalar_libreoffice_dmg; r=$?
  case $r in 0) verde "LibreOffice" ;; 4) rojo "LibreOffice no venía firmado por The Document Foundation; no se instaló." ;;
    *) rojo "LibreOffice no quedó instalado (bájalo a mano: https://www.libreoffice.org/download)." ;; esac

  if tiene npm; then
    npm_prefijo_propio
    tiene_npm_docs || gris "Instalando docx y pptxgenjs..."
    if instalar_npm_docs; then verde "Node: docx y pptxgenjs"; else rojo "No se pudieron instalar docx y pptxgenjs."; fi
  else
    rojo "Sin Node no se instalan docx y pptxgenjs."
  fi
  return 0
}

# Lo que va después del Python (yt-dlp por pip) y whisper compilado.
herramientas_intel_final() {
  # yt-dlp: el binario oficial (lib-oficiales.sh); por pip solo si ese no se pudo.
  if instalar_ytdlp_oficial || instalar_ytdlp_pip; then verde "yt-dlp"; else rojo "yt-dlp no quedó instalado (revisa el internet y vuelve a correr el instalador)."; fi
  quiere_audio || return 0
  tiene whisper-cli || gris "Compilando whisper para transcribir (5–15 minutos en Intel)..."
  if instalar_whisper_fuente; then verde "whisper"
  else rojo "whisper no quedó instalado: hace falta cmake y las Command Line Tools de Apple (paso 1, git)."; fi
}
