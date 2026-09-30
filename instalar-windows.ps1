# Arranque de una linea para Windows:
#
#   irm https://raw.githubusercontent.com/prcontreras23/claude-para-el-equipo/main/instalar-windows.ps1 | iex
#
# Con perfil:
#
#   $env:PERFIL="nombre-del-perfil"; irm https://raw.githubusercontent.com/prcontreras23/claude-para-el-equipo/main/instalar-windows.ps1 | iex

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Repo   = "prcontreras23/claude-para-el-equipo"
$Fuente = Join-Path $env:USERPROFILE "claude-para-el-equipo-fuente"

function Morir($m) { Write-Host ""; Write-Host "  X $m" -ForegroundColor Red; Write-Host ""; exit 1 }

Write-Host ""; Write-Host "Bajando Claude para el equipo..." -ForegroundColor White; Write-Host ""

$zip = Join-Path $env:TEMP "claude-para-el-equipo.zip"
# Dos servidores de GitHub con el mismo paquete: si el DNS de la red no encuentra
# github.com, se prueba codeload.github.com.
$bajado = $false
foreach ($url in @("https://github.com/$Repo/archive/refs/heads/main.zip", "https://codeload.github.com/$Repo/zip/refs/heads/main")) {
  try { Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing; $bajado = $true; break } catch {}
}
if (-not $bajado) { Morir "No se pudo bajar de GitHub. Si tienes internet, puede ser el DNS de la red: espera un minuto e intentalo otra vez." }

if (Test-Path $Fuente) { Remove-Item -Recurse -Force $Fuente -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path $Fuente | Out-Null
try {
  $temp = Join-Path $env:TEMP "cpe-extraido"
  if (Test-Path $temp) { Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue }
  Expand-Archive -Path $zip -DestinationPath $temp -Force
  $interna = Get-ChildItem $temp -Directory | Select-Object -First 1
  Copy-Item -Path (Join-Path $interna.FullName "*") -Destination $Fuente -Recurse -Force
  Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
  Remove-Item $zip -ErrorAction SilentlyContinue
} catch { Morir "No se pudo descomprimir el archivo bajado." }

Write-Host "  OK " -ForegroundColor Green -NoNewline; Write-Host "listo"
Write-Host "  archivos en $Fuente" -ForegroundColor DarkGray

$instalador = Join-Path $Fuente "instalar.ps1"
if (-not (Test-Path $instalador)) { Morir "El proyecto se bajo incompleto. Intentalo de nuevo." }
# -ExecutionPolicy Bypass vale solo para esta ejecucion; no cambia la maquina.
& powershell -NoProfile -ExecutionPolicy Bypass -File $instalador
