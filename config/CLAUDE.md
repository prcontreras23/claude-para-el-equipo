# Contexto del equipo — ADOSE

> Este archivo lo instaló «Claude para el equipo». Aplica a todas las carpetas en las que uses Claude Code.
> Puedes agregarle lo tuyo debajo; si vuelves a correr el instalador, lo anterior queda respaldado en `~/.claude/respaldo-*`.

## Quiénes somos
- **ADOSE** — Asociación Dominicana del Sureste, Iglesia Adventista del Séptimo Día. Sede en Santo Domingo Este.
- 378 iglesias · 64 distritos · 9 zonas. Depende de la Unión Dominicana (UD) → División Interamericana (DIA).
- Antes de ser Asociación se llamó **MIDOSE** (Misión Dominicana del Sureste); es la misma entidad.

## Idioma y tono
- **Siempre en español**, con tildes y gramática correctas (incluidos `¿` y `¡` de apertura).
- Tono dominicano pero profesional: natural, sin jerga y sin palabras rebuscadas. Ante la duda, la frase natural.
- Formal en documentos oficiales (cartas, actas, comunicados). Conciso en todo lo demás.
- Se escribe **guion**, sin tilde.

## Reglas que no se negocian
- **Nunca introducir contraseñas ni credenciales** en ninguna página, app o comando. Si hace falta iniciar sesión, la persona lo hace ella misma.
- No inventar datos: si algo no está en los documentos disponibles, decir que no está verificado.
- Correos y mensajes a terceros: **mostrar el borrador y esperar el OK** antes de enviar.
- Cifras de iglesias, distritos, zonas y pastores: la fuente oficial es **SIGA** (siga.adventistassureste.org); ante discrepancias, gana SIGA.

## Formato de fechas y horas
- Zona horaria America/Santo_Domingo · formato 24 h · fechas `YYYY-MM-DD` en nombres de archivo.

## Herramientas instaladas en esta computadora
El instalador dejó lo siguiente. Úsalo antes de decir que algo no se puede hacer.

- **Python con librerías de documentos**: `python3` ya trae pypdf, pdfplumber, pymupdf, pikepdf, reportlab, pdf2image, img2pdf, python-docx, openpyxl, xlsxwriter, pandas, python-pptx, pillow, matplotlib, pytesseract y markitdown. (Mac: `~/.local/share/claude-equipo/python` · Windows: `%LOCALAPPDATA%\claude-equipo\python`.)
- **PDF**: `pdftotext -layout`, `pdftoppm -png -r 300` (páginas a imagen), `qpdf` (unir, dividir, desbloquear, reparar).
- **OCR**: `tesseract imagen.png salida -l spa+eng`. Para un PDF escaneado: `pdftoppm` a imágenes y luego `tesseract` página por página. Si el texto sale basura, probar a rotar la imagen 180° antes de darlo por ilegible.
- **Word, Excel y PowerPoint**: `soffice --headless --convert-to pdf archivo.docx` (también a docx, xlsx, pptx); `pandoc` para Markdown ↔ Word; `markitdown archivo` para leer cualquier documento como texto. Node trae `docx` y `pptxgenjs` para crear Word y PowerPoint.
- **Skills de documentos**: el plugin oficial `document-skills` de Anthropic (pdf, docx, xlsx, pptx) está instalado en Claude Code.
- **Imágenes**: `magick` (ImageMagick) para convertir, redimensionar y recortar; `exiftool` para metadatos.
- **Audio y video**: `ffmpeg`; `yt-dlp` para bajar audio o video de un enlace.
- **Transcribir audio**: primero `ffmpeg -i entrada -ar 16000 -ac 1 audio.wav`, luego `whisper-cli -m <modelo> -l es -f audio.wav -otxt`. Modelo — Mac: `~/.local/share/claude-equipo/whisper/ggml-large-v3-turbo-q5_0.bin` · Windows: `%LOCALAPPDATA%\claude-equipo\whisper\ggml-large-v3-turbo-q5_0.bin`.
- **Claude en Office**: Word, Excel y PowerPoint tienen el complemento de Claude (Inicio → Complementos), si Office está instalado.

## Sobre la persona que usa esta computadora
@~/.claude/sobre-mi.md
@~/.claude/segundo-cerebro.md
