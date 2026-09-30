# Herramientas para que Claude pueda trabajar con PDF, Word, Excel, PowerPoint,
# imagenes, OCR y audio en Windows. Lo carga instalar.ps1.
#
#   winget   -> poppler, qpdf, tesseract, pandoc, ffmpeg, ImageMagick, exiftool,
#               node, yt-dlp y LibreOffice (algunos piden confirmar en una ventana de Windows)
#   uv       -> un Python propio con las librerias de documentos (queda primero en el PATH)
#   npm      -> docx y pptxgenjs (los usan los skills de Word y PowerPoint)
#   Whisper  -> whisper.cpp oficial (GitHub) + modelo large-v3-turbo q5_0 (~550 MB)
#   Claude   -> plugin oficial document-skills de Anthropic
#   Office   -> complementos de Claude en Word, Excel y PowerPoint (AppSource)
#
# Sin tildes a proposito: PowerShell 5 lee mal los .ps1 en UTF-8 sin BOM.

$script:HerrDir     = Join-Path $env:LOCALAPPDATA "claude-equipo"
$script:HerrPy      = Join-Path $script:HerrDir "python"
$script:HerrPyExe   = Join-Path $script:HerrPy "Scripts\python.exe"
$script:WhisperDir  = Join-Path $script:HerrDir "whisper"
$script:Modelo      = Join-Path $script:WhisperDir "ggml-large-v3-turbo-q5_0.bin"
$script:ModeloUrl   = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin"
$script:ModeloBytes = 574041195
$script:TessData    = Join-Path $script:HerrDir "tessdata"

# paquete de winget -> programa que deja
$script:WingetPaquetes = [ordered]@{
  "oschwartz10612.Poppler"            = "pdftotext"
  "QPDF.QPDF"                         = "qpdf"
  "UB-Mannheim.TesseractOCR"          = "tesseract"
  "JohnMacFarlane.Pandoc"             = "pandoc"
  "Gyan.FFmpeg"                       = "ffmpeg"
  "ImageMagick.ImageMagick"           = "magick"
  "OliverBetz.ExifTool"               = "exiftool"
  "OpenJS.NodeJS.LTS"                 = "node"
  "yt-dlp.yt-dlp"                     = "yt-dlp"
  "TheDocumentFoundation.LibreOffice" = "soffice"
}
$script:PyLibs  = @("pypdf","pdfplumber","pymupdf","pikepdf","reportlab","pdf2image","img2pdf","pytesseract",
                    "python-docx","openpyxl","xlsxwriter","pandas","python-pptx","pillow","matplotlib","defusedxml",
                    "markitdown[all]")
$script:NpmLibs = @("docx","pptxgenjs")

# ------------------------------------------------------------------ PATH

# Carpetas de programas que no se agregan solas al PATH.
function Rutas-Herramientas {
  $r = @(
    (Join-Path $script:HerrPy "Scripts"),
    (Join-Path $env:ProgramFiles "Tesseract-OCR"),
    (Join-Path $env:ProgramFiles "LibreOffice\program"),
    (Join-Path $env:ProgramFiles "nodejs"),
    (Join-Path $env:APPDATA "npm")
  )
  $w = Get-ChildItem -Path $script:WhisperDir -Recurse -Filter "whisper-cli.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($w) { $r += $w.DirectoryName }
  return $r
}

function Ruta-Herramientas {
  Ruta-Extendida
  foreach ($d in (Rutas-Herramientas)) {
    if ((Test-Path $d) -and ($env:PATH -notlike "*$d*")) { $env:PATH = "$d;$env:PATH" }
  }
  # Lo que winget deja en el PATH de la maquina y del usuario, sin reabrir la ventana.
  $actual = $env:PATH -split ";"
  foreach ($alcance in @("Machine","User")) {
    $v = [Environment]::GetEnvironmentVariable("PATH", $alcance)
    if (-not $v) { continue }
    foreach ($d in ($v -split ";")) {
      if ($d -and ($actual -notcontains $d)) { $env:PATH = "$env:PATH;$d"; $actual += $d }
    }
  }
}

function Persistir-RutasHerramientas {
  try {
    $actual = [Environment]::GetEnvironmentVariable("PATH", "User")
    $partes = @(); if ($actual) { $partes = $actual -split ";" | Where-Object { $_ } }
    foreach ($d in (Rutas-Herramientas)) {
      if ((Test-Path $d) -and ($partes -notcontains $d)) {
        # El Python de documentos va primero para que "python" traiga las librerias.
        if ($d -like "$script:HerrPy*") { $partes = @($d) + $partes } else { $partes += $d }
      }
    }
    [Environment]::SetEnvironmentVariable("PATH", ($partes -join ";"), "User")
  } catch {}
}

# ------------------------------------------------------------------ Programas (winget)

