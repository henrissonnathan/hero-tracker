# build-apk.ps1 — Compila o APK release do Hero Tracker
Set-Location $PSScriptRoot

# Adiciona Flutter e Java ao PATH
$env:JAVA_HOME = 'C:\Users\henri\AppData\Local\Programs\jdk-21.0.11+10'
$env:PATH = "C:\flutter\bin;$env:JAVA_HOME\bin;$env:PATH"

$version = (Select-String -Path "pubspec.yaml" -Pattern "^version:\s*(.+)").Matches[0].Groups[1].Value.Trim().Split("+")[0]
Write-Host ""
Write-Host "=== Hero Tracker v$version — Build APK ===" -ForegroundColor Cyan

# Copia local.properties do novel-reader (mesmo SDK)
$localProps = "..\novel-reader\android\local.properties"
if (Test-Path $localProps) {
    Copy-Item $localProps "android\local.properties" -Force
    Write-Host "local.properties copiado de novel-reader." -ForegroundColor Gray
}

Write-Host "Baixando dependências..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Host "pub get falhou." -ForegroundColor Red; exit 1 }

Write-Host "Compilando APK (arm64-v8a)..." -ForegroundColor Yellow
flutter build apk --release --target-platform android-arm64 --split-per-abi
if ($LASTEXITCODE -ne 0) { Write-Host "Build falhou." -ForegroundColor Red; exit 1 }

$apk = "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
if (Test-Path $apk) {
    $sizeMB = [math]::Round((Get-Item $apk).Length / 1MB, 1)
    Write-Host ""
    Write-Host "=== BUILD CONCLUIDO ===" -ForegroundColor Green
    Write-Host "APK: $apk ($sizeMB MB)" -ForegroundColor Cyan
} else {
    Write-Host "APK nao encontrado." -ForegroundColor Red
}

Read-Host "Pressione Enter para fechar"
