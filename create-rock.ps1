# Script para gerar arquivo .rock manualmente

$pluginName = "kong-plugin-kong-rhsso"
$version = "0.2.0-1"
$rockFile = "$pluginName-$version.src.rock"

Write-Host "Gerando arquivo .rock para $pluginName versao $version"

# Remover arquivo .rock anterior se existir
if (Test-Path $rockFile) {
    Remove-Item $rockFile -Force
}

# Criar diretório temporário
$tempDir = "temp-rock-build"
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Copiar arquivos necessários
Copy-Item "kong" -Destination $tempDir -Recurse
Copy-Item "README.md" -Destination $tempDir
Copy-Item "$pluginName-$version.rockspec" -Destination $tempDir

# Criar arquivo ZIP (rock é um ZIP renomeado)
$zipFile = "$pluginName-$version.zip"
$compress = @{
    Path = "$tempDir\*"
    CompressionLevel = "Optimal"
    DestinationPath = $zipFile
}
Compress-Archive @compress

# Renomear ZIP para .rock
if (Test-Path $zipFile) {
    Move-Item $zipFile $rockFile
}

# Limpar diretório temporário
Remove-Item $tempDir -Recurse -Force

if (Test-Path $rockFile) {
    Write-Host "Arquivo .rock gerado com sucesso: $rockFile"
    $fileInfo = Get-Item $rockFile
    Write-Host "Tamanho: $([math]::Round($fileInfo.Length / 1KB, 2)) KB"
} else {
    Write-Host "Erro ao gerar arquivo .rock"
}