function Programas-Faltan {
  Ruta-Herramientas
  $f = @()
  foreach ($p in $script:WingetPaquetes.Keys) { if (-not (Tiene $script:WingetPaquetes[$p])) { $f += $p } }
  return $f
}

function Instalar-Programas {
  if (-not (Tiene winget)) { return $false }
  foreach ($p in (Programas-Faltan)) {
    Gris "Instalando $p..."
    try { winget install --id $p -e --accept-source-agreements --accept-package-agreements --silent 2>&1 | Out-Null } catch {}
  }
  Ruta-Herramientas
  return ((Programas-Faltan).Count -eq 0)
}

# ------------------------------------------------------------------ OCR en espanol

# El instalador de Tesseract solo trae ingles, y su carpeta pide administrador.
# Se arma una tessdata del usuario (ingles copiado + espanol bajado) y se apunta
# TESSDATA_PREFIX a ella.
function Tiene-OcrEs {
  return ((Test-Path (Join-Path $script:TessData "spa.traineddata")) -and
          ([Environment]::GetEnvironmentVariable("TESSDATA_PREFIX","User") -eq $script:TessData))
}

function Instalar-OcrEs {
  if (Tiene-OcrEs) { return $true }
  try {
    New-Item -ItemType Directory -Force -Path $script:TessData | Out-Null
    $orig = Join-Path $env:ProgramFiles "Tesseract-OCR\tessdata"
    if (Test-Path $orig) { Copy-Item (Join-Path $orig "*.traineddata") $script:TessData -Force -ErrorAction SilentlyContinue }
    foreach ($l in @("spa","eng")) {
      $dest = Join-Path $script:TessData "$l.traineddata"
      if (-not (Test-Path $dest)) {
        Invoke-WebRequest -Uri "https://github.com/tesseract-ocr/tessdata/raw/main/$l.traineddata" -OutFile $dest -UseBasicParsing
      }
    }
    [Environment]::SetEnvironmentVariable("TESSDATA_PREFIX", $script:TessData, "User")
    $env:TESSDATA_PREFIX = $script:TessData
  } catch { return $false }
  return (Tiene-OcrEs)
}

# ------------------------------------------------------------------ Python con librerias de documentos

function Instalar-Uv {
  Ruta-Extendida
  if (Tiene uv) { return $true }
  try { Invoke-Expression (Invoke-RestMethod -Uri "https://astral.sh/uv/install.ps1" -TimeoutSec 60) | Out-Null } catch { return $false }
  Ruta-Extendida
  return (Tiene uv)
}

function Tiene-PythonDocs {
  if (-not (Test-Path $script:HerrPyExe)) { return $false }
  & $script:HerrPyExe -c "import pypdf, pdfplumber, pymupdf, docx, openpyxl, pandas, pptx, PIL, pytesseract, markitdown" 2>$null
  return ($LASTEXITCODE -eq 0)
}

function Instalar-PythonDocs {
  if (Tiene-PythonDocs) { return $true }
  New-Item -ItemType Directory -Force -Path $script:HerrDir | Out-Null
  if (-not (Test-Path $script:HerrPyExe)) { & uv venv --quiet --python 3.12 $script:HerrPy 2>&1 | Out-Null }
  $libs = $script:PyLibs
  & uv pip install --quiet --python $script:HerrPyExe $libs 2>&1 | Out-Null
  return (Tiene-PythonDocs)
}

# ------------------------------------------------------------------ Librerias de Node

function Tiene-NpmDocs {
  if (-not (Tiene npm)) { return $false }
  foreach ($l in $script:NpmLibs) { npm ls -g --depth=0 $l 2>&1 | Out-Null; if ($LASTEXITCODE -ne 0) { return $false } }
  return $true
}

function Instalar-NpmDocs {
  if (Tiene-NpmDocs) { return $true }
  if (-not (Tiene npm)) { return $false }
  $libs = $script:NpmLibs
  npm install -g --silent $libs 2>&1 | Out-Null
  return (Tiene-NpmDocs)
}

# ------------------------------------------------------------------ Transcripcion (whisper.cpp)

function Tiene-ModeloWhisper { return ((Test-Path $script:Modelo) -and ((Get-Item $script:Modelo).Length -eq $script:ModeloBytes)) }
function Tiene-Transcripcion { Ruta-Herramientas; return ((Tiene whisper-cli) -and (Tiene-ModeloWhisper)) }

