# Kong RHSSO Plugin Configuration Script for PowerShell
# Usage: .\configure-plugin.ps1 -ServiceId "your-service-id"

param(
    [Parameter(Mandatory=$true)]
    [string]$ServiceId,
    
    [string]$KongAdminUrl = "http://localhost:8001",
    [string]$RhssoBaseUrl = "https://keycloak.example.com/auth",
    [string]$ClientId = "frontend-app",
    [string]$ClientSecret = "your-client-secret",
    [string]$Realm = "master",
    [string]$Scopes = "read,write"
)

Write-Host "🚀 Configurando Kong RHSSO Plugin para o serviço: $ServiceId" -ForegroundColor Green
Write-Host "📍 Kong Admin URL: $KongAdminUrl" -ForegroundColor Cyan
Write-Host "🔐 RHSSO Base URL: $RhssoBaseUrl" -ForegroundColor Cyan

# Verificar se o serviço existe
Write-Host "🔍 Verificando se o serviço existe..." -ForegroundColor Yellow

try {
    $serviceCheck = Invoke-RestMethod -Uri "$KongAdminUrl/services/$ServiceId" -Method Get -ErrorAction Stop
    Write-Host "✅ Serviço encontrado!" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro: Serviço $ServiceId não encontrado no Kong" -ForegroundColor Red
    Write-Host "💡 Dica: Verifique se o service-id está correto e se o Kong está rodando" -ForegroundColor Yellow
    exit 1
}

# Configurar o plugin
Write-Host "⚙️  Configurando o plugin..." -ForegroundColor Yellow

$pluginConfig = @{
    name = "kong-rhsso"
    config = @{
        rhsso_base_url = $RhssoBaseUrl
        timeout = 10
        ssl_verify = $false
        cache_ttl = 300
        enable_metrics = $true
        log_level = "info"
        clients = @(
            @{
                client_id = $ClientId
                client_secret = $ClientSecret
                realm = $Realm
                scopes = $Scopes
            }
        )
    }
}

$jsonConfig = $pluginConfig | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "$KongAdminUrl/services/$ServiceId/plugins" `
                                  -Method Post `
                                  -Body $jsonConfig `
                                  -ContentType "application/json" `
                                  -ErrorAction Stop
    
    Write-Host "✅ Plugin configurado com sucesso!" -ForegroundColor Green
    Write-Host "📄 Resposta do Kong:" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 10 | Write-Host
    
    Write-Host ""
    Write-Host "🎉 Configuração concluída!" -ForegroundColor Green
    Write-Host "📝 Próximos passos:" -ForegroundColor Yellow
    Write-Host "   1. Teste a autenticação com um token válido"
    Write-Host "   2. Verifique os logs do Kong para debug"
    Write-Host "   3. Configure métricas se necessário"
    Write-Host ""
    Write-Host "🔧 Comandos úteis:" -ForegroundColor Yellow
    Write-Host "   • Listar plugins: Invoke-RestMethod $KongAdminUrl/plugins"
    Write-Host "   • Ver logs: docker-compose logs -f kong"
    Write-Host "   • Teste: Invoke-RestMethod -Uri 'http://localhost:8000/your-endpoint' -Headers @{'Authorization'='Bearer TOKEN'}"
    
} catch {
    Write-Host "❌ Erro ao configurar o plugin:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.Exception.Response) {
        $responseBody = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($responseBody)
        $responseText = $reader.ReadToEnd()
        Write-Host "Resposta do servidor: $responseText" -ForegroundColor Red
    }
    exit 1
}
