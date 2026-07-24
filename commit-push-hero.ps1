Set-Location $PSScriptRoot

Write-Host ""
Write-Host "=== Hero Tracker — Commit + Push (tipos de unidade) ===" -ForegroundColor Cyan

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

# Adiciona todos os arquivos modificados
Write-Host "Adicionando arquivos..." -ForegroundColor Yellow
git add lib/models/character_type.dart
git add lib/models/character.dart
git add lib/models/game_group.dart
git add lib/repositories/database_helper.dart
git add lib/ui/game_screen.dart
git add lib/ui/character_screen.dart

# Verifica se há algo para commitar
$status = git status --porcelain
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "Nada para commitar — já está atualizado." -ForegroundColor Green
} else {
    Write-Host "Commitando..." -ForegroundColor Yellow
    git commit -m "feat: tipos de unidade (soldado/heroi/comandante) + config de esquadrao

- Novo enum CharacterType: soldadoNormal, heroi, comandante
- Personagens agora tem tipo de unidade com emoji e cor distintos
- GameGroup: maxHeroesPerSquad e maxCommandersPerSquad configuraveis
- Barra de resumo do esquadrao mostra contagem vs limite, alerta se excedido
- Dialog de criacao/edicao de personagem atualizado com seletor de tipo visual
- Comandantes exibem nota 'nao entra em batalha diretamente'
- Migracao DB v2->v3 para novos campos"
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
