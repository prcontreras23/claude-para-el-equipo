# Perfiles

Un perfil es una carpeta con lo que **esa persona** necesita además de la base de `config/`.
Se copia encima de `~/.claude/` (en Windows, `%USERPROFILE%\.claude\`) y gana sobre la base.

Estructura posible dentro de `perfiles/<nombre>/`:

```
CLAUDE.md          ← reemplaza al CLAUDE.md base (si prefieres solo agregar, copia el base y añade)
settings.json      ← reemplaza al settings.json base
skills/<skill>/    ← se agregan a ~/.claude/skills/
commands/x.md      ← se agregan a ~/.claude/commands/
agents/x.md        ← se agregan a ~/.claude/agents/
```

Nada se borra: si la persona ya tenía otros skills, se quedan. Lo que se sobreescribe queda en `~/.claude/respaldo-<fecha>/`.

## Cómo se usa un perfil

**Mac**
```bash
curl -fsSL https://raw.githubusercontent.com/prcontreras23/claude-para-el-equipo/main/instalar.sh | bash -s -- ejemplo
```

**Windows**
```powershell
$env:PERFIL="ejemplo"; irm https://raw.githubusercontent.com/prcontreras23/claude-para-el-equipo/main/instalar-windows.ps1 | iex
```

Sin perfil, se instala solo la base.

## Crear uno nuevo

1. Copia `perfiles/ejemplo/` con el nombre de la persona (minúsculas, sin espacios: `noemi`, `soto`).
2. Ajusta su `CLAUDE.md` y agrega los skills que le toquen.
3. Haz commit y push. La persona corre la línea con su nombre y listo.

> Este repo es público. **No pongas aquí contraseñas, claves de API, teléfonos ni datos de casos.** Eso se configura después, en la máquina de cada quien.
