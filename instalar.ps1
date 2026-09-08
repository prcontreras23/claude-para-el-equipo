# Instalador principal para Windows. Lo lanza "Instalar en Windows.bat" (doble
# clic) o instalar-windows.ps1 (una linea). Perfil opcional en $env:PERFIL.

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-Location $PSScriptRoot

$Repo   = "prcontreras23/claude-para-el-equipo"
$Perfil = $env:PERFIL

. (Join-Path $PSScriptRoot "lib-requisitos.ps1")
. (Join-Path $PSScriptRoot "lib-config.ps1")

function Negrita($m) { Write-Host $m -ForegroundColor White }
function Verde($m)   { Write-Host "  OK  $m" -ForegroundColor Green }
function Rojo($m)    { Write-Host "  X   $m" -ForegroundColor Red }
function Gris($m)    { Write-Host "  $m" -ForegroundColor DarkGray }
function Paso($m)    { Write-Host ""; Negrita $m }

Write-Host ""
Negrita "Claude para el equipo - instalacion en Windows"
Gris ("Perfil: " + $(if ($Perfil) { $Perfil } else { "base" }))

# Claude Code pide Windows 10 1809 (build 17763) o mas nuevo.
if ([Environment]::OSVersion.Version.Build -lt 17763) { Rojo "Windows muy viejo: hace falta Windows 10 1809 o mas nuevo."; exit 1 }
try { Invoke-WebRequest -Uri "https://claude.ai" -Method Head -UseBasicParsing -TimeoutSec 15 | Out-Null }
catch { Rojo "No hay internet. Conectate e intentalo otra vez."; exit 1 }

Paso "1/4  git"
if (Instalar-Git) { Verde ("git " + ((git --version) -split " ")[2]) }
else { Rojo "No se pudo instalar git. Claude Code lo usa para ver cambios; se sigue igual." }

Paso "2/4  Claude Code"
if (Instalar-Claude) { Verde ("Claude Code " + ((claude --version) -split " ")[0]); Persistir-Ruta }
else { Rojo "No se pudo instalar Claude Code."; Gris "Prueba a mano en PowerShell:  irm https://claude.ai/install.ps1 | iex"; exit 1 }

Paso "3/4  Claude Desktop (la app de ventana)"
if (Instalar-ClaudeDesktop) { Verde "Claude Desktop instalada" }
else { Rojo "No se pudo instalar Claude Desktop. Bajala de claude.ai/download (Claude Code funciona igual)." }

Paso "4/4  Configuracion del equipo"
Aplicar-Config $PSScriptRoot $Perfil
Verde "$env:USERPROFILE\.claude listo (lo que habia quedo en .claude\respaldo-*)"

Write-Host ""
Negrita "Listo. Falta iniciar sesion, una sola vez:"
Gris "Se abre Claude Code y te pide entrar con tu cuenta (se abre el navegador)."
Gris "Usa la cuenta con la que te invitaron al equipo."
Write-Host ""
Read-Host "  Presiona Enter para abrir Claude Code" | Out-Null
Ruta-Extendida
& claude
