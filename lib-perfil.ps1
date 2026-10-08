# Perfil de la persona (equivalente de lib-perfil.sh):
#   %USERPROFILE%\.claude\sobre-mi.md -> lo lee Claude Code en toda conversación;
#                                        config\CLAUDE.md lo importa. Volver a
#                                        instalar no lo pisa.
#   un texto para claude.ai -> Configuración -> Perfil, copiado al portapapeles.
# Lo carga instalar.ps1. Este archivo va en UTF-8 CON BOM para que PowerShell 5
# lea bien las tildes: el texto que llega a claude.ai tiene que salir bien escrito.

$script:SobreMi = Join-Path $env:USERPROFILE ".claude\sobre-mi.md"

function Tiene-Perfil { return ((Test-Path $script:SobreMi) -and ((Get-Item $script:SobreMi).Length -gt 0)) }

function Preguntar($texto, $ejemplo) {
  $r = ""
  while (-not $r) {
    Write-Host "  $texto" -ForegroundColor White
    Write-Host "  (ej.: $ejemplo)" -ForegroundColor DarkGray
    $r = Read-Host "  >"
  }
  return $r
}

function Armar-Perfil {
  if ($script:EsAdose) {
    $ejNom = "Pastor Roberto, Noemí, Juan"; $ejCargo = "Pastor distrital, Tesorero, Secretaria, Director de Jóvenes"
    $ejOfi = "Tesorería, Distrito Los Mina, Ministerio Personal"; $ejTar = "cartas, informes, actas, presupuestos, sermones, planillas de Excel"
    $sufijo = " — ADOSE"; $adoseTxt = $true
  } else {
    $ejNom = "Ana, Pedro, Doctora Pérez"; $ejCargo = "Contadora, Maestra, Ingeniero, Ama de casa, Estudiante"
    $ejOfi = "mi negocio, la escuela, la oficina, mi casa"; $ejTar = "cartas, informes, presupuestos, estudiar, planillas de Excel"
    $sufijo = ""; $adoseTxt = $false
  }
  $nombre    = Preguntar "¿Cómo quieres que Claude te llame?" $ejNom
  $cargo     = Preguntar "¿A qué te dedicas?" $ejCargo
  $oficina   = Preguntar "¿Dónde trabajas o estudias?" $ejOfi
  $tareas    = Preguntar "¿Qué tareas haces más seguido?" $ejTar
  $programas = Preguntar "¿Qué programas usas más?" "Outlook, Excel, Word, WhatsApp, Google Drive"
  $estilo = ""
  while ($estilo -ne "1" -and $estilo -ne "2") {
    Write-Host "  ¿Cómo prefieres las respuestas?" -ForegroundColor White
    $estilo = Read-Host "  1 = cortas y al grano | 2 = detalladas, paso a paso >"
  }
  $intro = if ($adoseTxt) { "Soy $nombre, $cargo en $oficina de la Asociación Dominicana del Sureste (ADOSE), Iglesia Adventista del Séptimo Día, en República Dominicana." } else { "Soy $nombre. Me dedico a: $cargo. Trabajo o estudio en: $oficina." }
  $pref = if ($estilo -eq "1") { "cortas y al grano" } else { "detalladas y paso a paso" }

  New-Item -ItemType Directory -Force -Path (Split-Path $script:SobreMi) | Out-Null
  $md = @(
    "# Sobre mí", "",
    "- **Cómo llamarme**: $nombre",
    "- **A qué me dedico**: $cargo",
    "- **Dónde**: $oficina$sufijo",
    "- **Tareas más comunes**: $tareas",
    "- **Programas que más uso**: $programas",
    "- **Respuestas**: $pref", "",
    "Puedo editar este archivo cuando cambie algo. El instalador no lo vuelve a tocar."
  ) -join "`r`n"
  [System.IO.File]::WriteAllText($script:SobreMi, $md, (New-Object System.Text.UTF8Encoding($false)))

  return "$intro Lo que más hago: $tareas. Uso sobre todo $programas. Escríbeme en español, con tildes y en tono profesional y natural, sin palabras rebuscadas. Prefiero respuestas $pref. Si algo no está en mis documentos, dímelo en vez de suponerlo."
}
