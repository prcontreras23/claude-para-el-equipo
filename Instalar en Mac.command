#!/bin/bash
# Doble clic en Mac. Deja una Mac lista para trabajar con Claude:
#   1. Diagnóstico: revisa qué hay y qué falta.
#   2. Instala lo que falte: git, Claude Code, Claude Desktop (trae Cowork),
#      Google Chrome, las herramientas para PDF, Word, Excel, PowerPoint,
#      imágenes, OCR y transcripción de audio (ver lib-herramientas.sh), y la
#      configuración del equipo en ~/.claude.
#   3. Pasos que hace la persona, sin saltarse ninguno: entrar en claude.ai,
#      entrar en Claude Desktop, añadir la extensión de Claude a Chrome y entrar.
#   4. Diagnóstico final y abre Claude Code para entrar con la cuenta.
# Acepta un perfil como primer argumento.
#
# Si este archivo se bajó con el navegador, macOS no lo deja abrir con doble clic
# (Gatekeeper). Usa entonces la línea de instalar.sh que está en el README.

cd "$(dirname "$0")" || exit 1
set -uo pipefail
REPO="prcontreras23/claude-para-el-equipo"
PERFIL="${1:-${PERFIL:-}}"

source ./lib-requisitos.sh
source ./lib-config.sh
source ./lib-herramientas.sh
source ./lib-perfil.sh
source ./lib-extras.sh

negrita() { printf '\033[1m%s\033[0m\n' "$*"; }
verde()   { printf '\033[32m  ✓ %s\033[0m\n' "$*"; }
rojo()    { printf '\033[31m  ✗ %s\033[0m\n' "$*"; }
gris()    { printf '\033[90m  %s\033[0m\n' "$*"; }
paso()    { echo; negrita "$*"; }
esperar() { read -r -p "  $1 " _ < /dev/tty; }
abrir_web() { if tiene_chrome; then open -a "Google Chrome" "$1"; else open "$1"; fi; }
fila()    { if "$2"; then verde "$1"; else rojo "$1 — falta"; fi; }
tiene_git_ok()    { xcode-select -p >/dev/null 2>&1 && tiene git; }
tiene_claude_ok() { tiene claude; }

# Terminal real (/dev/ttysNNN). Hace falta para Homebrew (pide contraseña) y para
# abrir Claude Code: Bun se cae con «EINVAL: invalid argument, kqueue» si su
# entrada es /dev/tty, porque kqueue de macOS no acepta ese dispositivo.
real_tty="$(ps -o tty= -p $$ 2>/dev/null | tr -d ' ')"
[[ -n "$real_tty" && "$real_tty" != "??" && -c "/dev/$real_tty" ]] && real_tty="/dev/$real_tty" || real_tty=""

diagnostico() {
  ruta_extendida
  fila "git"                           tiene_git_ok
  fila "Claude Code"                   tiene_claude_ok
  fila "Claude Desktop (con Cowork)"   tiene_claude_desktop
  fila "Google Chrome"                 tiene_chrome
  fila "Extensión de Claude en Chrome" tiene_ext_chrome
  fila "Homebrew"                      tiene_brew
  fila "PDF (poppler, qpdf)"           tiene_pdf_tools
  fila "OCR en español (tesseract)"    tiene_ocr
  fila "Word/Excel/PPT (LibreOffice, pandoc)" tiene_conversion
  fila "Imágenes (ImageMagick, exiftool)"     tiene_imagenes
  fila "Audio y video (ffmpeg, yt-dlp)"       tiene_audio
  fila "Transcripción (whisper + modelo)"     tiene_transcripcion
  fila "Python con librerías de documentos"   tiene_python_docs
  fila "Node con docx y pptxgenjs"            tiene_npm_docs
  fila "Plugins de oficina y documentos"     tiene_plugins
  if tiene_office_alguna; then fila "Claude en Word, Excel y PowerPoint" tiene_claude_en_office
  else gris "Word, Excel y PowerPoint no están instalados; se salta Claude en Office."; fi
  fila "Configuración del equipo"      tiene_config_equipo
  fila "FastTrack (literatura académica)"    tiene_fasttrack
  fila "Tu perfil (sobre-mi.md)"       tiene_perfil
  if tiene_whatsapp; then verde "WhatsApp conectado"; else gris "WhatsApp: no conectado (opcional)"; fi
  if tiene_segundo_cerebro; then verde "Segundo cerebro en Obsidian"; else gris "Segundo cerebro: no configurado (opcional)"; fi
  fila "Sesión en Claude Code"         sesion_claude_code_activa
}

