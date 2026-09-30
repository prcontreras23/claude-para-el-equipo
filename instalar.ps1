# Instalador principal para Windows. Lo lanza "Instalar en Windows.bat" (doble
# clic) o instalar-windows.ps1 (una línea). Perfil opcional en $env:PERFIL.
#
# Deja una PC lista para trabajar con Claude, sea desde cero o con Claude ya instalado:
#   1. Diagnóstico: revisa qué hay y qué falta.
#   2. Instala lo que falte: git, Claude Code, Claude Desktop (trae Cowork), Google
#      Chrome, herramientas para PDF, Office, imágenes, OCR y audio, la configuración
#      del equipo, y los plugins y conectores de Claude Code.
#   3. Diez pasos guiados que hace la persona (los ya hechos se saltan).
#   4. Diagnóstico final y abre Claude Code.
#
# UTF-8 CON BOM a propósito: PowerShell 5 lee bien las tildes solo así.
# (instalar-windows.ps1 sí va sin tildes, porque llega por irm | iex.)

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-Location $PSScriptRoot

$Repo   = "prcontreras23/claude-para-el-equipo"
$Perfil = $env:PERFIL

. (Join-Path $PSScriptRoot "lib-requisitos.ps1")
. (Join-Path $PSScriptRoot "lib-config.ps1")
. (Join-Path $PSScriptRoot "lib-herramientas.ps1")
. (Join-Path $PSScriptRoot "lib-perfil.ps1")
. (Join-Path $PSScriptRoot "lib-extras.ps1")

function Negrita($m) { Write-Host $m -ForegroundColor White }
function Verde($m)   { Write-Host "  OK  $m" -ForegroundColor Green }
function Rojo($m)    { Write-Host "  X   $m" -ForegroundColor Red }
function Gris($m)    { Write-Host "  $m" -ForegroundColor DarkGray }
function Paso($m)    { Write-Host ""; Negrita $m }
function Esperar($m) { Read-Host "  $m" | Out-Null }
function Fila($nombre, $ok) { if ($ok) { Verde $nombre } else { Rojo "$nombre — falta" } }

function Abrir-Web($url) {
  $chrome = Ruta-Chrome
  if ($chrome) { Start-Process $chrome $url } else { Start-Process $url }
}

function Diagnostico {
  Ruta-Herramientas
  Fila "git"                                   (Tiene git)
  Fila "Claude Code"                           (Tiene claude)
  Fila "Claude Desktop (con Cowork)"           (Tiene-ClaudeDesktop)
  Fila "Google Chrome"                         (Tiene-Chrome)
  Fila "Extensión de Claude en Chrome"         (Tiene-ExtChrome)
  Fila "PDF (poppler, qpdf)"                   (Tiene-PdfTools)
  Fila "OCR en español (tesseract)"            (Tiene-Ocr)
  Fila "Word/Excel/PPT (LibreOffice, pandoc)"  (Tiene-Conversion)
  Fila "Imágenes (ImageMagick, exiftool)"      (Tiene-Imagenes)
  Fila "Audio y video (ffmpeg, yt-dlp)"        (Tiene-Audio)
  Fila "Transcripción (whisper + modelo)"      (Tiene-Transcripcion)
  Fila "Python con librerías de documentos"    (Tiene-PythonDocs)
  Fila "Node con docx y pptxgenjs"             (Tiene-NpmDocs)
  Fila "Plugins de oficina y documentos"       (Tiene-Plugins)
  Fila "FastTrack (literatura académica)"      (Tiene-FastTrack)
  if (Tiene-OfficeAlguna) { Fila "Claude en Word, Excel y PowerPoint" (Tiene-ClaudeEnOffice) }
  else { Gris "Word, Excel y PowerPoint no están instalados; se salta Claude en Office." }
  Fila "Configuración del equipo"              (Tiene-ConfigEquipo)
  Fila "Tu perfil (sobre-mi.md)"               (Tiene-Perfil)
  if (Tiene-WhatsApp) { Verde "WhatsApp conectado" } else { Gris "WhatsApp: no conectado (opcional)" }
  if (Tiene-SegundoCerebro) { Verde "Segundo cerebro en Obsidian" } else { Gris "Segundo cerebro: no configurado (opcional)" }
  Fila "Sesión en Claude Code"                 (Sesion-ClaudeCodeActiva)
}

