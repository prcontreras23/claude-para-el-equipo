# Extras de instalar.ps1 (equivalente de lib-extras.sh): app de Claude en el celular
# (QR), FastTrack, WhatsApp (opcional) y el segundo cerebro en Obsidian (opcional,
# patrón LLM Wiki de Karpathy). Usa Esperar/Gris/Verde/Rojo del instalador.
# UTF-8 CON BOM a propósito, para que PowerShell 5 lea bien las tildes.

function Ya-Hecho($pregunta) { $r = Read-Host "  $pregunta (s/n) >"; return ($r -match '^[sS]') }

# ------------------------------------------------------------------ App del celular

$script:AppIphone  = "https://apps.apple.com/app/claude-by-anthropic/id6473753684"
$script:AppAndroid = "https://play.google.com/store/apps/details?id=com.anthropic.claude"

function Mostrar-Qr($url) {
  $ok = $false
  if (Test-Path $script:HerrPyExe) {
    & $script:HerrPyExe -c "import qrcode,sys; q=qrcode.QRCode(border=2); q.add_data(sys.argv[1]); q.print_ascii(invert=True)" $url 2>$null
    $ok = ($LASTEXITCODE -eq 0)
  }
  if (-not $ok) { Gris "(No pude dibujar el código QR.)" }
  Gris "Enlace: $url"
}

function Paso-Celular {
  Gris "Con la app en el celular sigues tus conversaciones fuera de la oficina, le dictas"
  Gris "por voz y le mandas fotos de documentos. Es la misma cuenta y las mismas conversaciones."
  if (Ya-Hecho "¿Ya tienes la app de Claude en tu celular?") { Verde "App del celular"; return }
  $t = ""
  while ($t -ne "1" -and $t -ne "2") {
    $t = Read-Host "  ¿Tu celular es 1 = iPhone o 2 = Android? (Enter = saltar) >"
    if (-not $t) { Gris "Se salta."; return }
  }
  $url = if ($t -eq "1") { $script:AppIphone } else { $script:AppAndroid }
  Write-Host ""
  Gris "Abre la cámara del celular y apunta a este código:"
  Write-Host ""; Mostrar-Qr $url; Write-Host ""
  Gris "Instala la app y entra con el mismo correo (te llega un código)."
  if ($t -eq "1") {
    Gris "Si el iPhone dice que no se puede descargar por restricciones de contenido: la app"
    Gris "es 18+. Ajustes → Tiempo en pantalla → Restricciones de contenido y privacidad →"
    Gris "Restricciones de contenido de la App Store → Apps → 18+. Si pide un código, es el"
    Gris "de Tiempo en pantalla (no el del teléfono)."
  }
  Esperar "Cuando ya estés dentro de la app, presiona Enter..."
  Verde "App del celular"
}

# ------------------------------------------------------------------ FastTrack

$script:FastTrackUrl = "https://literature.researchfasttrack.com/mcp"
function Tiene-FastTrack { claude mcp get fasttrack-literature 2>&1 | Out-Null; return ($LASTEXITCODE -eq 0) }
function Instalar-FastTrack {
  if (Tiene-FastTrack) { return $true }
  claude mcp add --transport http --scope user fasttrack-literature $script:FastTrackUrl 2>&1 | Out-Null
  return (Tiene-FastTrack)
}

# ------------------------------------------------------------------ WhatsApp (opcional)

# whatsapp-para-claude registra el conector como «whatsapp-<instancia>».
function Tiene-WhatsApp {
  $f = Join-Path $env:USERPROFILE ".claude.json"
  return ((Test-Path $f) -and (Select-String -Path $f -Pattern '"whatsapp[^"]*":\s*\{' -Quiet))
}

