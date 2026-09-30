#!/bin/bash
# Perfil de la persona: unas preguntas cortas que dejan
#   ~/.claude/sobre-mi.md  → lo lee Claude Code (y el Code de Desktop) en toda
#                            conversación; config/CLAUDE.md lo importa. No está en
#                            config/, así que volver a instalar no lo pisa.
#   un texto para claude.ai → Configuración → Perfil, copiado al portapapeles.
# Lo carga "Instalar en Mac.command".

SOBRE_MI="$HOME/.claude/sobre-mi.md"

tiene_perfil() { [[ -s "$SOBRE_MI" ]]; }

preguntar() {  # preguntar "texto" "ejemplo" → respuesta en $R
  local r=""
  while [[ -z "$r" ]]; do
    printf '\033[1m  %s\033[0m\n' "$1"
    printf '\033[90m  (ej.: %s)\033[0m\n' "$2"
    read -r -p "  > " r < /dev/tty
  done
  R="$r"
}

armar_perfil() {
  preguntar "¿Cómo quieres que Claude te llame?" "Pastor Roberto, Noemí, Juan"; local nombre="$R"
  preguntar "¿Cuál es tu cargo?" "Pastor distrital, Tesorero, Secretaria, Director de Jóvenes"; local cargo="$R"
  preguntar "¿En qué oficina, departamento o distrito trabajas?" "Tesorería, Distrito Los Mina, Ministerio Personal"; local oficina="$R"
  preguntar "¿Qué tareas haces más seguido?" "cartas, informes, actas, presupuestos, sermones, planillas de Excel"; local tareas="$R"
  preguntar "¿Qué programas usas más?" "Outlook, Excel, Word, WhatsApp, Google Drive"; local programas="$R"
  local estilo=""
  while [[ "$estilo" != "1" && "$estilo" != "2" ]]; do
    printf '\033[1m  ¿Cómo prefieres las respuestas?\033[0m\n'
    read -r -p "  1 = cortas y al grano · 2 = detalladas, paso a paso > " estilo < /dev/tty
  done
  local pref; [[ "$estilo" == "1" ]] && pref="cortas y al grano" || pref="detalladas y paso a paso"

  mkdir -p "$(dirname "$SOBRE_MI")"
  cat > "$SOBRE_MI" <<FIN
# Sobre mí

- **Cómo llamarme**: $nombre
- **Cargo**: $cargo
- **Oficina, departamento o distrito**: $oficina — ADOSE
- **Tareas más comunes**: $tareas
- **Programas que más uso**: $programas
- **Respuestas**: $pref

Puedo editar este archivo cuando cambie algo. El instalador no lo vuelve a tocar.
FIN

  PERFIL_TEXTO="Soy $nombre, $cargo en $oficina de la Asociación Dominicana del Sureste (ADOSE), Iglesia Adventista del Séptimo Día, en República Dominicana. Lo que más hago: $tareas. Uso sobre todo $programas. Escríbeme en español, con tildes y en tono profesional y natural, sin palabras rebuscadas. Prefiero respuestas $pref. Si algo no está en mis documentos, dímelo en vez de suponerlo."
}