Write-Host ""
Negrita "Claude para el equipo — instalación en Windows"
Gris ("Perfil: " + $(if ($Perfil) { $Perfil } else { "base" }))
Write-Host ""
Gris "Esto deja tu computadora lista para trabajar con Claude. Tarda de 20 a 40 minutos la"
Gris "primera vez; si vuelves a correrlo, solo hace lo que falte."
Gris "Casi todo va solo. Cuando veas  >  escribe tu respuesta y presiona Enter."
Gris "Si Windows pregunta si permites que una aplicación haga cambios, dale a Sí."

# Claude Code pide Windows 10 1809 (build 17763) o más nuevo.
if ([Environment]::OSVersion.Version.Build -lt 17763) { Rojo "Windows muy viejo: hace falta Windows 10 1809 o más nuevo."; exit 1 }
# claude.ai responde 403 a las peticiones de terminal; la prueba de red va contra GitHub.
try { Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$Repo/main/README.md" -Method Head -UseBasicParsing -TimeoutSec 15 | Out-Null }
catch { Rojo "No hay internet. Conéctate e inténtalo otra vez."; exit 1 }

# -- 1. Diagnóstico ------------------------------------------------------------
Paso "Revisando esta computadora..."
Diagnostico

# -- 2. Instalar lo que falte --------------------------------------------------
Paso "1/7  git"
if (Instalar-Git) { Verde ("git " + ((git --version) -split " ")[2]) }
else { Rojo "No se pudo instalar git. Claude Code lo usa para ver cambios; se sigue igual." }

Paso "2/7  Claude Code"
if (Instalar-Claude) { Verde ("Claude Code " + ((claude --version) -split " ")[0]); Persistir-Ruta }
else { Rojo "No se pudo instalar Claude Code."; Gris "Prueba a mano en PowerShell:  irm https://claude.ai/install.ps1 | iex"; exit 1 }

Paso "3/7  Claude Desktop (la app de ventana; ahí está Cowork)"
if (-not (Tiene-ClaudeDesktop)) { Gris "Descargando (unos minutos)..." }
if (Instalar-ClaudeDesktop) { Verde "Claude Desktop instalada" }
else { Rojo "No se pudo instalar sola."; Gris "Más abajo se abre la página para bajarla a mano." }

Paso "4/7  Google Chrome (para la extensión de Claude)"
if (-not (Tiene-Chrome)) { Gris "Descargando (unos minutos)..." }
if (Instalar-Chrome) { Verde "Google Chrome instalado" }
else { Rojo "No se pudo instalar solo."; Gris "Más abajo se abre la página para bajarlo a mano." }

Paso "5/7  Herramientas para documentos, imágenes, OCR y audio"
if (Tiene winget) {
  Gris "Programas (puede tardar 10–20 minutos la primera vez)..."
  if (Instalar-Programas) { Verde "poppler, qpdf, tesseract, pandoc, ffmpeg, ImageMagick, exiftool, node, yt-dlp, LibreOffice" }
  else { Rojo ("No quedaron todos: " + ((Programas-Faltan) -join ", ")) }
} else {
  Rojo "Esta PC no tiene winget; se saltan PDF, OCR, LibreOffice, pandoc, ffmpeg, ImageMagick y node."
  Gris "Instala «Instalador de aplicación» desde la Microsoft Store y vuelve a correr esto."
}
if (Instalar-OcrEs) { Verde "OCR en español" } else { Rojo "No se pudo preparar el español para el OCR." }
if (Instalar-NpmDocs) { Verde "Node: docx y pptxgenjs" } else { Rojo "No se pudieron instalar docx y pptxgenjs." }
if ((Instalar-Uv) -and (Instalar-PythonDocs)) { Verde "Python con librerías de PDF, Word, Excel, PowerPoint, imágenes y OCR" }
else { Rojo "No se pudo preparar el Python con las librerías de documentos." }
if (Instalar-WhisperCli) { Verde "whisper-cli" } else { Rojo "No se pudo bajar whisper-cli." }
if (-not (Tiene-ModeloWhisper)) { Gris "Bajando el modelo para transcribir audio (~550 MB)..." }
if (Instalar-ModeloWhisper) { Verde "Modelo de transcripción en $script:Modelo" } else { Rojo "No se pudo bajar el modelo de transcripción." }
Persistir-RutasHerramientas

Paso "6/7  Configuración del equipo"
Aplicar-Config $PSScriptRoot $Perfil
Verde "$env:USERPROFILE\.claude listo (si ya tenías tu propia configuración, se respetó)"

Paso "7/7  Plugins y conectores de Claude Code"
Gris "document-skills, productivity, enterprise-search, operations, human-resources,"
Gris "finance, data, marketing y pdf-viewer"
if (Instalar-Plugins) { Verde "Plugins instalados y activos" } else { Rojo ("No quedaron: " + ((Plugins-Faltan) -join ", ")) }
if (Instalar-FastTrack) { Verde "FastTrack (búsqueda de literatura académica)" } else { Rojo "No se pudo agregar FastTrack." }

# -- 3. Pasos que hace la persona. No se sigue hasta que cada uno quede hecho. -
$script:Total = 10
$script:N = 0
function Siguiente($titulo) { $script:N++; Paso ("Paso " + $script:N + " de " + $script:Total + " — " + $titulo) }

Write-Host ""
Negrita "Lo automático terminó. Ahora te guío en $script:Total pasos cortos."
Gris "En cada uno se abre lo que haga falta y el instalador espera a que termines."

Siguiente "Entrar a Claude en internet"
if (Ya-Hecho "¿Ya entraste antes a claude.ai con tu correo del equipo?") { Verde "claude.ai" }
else {
  Gris "Se abre claude.ai. Escribe el correo con el que te invitaron; Claude te manda"
  Gris "un código a ese correo. Búscalo en tu correo, pégalo y entra."
  Abrir-Web "https://claude.ai/login"
  Esperar "Cuando ya estés dentro de claude.ai, presiona Enter..."
  Verde "claude.ai"
}

Siguiente "Conectar tu correo, calendario y archivos"
Gris "Así Claude puede leer tus correos, ver tu agenda y buscar en tus documentos cuando"
Gris "se lo pidas. Sirve en claude.ai, Claude Desktop, Cowork y Claude Code."
if (Ya-Hecho "¿Ya conectaste tu correo y tu calendario en claude.ai?") { Verde "Conectores" }
else {
  Gris "Se abre Personalización → Conectores. En «Descubrir», dale a «Conectar» en los que uses:"
  Gris "  • Microsoft 365 — Outlook, calendario, OneDrive y Teams (el correo del trabajo)"
  Gris "  • Gmail y Google Calendar — si también usas Google"
  Gris "  • Google Drive — si guardas documentos ahí"
  Gris "  • FastTrack — en «Añadir» → conector personalizado, pega: $script:FastTrackUrl"
  Gris "Si Microsoft 365 no aparece, avisa a Secretaría: lo activa el administrador del equipo."
  Abrir-Web "https://claude.ai/customize/connectors"
  Esperar "Cuando hayas conectado los que usas, presiona Enter..."
  Verde "Conectores"
}

Siguiente "Tu perfil: que Claude sepa quién eres"
Gris "Claude trabaja mucho mejor cuando sabe tu cargo, tu oficina y lo que haces cada día:"
Gris "las cartas le salen con tu cargo, los informes con tu oficina, y no tienes que"
Gris "explicarle lo mismo en cada conversación. Son seis preguntas cortas."
$rehacer = $true
if (Tiene-Perfil) { Gris "Ya tienes un perfil guardado."; $rehacer = (Ya-Hecho "¿Quieres volver a llenarlo?") }
if ($rehacer) {
  Write-Host ""
  $texto = Armar-Perfil
  Verde "Guardado (Claude Code y Claude Desktop lo leen siempre)"
  Write-Host ""
  Gris "Ahora el mismo perfil en claude.ai, para que también lo usen el chat y Cowork."
  Set-Clipboard -Value $texto
  Gris "Ya copié este texto; solo tienes que pegarlo con Ctrl+V:"
  Write-Host ""; Write-Host "    $texto" -ForegroundColor Cyan; Write-Host ""
  Gris "Se abre tu cuenta en claude.ai. Pon tu nombre en «¿Cómo quieres que Claude te llame?»,"
  Gris "escoge la descripción más parecida a tu trabajo y pega el texto en «Instrucciones para Claude»."
  Gris "Luego, en «Memoria» (a la izquierda), actívala: así Claude recuerda lo que vas trabajando."
  Abrir-Web "https://claude.ai/settings/account"
  Esperar "Cuando lo hayas guardado, presiona Enter..."
}
Verde "Perfil"

Siguiente "Claude Desktop (Chat, Cowork y Code)"
while (-not (Tiene-ClaudeDesktop)) {
  Rojo "Claude Desktop no está instalada."
  Gris "Se abre la página de descarga: bájala, abre el archivo y sigue el instalador."
  Abrir-Web "https://claude.ai/download"
  Esperar "Cuando termine de instalarse, presiona Enter..."
}
$desktop = Ruta-ClaudeDesktop
if ($desktop) { Start-Process $desktop } else { Gris "Abre Claude desde el menú Inicio (escribe Claude)." }
if (Ya-Hecho "Se abrió Claude Desktop. ¿Ya estaba con tu cuenta adentro?") { Verde "Claude Desktop" }
else {
  Gris "Entra con el mismo correo (te llega otro código). Arriba verás Chat, Cowork y Code."
  Esperar "Cuando estés dentro de Claude Desktop, presiona Enter..."
  Verde "Claude Desktop"
}

Siguiente "Extensión de Claude en Chrome"
Gris "Con la extensión, Claude puede ayudarte dentro de cualquier página web."
while (-not (Tiene-Chrome)) {
  Rojo "Google Chrome no está instalado, y la extensión solo funciona en Chrome."
  Gris "Se abre la página de Chrome: bájalo y sigue el instalador."
  Start-Process "https://www.google.com/chrome/"
  Esperar "Cuando Chrome esté instalado, presiona Enter..."
}
if ((Tiene-ExtChrome) -and (Ya-Hecho "La extensión ya está en Chrome. ¿Ya entraste en ella con tu cuenta?")) { Verde "Extensión de Chrome" }
else {
  while (-not (Tiene-ExtChrome)) {
    Gris "Se abre la extensión en Chrome. Dale a «Añadir a Chrome» y luego a «Añadir extensión»."
    Start-Process (Ruta-Chrome) $script:ChromeExtUrl
    Esperar "Cuando la hayas añadido, presiona Enter..."
    if (-not (Tiene-ExtChrome)) { Rojo "Todavía no aparece la extensión en Chrome." }
  }
  Gris "Haz clic en el ícono de Claude arriba a la derecha en Chrome (si no se ve, está"
  Gris "en la pieza de rompecabezas) y entra con tu cuenta."
  Esperar "Cuando hayas entrado en la extensión, presiona Enter..."
  Verde "Extensión de Chrome"
}

Siguiente "Claude en tu celular"
Paso-Celular

Siguiente "Claude en Word, Excel y PowerPoint"
if (-not (Tiene-OfficeAlguna)) { Gris "Esta computadora no tiene Word, Excel ni PowerPoint. Se salta este paso." }
foreach ($app in $script:OfficeApps.Keys) {
  if (-not (Tiene-OfficeApp $app)) { continue }
  $intentos = 0
  while (-not (Tiene-ClaudeOffice $app)) {
    if ($intentos -ge 3) { Rojo "No se detecta Claude en $app. Sigue; revísalo después en $app → Inicio → Complementos."; break }
    Gris "Se abre Claude para $app. Dale a «Obtener ahora», entra con tu correo del equipo"
    Gris "y acepta abrirlo en $app. Si no abre: en $app ve a Inicio → Complementos,"
    Gris "busca «Claude» y dale a «Agregar»."
    Abrir-Web ("https://appsource.microsoft.com/product/office/" + $script:OfficeApps[$app].Url)
    Esperar "Cuando Claude aparezca en $app, ábrelo una vez y presiona Enter..."
    $intentos++
    if (-not (Tiene-ClaudeOffice $app)) { Rojo "Todavía no aparece Claude en $app." }
  }
  if (Tiene-ClaudeOffice $app) { Verde "Claude en $app" }
}

Siguiente "WhatsApp (opcional)"
Paso-WhatsApp

Siguiente "Tu segundo cerebro en Obsidian (opcional)"
Paso-SegundoCerebro $PSScriptRoot

# -- 4. Diagnóstico final y Claude Code ----------------------------------------
Paso "Cómo quedó esta computadora"
Diagnostico

Siguiente "Claude Code"
Ruta-Herramientas
$intentos = 0
while (-not (Sesion-ClaudeCodeActiva) -and $intentos -lt 3) {
  Gris "Se abre el navegador para que Claude Code entre con tu cuenta (el mismo correo)."
  & claude auth login
  $intentos++
  if (-not (Sesion-ClaudeCodeActiva)) { Rojo "Claude Code todavía no tiene tu cuenta." }
}
if (Sesion-ClaudeCodeActiva) { Verde "Claude Code con tu cuenta" }

Write-Host ""
Negrita "Todo listo."
Gris "Para trabajar, abre Claude Desktop: ahí tienes Chat, Cowork y Code."
if (Tiene-SegundoCerebro) { Gris "Tu segundo cerebro está en Obsidian; empieza por la nota «Inicio»." }
Gris "Si más adelante quieres agregar WhatsApp o el segundo cerebro, vuelve a pegar la misma línea."
Esperar "Presiona Enter para abrir Claude Code aquí mismo..."
& claude
