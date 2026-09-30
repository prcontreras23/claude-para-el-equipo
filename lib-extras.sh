#!/bin/bash
# Extras de "Instalar en Mac.command": app de Claude en el celular (QR), FastTrack,
# WhatsApp (opcional) y el segundo cerebro en Obsidian (opcional, patrón LLM Wiki
# de Karpathy). Usa esperar/gris/verde/rojo/negrita del instalador.

# ------------------------------------------------------------------ Preguntas

ya_hecho() {  # ya_hecho "¿Ya ...?" → 0 si la persona dice que sí
  local r; read -r -p "  $1 (s/n) > " r < /dev/tty; [[ "$r" == [sS]* ]]
}

# ------------------------------------------------------------------ App del celular

APP_IPHONE="https://apps.apple.com/app/claude-by-anthropic/id6473753684"
APP_ANDROID="https://play.google.com/store/apps/details?id=com.anthropic.claude"

mostrar_qr() {
  local py="$HERR_PY/bin/python"
  if [[ -x "$py" ]] && "$py" -c "import qrcode" 2>/dev/null; then
    "$py" -c "import qrcode,sys; q=qrcode.QRCode(border=2); q.add_data(sys.argv[1]); q.print_ascii(invert=True)" "$1" | sed 's/^/    /'
  else
    gris "(No pude dibujar el código QR.)"
  fi
  gris "Enlace: $1"
}

paso_celular() {
  gris "Con la app en el celular sigues tus conversaciones fuera de la oficina, le dictas"
  gris "por voz y le mandas fotos de documentos. Es la misma cuenta y las mismas conversaciones."
  if ya_hecho "¿Ya tienes la app de Claude en tu celular?"; then verde "App del celular"; return; fi
  local t=""
  while [[ "$t" != "1" && "$t" != "2" ]]; do
    read -r -p "  ¿Tu celular es 1 = iPhone o 2 = Android? > " t < /dev/tty
  done
  local url="$APP_IPHONE"; [[ "$t" == "2" ]] && url="$APP_ANDROID"
  echo
  gris "Abre la cámara del celular y apunta a este código:"
  echo; mostrar_qr "$url"; echo
  gris "Instala la app y entra con el mismo correo (te llega un código)."
  esperar "Cuando ya estés dentro de la app, presiona Enter..."
  verde "App del celular"
}

# ------------------------------------------------------------------ FastTrack (búsqueda de literatura académica)

FASTTRACK_URL="https://literature.researchfasttrack.com/mcp"
tiene_fasttrack() { claude mcp get fasttrack-literature >/dev/null 2>&1; }

instalar_fasttrack() {
  tiene_fasttrack && return 0
  claude mcp add --transport http --scope user fasttrack-literature "$FASTTRACK_URL" >/dev/null 2>&1
  tiene_fasttrack
}

# ------------------------------------------------------------------ WhatsApp (opcional)

tiene_whatsapp() { claude mcp get whatsapp >/dev/null 2>&1; }

paso_whatsapp() {
  if tiene_whatsapp; then verde "WhatsApp ya está conectado con Claude"; return; fi
  gris "Puedes conectar tu WhatsApp para pedirle a Claude cosas como «búscame lo que me"
  gris "escribió Juan la semana pasada» o «prepárame la respuesta a este grupo»."
  gris "Antes de decidir:"
  gris "  • Claude tendría acceso a TODO tu WhatsApp: chats personales, grupos y fotos."
  gris "  • Los mensajes se quedan en esta computadora; a Claude solo va lo que le pidas."
  gris "  • Puede enviar mensajes en tu nombre: revisa siempre el borrador antes."
  gris "  • Se desconecta cuando quieras: WhatsApp → Ajustes → Dispositivos vinculados."
  gris "  • Si esta computadora la usan otras personas, mejor no lo conectes."
  if ! ya_hecho "¿Quieres conectar tu WhatsApp ahora?"; then gris "Se salta. Lo puedes hacer después volviendo a correr el instalador."; return; fi
  gris "Ten el celular a mano: vas a escanear un código QR desde WhatsApp."
  curl -fsSL https://raw.githubusercontent.com/prcontreras23/whatsapp-para-claude/main/instalar.sh | bash
  if tiene_whatsapp; then verde "WhatsApp conectado"; else rojo "WhatsApp no quedó conectado. Puedes volver a intentarlo después."; fi
}

# ------------------------------------------------------------------ Segundo cerebro en Obsidian (opcional)

tiene_obsidian() { [[ -d /Applications/Obsidian.app || -d "$HOME/Applications/Obsidian.app" ]]; }

instalar_obsidian() {
  tiene_obsidian && return 0
  tiene_brew || return 1
  HOMEBREW_NO_ENV_HINTS=1 brew install --cask obsidian >/dev/null 2>&1
  tiene_obsidian
}