echo
negrita "Claude para el equipo — instalación en Mac"
gris "Perfil: ${PERFIL:-base}"
echo
gris "Esto deja tu Mac lista para trabajar con Claude. Tarda de 20 a 40 minutos la primera"
gris "vez; si vuelves a correrlo, solo hace lo que falte."
gris "Casi todo va solo. Cuando veas  >  escribe tu respuesta y presiona Enter."
gris "Si en algún momento te pide la contraseña de la Mac, es la misma con la que entras a ella."

[[ "$(uname -s)" == "Darwin" ]] || { rojo "Esto es para Mac."; exit 1; }
# claude.ai responde 403 a curl (protección anti-bots), así que la prueba de red va contra GitHub.
if ! curl -fsSI --max-time 15 "https://raw.githubusercontent.com/$REPO/main/README.md" >/dev/null 2>&1; then
  rojo "No hay internet. Conéctate e inténtalo otra vez."; exit 1
fi

# ── 1. Diagnóstico ──────────────────────────────────────────────────────────
paso "Revisando esta Mac..."
diagnostico

# ── 2. Instalar lo que falte ────────────────────────────────────────────────
paso "1/7  git"
if instalar_git; then verde "git $(git --version | awk '{print $3}')"; else rojo "git no quedó instalado. Claude Code funciona igual; solo pierde el historial de cambios de git."; fi

paso "2/7  Claude Code"
if instalar_claude; then verde "Claude Code $(claude --version 2>/dev/null | awk '{print $1}')"; persistir_ruta
else rojo "No se pudo instalar Claude Code."; gris "Prueba a mano: curl -fsSL https://claude.ai/install.sh | bash"; exit 1; fi

paso "3/7  Claude Desktop (la app de ventana; ahí está Cowork)"
tiene_claude_desktop || gris "Descargando (unos minutos)..."
instalar_claude_desktop; r=$?
case $r in
  0) verde "Claude Desktop instalada" ;;
  3) rojo "La descarga no coincidió con su checksum; no se instaló." ;;
  4) rojo "La app no venía firmada por Anthropic; no se instaló." ;;
  *) rojo "No se pudo instalar sola." ;;
esac
[[ $r -ne 0 ]] && gris "Más abajo se abre la página para bajarla a mano."

paso "4/7  Google Chrome (para la extensión de Claude)"
tiene_chrome || gris "Descargando (unos minutos)..."
instalar_chrome; r=$?
case $r in
  0) verde "Google Chrome instalado" ;;
  4) rojo "Chrome no venía firmado por Google; no se instaló." ;;
  *) rojo "No se pudo instalar solo." ;;
esac
[[ $r -ne 0 ]] && gris "Más abajo se abre la página para bajarlo a mano."

paso "5/7  Herramientas para documentos, imágenes, OCR y audio"
if tiene_brew; then
  verde "Homebrew"
elif [[ -n "$real_tty" ]]; then
  gris "Hace falta Homebrew (el instalador de programas de la Mac)."
  gris "Te va a pedir la contraseña con la que entras a esta Mac y luego un Enter."
  gris "Mientras la escribes no se ven los caracteres; es normal."
  if instalar_brew "$real_tty"; then verde "Homebrew"; else rojo "Homebrew no quedó instalado."; fi
else
  rojo "Falta Homebrew y hace falta la Terminal para instalarlo (pide contraseña)."
fi

if tiene_brew; then
  gris "Programas (esto puede tardar 10–20 minutos la primera vez)..."
  if instalar_formulas; then verde "poppler, qpdf, tesseract, pandoc, ffmpeg, ImageMagick, exiftool, whisper, node, yt-dlp"
  else rojo "No quedaron todos: $(brew_falta | tr '\n' ' ')"; fi
  tiene_libreoffice || gris "Bajando LibreOffice (~300 MB, unos minutos; no cierres esta ventana)..."
  if instalar_libreoffice; then verde "LibreOffice"; else rojo "LibreOffice no quedó instalado."; fi
  if instalar_ocr_es; then verde "OCR en español"; else rojo "No se pudo bajar el español para el OCR."; fi
  tiene_npm_docs || gris "Instalando docx y pptxgenjs..."
  if instalar_npm_docs; then verde "Node: docx y pptxgenjs"; else rojo "No se pudieron instalar docx y pptxgenjs."; fi
else
  rojo "Sin Homebrew se saltan: PDF, OCR, LibreOffice, pandoc, ffmpeg, ImageMagick, whisper y node."
fi

tiene_python_docs || gris "Preparando Python con las librerías de documentos (unos minutos)..."
if instalar_uv && instalar_python_docs; then persistir_python_docs; verde "Python con librerías de PDF, Word, Excel, PowerPoint, imágenes y OCR"
else rojo "No se pudo preparar el Python con las librerías de documentos."; fi

