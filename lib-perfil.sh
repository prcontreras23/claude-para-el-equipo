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
  local ej_nom ej_cargo ej_ofi ej_tar
  if [[ "${ES_ADOSE:-n}" == "s" ]]; then
    ej_nom="Pastor Roberto, Noemí, Juan"; ej_cargo="Pastor distrital, Tesorero, Secretaria, Director de Jóvenes"
    ej_ofi="Tesorería, Distrito Los Mina, Ministerio Personal"; ej_tar="cartas, informes, actas, presupuestos, sermones, planillas de Excel"
  else
    ej_nom="Ana, Pedro, Doctora Pérez"; ej_cargo="Contadora, Maestra, Ingeniero, Ama de casa, Estudiante"
    ej_ofi="mi negocio, la escuela, la oficina, mi casa"; ej_tar="cartas, informes, presupuestos, estudiar, planillas de Excel"
  fi
  preguntar "¿Cómo quieres que Claude te llame?" "$ej_nom"; local nombre="$R"
  preguntar "¿A qué te dedicas?" "$ej_cargo"; local cargo="$R"
  preguntar "¿Dónde trabajas o estudias?" "$ej_ofi"; local oficina="$R"
  preguntar "¿Qué tareas haces más seguido?" "$ej_tar"; local tareas="$R"
  preguntar "¿Qué programas usas más?" "Outlook, Excel, Word, WhatsApp, Google Drive"; local programas="$R"
  local sufijo="" intro="Soy $nombre. Me dedico a: $cargo. Trabajo o estudio en: $oficina."
  if [[ "${ES_ADOSE:-n}" == "s" ]]; then
    sufijo=" — ADOSE"
    intro="Soy $nombre, $cargo en $oficina de la Asociación Dominicana del Sureste (ADOSE), Iglesia Adventista del Séptimo Día, en República Dominicana."
  fi
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
- **A qué me dedico**: $cargo
- **Dónde**: $oficina$sufijo
- **Tareas más comunes**: $tareas
- **Programas que más uso**: $programas
- **Respuestas**: $pref

Puedo editar este archivo cuando cambie algo. El instalador no lo vuelve a tocar.
FIN

  PERFIL_TEXTO="$intro Lo que más hago: $tareas. Uso sobre todo $programas. Escríbeme en español, con tildes y en tono profesional y natural, sin palabras rebuscadas. Prefiero respuestas $pref. Si algo no está en mis documentos, dímelo en vez de suponerlo."
}
