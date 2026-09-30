# Instalador principal para Windows. Lo lanza "Instalar en Windows.bat" (doble
# clic) o instalar-windows.ps1 (una linea). Perfil opcional en $env:PERFIL.
#
# Deja una PC lista para trabajar con Claude:
#   1. Diagnostico: revisa que hay y que falta.
#   2. Instala lo que falte: git, Claude Code, Claude Desktop (trae Cowork),
#      Google Chrome, las herramientas para PDF, Word, Excel, PowerPoint,
#      imagenes, OCR y transcripcion de audio (ver lib-herramientas.ps1), y la
#      configuracion del equipo en %USERPROFILE%\.claude.
#   3. Pasos que hace la persona, sin saltarse ninguno: entrar en claude.ai,
#      entrar en Claude Desktop, anadir la extension de Claude a Chrome y entrar.
#   4. Diagnostico final y abre Claude Code para entrar con la cuenta.
#
# Sin tildes a proposito: PowerShell 5 lee mal los .ps1 en UTF-8 sin BOM.

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-Location $PSScriptRoot

$Repo   = "prcontreras23/claude-para-el-equipo"
$Perfil = $env:PERFIL

. (Join-Path $PSScriptRoot "lib-requisitos.ps1")
. (Join-Path $PSScriptRoot "lib-config.ps1")
. (Join-Path $PSScriptRoot "lib-herramientas.ps1")

function Negrita($m) { Write-Host $m -ForegroundColor White }
function Verde($m)   { Write-Host "  OK  $m" -ForegroundColor Green }
function Rojo($m)    { Write-Host "  X   $m" -ForegroundColor Red }
function Gris($m)    { Write-Host "  $m" -ForegroundColor DarkGray }
function Paso($m)    { Write-Host ""; Negrita $m }
function Esperar($m) { Read-Host "  $m" | Out-Null }
function Fila($nombre, $ok) { if ($ok) { Verde $nombre } else { Rojo "$nombre - falta" } }

function Abrir-Web($url) {
  $chrome = Ruta-Chrome
  if ($chrome) { Start-Process $chrome $url } else { Start-Process $url }
}

function Diagnostico {
  Ruta-Herramientas
  Fila "git"                           (Tiene git)
  Fila "Claude Code"                   (Tiene claude)
  Fila "Claude Desktop (con Cowork)"   (Tiene-ClaudeDesktop)
  Fila "Google Chrome"                 (Tiene-Chrome)
  Fila "Extension de Claude en Chrome" (Tiene-ExtChrome)
  Fila "PDF (poppler, qpdf)"                  (Tiene-PdfTools)
  Fila "OCR en espanol (tesseract)"           (Tiene-Ocr)
  Fila "Word/Excel/PPT (LibreOffice, pandoc)" (Tiene-Conversion)
  Fila "Imagenes (ImageMagick, exiftool)"     (Tiene-Imagenes)
  Fila "Audio y video (ffmpeg, yt-dlp)"       (Tiene-Audio)
  Fila "Transcripcion (whisper + modelo)"     (Tiene-Transcripcion)
  Fila "Python con librerias de documentos"   (Tiene-PythonDocs)
  Fila "Node con docx y pptxgenjs"            (Tiene-NpmDocs)
  Fila "Skills de documentos en Claude Code"  (Tiene-SkillsDocs)
  if (Tiene-OfficeAlguna) { Fila "Claude en Word, Excel y PowerPoint" (Tiene-ClaudeEnOffice) }
  else { Gris "Word, Excel y PowerPoint no estan instalados; se salta Claude en Office." }
  Fila "Configuracion del equipo"      (Tiene-ConfigEquipo)
  Fila "Sesion en Claude Code"         (Tiene-SesionClaudeCode)
}

Write-Host ""
Negrita "Claude para el equipo - instalacion en Windows"
Gris ("Perfil: " + $(if ($Perfil) { $Perfil } else { "base" }))

