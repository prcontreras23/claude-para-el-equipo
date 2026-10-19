#!/bin/bash
# Herramientas para que Claude pueda trabajar con PDF, Word, Excel, PowerPoint,
# imágenes, OCR y audio en macOS. Lo carga "Instalar en Mac.command".
#
#   Homebrew  → poppler, qpdf, tesseract (+ español), ffmpeg, imagemagick y, si la
#               persona va a trabajar audio, whisper-cpp (no tienen binario oficial)
#   Oficiales → yt-dlp, pandoc, Node, exiftool y LibreOffice, bajados ya compilados
#               de la página de cada proyecto (ver lib-oficiales.sh): menos
#               descargas que por Homebrew y la versión del autor
#   uv        → un Python propio con las librerías de documentos (queda primero en el PATH)
#   uv        → además, en ese mismo Python: ocrmac (OCR con Apple Vision, liviano)
#               y, solo si va a trabajar audio, silero-vad (detecta dónde hay voz;
#               trae torch, ~700 MB)
#   npm       → docx y pptxgenjs (los usan los skills de Word y PowerPoint)
#   Whisper   → modelo large-v3-turbo (q5_0, ~550 MB) para transcribir en español,
#               solo si va a trabajar audio
#   Claude    → plugins: document-skills, productivity y watch (ver videos)
#
# Lo de audio (whisper, su modelo y Silero) pesa ~1.3 GB y casi nadie lo usa: va
# solo si la persona contesta que sí a «¿Vas a transcribir audios o editar
# grabaciones?» (QUIERE_AUDIO, lo fija "Instalar en Mac.command").
#
# Homebrew es lo único que pide la contraseña de la Mac (una vez).

QUIERE_AUDIO="${QUIERE_AUDIO:-n}"
quiere_audio() { [[ "$QUIERE_AUDIO" == "s" ]]; }

HERR_DIR="$HOME/.local/share/claude-equipo"
HERR_PY="$HERR_DIR/python"
HERR_MODELO="$HERR_DIR/whisper/ggml-large-v3-turbo-q5_0.bin"
HERR_MODELO_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin"
HERR_MODELO_BYTES=574041195

# fórmula:programa — se instala la fórmula solo si el programa no está ya (por
# ejemplo, pandoc o node instalados por otra vía).
# pandoc, node, exiftool y yt-dlp ya no van por aquí: se bajan de su fuente oficial.
# whisper-cpp se agrega solo si la persona va a trabajar audio (ver brew_falta).
BREW_FORMULAS=(poppler:pdftotext qpdf:qpdf tesseract:tesseract ffmpeg:ffmpeg
               imagemagick:magick)
PY_LIBS=(pypdf pdfplumber pymupdf pikepdf reportlab pdf2image img2pdf pytesseract
         python-docx openpyxl xlsxwriter pandas python-pptx pillow matplotlib defusedxml
         "markitdown[all]" qrcode)
# Apple Vision y Silero: aparte de PY_LIBS porque torch pesa y tarda; si falla,
# el Python de documentos queda igual. Sin torchaudio: su torchcodec choca con
# torch nuevo; el audio se lee con soundfile.
PY_VISION_LIBS=(ocrmac)
PY_VOZ_LIBS=(silero-vad soundfile)
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
  quiere_audio && ! tiene whisper-cli && echo whisper-cpp
  return 0
}

instalar_formulas() {
  local faltan; faltan="$(brew_falta | tr '\n' ' ')"
  [[ -z "${faltan// /}" ]] && return 0
  gris "Instalando: $faltan"
  HOMEBREW_NO_ENV_HINTS=1 brew install $faltan >/dev/null 2>&1
  [[ -z "$(brew_falta)" ]]
}

tiene_libreoffice() { [[ -d /Applications/LibreOffice.app || -d "$HOME/Applications/LibreOffice.app" ]]; }

# El .dmg oficial de The Document Foundation (instalar_libreoffice_dmg, en
# lib-intel.sh), en Intel y en Apple Silicon.
instalar_libreoffice() { instalar_libreoffice_dmg; }

# ------------------------------------------------------------------ OCR en español

# Donde queda el español según cómo se instaló tesseract: Homebrew (Apple Silicon o
# Intel) o MacPorts (Intel).
tessdata_dirs() {
  local p; p="$(brew --prefix 2>/dev/null)"; [[ -n "$p" ]] && echo "$p/share/tessdata"
  echo /opt/homebrew/share/tessdata; echo /usr/local/share/tessdata; echo /opt/local/share/tessdata
}
tessdata_dir() { local d; for d in $(tessdata_dirs); do [[ -d "$d" ]] && { echo "$d"; return; }; done; }
tiene_ocr_es() {
  local d; for d in $(tessdata_dirs); do [[ -s "$d/spa.traineddata" ]] && return 0; done; return 1
}

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

tiene_vision() {
  [[ -x "$HERR_PY/bin/python" ]] || return 1
  "$HERR_PY/bin/python" -c "import ocrmac" 2>/dev/null
}

instalar_vision() {
  tiene_vision && return 0
  [[ -x "$HERR_PY/bin/python" ]] || return 1
  uv pip install --quiet --python "$HERR_PY/bin/python" "${PY_VISION_LIBS[@]}" >/dev/null 2>&1
  tiene_vision
}

tiene_silero() {
  [[ -x "$HERR_PY/bin/python" ]] || return 1
  "$HERR_PY/bin/python" -c "import silero_vad, soundfile, torch" 2>/dev/null
}

instalar_silero() {
  tiene_silero && return 0
  [[ -x "$HERR_PY/bin/python" ]] || return 1
  uv pip install --quiet --python "$HERR_PY/bin/python" "${PY_VOZ_LIBS[@]}" >/dev/null 2>&1
  tiene_silero
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
# watch (bradautomates/claude-video, MIT): Claude «ve» un video de YouTube,
# Instagram, TikTok o un archivo local — fotogramas con ffmpeg, subtítulos con
# yt-dlp. Se deja en modo local: nada sale de la computadora sin pedirlo.
# Los otros de knowledge-work-plugins (enterprise-search, operations,
# human-resources, finance, data, marketing, pdf-viewer) ya no se instalan: son
# flujos de empresa en inglés que el equipo no usa y solo llenan Claude de
# opciones. A quien ya los tenga no se le quitan.
MARKETPLACES=(anthropics/skills anthropics/knowledge-work-plugins bradautomates/claude-video)
PLUGINS=(document-skills@anthropic-agent-skills productivity@knowledge-work-plugins
         watch@claude-video)

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
  configurar_watch
  tiene_plugins
}

# Deja watch configurado para que no haga preguntas la primera vez: motor local
# (el video no se sube a Google), detalle «balanced» y sin transcripción en la
# nube. Corre con el Python del equipo (watch pide 3.10 o más; el de macOS es 3.9).
# Si la persona ya tiene su configuración, no se toca.
configurar_watch() {
  [[ -s "$HOME/.config/watch/.env" ]] && grep -qs '^SETUP_COMPLETE=' "$HOME/.config/watch/.env" && return 0
  local dir py="$HERR_PY/bin/python"
  dir="$(ls -d "$HOME"/.claude/plugins/cache/claude-video/watch/*/skills/watch 2>/dev/null | sort -V | tail -1)"
  [[ -n "$dir" && -x "$py" ]] || return 1
  "$py" "$dir/scripts/setup.py" --engine local >/dev/null 2>&1
  "$py" "$dir/scripts/setup.py" --backend none --detail balanced >/dev/null 2>&1
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
