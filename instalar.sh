#!/bin/bash
# Arranque de una línea para Mac (esquiva Gatekeeper: lo que baja curl no queda
# marcado como "de internet"):
#
#   curl -fsSL https://raw.githubusercontent.com/prcontreras23/claude-para-el-equipo/main/instalar.sh | bash
#
# Con perfil:
#
#   curl -fsSL .../instalar.sh | bash -s -- nombre-del-perfil

set -uo pipefail
REPO="prcontreras23/claude-para-el-equipo"
FUENTE="$HOME/claude-para-el-equipo-fuente"
PERFIL="${1:-}"

rojo()  { printf '\033[31m%s\033[0m\n' "$*"; }
verde() { printf '\033[32m%s\033[0m\n' "$*"; }
gris()  { printf '\033[90m%s\033[0m\n' "$*"; }
morir() { echo; rojo "  ✗ $*"; echo; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || morir "Este arranque es para Mac."

echo; printf '\033[1m%s\033[0m\n' "Bajando Claude para el equipo..."; echo
rm -rf "$FUENTE"; mkdir -p "$FUENTE"
curl -fsSL "https://github.com/$REPO/archive/refs/heads/main.tar.gz" | tar -xz -C "$FUENTE" --strip-components=1 \
  || morir "No se pudo bajar. Revisa que tengas internet e inténtalo otra vez."
chmod +x "$FUENTE/Instalar en Mac.command" 2>/dev/null
verde "  ✓ listo"; gris "  archivos en $FUENTE"

if : < /dev/tty 2>/dev/null; then
  exec "$FUENTE/Instalar en Mac.command" "$PERFIL" < /dev/tty
else
  exec "$FUENTE/Instalar en Mac.command" "$PERFIL"
fi