# Claude Code pide Windows 10 1809 (build 17763) o mas nuevo.
if ([Environment]::OSVersion.Version.Build -lt 17763) { Rojo "Windows muy viejo: hace falta Windows 10 1809 o mas nuevo."; exit 1 }
# claude.ai responde 403 a las peticiones de terminal; la prueba de red va contra GitHub.
try { Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$Repo/main/README.md" -Method Head -UseBasicParsing -TimeoutSec 15 | Out-Null }
catch { Rojo "No hay internet. Conectate e intentalo otra vez."; exit 1 }

# -- 1. Diagnostico ------------------------------------------------------------
Paso "Revisando esta PC..."
Diagnostico

# -- 2. Instalar lo que falte --------------------------------------------------
Paso "1/6  git"
if (Instalar-Git) { Verde ("git " + ((git --version) -split " ")[2]) }
else { Rojo "No se pudo instalar git. Claude Code lo usa para ver cambios; se sigue igual." }

Paso "2/6  Claude Code"
if (Instalar-Claude) { Verde ("Claude Code " + ((claude --version) -split " ")[0]); Persistir-Ruta }
else { Rojo "No se pudo instalar Claude Code."; Gris "Prueba a mano en PowerShell:  irm https://claude.ai/install.ps1 | iex"; exit 1 }

Paso "3/6  Claude Desktop (la app de ventana; ahi esta Cowork)"
if (-not (Tiene-ClaudeDesktop)) { Gris "Descargando (unos minutos)..." }
if (Instalar-ClaudeDesktop) { Verde "Claude Desktop instalada" }
else { Rojo "No se pudo instalar sola."; Gris "Mas abajo se abre la pagina para bajarla a mano." }

Paso "4/6  Google Chrome (para la extension de Claude)"
if (-not (Tiene-Chrome)) { Gris "Descargando (unos minutos)..." }
if (Instalar-Chrome) { Verde "Google Chrome instalado" }
else { Rojo "No se pudo instalar solo."; Gris "Mas abajo se abre la pagina para bajarlo a mano." }

Paso "5/6  Herramientas para documentos, imagenes, OCR y audio"
if (Tiene winget) {
  Gris "Programas (puede tardar 10-20 minutos la primera vez). Si Windows pregunta"
  Gris "si permites que la aplicacion haga cambios, dale a Si."
  if (Instalar-Programas) { Verde "poppler, qpdf, tesseract, pandoc, ffmpeg, ImageMagick, exiftool, node, yt-dlp, LibreOffice" }
  else { Rojo ("No quedaron todos: " + ((Programas-Faltan) -join ", ")) }
} else {
  Rojo "Esta PC no tiene winget; se saltan PDF, OCR, LibreOffice, pandoc, ffmpeg, ImageMagick y node."
  Gris "Instala 'Instalador de aplicacion' desde la Microsoft Store y vuelve a correr esto."
}
if (Instalar-OcrEs) { Verde "OCR en espanol" } else { Rojo "No se pudo preparar el espanol para el OCR." }
if (Instalar-NpmDocs) { Verde "Node: docx y pptxgenjs" } else { Rojo "No se pudieron instalar docx y pptxgenjs." }
if ((Instalar-Uv) -and (Instalar-PythonDocs)) { Verde "Python con librerias de PDF, Word, Excel, PowerPoint, imagenes y OCR" }
else { Rojo "No se pudo preparar el Python con las librerias de documentos." }
if (Instalar-WhisperCli) { Verde "whisper-cli" } else { Rojo "No se pudo bajar whisper-cli." }
if (-not (Tiene-ModeloWhisper)) { Gris "Bajando el modelo para transcribir audio (~550 MB)..." }
if (Instalar-ModeloWhisper) { Verde "Modelo de transcripcion en $script:Modelo" } else { Rojo "No se pudo bajar el modelo de transcripcion." }
Persistir-RutasHerramientas
if (Instalar-SkillsDocs) { Verde "Skills de documentos de Anthropic en Claude Code" } else { Rojo "No se pudieron instalar los skills de documentos." }

Paso "6/6  Configuracion del equipo"
Aplicar-Config $PSScriptRoot $Perfil
Verde "$env:USERPROFILE\.claude listo (lo que habia quedo en .claude\respaldo-*)"

# -- 3. Pasos que hace la persona. No se sigue hasta que cada uno quede hecho. -
Write-Host ""
Negrita "Ahora faltan cinco pasos que haces tu. El instalador espera a que termines cada uno."

Paso "A/E  Entrar a Claude en linea"
Gris "Se abre claude.ai en el navegador. Escribe el correo con el que te invitaron;"
Gris "Claude te manda un codigo a ese correo. Pegalo y entra."
Abrir-Web "https://claude.ai/login"
Esperar "Cuando ya estes dentro de claude.ai, presiona Enter..."
Verde "claude.ai"

Paso "B/E  Claude Desktop"
while (-not (Tiene-ClaudeDesktop)) {
  Rojo "Claude Desktop no esta instalada."
  Gris "Se abre la pagina de descarga: bajala, abre el archivo y sigue el instalador."
  Abrir-Web "https://claude.ai/download"
  Esperar "Cuando termine de instalarse, presiona Enter..."
}
$desktop = Ruta-ClaudeDesktop
if ($desktop) { Start-Process $desktop; Gris "Se abrio Claude Desktop." }
else { Gris "Abre Claude desde el menu Inicio (escribe Claude)." }
Gris "Entra con el mismo correo (te llega otro codigo). Arriba estan Chat, Cowork y Code."
Esperar "Cuando estes dentro de Claude Desktop, presiona Enter..."
Verde "Claude Desktop"

Paso "C/E  Extension de Claude en Chrome"
while (-not (Tiene-Chrome)) {
  Rojo "Google Chrome no esta instalado, y la extension solo funciona en Chrome."
  Gris "Se abre la pagina de Chrome: bajalo y sigue el instalador."
  Start-Process "https://www.google.com/chrome/"
  Esperar "Cuando Chrome este instalado, presiona Enter..."
}
while (-not (Tiene-ExtChrome)) {
  Gris "Se abre la extension en Chrome. Dale a 'Anadir a Chrome' y luego a 'Anadir extension'."
  Start-Process (Ruta-Chrome) $script:ChromeExtUrl
  Esperar "Cuando la hayas anadido, presiona Enter..."
  if (-not (Tiene-ExtChrome)) { Rojo "Todavia no aparece la extension en Chrome." }
}
Gris "Haz clic en el icono de Claude arriba a la derecha en Chrome (si no se ve, esta"
Gris "en la pieza de rompecabezas) y entra con tu cuenta."
Esperar "Cuando hayas entrado en la extension, presiona Enter..."
Verde "Extension de Chrome"

Paso "D/E  Claude en Word, Excel y PowerPoint"
if (-not (Tiene-OfficeAlguna)) { Gris "Esta PC no tiene Word, Excel ni PowerPoint. Se salta este paso." }
foreach ($app in $script:OfficeApps.Keys) {
  if (-not (Tiene-OfficeApp $app)) { continue }
  $intentos = 0
  while (-not (Tiene-ClaudeOffice $app)) {
    if ($intentos -ge 3) { Rojo "No se detecta Claude en $app. Sigue el instalador; revisa despues en $app -> Inicio -> Complementos."; break }
    Gris "Se abre Claude para $app en AppSource. Dale a 'Obtener ahora', entra con tu"
    Gris "correo del equipo y acepta abrirlo en $app. Si no abre, en $app ve a"
    Gris "Inicio -> Complementos, busca 'Claude' y dale a 'Agregar'."
    Abrir-Web ("https://appsource.microsoft.com/product/office/" + $script:OfficeApps[$app].Url)
    Esperar "Cuando Claude aparezca en $app, abrelo una vez y presiona Enter..."
    $intentos++
    if (-not (Tiene-ClaudeOffice $app)) { Rojo "Todavia no aparece Claude en $app." }
  }
  if (Tiene-ClaudeOffice $app) { Verde "Claude en $app" }
}

# -- 4. Diagnostico final y Claude Code ----------------------------------------
Paso "Como quedo esta PC"
Diagnostico

Paso "E/E  Claude Code"
if (Tiene-SesionClaudeCode) { Gris "Claude Code ya tiene tu cuenta. Se abre para que empieces a trabajar." }
else {
  Gris "Se abre Claude Code aqui mismo. Elige entrar con tu cuenta de Claude"
  Gris "(se abre el navegador) y usa el mismo correo."
}
Esperar "Presiona Enter para abrir Claude Code..."
Ruta-Herramientas
& claude