tiene_modelo_whisper || gris "Bajando el modelo para transcribir audio (~550 MB)..."
if instalar_modelo_whisper; then verde "Modelo de transcripción en $HERR_MODELO"; else rojo "No se pudo bajar el modelo de transcripción."; fi


paso "6/7  Configuración del equipo"
aplicar_config "$PWD" "$PERFIL"
verde "~/.claude listo (lo que había quedó respaldado en ~/.claude/respaldo-*)"

paso "7/7  Plugins y conectores de Claude Code"
gris "document-skills, productivity, enterprise-search, operations, human-resources,"
gris "finance, data, marketing y pdf-viewer"
if instalar_plugins; then verde "Plugins instalados y activos"
else rojo "No quedaron: $(plugins_faltan | tr '\n' ' ')"; fi
if instalar_fasttrack; then verde "FastTrack (búsqueda de literatura académica)"; else rojo "No se pudo agregar FastTrack."; fi

# ── 3. Pasos que hace la persona. No se sigue hasta que cada uno quede hecho. ─
if ! : < /dev/tty 2>/dev/null; then
  echo
  negrita "Faltan pasos que se hacen a mano. Vuelve a correr el instalador en la Terminal para que te guíe."
  exit 0
fi

TOTAL=10
n=0
siguiente() { n=$((n + 1)); paso "Paso $n de $TOTAL — $1"; }

echo
negrita "Lo automático terminó. Ahora te guío en $TOTAL pasos cortos."
gris "En cada uno se abre lo que haga falta y el instalador espera a que termines."

siguiente "Entrar a Claude en internet"
if ya_hecho "¿Ya entraste antes a claude.ai con tu correo del equipo?"; then verde "claude.ai"
else
  gris "Se abre claude.ai. Escribe el correo con el que te invitaron; Claude te manda"
  gris "un código a ese correo. Búscalo en tu correo, pégalo y entra."
  abrir_web "https://claude.ai/login"
  esperar "Cuando ya estés dentro de claude.ai, presiona Enter..."
  verde "claude.ai"
fi

siguiente "Conectar tu correo, calendario y archivos"
gris "Así Claude puede leer tus correos, ver tu agenda y buscar en tus documentos cuando"
gris "se lo pidas. Sirve en claude.ai, Claude Desktop, Cowork y Claude Code."
if ya_hecho "¿Ya conectaste tu correo y tu calendario en claude.ai?"; then verde "Conectores"
else
  gris "Se abre la página de conectores. Dale a «Conectar» en los que uses:"
  gris "  • Microsoft 365 — Outlook, calendario, OneDrive y Teams (el correo del trabajo)"
  gris "  • Gmail y Google Calendar — si también usas Google"
  gris "  • Google Drive — si guardas documentos ahí"
  gris "  • FastTrack — «Agregar conector personalizado» y pega: $FASTTRACK_URL"
  gris "Si Microsoft 365 no aparece, avisa a Secretaría: lo activa el administrador del equipo."
  abrir_web "https://claude.ai/settings/connectors"
  esperar "Cuando hayas conectado los que usas, presiona Enter..."
  verde "Conectores"
fi

siguiente "Tu perfil: que Claude sepa quién eres"
gris "Claude trabaja mucho mejor cuando sabe tu cargo, tu oficina y lo que haces cada día:"
gris "las cartas le salen con tu cargo, los informes con tu oficina, y no tienes que"
gris "explicarle lo mismo en cada conversación. Son seis preguntas cortas."
rehacer="s"
if tiene_perfil; then
  gris "Ya tienes un perfil guardado."
  ya_hecho "¿Quieres volver a llenarlo?" || rehacer="n"
fi
if [[ "$rehacer" == "s" ]]; then
  echo
  armar_perfil
  verde "Guardado (Claude Code y Claude Desktop lo leen siempre)"
  echo
  gris "Ahora el mismo perfil en claude.ai, para que también lo usen el chat y Cowork."
  printf '%s' "$PERFIL_TEXTO" | pbcopy
  gris "Ya copié este texto; solo tienes que pegarlo con Cmd+V:"
  echo; printf '%s\n' "$PERFIL_TEXTO" | fold -s -w 86 | sed 's/^/    /'; echo
  gris "Se abre tu perfil en claude.ai. Pon tu nombre donde dice cómo llamarte y pega el"
  gris "texto en «preferencias personales». Dale a Guardar."
  gris "Si ves la opción de Memoria, actívala: así Claude recuerda lo que vas trabajando."
  abrir_web "https://claude.ai/settings/profile"
  esperar "Cuando lo hayas guardado, presiona Enter..."
fi
verde "Perfil"