function Paso-WhatsApp {
  if (Tiene-WhatsApp) { Verde "WhatsApp ya está conectado con Claude"; return }
  Gris "Puedes conectar tu WhatsApp para pedirle a Claude cosas como «búscame lo que me"
  Gris "escribió Juan la semana pasada» o «prepárame la respuesta a este grupo»."
  Gris "Antes de decidir:"
  Gris "  • Claude tendría acceso a TODO tu WhatsApp: chats personales, grupos y fotos."
  Gris "  • Los mensajes se quedan en esta computadora; a Claude solo va lo que le pidas."
  Gris "  • Puede enviar mensajes en tu nombre: revisa siempre el borrador antes."
  Gris "  • Se desconecta cuando quieras: WhatsApp → Ajustes → Dispositivos vinculados."
  Gris "  • Si esta computadora la usan otras personas, mejor no lo conectes."
  if (-not (Ya-Hecho "¿Quieres conectar tu WhatsApp ahora?")) { Gris "Se salta. Lo puedes hacer después volviendo a correr el instalador."; return }
  Gris "Ten el celular a mano: vas a escanear un código QR desde WhatsApp."
  # En otra ventana de PowerShell: si ese instalador termina con "exit", no cierra este.
  & powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/prcontreras23/whatsapp-para-claude/main/instalar-windows.ps1 | iex"
  if (Tiene-WhatsApp) { Verde "WhatsApp conectado" } else { Rojo "WhatsApp no quedó conectado. Puedes volver a intentarlo después." }
}

# ------------------------------------------------------------------ Segundo cerebro en Obsidian (opcional)

$script:ObsidianExe = Join-Path $env:LOCALAPPDATA "Programs\Obsidian\Obsidian.exe"
$script:SegundoCerebroNota = Join-Path $env:USERPROFILE ".claude\segundo-cerebro.md"

function Tiene-Obsidian { return (Test-Path $script:ObsidianExe) }
function Tiene-SegundoCerebro { return (Test-Path $script:SegundoCerebroNota) }

function Instalar-Obsidian {
  if (Tiene-Obsidian) { return $true }
  if (-not (Tiene winget)) { return $false }
  try { winget install --id Obsidian.Obsidian -e --accept-source-agreements --accept-package-agreements --silent 2>&1 | Out-Null } catch {}
  return (Tiene-Obsidian)
}

function Elegir-RutaSegundoCerebro {
  $opciones = @()
  $icloud = Join-Path $env:USERPROFILE "iCloudDrive"
  if (Test-Path $icloud) { $opciones += ,@("iCloud Drive (se sincroniza con tu iPhone o iPad)", $icloud) }
  if ($env:OneDrive -and (Test-Path $env:OneDrive)) { $opciones += ,@("OneDrive (se sincroniza con tu cuenta de Microsoft)", $env:OneDrive) }
  $opciones += ,@("Documentos (solo en esta computadora)", [Environment]::GetFolderPath("MyDocuments"))
  $opciones += ,@("Escoger otra carpeta", $null)

  Write-Host "  ¿Dónde quieres crear tu segundo cerebro?" -ForegroundColor White
  for ($i = 0; $i -lt $opciones.Count; $i++) { Gris ("  " + ($i + 1) + " = " + $opciones[$i][0]) }
  Gris "  (Enter = 1)"
  while ($true) {
    $o = Read-Host "  >"
    if (-not $o) { $o = "1" }
    $n = 0
    if (-not [int]::TryParse($o, [ref]$n) -or $n -lt 1 -or $n -gt $opciones.Count) { Rojo ("Escribe un número del 1 al " + $opciones.Count + "."); continue }
    $base = $opciones[$n - 1][1]
    if (-not $base) {
      Add-Type -AssemblyName System.Windows.Forms
      $d = New-Object System.Windows.Forms.FolderBrowserDialog
      $d.Description = "Escoge dónde crear tu Segundo cerebro"
      if ($d.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $base = $d.SelectedPath }
      else { Rojo "No escogiste carpeta."; continue }
    }
    return (Join-Path $base "Segundo cerebro")
  }
}

