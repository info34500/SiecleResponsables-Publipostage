@echo off
rem Glissez un export CSV de SiecleResponsables sur ce fichier.
rem Le fichier pret pour Mail Merge est cree a cote (suffixe _publipostage).
if "%~1"=="" (
  echo Glissez un fichier CSV exporte par SiecleResponsables sur ce lanceur.
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Preparer-Publipostage.ps1" -Fichier "%~1"
pause
