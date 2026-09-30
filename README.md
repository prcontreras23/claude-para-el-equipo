# Claude para el equipo

Deja **Claude Code** y **Claude Desktop** instalados y configurados en una computadora que no tiene nada, con una sola línea (o un doble clic). Para Mac y Windows.

Pensado para el equipo de ADOSE: la persona pega una línea, espera unos minutos, entra con su cuenta, y ya tiene Claude con las reglas del equipo (español, tono, qué no hacer con credenciales, fuentes oficiales).

---

## Antes de empezar (lo hace quien invita)

1. **Invita a la persona al equipo de Claude** desde [claude.ai](https://claude.ai) → Configuración → Miembros. Claude Code necesita una cuenta Team, Pro, Max o Enterprise; la gratuita no sirve.
2. Si quieres darle algo más que la base (skills, un CLAUDE.md con su rol), créale un **perfil** en `perfiles/` — ver [perfiles/README.md](perfiles/README.md). Si no, con la base basta.

---

## Instalar

### Mac

Abrir la app **Terminal** (Spotlight → «Terminal») y pegar:

```bash
curl -fsSL https://raw.githubusercontent.com/prcontreras23/claude-para-el-equipo/main/instalar.sh | bash
```

Con perfil:

```bash
curl -fsSL https://raw.githubusercontent.com/prcontreras23/claude-para-el-equipo/main/instalar.sh | bash -s -- nombre-del-perfil
```

> Si es una Mac nueva, macOS abrirá una ventana para instalar las *Command Line Tools* (traen git). Dale a **Instalar** y espera; el instalador sigue solo cuando termina.

### Windows

Abrir **PowerShell** (menú Inicio → «PowerShell») y pegar:

```powershell
irm https://raw.githubusercontent.com/prcontreras23/claude-para-el-equipo/main/instalar-windows.ps1 | iex
```

Con perfil:

```powershell
$env:PERFIL="nombre-del-perfil"; irm https://raw.githubusercontent.com/prcontreras23/claude-para-el-equipo/main/instalar-windows.ps1 | iex
```

### Doble clic (alternativa)

Descargar el ZIP (botón verde **Code** → **Download ZIP**), descomprimir y hacer doble clic en `Instalar en Windows.bat`.
En Mac el doble clic en `Instalar en Mac.command` **no funciona si el archivo se bajó con el navegador** (Gatekeeper lo bloquea); por eso la línea de arriba es el camino recomendado.

---

## Qué hace

**1. Diagnóstico.** Revisa la máquina y marca qué hay y qué falta: git, Claude Code, Claude Desktop (trae Cowork), Google Chrome, la extensión de Claude en Chrome, las herramientas de documentos, OCR y audio, Claude en Word/Excel/PowerPoint, la configuración del equipo y la sesión de Claude Code.

**2. Instala lo que falte**, solo:

| Paso | Mac | Windows |
|---|---|---|
| git | Command Line Tools de Xcode (diálogo del sistema) | winget `Git.Git`, o instalador oficial silencioso |
| Claude Code | `claude.ai/install.sh` (queda en `~/.local/bin`, se actualiza solo) | `claude.ai/install.ps1` |
| Claude Desktop | Descarga de `downloads.claude.ai`, verificada por checksum y firma de **Anthropic PBC** | winget `Anthropic.Claude` |
| Google Chrome | Descarga de `dl.google.com`, verificada por firma de **Google** | winget `Google.Chrome`, o instalador oficial verificado por firma |
| Herramientas (PDF, Office, imágenes, OCR, audio) | Homebrew: poppler, qpdf, tesseract + español, pandoc, ffmpeg, ImageMagick, exiftool, whisper-cpp, node, yt-dlp, LibreOffice | winget: los mismos (whisper.cpp desde su GitHub oficial) |
| Python de documentos | `uv` + Python 3.12 en `~/.local/share/claude-equipo/python` con pypdf, pdfplumber, pymupdf, pikepdf, reportlab, python-docx, openpyxl, pandas, python-pptx, pillow, pytesseract, markitdown… | Igual, en `%LOCALAPPDATA%\claude-equipo\python` |
| Transcripción | Modelo whisper `large-v3-turbo` q5_0 (~550 MB) | Igual |
| Skills de documentos | Plugin oficial `document-skills` de Anthropic en Claude Code | Igual |
| Configuración | Copia `config/` a `~/.claude/` y encima el perfil, si lo hay | Igual, en `%USERPROFILE%\.claude\` |

**3. Plugins y conectores de Claude Code**, solos: `document-skills` y los de oficina de Anthropic (`productivity`, `enterprise-search`, `operations`, `human-resources`, `finance`, `data`, `marketing`, `pdf-viewer`), y el conector de FastTrack.

**4. Diez pasos guiados.** Los que ya están hechos se detectan o se preguntan («¿Ya lo tienes?») y se saltan:

| Paso | Qué hace |
|---|---|
| 1. Entrar a claude.ai | Abre `claude.ai/login` |
| 2. Conectores | Abre `claude.ai/customize/connectors` (Personalización → Conectores) para conectar Microsoft 365 (Outlook, calendario, OneDrive, Teams), Gmail, Google Calendar, Google Drive y FastTrack |
| 3. Perfil | Seis preguntas (nombre, cargo, oficina, tareas, programas, estilo). Guarda `~/.claude/sobre-mi.md` y copia al portapapeles el texto para «Instrucciones para Claude» (claude.ai → Configuración → Cuenta) |
| 4. Claude Desktop | Comprueba que esté instalada, la abre y espera a que la persona entre |
| 5. Extensión de Chrome | No sigue hasta detectarla instalada |
| 6. App del celular | iPhone o Android, con código QR en la Terminal |
| 7. Claude en Word, Excel y PowerPoint | Complementos de AppSource, verificados en la caché de Office |
| 8. WhatsApp (opcional) | Aviso de privacidad y, si la persona quiere, corre [whatsapp-para-claude](https://github.com/prcontreras23/whatsapp-para-claude) |
| 9. Segundo cerebro (opcional) | Instala Obsidian, pregunta dónde crearlo (iCloud, OneDrive, Documentos u otra carpeta) y cuatro preguntas más; arma una bóveda con el patrón *LLM Wiki* de Karpathy (`fuentes/`, `wiki/`, `CLAUDE.md` como esquema) y la registra en Obsidian |
| 10. Claude Code | Diagnóstico final, `claude auth login` hasta que quede la sesión, y abre `claude` |

**Sirve igual si la persona ya usaba Claude**: lo instalado se salta, su `CLAUDE.md` se respeta (las reglas del equipo se importan desde `~/.claude/equipo-adose.md`) y su `settings.json` no se toca.

En Mac, **Homebrew pide una vez la contraseña de la computadora**; el resto no. En Windows, algunos programas (LibreOffice, Tesseract, Node) hacen que Windows pregunte si se permiten cambios: hay que darle a **Sí**. La primera corrida baja unos 2 GB y tarda de 20 a 40 minutos. Lo que ya existiera en `~/.claude` queda en `~/.claude/respaldo-<fecha>/`.

Se puede volver a correr las veces que haga falta: lo instalado se detecta y se salta; la configuración se vuelve a aplicar.

---|---|---|
| git | Command Line Tools de Xcode (diálogo del sistema) | winget `Git.Git`, o instalador oficial silencioso |
| Claude Code | `claude.ai/install.sh` (queda en `~/.local/bin`, se actualiza solo) | `claude.ai/install.ps1` |
| Claude Desktop | Descarga de `downloads.claude.ai`, verificada por checksum y firma de **Anthropic PBC** | winget `Anthropic.Claude` |
| Herramientas (PDF, Office, imágenes, OCR, audio) | Homebrew: poppler, qpdf, tesseract + español, pandoc, ffmpeg, ImageMagick, exiftool, whisper-cpp, node, yt-dlp, LibreOffice | winget: los mismos (whisper.cpp desde su GitHub oficial) |
| Python de documentos | `uv` + Python 3.12 en `~/.local/share/claude-equipo/python` con pypdf, pdfplumber, pymupdf, pikepdf, reportlab, python-docx, openpyxl, pandas, python-pptx, pillow, pytesseract, markitdown… | Igual, en `%LOCALAPPDATA%\claude-equipo\python` |
| Transcripción | Modelo whisper `large-v3-turbo` q5_0 (~550 MB) | Igual |
| Skills de documentos | Plugin oficial `document-skills` de Anthropic en Claude Code | Igual |
| Configuración | Copia `config/` a `~/.claude/` y encima el perfil, si lo hay | Igual, en `%USERPROFILE%\.claude\` |
| Sesión | Abre `claude` para que la persona entre con su cuenta (navegador) | Igual |

En Mac, **Homebrew pide una vez la contraseña de la computadora**; el resto no. En Windows, algunos programas (LibreOffice, Tesseract, Node) hacen que Windows pregunte si se permiten cambios: hay que darle a **Sí**. La primera corrida baja unos 2 GB y tarda de 20 a 40 minutos. Lo que ya existiera en `~/.claude` queda en `~/.claude/respaldo-<fecha>/`.

Se puede volver a correr las veces que haga falta: lo instalado se detecta y se salta; la configuración se vuelve a aplicar.

---

## Qué trae la configuración base (`config/`)

- `CLAUDE.md` — contexto de ADOSE, idioma y tono, reglas de credenciales y de fuentes oficiales. Aplica en todas las carpetas.
- `settings.json` — tema oscuro, aviso cuando Claude necesita algo, búsqueda web permitida.

Lo que **no** trae, a propósito: conectores (Gmail, Outlook, Notion, Drive…), que vienen con la cuenta de claude.ai y se activan desde ahí; y el WhatsApp, que tiene su propio instalador en [whatsapp-para-claude](https://github.com/prcontreras23/whatsapp-para-claude).

---

## Después de instalar

El propio instalador guía la entrada en claude.ai, Claude Desktop, la extensión de Chrome y Claude Code. Para trabajar después: abrir Claude Desktop (Chat, Cowork, Code) o, en la Terminal (o PowerShell), entrar a una carpeta y escribir `claude`.

---

## Mantener

- Cambios para todos → editar `config/`. Cambios para una persona → su carpeta en `perfiles/`.
- Este repo es **público**: cero contraseñas, claves, teléfonos o datos de casos.
- La parte de Windows está escrita siguiendo el mismo patrón del instalador de WhatsApp, pero **conviene probarla en una PC real la primera vez**.
