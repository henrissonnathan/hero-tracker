param([string]$Message)

Set-Location $PSScriptRoot

# Gate de qualidade (Fase 1): nada de commit com analyze/teste quebrado.
& PowerShell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\testes.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "TESTAR falhou - commit abortado." -ForegroundColor Red
    Read-Host "Pressione Enter para fechar"
    exit 1
}

Write-Host ""
Write-Host "=== Hero Tracker — Commit + Push ===" -ForegroundColor Cyan

# Configura user se não estiver configurado
$email = (git config user.email 2>$null).Trim()
if ([string]::IsNullOrWhiteSpace($email)) {
    git config user.email "henrisson2000@gmail.com"
    git config user.name "Henrisson"
    Write-Host "User configurado." -ForegroundColor Gray
}

# Remove locks residuais
foreach ($lock in @(".git\index.lock", ".git\HEAD.lock", ".git\config.lock")) {
    if (Test-Path $lock) { Remove-Item $lock -Force; Write-Host "Lock removido: $lock" -ForegroundColor Gray }
}

# Token
$tokenFile = "..\novel-reader\.github_token"
if (-not (Test-Path $tokenFile)) { $tokenFile = ".github_token" }
$token = ""
if (Test-Path $tokenFile) { $token = (Get-Content $tokenFile -Raw).Trim() }

# Adiciona TODOS os arquivos versionaveis (build/ e .dart_tool/ ja no .gitignore)
Write-Host "Adicionando arquivos..." -ForegroundColor Yellow
git add -A

# Nada staged? nada a commitar (olha o INDEX, nao a arvore)
git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "Nada para commitar — ja esta atualizado." -ForegroundColor Green
} else {
    # Mensagem: parametro -Message, senao pergunta.
    if ([string]::IsNullOrWhiteSpace($Message)) {
        $Message = Read-Host "Mensagem do commit"
    }
    if ([string]::IsNullOrWhiteSpace($Message)) {
        Write-Host "Sem mensagem — commit cancelado." -ForegroundColor Red
        Read-Host "Pressione Enter para fechar"
        exit 1
    }
    Write-Host "Commitando..." -ForegroundColor Yellow
    git commit -m $Message
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Commit falhou!" -ForegroundColor Red
        Read-Host "Pressione Enter para fechar"
        exit 1
    }
    Write-Host "Commit criado." -ForegroundColor Green
}

# Push
if (-not [string]::IsNullOrWhiteSpace($token)) {
    $owner = "henrissonnathan"
    $repo  = "hero-tracker"
    $remoteUrl = "https://${owner}:${token}@github.com/${owner}/${repo}.git"
    git remote set-url origin $remoteUrl 2>$null
    Write-Host "Enviando para GitHub..." -ForegroundColor Yellow
    git push origin master
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Push falhou." -ForegroundColor Red
        Read-Host "Pressione Enter para fechar"
        exit 1
    }
    Write-Host ""
    Write-Host "=== Pronto! Hero Tracker atualizado no GitHub. ===" -ForegroundColor Green
    Write-Host "https://github.com/$owner/$repo" -ForegroundColor Cyan
} else {
    Write-Host "Token nao encontrado — commit feito localmente, push pendente." -ForegroundColor Yellow
}

Write-Host ""
Read-Host "Pressione Enter para fechar"
