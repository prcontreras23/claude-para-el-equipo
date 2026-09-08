# Funciones para instalar lo que Claude Code necesita en Windows: git, Claude Code
# y Claude Desktop. Usa winget si esta; si no, cae a los instaladores oficiales.
# Lo cargan instalar.ps1 e instalar-windows.ps1.

$script:LocalBin = Join-Path $env:USERPROFILE ".local\bin"

function Ruta-Extendida {
  $extra = @(
    $script:LocalBin,
    (Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links"),
    "C:\Program Files\Git\cmd",
    "C:\Program Files (x86)\Git\cmd"
  )
  foreach ($d in $extra) {
    if ((Test-Path $d) -and ($env:PATH -notlike "*$d*")) { $env:PATH = "$d;$env:PATH" }
  }
}

function Tiene($cmd) { $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue) }

function Probar-Winget($paqueteId) {
  if (-not (Tiene winget)) { return $false }
  try {
    winget install --id $paqueteId -e --accept-source-agreements `
      --accept-package-agreements --silent 2>&1 | Out-Null
  } catch { return $false }
  Ruta-Extendida
  return $true
}

# ------------------------------------------------------------------ git

function Instalar-Git {
  Ruta-Extendida
  if (Tiene git) { return $true }
  if (Probar-Winget "Git.Git") { Ruta-Extendida; if (Tiene git) { return $true } }

  # Instalador oficial de Git for Windows, silencioso.
  try {
    $arch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "64-bit" }
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/git-for-windows/git/releases/latest" -TimeoutSec 30
    $asset = $rel.assets | Where-Object { $_.name -like "*$arch.exe" -and $_.name -notlike "*Portable*" } | Select-Object -First 1
    if (-not $asset) { return $false }
    $exe = Join-Path $env:TEMP $asset.name
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $exe -UseBasicParsing
    Start-Process -FilePath $exe -ArgumentList "/VERYSILENT","/NORESTART" -Wait
    Remove-Item $exe -ErrorAction SilentlyContinue
  } catch { return $false }
  Ruta-Extendida
  return (Tiene git)
}

# ------------------------------------------------------------------ Claude Code

function Instalar-Claude {
  Ruta-Extendida
  if (Tiene claude) { return $true }
  # Instalador oficial de Anthropic. No necesita Node ni npm.
  try {
    $script = Invoke-RestMethod -Uri "https://claude.ai/install.ps1" -TimeoutSec 60
    Invoke-Expression $script | Out-Null
  } catch { return $false }
  Ruta-Extendida
  return (Tiene claude)
}

# ------------------------------------------------------------------ Claude Desktop

function Tiene-ClaudeDesktop {
  $rutas = @(
    (Join-Path $env:LOCALAPPDATA "Programs\Claude\Claude.exe"),
    (Join-Path $env:LOCALAPPDATA "AnthropicClaude\Claude.exe"),
    "C:\Program Files\Claude\Claude.exe"
  )
  foreach ($r in $rutas) { if (Test-Path $r) { return $true } }
  if (Tiene winget) {
    $l = winget list --id Anthropic.Claude -e 2>$null | Out-String
    if ($l -match "Anthropic\.Claude") { return $true }
  }
  return $false
}

function Instalar-ClaudeDesktop {
  if (Tiene-ClaudeDesktop) { return $true }
  if (Probar-Winget "Anthropic.Claude") { if (Tiene-ClaudeDesktop) { return $true } }
  return $false
}

# ------------------------------------------------------------------ PATH persistente

function Persistir-Ruta {
  try {
    $actual = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($actual -notlike "*$script:LocalBin*") {
      $nuevo = if ([string]::IsNullOrEmpty($actual)) { $script:LocalBin } else { "$actual;$script:LocalBin" }
      [Environment]::SetEnvironmentVariable("PATH", $nuevo, "User")
    }
  } catch {}
}
