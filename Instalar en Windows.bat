@echo off
REM Doble clic en Windows. Instala git, Claude Code y Claude Desktop y deja la
REM configuracion del equipo. Para usar un perfil, usa la linea de PowerShell
REM del README con $env:PERFIL.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0instalar.ps1"
if errorlevel 1 (
  echo.
  echo Hubo un problema. Puedes cerrar esta ventana.
  pause
)