# Dónde va: la persona escoge. iCloud se ofrece primero porque se sincroniza con el
# iPhone/iPad; dentro de la carpeta elegida se crea «Segundo cerebro».
carpeta_icloud() {
  local md="$HOME/Library/Mobile Documents"
  if [[ -d "$md/iCloud~md~obsidian/Documents" ]]; then echo "$md/iCloud~md~obsidian/Documents"
  elif [[ -d "$md/com~apple~CloudDocs" ]]; then echo "$md/com~apple~CloudDocs"; fi
}

elegir_ruta_segundo_cerebro() {  # deja la ruta en $RUTA
  local icloud; icloud="$(carpeta_icloud)"
  printf '\033[1m  ¿Dónde quieres crear tu segundo cerebro?\033[0m\n'
  if [[ -n "$icloud" ]]; then
    gris "  1 = iCloud (recomendado: se sincroniza con tu iPhone o iPad)"
  else
    gris "  1 = iCloud — no está activo en esta Mac (Ajustes del Sistema → tu nombre → iCloud → iCloud Drive)"
  fi
  gris "  2 = Documentos (solo en esta Mac)"
  gris "  3 = Escoger otra carpeta"
  local rec=2; [[ -n "$icloud" ]] && rec=1
  gris "  (Enter = $rec)"
  local o="" base=""
  while [[ -z "$base" ]]; do
    read -r -p "  > " o < /dev/tty
    [[ -z "$o" ]] && o="$rec"
    case "$o" in
      1) [[ -n "$icloud" ]] && base="$icloud" || rojo "iCloud no está activo; escoge 2 o 3, o actívalo y vuelve a correr esto." ;;
      2) base="$HOME/Documents" ;;
      3) base="$(osascript -e 'POSIX path of (choose folder with prompt "Escoge dónde crear tu Segundo cerebro")' 2>/dev/null)"
         base="${base%/}"; [[ -z "$base" ]] && rojo "No escogiste carpeta. Elige 1, 2 o 3." ;;
      *) rojo "Escribe 1, 2 o 3." ;;
    esac
  done
  RUTA="$base/Segundo cerebro"
}

SEGUNDO_CEREBRO_NOTA="$HOME/.claude/segundo-cerebro.md"
tiene_segundo_cerebro() { [[ -f "$SEGUNDO_CEREBRO_NOTA" ]]; }

# Registra la bóveda en Obsidian (obsidian.json) para que abra directo en ella.
registrar_boveda() {
  local ruta="$1" cfg="$HOME/Library/Application Support/obsidian/obsidian.json" py="$HERR_PY/bin/python"
  [[ -x "$py" ]] || py="$(command -v python3)"
  [[ -n "$py" ]] || return 1
  osascript -e 'tell application "Obsidian" to quit' >/dev/null 2>&1; sleep 1
  mkdir -p "$(dirname "$cfg")"
  "$py" - "$cfg" "$ruta" <<'PY'
import json, os, secrets, sys, time
cfg, ruta = sys.argv[1], sys.argv[2]
d = {}
if os.path.exists(cfg):
    try: d = json.load(open(cfg))
    except Exception: sys.exit(0)  # no se puede leer: no se toca, se perderían las bóvedas
v = d.setdefault("vaults", {})
for x in v.values(): x.pop("open", None)
ya = [k for k, x in v.items() if x.get("path") == ruta]
k = ya[0] if ya else secrets.token_hex(8)
v[k] = {"path": ruta, "ts": int(time.time() * 1000), "open": True}
json.dump(d, open(cfg, "w"))
PY
}

