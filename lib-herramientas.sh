#!/bin/bash
# Herramientas para que Claude pueda trabajar con PDF, Word, Excel, PowerPoint,
# imágenes, OCR y audio en macOS. Lo carga "Instalar en Mac.command".
#
#   Homebrew  → poppler, qpdf, tesseract (+ español), pandoc, ffmpeg, imagemagick,
#               exiftool, whisper-cpp, node, yt-dlp y LibreOffice
#   uv        → un Python propio con las librerías de documentos (queda primero en el PATH)
#   npm       → docx y pptxgenjs (los usan los skills de Word y PowerPoint)
#   Whisper   → modelo large-v3-turbo (q5_0, ~550 MB) para transcribir en español
#   Claude    → plugins oficiales: document-skills y los de oficina (productivity,
#               enterprise-search, operations, human-resources, finance, data,
#               marketing, pdf-viewer)
#
# Homebrew es lo único que pide la contraseña de la Mac (una vez).

HERR_DIR="$HOME/.local/share/claude-equipo"
HERR_PY="$HERR_DIR/python"
HERR_MODELO="$HERR_DIR/whisper/ggml-large-v3-turbo-q5_0.bin"
HERR_MODELO_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin"
HERR_MODELO_BYTES=574041195

# fórmula:programa — se instala la fórmula solo si el programa no está ya (por
# ejemplo, pandoc o node instalados por otra vía).
BREW_FORMULAS=(poppler:pdftotext qpdf:qpdf tesseract:tesseract pandoc:pandoc ffmpeg:ffmpeg
               imagemagick:magick exiftool:exiftool whisper-cpp:whisper-cli node:node yt-dlp:yt-dlp)
PY_LIBS=(pypdf pdfplumber pymupdf pikepdf reportlab pdf2image img2pdf pytesseract
         python-docx openpyxl xlsxwriter pandas python-pptx pillow matplotlib defusedxml
         "markitdown[all]" qrcode)
NPM_LIBS=(docx pptxgenjs)

# ------------------------------------------------------------------ Homebrew

brew_activar() {
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x "$b" ]] && { eval "$("$b" shellenv)"; return 0; }
  done
  return 1
}

tiene_brew() { brew_activar; }

# El instalador oficial pide la contraseña de la Mac y un Enter. Necesita el
# terminal real como entrada (ver real_tty en "Instalar en Mac.command").
instalar_brew() {
  tiene_brew && return 0
  local tty_real="$1"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" < "$tty_real" || return 1
  brew_activar || return 1
  local rc="$HOME/.zprofile"
  [[ "${SHELL:-}" == *bash* ]] && rc="$HOME/.bash_profile"
  grep -qsF 'brew shellenv' "$rc" || echo "eval \"\$($(command -v brew) shellenv)\"" >> "$rc"
}

# Sin arreglos vacíos: con set -u, el bash 3.2 de macOS da «unbound variable» al
# expandir "${arreglo[@]}" si está vacío.
brew_falta() {
  local f
  ruta_extendida
  for f in "${BREW_FORMULAS[@]}"; do tiene "${f#*:}" || echo "${f%%:*}"; done
}

instalar_formulas() {
  local faltan; faltan="$(brew_falta | tr '\n' ' ')"
  [[ -z "${faltan// /}" ]] && return 0
  gris "Instalando: $faltan"
  HOMEBREW_NO_ENV_HINTS=1 brew install $faltan >/dev/null 2>&1
  [[ -z "$(brew_falta)" ]]
}

tiene_libreoffice() { [[ -d /Applications/LibreOffice.app || -d "$HOME/Applications/LibreOffice.app" ]]; }

instalar_libreoffice() {
  tiene_libreoffice && return 0
  HOMEBREW_NO_ENV_HINTS=1 brew install --cask libreoffice >/dev/null 2>&1
  tiene_libreoffice
}

# ------------------------------------------------------------------ OCR en español