function Registrar-Boveda($ruta) {
  $cfg = Join-Path $env:APPDATA "obsidian\obsidian.json"
  Get-Process -Name Obsidian -ErrorAction SilentlyContinue | Stop-Process -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 1
  New-Item -ItemType Directory -Force -Path (Split-Path $cfg) | Out-Null
  $d = $null
  # Si el archivo existe pero no se puede leer, no se toca: se perderían las bóvedas de la persona.
  if (Test-Path $cfg) { try { $d = Get-Content $cfg -Raw | ConvertFrom-Json -ErrorAction Stop } catch { return } }
  $vaults = @{}
  if ($d -and $d.vaults) { foreach ($p in $d.vaults.PSObject.Properties) { $vaults[$p.Name] = @{ path = $p.Value.path; ts = $p.Value.ts } } }
  $id = ($vaults.Keys | Where-Object { $vaults[$_].path -eq $ruta } | Select-Object -First 1)
  if (-not $id) { $id = -join ((1..16) | ForEach-Object { "0123456789abcdef"[(Get-Random -Maximum 16)] }) }
  $vaults[$id] = @{ path = $ruta; ts = [long]([DateTimeOffset]::Now.ToUnixTimeMilliseconds()); open = $true }
  $json = @{ vaults = $vaults } | ConvertTo-Json -Depth 5
  [System.IO.File]::WriteAllText($cfg, $json, (New-Object System.Text.UTF8Encoding($false)))
}

function Rellenar($archivo, $valores) {
  $txt = [System.IO.File]::ReadAllText($archivo)
  foreach ($k in $valores.Keys) { $txt = $txt.Replace("{{$k}}", $valores[$k]) }
  [System.IO.File]::WriteAllText($archivo, $txt, (New-Object System.Text.UTF8Encoding($false)))
}

