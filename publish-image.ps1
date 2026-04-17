# 1. Perguntar os dados ao usuário
Write-Host "--- Publicador do Chatwoot Modificado ---" -ForegroundColor Cyan
$version = Read-Host "Digite a versão da imagem (ex: 1.0.0)"
$username = Read-Host "Digite o seu nome de usuário do Docker Hub (ex: arman)"

# Validar entradas
if (-not $version -or -not $username) {
    Write-Host "Erro: Versão e usuário são obrigatórios!" -ForegroundColor Red
    exit
}

# Montar o caminho completo
$dockerRepo = "$username/chatwoot-white-label"
$imageFull = "${dockerRepo}:$version"
$imageLatest = "${dockerRepo}:latest"

# 2. Iniciar o Build
Write-Host "`n--- Iniciando Build da imagem: $imageFull ---" -ForegroundColor Cyan
docker build -f docker/Dockerfile -t $imageFull .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro no build da imagem. Abortando operação." -ForegroundColor Red
    exit
}

# 3. Criar a Tag 'latest'
Write-Host "`n--- Criando tag 'latest' ---" -ForegroundColor Cyan
docker tag $imageFull $imageLatest

# 4. Fazer o Push
Write-Host "`n--- Fazendo Push para o Docker Hub ---" -ForegroundColor Yellow
Write-Host "Certifique-se de estar logado: 'docker login'`n" -ForegroundColor Gray

docker push $imageFull
if ($LASTEXITCODE -eq 0) {
    docker push $imageLatest
    Write-Host "`nSucesso! Imagens publicadas: $imageFull e $imageLatest" -ForegroundColor Green
} else {
    Write-Host "Erro ao fazer push. Verifique seu login no Docker Hub." -ForegroundColor Red
}
