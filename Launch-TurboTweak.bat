@echo off
:: Final TurboTweak launcher using PowerShell 7 directly

set "psScript=TurboTweakMenu.ps1"
set "psPath=%~dp0%psScript%"
set "pwshExe=%ProgramFiles%\PowerShell\7\pwsh.exe"

:: Direct elevated launch — no hidden nesting
"%pwshExe%" -ExecutionPolicy Bypass -Command "Start-Process '%pwshExe%' -ArgumentList '-ExecutionPolicy','Bypass','-File','\"%psPath%\"' -Verb RunAs"
