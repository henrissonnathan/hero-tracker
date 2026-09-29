# Gate de qualidade do Hero Tracker (Fase 1 do roadmap)
# Roda análise estática + suite de testes. Qualquer falha => exit != 0.
# Uso: .\TESTAR.bat  (ou powershell -File testes.ps1)
Set-Location $PSScriptRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    $env:PATH = "C:\flutter\bin;$env:PATH"
}

Write-Host ""
Write-Host "=== Hero Tracker - TESTAR (analyze + test) ===" -ForegroundColor Cyan

Write-Host "[1/2] flutter analyze --fatal-infos..." -ForegroundColor Yellow
flutter analyze --fatal-infos
if ($LASTEXITCODE -ne 0) {
    Write-Host "ANALYZE FALHOU - corrija antes de commitar." -ForegroundColor Red
    exit 1
}

Write-Host "[2/2] flutter test..." -ForegroundColor Yellow
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Host "TESTES FALHARAM - corrija antes de commitar." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== TUDO VERDE - pode commitar. ===" -ForegroundColor Green
exit 0
