@echo off
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0testes.ps1"
exit /b %ERRORLEVEL%
