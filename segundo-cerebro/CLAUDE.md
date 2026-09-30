# CLAUDE.md — Esquema del segundo cerebro de {{NOMBRE}}

> Este archivo es el **esquema**: le dice a Claude cómo mantener esta wiki. Sigue el patrón *LLM Wiki* de Andrej Karpathy. Leerlo al inicio de cada sesión en esta carpeta. {{NOMBRE}} y Claude lo van ajustando con el uso.
> Creado por «Claude para el equipo» el {{FECHA}}.

## Para qué es
- **Usos**: {{USOS}}
- **Temas principales**: {{TEMAS}}
- **Fuentes que va a traer**: {{FUENTES}}

## Las tres capas

```
fuentes/   CAPA 1 — lo que {{NOMBRE}} trae: PDF, actas, notas, audios, artículos, fotos.
           Claude LEE de aquí y NUNCA modifica ni borra nada.
  documentos/  PDF, Word, Excel, presentaciones
  audios/      grabaciones (Claude las transcribe con whisper y guarda el texto al lado)
  web/         artículos guardados con Obsidian Web Clipper
  imagenes/    fotos y adjuntos (Obsidian guarda aquí los adjuntos)
  notas/       notas sueltas y apuntes rápidos

wiki/      CAPA 2 — la escribe y la mantiene Claude, entera.
  index.md     catálogo de todo: cada página con enlace y una línea de resumen
  log.md       bitácora cronológica, solo se agrega al final
  fuentes/     una página de resumen por cada fuente ingerida
{{CARPETAS_WIKI}}
  respuestas/  análisis y respuestas que vale la pena guardar
  scripts/     buscar.py — búsqueda BM25 cuando el índice no basta

CLAUDE.md  CAPA 3 — este esquema.
```

**Regla clave**: {{NOMBRE}} casi nunca escribe la wiki. Trae fuentes, pregunta y dirige. Claude resume, enlaza, archiva y lleva la bitácora.

## Operaciones

### INGERIR (fuente nueva → integrarla a la wiki)
Cuando {{NOMBRE}} diga «ingiere esto», «guarda esto», «procesa lo que puse en fuentes»:
1. Leer la fuente completa. Si es audio: `ffmpeg -i audio -ar 16000 -ac 1 audio.wav` y `whisper-cli -m <modelo> -l es -f audio.wav -otxt` (el modelo está indicado en `~/.claude/CLAUDE.md`), y guardar el texto junto al audio. Si es un PDF escaneado o una foto: OCR con `tesseract -l spa+eng`.
2. {{MODO_INGEST}}
3. Crear `wiki/fuentes/<fecha> — <título>.md` con el resumen y los puntos clave, con `fuente:` y `fuente_fecha:` en el frontmatter.
4. Actualizar las páginas de personas, temas y proyectos que la fuente toque (una fuente puede tocar 5–15 páginas), con enlaces `[[...]]` en ambas direcciones. Si contradice algo que ya estaba, decirlo en la página y en el resumen.
5. Actualizar `wiki/index.md`.
6. Agregar al final de `wiki/log.md`: `## [AAAA-MM-DD] ingerir | <título>`.

### PREGUNTAR (responder desde la wiki, no desde cero)
1. Leer `wiki/index.md` primero; entrar solo a las páginas que el índice señala.
2. Si el índice no basta: `python3 wiki/scripts/buscar.py "consulta" 5`.
3. Responder citando las páginas con `[[enlaces]]`.
4. Si la respuesta vale para después (una comparación, un análisis, una decisión), guardarla en `wiki/respuestas/` y anotarla en el índice y en la bitácora (`## [AAAA-MM-DD] pregunta | <tema>`).

### REVISAR (cuando {{NOMBRE}} diga «revisa la wiki»)
Buscar contradicciones entre páginas, datos viejos que una fuente nueva ya superó, páginas sin enlaces que lleguen a ellas, temas mencionados sin página propia, enlaces rotos y vacíos que valga la pena llenar. Proponer preguntas o fuentes nuevas. Anotar en la bitácora: `## [AAAA-MM-DD] revisión | <hallazgos>`.

## No inventar
- Lo que no tenga fuente en `fuentes/` o en una página con `fuente:` no se presenta como un hecho: se dice que no está verificado.
- Ante la duda, «no está en tu segundo cerebro» es mejor que suponer.

## Convenciones
- Nombres de archivo: `AAAA-MM-DD — Descripción.md` para lo que tiene fecha; el nombre de la persona, tema o proyecto para lo demás.
- Frontmatter en cada página de la wiki:
  ```yaml
  tipo: fuente | persona | tema | proyecto | respuesta
  fecha: AAAA-MM-DD
  actualizado: AAAA-MM-DD
  ```
- Español con tildes. Enlaces internos siempre con `[[...]]`, para que se vean en el grafo de Obsidian.
- Las imágenes van en `fuentes/imagenes/`.