tessdata_dir() { echo "$(brew --prefix 2>/dev/null)/share/tessdata"; }
tiene_ocr_es()  { [[ -s "$(tessdata_dir)/spa.traineddata" ]]; }

instalar_ocr_es() {
  tiene_ocr_es && return 0
  local d; d="$(tessdata_dir)"; [[ -d "$d" ]] || return 1
  curl -fsSL --max-time 300 "https://github.com/tesseract-ocr/tessdata/raw/main/spa.traineddata" -o "$d/spa.traineddata.tmp" \
    && mv "$d/spa.traineddata.tmp" "$d/spa.traineddata"
  tiene_ocr_es
}

# ------------------------------------------------------------------ Python con librerías de documentos

tiene_uv() { ruta_extendida; tiene uv; }

instalar_uv() {
  tiene_uv && return 0
  curl -LsSf https://astral.sh/uv/install.sh 2>/dev/null | sh >/dev/null 2>&1
  tiene_uv
}

tiene_python_docs() {
  [[ -x "$HERR_PY/bin/python" ]] || return 1
  "$HERR_PY/bin/python" -c "import pypdf, pdfplumber, pymupdf, docx, openpyxl, pandas, pptx, PIL, pytesseract, markitdown" 2>/dev/null
}

instalar_python_docs() {
  tiene_python_docs && return 0
  mkdir -p "$HERR_DIR"
  [[ -x "$HERR_PY/bin/python" ]] || uv venv --quiet --python 3.12 "$HERR_PY" >/dev/null 2>&1 || return 1
  uv pip install --quiet --python "$HERR_PY/bin/python" "${PY_LIBS[@]}" >/dev/null 2>&1
  tiene_python_docs
}

# Ese Python queda primero en el PATH, así `python3` y `pip` ya traen las librerías.
persistir_python_docs() {
  local rc="$HOME/.zshrc"
  [[ "${SHELL:-}" == *bash* ]] && rc="$HOME/.bash_profile"
  grep -qsF "$HERR_PY/bin" "$rc" || echo "export PATH=\"$HERR_PY/bin:\$PATH\"   # Claude para el equipo: Python con librerías de documentos" >> "$rc"
  export PATH="$HERR_PY/bin:$PATH"
}

# ------------------------------------------------------------------ Librerías de Node

tiene_npm_docs() {
  tiene npm || return 1
  local l; for l in "${NPM_LIBS[@]}"; do npm ls -g --depth=0 "$l" >/dev/null 2>&1 || return 1; done
}

instalar_npm_docs() {
  tiene_npm_docs && return 0
  tiene npm || return 1
  npm install -g --silent "${NPM_LIBS[@]}" >/dev/null 2>&1
  tiene_npm_docs
}

# ------------------------------------------------------------------ Transcripción (whisper.cpp)

tiene_modelo_whisper() {
  [[ -f "$HERR_MODELO" ]] && [[ "$(stat -f %z "$HERR_MODELO" 2>/dev/null)" == "$HERR_MODELO_BYTES" ]]
}

tiene_transcripcion() { tiene whisper-cli && tiene_modelo_whisper; }

instalar_modelo_whisper() {
  tiene_modelo_whisper && return 0
  mkdir -p "$(dirname "$HERR_MODELO")"
  curl -fL --max-time 3600 "$HERR_MODELO_URL" -o "$HERR_MODELO.tmp" 2>/dev/null && mv "$HERR_MODELO.tmp" "$HERR_MODELO"
  tiene_modelo_whisper
}

# ------------------------------------------------------------------ Plugins y skills de oficina

# Plugins oficiales de Anthropic: document-skills (PDF, Word, Excel, PowerPoint)
# y los de trabajo de oficina de knowledge-work-plugins. Se declaran también en
# config/settings.json, y se instalan después de aplicar la configuración, porque
# instalar escribe en ~/.claude/settings.json.
MARKETPLACES=(anthropics/skills anthropics/knowledge-work-plugins)
PLUGINS=(document-skills@anthropic-agent-skills
         productivity@knowledge-work-plugins enterprise-search@knowledge-work-plugins
         operations@knowledge-work-plugins human-resources@knowledge-work-plugins
         finance@knowledge-work-plugins data@knowledge-work-plugins
         marketing@knowledge-work-plugins pdf-viewer@knowledge-work-plugins)

