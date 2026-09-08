#!/bin/bash
# Doble clic en Mac. Instala git, Claude Code y Claude Desktop, y deja la
# configuración del equipo en ~/.claude. Acepta un perfil como primer argumento.
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

echo
negrita "Claude para el equipo — instalación en Mac"
gris "Perfil: ${PERFIL:-base}"

[[ "$(uname -s)" == "Darwin" ]] || { rojo "Esto es para Mac."; exit 1; }
# claude.ai responde 403 a curl (protección anti-bots), así que la prueba de red va contra GitHub.
if ! curl -fsSI --max-time 15 "https://raw.githubusercontent.com/$REPO/main/README.md" >/dev/null 2>&1; then
  rojo "No hay internet. Conéctate e inténtalo otra vez."; exit 1
fi

paso "1/4  git"
if instalar_git; then verde "git $(git --version | awk '{print $3}')"; else rojo "git no quedó instalado. Claude Code funciona igual; solo pierde el historial de cambios de git."; fi

paso "2/4  Claude Code"
if instalar_claude; then verde "Claude Code $(claude --version 2>/dev/null | awk '{print $1}')"; persistir_ruta
else rojo "No se pudo instalar Claude Code."; gris "Prueba a mano: curl -fsSL https://claude.ai/install.sh | bash"; exit 1; fi

paso "3/4  Claude Desktop (la app de ventana)"
instalar_claude_desktop; r=$?
case $r in
  0) verde "Claude Desktop instalada" ;;
  3) rojo "La descarga no coincidió con su checksum; no se instaló. Bájala de claude.ai/download." ;;
  4) rojo "La app no venía firmada por Anthropic; no se instaló. Bájala de claude.ai/download." ;;
  *) rojo "No se pudo instalar Claude Desktop. Bájala de claude.ai/download (Claude Code funciona igual)." ;;
esac

paso "4/4  Configuración del equipo"
aplicar_config "$PWD" "$PERFIL"
verde "~/.claude listo (lo que había quedó respaldado en ~/.claude/respaldo-*)"

echo
negrita "Listo. Falta iniciar sesión, una sola vez:"
gris "Se abre Claude Code y te va a pedir entrar con tu cuenta (se abre el navegador)."
gris "Usa la cuenta con la que te invitaron al equipo."
echo
if : < /dev/tty 2>/dev/null; then
  read -r -p "  Presiona Enter para abrir Claude Code... " _ < /dev/tty
  ruta_extendida
  exec claude
else
  gris "Abre la Terminal y escribe:  claude"
fi
