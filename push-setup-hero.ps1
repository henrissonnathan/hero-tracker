Set-Location $PSScriptRoot

# Remove locks do git se existirem
foreach ($lock in @(".git\index.lock", ".git\HEAD.lock", ".git\config.lock")) {
    if (Test-Path $lock) { Remove-Item $lock -Force; Write-Host "Lock removido: $lock" -ForegroundColor Gray }
}

Write-Host ""
Write-Host "=== Hero Tracker — Setup Git + Push para GitHub ===" -ForegroundColor Cyan

# Token do arquivo no novel-reader (mesmo token)
$tokenFile = "..\novel-reader\.github_token"
if (-not (Test-Path $tokenFile)) {
    $tokenFile = ".github_token"
}
if (-not (Test-Path $tokenFile)) {
    Write-Host "ERRO: arquivo .github_token nao encontrado." -ForegroundColor Red
    Write-Host "Coloque o token em D:\project\novel-reader\.github_token ou D:\project\hero-tracker\.github_token" -ForegroundColor Yellow
    Read-Host "Pressione Enter para fechar"
    exit 1
}
$token = (Get-Content $tokenFile -Raw).Trim()

$owner   = "henrissonnathan"
$repo    = "hero-tracker"
$headers = @{
    Authorization          = "Bearer $token"
    Accept                 = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
    "User-Agent"           = "$owner-$repo-push-script"
}

# Verifica se repositorio ja existe
$repoExists = $false
try {
    $repoInfo = Invoke-RestMethod `
        -Uri "https://api.github.com/repos/$owner/$repo" `
        -Headers $headers -ErrorAction Stop
    $repoExists = $true
    Write-Host "Repositorio ja existe: $($repoInfo.html_url)" -ForegroundColor Gray
} catch {
    Write-Host "Repositorio nao encontrado — criando..." -ForegroundColor Yellow
}

if (-not $repoExists) {
    $payload = @{
        name        = $repo
        description = "Tracker de herois/personagens para RPG e web novels"
        private     = $false
        auto_init   = $false
    } | ConvertTo-Json

    try {
        $created = Invoke-RestMethod `
            -Uri "https://api.github.com/user/repos" `
            -Method POST -Headers $headers `
            -Body $payload -ContentType "application/json"
        Write-Host "Repositorio criado: $($created.html_url)" -ForegroundColor Green
    } catch {
        Write-Host "Erro ao criar repositorio: $_" -ForegroundColor Red
        Read-Host "Pressione Enter para fechar"
        exit 1
    }
}

# Configura remote e faz push
$remoteUrl = "https://${owner}:${token}@github.com/${owner}/${repo}.git"

# Adiciona ou atualiza origin
$existingRemote = & git remote 2>$null
if ($existingRemote -match "origin") {
    git remote set-url origin $remoteUrl
} else {
    git remote add origin $remoteUrl
}

Write-Host "Enviando para GitHub..." -ForegroundColor Yellow
git push -u origin master
if ($LASTEXITCODE -ne 0) {
    Write-Host "Push falhou! Verifique o token e a conexao." -ForegroundColor Red
    Read-Host "Pressione Enter para fechar"
    exit 1
}

Write-Host ""
Write-Host "=== Pronto! Hero Tracker enviado para GitHub. ===" -ForegroundColor Green
Write-Host "https://github.com/$owner/$repo" -ForegroundColor Cyan
Write-Host ""
Read-Host "Pressione Enter para fechar"
