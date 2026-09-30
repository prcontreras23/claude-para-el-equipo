# Aplica la configuracion del equipo a %USERPROFILE%\.claude (y encima un perfil).
# Mismas reglas que lib-config.sh: respaldo de lo existente, config/ base,
# perfiles/<nombre>/ gana, nada se borra.

function Copiar-Capa($capa, $destino, $respaldo) {
  if (-not (Test-Path $capa)) { return }
  Get-ChildItem -Path $capa -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($capa.Length).TrimStart('\','/')
    if ($rel -eq "README.md") { return }
    $dest0 = Join-Path $destino $rel
    # Quien ya usaba Claude conserva lo suyo (ver lib-config.sh).
    if ($rel -eq "CLAUDE.md" -and (Test-Path $dest0) -and -not (Select-String -Path $dest0 -Pattern "Claude para el equipo" -SimpleMatch -Quiet)) {
      Copy-Item $_.FullName (Join-Path $destino "equipo-adose.md") -Force
      if (-not (Select-String -Path $dest0 -Pattern "@~/.claude/equipo-adose.md" -SimpleMatch -Quiet)) {
        Add-Content -Path $dest0 -Value "`r`n`r`n## Reglas del equipo de ADOSE`r`n@~/.claude/equipo-adose.md" -Encoding UTF8
      }
      return
    }
    if ($rel -eq "settings.json" -and (Test-Path $dest0)) { return }
    $dest = Join-Path $destino $rel
    $bk = Join-Path $respaldo $rel
    # Se respalda solo la primera vez: el original no lo pisa la capa siguiente.
    if ((Test-Path $dest) -and -not (Test-Path $bk)) {
      New-Item -ItemType Directory -Force -Path (Split-Path $bk) | Out-Null
      Copy-Item $dest $bk -Force
    }
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    Copy-Item $_.FullName $dest -Force
  }
}

function Aplicar-Config($fuente, $perfil) {
  $destino  = Join-Path $env:USERPROFILE ".claude"
  $respaldo = Join-Path $destino ("respaldo-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
  New-Item -ItemType Directory -Force -Path $destino | Out-Null

  Copiar-Capa (Join-Path $fuente "config") $destino $respaldo

  if ($perfil) {
    $dirPerfil = Join-Path (Join-Path $fuente "perfiles") $perfil
    if (Test-Path $dirPerfil) { Copiar-Capa $dirPerfil $destino $respaldo }
    else { Write-Host "  ! No existe el perfil '$perfil'; se aplico solo la base." -ForegroundColor Yellow; $perfil = $null }
  }

  $nombre = if ($perfil) { $perfil } else { "base" }
  @("repo: $Repo", "perfil: $nombre", "fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm')") |
    Set-Content -Path (Join-Path $destino ".claude-para-el-equipo") -Encoding UTF8
}
