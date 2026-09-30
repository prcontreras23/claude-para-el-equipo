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

**1. Diagnóstico.** Revisa la máquina y marca qué hay y qué falta: git, Claude Code, Claude Desktop (trae Cowork), Google Chrome, la extensión de Claude en Chrome, la configuración del equipo y la sesión de Claude Code.

**2. Instala lo que falte**, solo:

| Paso | Mac | Windows |
|---|---|---|
| git | Command Line Tools de Xcode (diálogo del sistema) | winget `Git.Git`, o instalador oficial silencioso |
| Claude Code | `claude.ai/install.sh` (queda en `~/.local/bin`, se actualiza solo) | `claude.ai/install.ps1` |
| Claude Desktop | Descarga de `downloads.claude.ai`, verificada por checksum y firma de **Anthropic PBC** | winget `Anthropic.Claude` |
| Google Chrome | Descarga de `dl.google.com`, verificada por firma de **Google** | winget `Google.Chrome`, o instalador oficial verificado por firma |
| Configuración | Copia `config/` a `~/.claude/` y encima el perfil, si lo hay | Igual, en `%USERPROFILE%\.claude\` |

**3. Pasos que hace la persona.** El instalador no sigue hasta que cada uno quede hecho:

| Paso | Qué hace el instalador |
|---|---|
| A. Entrar en claude.ai | Abre `claude.ai/login` y espera |
| B. Claude Desktop | Si no quedó instalada, abre `claude.ai/download` y no sigue hasta encontrarla; luego la abre para entrar |
| C. Extensión de Chrome | Abre la extensión en la Chrome Web Store y no sigue hasta que aparece instalada; luego pide entrar en ella |
| D. Claude Code | Muestra el diagnóstico final y abre `claude` para entrar con la cuenta |

Nada pide contraseña de administrador (salvo el diálogo de Apple para las Command Line Tools, que es del sistema). Lo que ya existiera en `~/.claude` queda en `~/.claude/respaldo-<fecha>/`.

Se puede volver a correr las veces que haga falta: lo instalado se detecta y se salta; la configuración se vuelve a aplicar.

---|---|---|
| git | Command Line Tools de Xcode (diálogo del sistema) | winget `Git.Git`, o instalador oficial silencioso |
| Claude Code | `claude.ai/install.sh` (queda en `~/.local/bin`, se actualiza solo) | `claude.ai/install.ps1` |
| Claude Desktop | Descarga de `downloads.claude.ai`, verificada por checksum y firma de **Anthropic PBC** | winget `Anthropic.Claude` |
| Configuración | Copia `config/` a `~/.claude/` y encima el perfil, si lo hay | Igual, en `%USERPROFILE%\.claude\` |
| Sesión | Abre `claude` para que la persona entre con su cuenta (navegador) | Igual |

Nada pide contraseña de administrador (salvo el diálogo de Apple para las Command Line Tools, que es del sistema). Lo que ya existiera en `~/.claude` queda en `~/.claude/respaldo-<fecha>/`.

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
