@echo off
setlocal
set PROJ=%~dp0
if "%PROJ:~-1%"=="\" set PROJ=%PROJ:~0,-1%

set JAVA_HOME=C:\Users\henri\AppData\Local\Programs\jdk-21.0.11+10
set PATH=C:\flutter\bin;%JAVA_HOME%\bin;%PATH%
set APK=%PROJ%\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk

:: Procura ADB
set ADB=
if exist "C:\Users\henri\AppData\Local\Android\Sdk\platform-tools\adb.exe" (
    set ADB=C:\Users\henri\AppData\Local\Android\Sdk\platform-tools\adb.exe
)
if "%ADB%"=="" (
    for /f "delims=" %%A in ('where adb 2^>nul') do set ADB=%%A
)

echo.
echo === Hero Tracker - BUILD + INSTALAR ===
echo.

cd /d "%PROJ%"

echo [1/3] pub get...
call flutter pub get
if %ERRORLEVEL% neq 0 ( echo FALHOU. & pause & exit /b 1 )

echo [2/3] Compilando APK release...
call flutter build apk --release --target-platform android-arm64 --split-per-abi
if %ERRORLEVEL% neq 0 ( echo BUILD FALHOU. & pause & exit /b 1 )

if not exist "%APK%" (
    echo APK nao encontrado: %APK%
    pause & exit /b 1
)

echo Build OK!

if "%ADB%"=="" (
    echo ADB nao encontrado - instale manualmente: %APK%
    pause & exit /b 0
)

echo [3/3] Instalando no celular...
"%ADB%" devices
"%ADB%" install -r "%APK%"
if %ERRORLEVEL% neq 0 ( echo INSTALACAO FALHOU. & pause & exit /b 1 )

echo.
echo === Hero Tracker instalado com sucesso! ===
pause
endlocal