# reemplaza {{CLAVE}} en un archivo
rellenar() {
  local f="$1"; shift
  local txt; txt="$(cat "$f")"
  while [[ $# -ge 2 ]]; do txt="${txt//\{\{$1\}\}/$2}"; shift 2; done
  printf '%s\n' "$txt" > "$f"
}

paso_segundo_cerebro() {
  gris "Un «segundo cerebro» es una carpeta de notas en Obsidian que Claude organiza por ti:"
  gris "le traes documentos, actas, audios o artículos, y él los resume, los conecta entre sí"
  gris "y te responde con lo que hay ahí. (Patrón LLM Wiki de Andrej Karpathy.)"
  if tiene_segundo_cerebro; then
    verde "Ya tienes un segundo cerebro: $(sed -n 's/^- \*\*Carpeta\*\*: //p' "$SEGUNDO_CEREBRO_NOTA")"
    return
  fi
  if ! ya_hecho "¿Quieres configurarlo ahora? Es opcional"; then gris "Se salta. Lo puedes hacer después volviendo a correr el instalador."; return; fi

  gris "Instalando Obsidian..."
  if instalar_obsidian; then verde "Obsidian"; else rojo "No se pudo instalar Obsidian. Bájalo de obsidian.md y vuelve a correr esto."; return; fi

  echo
  elegir_ruta_segundo_cerebro; local ruta="$RUTA"
  gris "Carpeta: $ruta"
  if [[ -e "$ruta/CLAUDE.md" ]]; then
    gris "Esa carpeta ya tiene un CLAUDE.md; se deja como está."
  else
    echo
    gris "Cuatro preguntas para armarlo a tu medida:"
    local usos="" u
    printf '\033[1m  ¿Para qué lo vas a usar? Escribe los números separados por coma.\033[0m\n'
    gris "  1 = mi trabajo (reuniones, casos, informes)   2 = estudio bíblico y sermones"
    gris "  3 = formación y estudios (cursos, maestría)   4 = personal (metas, salud, finanzas)"
    read -r -p "  > " u < /dev/tty
    local carpetas="  personas/    una página por persona
  temas/       una página por tema"
    [[ "$u" == *1* ]] && { usos+="trabajo del cargo (reuniones, casos, informes); "; carpetas+="
  proyectos/   una página por proyecto o caso
  reuniones/   una página por reunión, con acuerdos y pendientes"; }
    [[ "$u" == *2* ]] && { usos+="estudio bíblico y sermones; "; carpetas+="
  estudios/    estudios por pasaje o libro de la Biblia
  sermones/    sermones y bosquejos"; }
    [[ "$u" == *3* ]] && { usos+="formación y estudios; "; carpetas+="
  cursos/      una página por curso o materia"; }
    [[ "$u" == *4* ]] && { usos+="personal (metas, salud, finanzas); "; carpetas+="
  personal/    metas, hábitos, salud y finanzas"; }
    [[ -z "$usos" ]] && usos="general; "
    usos="${usos%; }"
    preguntar "¿Qué temas principales vas a guardar ahí?" "las iglesias de mi distrito, finanzas, evangelismo, liderazgo"; local temas="$R"
    preguntar "¿Qué vas a traer como fuentes?" "PDF, actas, audios de reuniones, artículos de internet, fotos de documentos"; local fuentes="$R"
    local m="" modo
    while [[ "$m" != "1" && "$m" != "2" ]]; do
      printf '\033[1m  Cuando le traigas algo nuevo, ¿qué prefieres?\033[0m\n'
      read -r -p "  1 = que Claude me comente lo importante antes de integrarlo · 2 = que lo integre solo y me dé un resumen > " m < /dev/tty
    done
    if [[ "$m" == "1" ]]; then modo="Comentar con la persona los puntos clave y preguntarle qué destacar antes de escribir en la wiki."
    else modo="Integrar sin preguntar y, al terminar, darle a la persona un resumen corto de qué páginas se crearon o cambiaron."; fi
    local nombre; nombre="$(sed -n 's/^- \*\*Cómo llamarme\*\*: //p' "$SOBRE_MI" 2>/dev/null)"; [[ -z "$nombre" ]] && nombre="la persona"

    mkdir -p "$ruta"
    cp -R "$PWD/segundo-cerebro/." "$ruta/"
    mkdir -p "$ruta/fuentes/"{documentos,audios,web,imagenes,notas} "$ruta/wiki/"{fuentes,respuestas}
    while IFS= read -r linea; do
      local c; c="$(echo "$linea" | awk '{print $1}')"; [[ -n "$c" ]] && mkdir -p "$ruta/wiki/${c%/}"
    done <<< "$carpetas"
    local hoy; hoy="$(date +%Y-%m-%d)"
    rellenar "$ruta/CLAUDE.md" NOMBRE "$nombre" FECHA "$hoy" USOS "$usos" TEMAS "$temas" FUENTES "$fuentes" MODO_INGEST "$modo" CARPETAS_WIKI "$carpetas"
    rellenar "$ruta/wiki/log.md" FECHA "$hoy"
    verde "Segundo cerebro creado"
  fi

  cat > "$SEGUNDO_CEREBRO_NOTA" <<FIN
# Segundo cerebro

- **Carpeta**: $ruta
- Es una wiki de Obsidian con el patrón LLM Wiki de Karpathy. Sus reglas están en el CLAUDE.md de esa carpeta.
- Cuando la persona pida guardar, anotar, ingerir o buscar algo en «su segundo cerebro», «sus notas» u «Obsidian», trabajar en esa carpeta siguiendo su CLAUDE.md.
FIN
  registrar_boveda "$ruta" || true
  open -a Obsidian 2>/dev/null
  gris "Se abrió Obsidian con tu segundo cerebro. Empieza por la nota «Inicio»."
  gris "Para trabajarlo con Claude: en Claude Desktop → Code, elige la carpeta «Segundo cerebro»."

  if tiene_chrome && ya_hecho "¿Quieres la extensión Obsidian Web Clipper para guardar artículos de internet?"; then
    gris "Dale a «Añadir a Chrome». En sus opciones pon como carpeta:  fuentes/web"
    open -a "Google Chrome" "https://chromewebstore.google.com/detail/cnjifjpddelmedmihgijeibhnjfabmlf"
    esperar "Cuando la hayas añadido, presiona Enter..."
  fi
  verde "Segundo cerebro"
}
