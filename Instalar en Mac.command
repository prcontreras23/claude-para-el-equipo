#!/bin/bash
# Doble clic en Mac. Deja una Mac lista para trabajar con Claude:
#   1. Diagnóstico: revisa qué hay y qué falta.
#   2. Instala lo que falte: git, Claude Code, Claude Desktop (trae Cowork),
#      Google Chrome y la configuración del equipo en ~/.claude.
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

diagnostico() {
  ruta_extendida
  fila "git"                           tiene_git_ok
  fila "Claude Code"                   tiene_claude_ok
  fila "Claude Desktop (con Cowork)"   tiene_claude_desktop
  fila "Google Chrome"                 tiene_chrome
  fila "Extensión de Claude en Chrome" tiene_ext_chrome
  fila "Configuración del equipo"      tiene_config_equipo
  fila "Sesión en Claude Code"         tiene_sesion_claude_code
}

echo
negrita "Claude para el equipo — instalación en Mac"
gris "Perfil: ${PERFIL:-base}"

[[ "$(uname -s)" == "Darwin" ]] || { rojo "Esto es para Mac."; exit 1; }
# claude.ai responde 403 a curl (protección anti-bots), así que la prueba de red va contra GitHub.
if ! curl -fsSI --max-time 15 "https://raw.githubusercontent.com/$REPO/main/README.md" >/dev/null 2>&1; then
  rojo "No hay internet. Conéctate e inténtalo otra vez."; exit 1
fi

# ── 1. Diagnóstico ──────────────────────────────────────────────────────────
paso "Revisando esta Mac..."
diagnostico

# ── 2. Instalar lo que falte ────────────────────────────────────────────────
paso "1/5  git"
if instalar_git; then verde "git $(git --version | awk '{print $3}')"; else rojo "git no quedó instalado. Claude Code funciona igual; solo pierde el historial de cambios de git."; fi

paso "2/5  Claude Code"
if instalar_claude; then verde "Claude Code $(claude --version 2>/dev/null | awk '{print $1}')"; persistir_ruta
else rojo "No se pudo instalar Claude Code."; gris "Prueba a mano: curl -fsSL https://claude.ai/install.sh | bash"; exit 1; fi

paso "3/5  Claude Desktop (la app de ventana; ahí está Cowork)"
tiene_claude_desktop || gris "Descargando (unos minutos)..."
instalar_claude_desktop; r=$?
case $r in
  0) verde "Claude Desktop instalada" ;;
  3) rojo "La descarga no coincidió con su checksum; no se instaló." ;;
  4) rojo "La app no venía firmada por Anthropic; no se instaló." ;;
  *) rojo "No se pudo instalar sola." ;;
esac
[[ $r -ne 0 ]] && gris "Más abajo se abre la página para bajarla a mano."

paso "4/5  Google Chrome (para la extensión de Claude)"
tiene_chrome || gris "Descargando (unos minutos)..."
instalar_chrome; r=$?
case $r in
  0) verde "Google Chrome instalado" ;;
  4) rojo "Chrome no venía firmado por Google; no se instaló." ;;
  *) rojo "No se pudo instalar solo." ;;
esac
[[ $r -ne 0 ]] && gris "Más abajo se abre la página para bajarlo a mano."

paso "5/5  Configuración del equipo"
aplicar_config "$PWD" "$PERFIL"
verde "~/.claude listo (lo que había quedó respaldado en ~/.claude/respaldo-*)"

# ── 3. Pasos que hace la persona. No se sigue hasta que cada uno quede hecho. ─
if ! : < /dev/tty 2>/dev/null; then
  echo
  negrita "Faltan cuatro pasos que se hacen a mano:"
  gris "1. Entrar en claude.ai con tu cuenta"
  gris "2. Abrir Claude Desktop y entrar (si no está, bajarla de claude.ai/download)"
  gris "3. Añadir la extensión de Claude a Chrome y entrar: $CHROME_EXT_URL"
  gris "4. Abrir la Terminal, escribir  claude  y entrar"
  exit 0
fi

echo
negrita "Ahora faltan cuatro pasos que haces tú. El instalador espera a que termines cada uno."

paso "A/D  Entrar a Claude en línea"
gris "Se abre claude.ai en el navegador. Escribe el correo con el que te invitaron;"
gris "Claude te manda un código a ese correo. Pégalo y entra."
abrir_web "https://claude.ai/login"
esperar "Cuando ya estés dentro de claude.ai, presiona Enter..."
verde "claude.ai"

paso "B/D  Claude Desktop"
while ! tiene_claude_desktop; do
  rojo "Claude Desktop no está en Aplicaciones."
  gris "Se abre la página de descarga: bájala, abre el archivo y arrastra Claude a Aplicaciones."
  abrir_web "https://claude.ai/download"
  esperar "Cuando esté en Aplicaciones, presiona Enter..."
done
open -a Claude
gris "Se abrió Claude Desktop. Entra con el mismo correo (te llega otro código)."
gris "Ahí mismo, arriba, están Chat, Cowork y Code."
esperar "Cuando estés dentro de Claude Desktop, presiona Enter..."
verde "Claude Desktop"

paso "C/D  Extensión de Claude en Chrome"
while ! tiene_chrome; do
  rojo "Google Chrome no está instalado, y la extensión solo funciona en Chrome."
  gris "Se abre la página de Chrome: bájalo, abre el archivo y arrastra Chrome a Aplicaciones."
  open "https://www.google.com/chrome/"
  esperar "Cuando Chrome esté en Aplicaciones, presiona Enter..."
done
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

# ── 4. Diagnóstico final y Claude Code ──────────────────────────────────────
paso "Cómo quedó esta Mac"
diagnostico

paso "D/D  Claude Code"
if tiene_sesion_claude_code; then
  gris "Claude Code ya tiene tu cuenta. Se abre para que empieces a trabajar."
else
  gris "Se abre Claude Code aquí mismo. Elige entrar con tu cuenta de Claude"
  gris "(se abre el navegador) y usa el mismo correo."
fi
esperar "Presiona Enter para abrir Claude Code..."
ruta_extendida
# Claude Code (Bun) se cae con «EINVAL: invalid argument, kqueue» si su entrada es
# /dev/tty, porque kqueue de macOS no acepta ese dispositivo. Se le da el terminal
# real (/dev/ttysNNN), que es lo mismo que tiene cuando se abre a mano.
real_tty="$(ps -o tty= -p $$ 2>/dev/null | tr -d ' ')"
if [[ -n "$real_tty" && "$real_tty" != "??" && -c "/dev/$real_tty" ]]; then
  exec claude < "/dev/$real_tty"
fi
negrita "Escribe  claude  y presiona Enter para empezar."