# whisper.cpp no esta en winget: se baja el zip oficial de la version mas nueva
# que publique binarios x64 para Windows.
function Instalar-WhisperCli {
  Ruta-Herramientas
  if (Tiene whisper-cli) { return $true }
  try {
    $rels = Invoke-RestMethod -Uri "https://api.github.com/repos/ggml-org/whisper.cpp/releases?per_page=15" -TimeoutSec 30
    $asset = $null
    foreach ($r in $rels) { $asset = $r.assets | Where-Object { $_.name -eq "whisper-bin-x64.zip" } | Select-Object -First 1; if ($asset) { break } }
    if (-not $asset) { return $false }
    $zip = Join-Path $env:TEMP "whisper-bin-x64.zip"
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -UseBasicParsing
    $bin = Join-Path $script:WhisperDir "bin"
    if (Test-Path $bin) { Remove-Item -Recurse -Force $bin -ErrorAction SilentlyContinue }
    Expand-Archive -Path $zip -DestinationPath $bin -Force
    Remove-Item $zip -ErrorAction SilentlyContinue
  } catch { return $false }
  Ruta-Herramientas
  return (Tiene whisper-cli)
}

function Instalar-ModeloWhisper {
  if (Tiene-ModeloWhisper) { return $true }
  try {
    New-Item -ItemType Directory -Force -Path $script:WhisperDir | Out-Null
    $tmp = "$script:Modelo.tmp"
    # BITS descarga archivos grandes mejor que Invoke-WebRequest en PowerShell 5.
    try { Start-BitsTransfer -Source $script:ModeloUrl -Destination $tmp -ErrorAction Stop }
    catch { Invoke-WebRequest -Uri $script:ModeloUrl -OutFile $tmp -UseBasicParsing }
    Move-Item $tmp $script:Modelo -Force
  } catch { return $false }
  return (Tiene-ModeloWhisper)
}

# ------------------------------------------------------------------ Skills oficiales de documentos

function Tiene-SkillsDocs { return ((claude plugin list 2>&1 | Out-String) -match "document-skills") }

function Instalar-SkillsDocs {
  if (Tiene-SkillsDocs) { return $true }
  claude plugin marketplace add anthropics/skills 2>&1 | Out-Null
  claude plugin install document-skills@anthropic-agent-skills 2>&1 | Out-Null
  return (Tiene-SkillsDocs)
}

# ------------------------------------------------------------------ Claude en Word, Excel y PowerPoint

# Office no deja instalar complementos desde un script: se abre la pagina de
# AppSource y aqui se comprueba en la cache de complementos (Wef) que ya quedo.
# "Claude in Microsoft Office" (11d7cf85-...) cuenta para Excel y PowerPoint.
$script:OfficeGuid = "11d7cf85-ae5a-43b8-bc58-1e1a151cce24"
$script:OfficeApps = [ordered]@{
  "Word"       = @{ Exe = "WINWORD.EXE";  Ids = @("wa200010453");                                Url = "WA200010453" }
  "Excel"      = @{ Exe = "EXCEL.EXE";    Ids = @("wa200009404","wa200010725",$script:OfficeGuid); Url = "WA200009404" }
  "PowerPoint" = @{ Exe = "POWERPNT.EXE"; Ids = @("wa200010001",$script:OfficeGuid);              Url = "WA200010001" }
}

function Tiene-OfficeApp($app) {
  $exe = $script:OfficeApps[$app].Exe
  foreach ($base in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
    if (-not $base) { continue }
    if (Test-Path (Join-Path $base "Microsoft Office\root\Office16\$exe")) { return $true }
  }
  return $false
}

function Tiene-OfficeAlguna { foreach ($a in $script:OfficeApps.Keys) { if (Tiene-OfficeApp $a) { return $true } }; return $false }

function Tiene-ClaudeOffice($app) {
  $wef = Join-Path $env:LOCALAPPDATA "Microsoft\Office\16.0\Wef"
  if (-not (Test-Path $wef)) { return $false }
  foreach ($id in $script:OfficeApps[$app].Ids) {
    if (Get-ChildItem -Path $wef -Recurse -Filter "*$id*" -ErrorAction SilentlyContinue | Select-Object -First 1) { return $true }
    if (Get-ChildItem -Path $wef -Recurse -File -ErrorAction SilentlyContinue |
        Select-String -Pattern $id -SimpleMatch -List -ErrorAction SilentlyContinue | Select-Object -First 1) { return $true }
  }
  return $false
}

function Tiene-ClaudeEnOffice {
  $hay = $false
  foreach ($a in $script:OfficeApps.Keys) {
    if (-not (Tiene-OfficeApp $a)) { continue }
    $hay = $true
    if (-not (Tiene-ClaudeOffice $a)) { return $false }
  }
  return $hay
}

# ------------------------------------------------------------------ Resumen para el diagnostico

function Tiene-PdfTools   { return ((Tiene pdftotext) -and (Tiene pdftoppm) -and (Tiene qpdf)) }
function Tiene-Ocr        { return ((Tiene tesseract) -and (Tiene-OcrEs)) }
function Tiene-Conversion { return ((Tiene pandoc) -and (Tiene soffice)) }
function Tiene-Imagenes   { return ((Tiene magick) -and (Tiene exiftool)) }
function Tiene-Audio      { return ((Tiene ffmpeg) -and (Tiene yt-dlp)) }