tiene_plugins() {
  local lista p; lista="$(claude plugin list 2>/dev/null)" || return 1
  for p in "${PLUGINS[@]}"; do [[ "$lista" == *"$p"* ]] || return 1; done
}

plugins_faltan() {
  local lista p; lista="$(claude plugin list 2>/dev/null)"
  for p in "${PLUGINS[@]}"; do [[ "$lista" == *"$p"* ]] || echo "${p%%@*}"; done
}

# Siempre se corre (instalar dos veces no hace daño): así, si la configuración
# pisó settings.json, los plugins vuelven a quedar activos.
instalar_plugins() {
  local m p
  for m in "${MARKETPLACES[@]}"; do claude plugin marketplace add "$m" >/dev/null 2>&1; done
  claude plugin marketplace update >/dev/null 2>&1
  for p in "${PLUGINS[@]}"; do claude plugin install "$p" >/dev/null 2>&1; done
  tiene_plugins
}

# ------------------------------------------------------------------ Sesión de Claude Code

sesion_claude_code_activa() {
  claude auth status 2>/dev/null | grep -q '"loggedIn": true' || tiene_sesion_claude_code
}

# ------------------------------------------------------------------ Resumen para el diagnóstico

tiene_pdf_tools()  { tiene pdftotext && tiene pdftoppm && tiene qpdf; }
tiene_ocr()        { tiene tesseract && tiene_ocr_es; }
tiene_conversion() { tiene pandoc && tiene_libreoffice; }
tiene_imagenes()   { tiene magick && tiene exiftool; }
tiene_audio()      { tiene ffmpeg && tiene yt-dlp; }

# ------------------------------------------------------------------ Claude en Word, Excel y PowerPoint

# Complementos de Claude en AppSource. Office no deja instalarlos desde un
# script: se abre la página, la persona le da a «Obtener ahora», y aquí se
# comprueba en la caché de complementos de Office (Wef) que ya quedó.
# «Claude in Microsoft Office» (11d7cf85-…) cuenta para Excel y PowerPoint.
OFFICE_CLAUDE_GUID="11d7cf85-ae5a-43b8-bc58-1e1a151cce24"
office_app_nombre() { case "$1" in Word) echo "Microsoft Word";; Excel) echo "Microsoft Excel";; Powerpoint) echo "Microsoft PowerPoint";; esac; }
office_ids()        { case "$1" in Word) echo "wa200010453";; Excel) echo "wa200009404 wa200010725 $OFFICE_CLAUDE_GUID";; Powerpoint) echo "wa200010001 $OFFICE_CLAUDE_GUID";; esac; }
office_url()        { case "$1" in Word) echo "WA200010453";; Excel) echo "WA200009404";; Powerpoint) echo "WA200010001";; esac | sed 's#^#https://appsource.microsoft.com/product/office/#'; }

tiene_office_app() { [[ -d "/Applications/$(office_app_nombre "$1").app" ]]; }

tiene_claude_office() {
  local wef="$HOME/Library/Containers/com.microsoft.$1/Data/Library/Application Support/Microsoft/Office/16.0/Wef" id
  [[ -d "$wef" ]] || return 1
  for id in $(office_ids "$1"); do
    [[ -n "$(find "$wef" -iname "*$id*" -print -quit 2>/dev/null)" ]] && return 0
  done
  return 1
}

tiene_office_alguna() { tiene_office_app Word || tiene_office_app Excel || tiene_office_app Powerpoint; }

# Para el diagnóstico: cada app de Office instalada tiene su Claude.
tiene_claude_en_office() {
  local a hay=1
  for a in Word Excel Powerpoint; do
    tiene_office_app "$a" || continue
    hay=0; tiene_claude_office "$a" || return 1
  done
  return $hay
}