siguiente "Claude Desktop (Chat, Cowork y Code)"
while ! tiene_claude_desktop; do
  rojo "Claude Desktop no está en Aplicaciones."
  gris "Se abre la página de descarga: bájala, abre el archivo y arrastra Claude a Aplicaciones."
  abrir_web "https://claude.ai/download"
  esperar "Cuando esté en Aplicaciones, presiona Enter..."
done
open -a Claude
if ya_hecho "Se abrió Claude Desktop. ¿Ya estaba con tu cuenta adentro?"; then verde "Claude Desktop"
else
  gris "Entra con el mismo correo (te llega otro código). Arriba verás Chat, Cowork y Code."
  esperar "Cuando estés dentro de Claude Desktop, presiona Enter..."
  verde "Claude Desktop"
fi

siguiente "Extensión de Claude en Chrome"
gris "Con la extensión, Claude puede ayudarte dentro de cualquier página web."
while ! tiene_chrome; do
  rojo "Google Chrome no está instalado, y la extensión solo funciona en Chrome."
  gris "Se abre la página de Chrome: bájalo, abre el archivo y arrastra Chrome a Aplicaciones."
  open "https://www.google.com/chrome/"
  esperar "Cuando Chrome esté en Aplicaciones, presiona Enter..."
done
if tiene_ext_chrome && ya_hecho "La extensión ya está en Chrome. ¿Ya entraste en ella con tu cuenta?"; then verde "Extensión de Chrome"
else
  while ! tiene_ext_chrome; do
    gris "Se abre la extensión en Chrome. Dale a «Añadir a Chrome» y luego a «Añadir extensión»."
    open -a "Google Chrome" "$CHROME_EXT_URL"
    esperar "Cuando la hayas añadido, presiona Enter..."
    tiene_ext_chrome || rojo "Todavía no aparece la extensión en Chrome."
  done
  gris "Haz clic en el ícono de Claude arriba a la derecha en Chrome (si no se ve, está"
  gris "en la pieza de rompecabezas) y entra con tu cuenta."
  esperar "Cuando hayas entrado en la extensión, presiona Enter..."
  verde "Extensión de Chrome"
fi

siguiente "Claude en tu celular"
paso_celular

siguiente "Claude en Word, Excel y PowerPoint"
if ! tiene_office_alguna; then
  gris "Esta Mac no tiene Word, Excel ni PowerPoint. Se salta este paso."
fi
for app in Word Excel Powerpoint; do
  tiene_office_app "$app" || continue
  nombre="$(office_app_nombre "$app")"
  intentos=0
  while ! tiene_claude_office "$app"; do
    if (( intentos >= 3 )); then
      rojo "No se detecta Claude en $nombre. Sigue; revísalo después en $nombre → Inicio → Complementos."
      break
    fi
    gris "Se abre Claude para $nombre. Dale a «Obtener ahora», entra con tu correo del equipo"
    gris "y acepta abrirlo en $nombre. Si no abre: en $nombre ve a Inicio → Complementos,"
    gris "busca «Claude» y dale a «Agregar»."
    abrir_web "$(office_url "$app")"
    esperar "Cuando Claude aparezca en $nombre, ábrelo una vez y presiona Enter..."
    intentos=$((intentos + 1))
    tiene_claude_office "$app" || rojo "Todavía no aparece Claude en $nombre."
  done
  tiene_claude_office "$app" && verde "Claude en $nombre"
done

siguiente "WhatsApp (opcional)"
paso_whatsapp

siguiente "Tu segundo cerebro en Obsidian (opcional)"
paso_segundo_cerebro

# ── 4. Diagnóstico final y Claude Code ──────────────────────────────────────
paso "Cómo quedó esta Mac"
diagnostico

siguiente "Claude Code"
ruta_extendida
intentos=0
while ! sesion_claude_code_activa && (( intentos < 3 )); do
  gris "Se abre el navegador para que Claude Code entre con tu cuenta (el mismo correo)."
  if [[ -n "$real_tty" ]]; then claude auth login < "$real_tty"; else claude auth login; fi
  intentos=$((intentos + 1))
  sesion_claude_code_activa || rojo "Claude Code todavía no tiene tu cuenta."
done
sesion_claude_code_activa && verde "Claude Code con tu cuenta"

echo
negrita "Todo listo."
gris "Para trabajar, abre Claude Desktop: ahí tienes Chat, Cowork y Code."
tiene_segundo_cerebro && gris "Tu segundo cerebro está en Obsidian; empieza por la nota «Inicio»."
gris "Si más adelante quieres agregar WhatsApp o el segundo cerebro, vuelve a pegar la misma línea."
esperar "Presiona Enter para abrir Claude Code aquí mismo..."
# Terminal real, no /dev/tty (ver real_tty arriba).
[[ -n "$real_tty" ]] && exec claude < "$real_tty"
negrita "Escribe  claude  y presiona Enter para empezar."
