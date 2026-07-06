# install-phone.ps1 — Instala o APK no celular via ADB
Set-Location $PSScriptRoot

$apk = "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
if (-not (Test-Path $apk)) {
    Write-Host "APK nao encontrado. Rode BUILD_APK.bat primeiro." -ForegroundColor Red
    Read-Host "Enter para fechar"
    exit 1
}

Write-Host "Verificando dispositivo ADB..." -ForegroundColor Yellow
$devices = & adb devices 2>&1 | Select-String "device$"
if (-not $devices) {
    Write-Host "Nenhum dispositivo conectado. Conecte o celular e habilite depuracao USB." -ForegroundColor Red
    Read-Host "Enter para fechar"
    exit 1
}

Write-Host "Instalando APK..." -ForegroundColor Yellow
adb install -r $apk
if ($LASTEXITCODE -eq 0) {
    Write-Host "Instalado com sucesso!" -ForegroundColor Green
} else {
    Write-Host "Erro na instalacao." -ForegroundColor Red
}

Read-Host "Enter para fechar"