function Paso-SegundoCerebro($fuenteRepo) {
  Gris "Un «segundo cerebro» es una carpeta de notas en Obsidian que Claude organiza por ti:"
  Gris "le traes documentos, actas, audios o artículos, y él los resume, los conecta entre sí"
  Gris "y te responde con lo que hay ahí. (Patrón LLM Wiki de Andrej Karpathy.)"
  if (Tiene-SegundoCerebro) { Verde "Ya tienes un segundo cerebro configurado"; return }
  if (-not (Ya-Hecho "¿Quieres configurarlo ahora? Es opcional")) { Gris "Se salta. Lo puedes hacer después volviendo a correr el instalador."; return }

  Gris "Instalando Obsidian..."
  if (Instalar-Obsidian) { Verde "Obsidian" } else { Rojo "No se pudo instalar Obsidian. Bájalo de obsidian.md y vuelve a correr esto."; return }

  Write-Host ""
  $ruta = Elegir-RutaSegundoCerebro
  Gris "Carpeta: $ruta"
  if (Test-Path (Join-Path $ruta "CLAUDE.md")) {
    Gris "Esa carpeta ya tiene un CLAUDE.md; se deja como está."
  } else {
    Write-Host ""
    Gris "Cuatro preguntas para armarlo a tu medida:"
    Write-Host "  ¿Para qué lo vas a usar? Escribe los números separados por coma." -ForegroundColor White
    Gris "  1 = mi trabajo (reuniones, casos, informes)   2 = estudio bíblico y sermones"
    Gris "  3 = formación y estudios (cursos, maestría)   4 = personal (metas, salud, finanzas)"
    $u = Read-Host "  >"
    $usos = @()
    $carpetas = @("  personas/    una página por persona", "  temas/       una página por tema")
    if ($u -match "1") { $usos += "trabajo del cargo (reuniones, casos, informes)"; $carpetas += "  proyectos/   una página por proyecto o caso"; $carpetas += "  reuniones/   una página por reunión, con acuerdos y pendientes" }
    if ($u -match "2") { $usos += "estudio bíblico y sermones"; $carpetas += "  estudios/    estudios por pasaje o libro de la Biblia"; $carpetas += "  sermones/    sermones y bosquejos" }
    if ($u -match "3") { $usos += "formación y estudios"; $carpetas += "  cursos/      una página por curso o materia" }
    if ($u -match "4") { $usos += "personal (metas, salud, finanzas)"; $carpetas += "  personal/    metas, hábitos, salud y finanzas" }
    if ($usos.Count -eq 0) { $usos = @("general") }
    $temas   = Preguntar "¿Qué temas principales vas a guardar ahí?" "las iglesias de mi distrito, finanzas, evangelismo, liderazgo"
    $fuentes = Preguntar "¿Qué vas a traer como fuentes?" "PDF, actas, audios de reuniones, artículos de internet, fotos de documentos"
    $m = ""
    while ($m -ne "1" -and $m -ne "2") {
      Write-Host "  Cuando le traigas algo nuevo, ¿qué prefieres?" -ForegroundColor White
      $m = Read-Host "  1 = que Claude me comente lo importante antes de integrarlo | 2 = que lo integre solo y me dé un resumen >"
    }
    $modo = if ($m -eq "1") { "Comentar con la persona los puntos clave y preguntarle qué destacar antes de escribir en la wiki." } else { "Integrar sin preguntar y, al terminar, darle a la persona un resumen corto de qué páginas se crearon o cambiaron." }
    $nombre = "la persona"
    if (Test-Path $script:SobreMi) {
      $l = Select-String -Path $script:SobreMi -Pattern '^- \*\*Cómo llamarme\*\*: (.+)$' | Select-Object -First 1
      if ($l) { $nombre = $l.Matches[0].Groups[1].Value }
    }

    New-Item -ItemType Directory -Force -Path $ruta | Out-Null
    Copy-Item -Path (Join-Path $fuenteRepo "segundo-cerebro\*") -Destination $ruta -Recurse -Force
    foreach ($c in @("documentos","audios","web","imagenes","notas")) { New-Item -ItemType Directory -Force -Path (Join-Path $ruta "fuentes\$c") | Out-Null }
    foreach ($c in @("fuentes","respuestas")) { New-Item -ItemType Directory -Force -Path (Join-Path $ruta "wiki\$c") | Out-Null }
    foreach ($linea in $carpetas) { $c = ($linea.Trim() -split "\s+")[0].TrimEnd("/"); New-Item -ItemType Directory -Force -Path (Join-Path $ruta "wiki\$c") | Out-Null }
    $hoy = Get-Date -Format "yyyy-MM-dd"
    Rellenar (Join-Path $ruta "CLAUDE.md") @{ NOMBRE = $nombre; FECHA = $hoy; USOS = ($usos -join "; "); TEMAS = $temas; FUENTES = $fuentes; MODO_INGEST = $modo; CARPETAS_WIKI = ($carpetas -join "`n") }
    Rellenar (Join-Path $ruta "wiki\log.md") @{ FECHA = $hoy }
    Verde "Segundo cerebro creado"
  }

  $nota = @(
    "# Segundo cerebro", "",
    "- **Carpeta**: $ruta",
    "- Es una wiki de Obsidian con el patrón LLM Wiki de Karpathy. Sus reglas están en el CLAUDE.md de esa carpeta.",
    "- Cuando la persona pida guardar, anotar, ingerir o buscar algo en «su segundo cerebro», «sus notas» u «Obsidian», trabajar en esa carpeta siguiendo su CLAUDE.md."
  ) -join "`r`n"
  [System.IO.File]::WriteAllText($script:SegundoCerebroNota, $nota, (New-Object System.Text.UTF8Encoding($false)))
  try { Registrar-Boveda $ruta } catch {}
  if (Tiene-Obsidian) { Start-Process $script:ObsidianExe }
  Gris "Se abrió Obsidian con tu segundo cerebro. Empieza por la nota «Inicio»."
  Gris "Para trabajarlo con Claude: en Claude Desktop → Code, elige la carpeta «Segundo cerebro»."

  if ((Tiene-Chrome) -and (Ya-Hecho "¿Quieres la extensión Obsidian Web Clipper para guardar artículos de internet?")) {
    Gris "Dale a «Añadir a Chrome». En sus opciones pon como carpeta:  fuentes/web"
    Start-Process (Ruta-Chrome) "https://chromewebstore.google.com/detail/cnjifjpddelmedmihgijeibhnjfabmlf"
    Esperar "Cuando la hayas añadido, presiona Enter..."
  }
  Verde "Segundo cerebro"
}
