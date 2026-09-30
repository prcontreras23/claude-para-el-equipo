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
# Dos servidores de GitHub con el mismo paquete: si el DNS de la red no encuentra
# github.com (pasó en la oficina), se prueba codeload.github.com.
bajar() {
  local url
  for url in "https://github.com/$REPO/archive/refs/heads/main.tar.gz" \
             "https://codeload.github.com/$REPO/tar.gz/refs/heads/main"; do
    rm -rf "$FUENTE"; mkdir -p "$FUENTE"
    curl -fsSL --retry 2 "$url" 2>/dev/null | tar -xz -C "$FUENTE" --strip-components=1 2>/dev/null \
      && [[ -f "$FUENTE/Instalar en Mac.command" ]] && return 0
  done
  return 1
}
bajar || morir "No se pudo bajar de GitHub. Si tienes internet, puede ser el DNS de la red: espera un minuto e inténtalo otra vez."
chmod +x "$FUENTE/Instalar en Mac.command" 2>/dev/null
verde "  ✓ listo"; gris "  archivos en $FUENTE"

if : < /dev/tty 2>/dev/null; then
  exec "$FUENTE/Instalar en Mac.command" "$PERFIL" < /dev/tty
else
  exec "$FUENTE/Instalar en Mac.command" "$PERFIL"
fi
