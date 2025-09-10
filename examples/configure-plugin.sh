#!/bin/bash

# Kong RHSSO Plugin Configuration Script
# Usage: ./configure-plugin.sh <service-id>

set -e

SERVICE_ID=${1:-"your-service-id"}
KONG_ADMIN_URL=${KONG_ADMIN_URL:-"http://localhost:8001"}
RHSSO_BASE_URL=${RHSSO_BASE_URL:-"https://keycloak.example.com/auth"}

echo "🚀 Configurando Kong RHSSO Plugin para o serviço: $SERVICE_ID"
echo "📍 Kong Admin URL: $KONG_ADMIN_URL"
echo "🔐 RHSSO Base URL: $RHSSO_BASE_URL"

# Verificar se o serviço existe
echo "🔍 Verificando se o serviço existe..."
SERVICE_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$KONG_ADMIN_URL/services/$SERVICE_ID")

if [ "$SERVICE_CHECK" != "200" ]; then
    echo "❌ Erro: Serviço $SERVICE_ID não encontrado no Kong"
    echo "💡 Dica: Verifique se o service-id está correto e se o Kong está rodando"
    exit 1
fi

echo "✅ Serviço encontrado!"

# Configurar o plugin
echo "⚙️  Configurando o plugin..."

PLUGIN_CONFIG=$(cat << EOF
{
  "name": "kong-rhsso",
  "config": {
    "rhsso_base_url": "$RHSSO_BASE_URL",
    "timeout": 10,
    "ssl_verify": false,
    "cache_ttl": 300,
    "enable_metrics": true,
    "log_level": "info",
    "clients": [
      {
        "client_id": "${CLIENT_ID:-frontend-app}",
        "client_secret": "${CLIENT_SECRET:-your-client-secret}",
        "realm": "${REALM:-master}",
        "scopes": "${SCOPES:-read,write}"
      }
    ]
  }
}
EOF
)

RESPONSE=$(curl -s -X POST "$KONG_ADMIN_URL/services/$SERVICE_ID/plugins" \
  -H "Content-Type: application/json" \
  -d "$PLUGIN_CONFIG")

# Verificar se a configuração foi bem-sucedida
if echo "$RESPONSE" | grep -q '"name":"kong-rhsso"'; then
    echo "✅ Plugin configurado com sucesso!"
    echo "📄 Resposta do Kong:"
    echo "$RESPONSE" | jq '.'
    
    echo ""
    echo "🎉 Configuração concluída!"
    echo "📝 Próximos passos:"
    echo "   1. Teste a autenticação com um token válido"
    echo "   2. Verifique os logs do Kong para debug"
    echo "   3. Configure métricas se necessário"
    echo ""
    echo "🔧 Comandos úteis:"
    echo "   • Listar plugins: curl $KONG_ADMIN_URL/plugins"
    echo "   • Ver logs: docker-compose logs -f kong"
    echo "   • Teste: curl -H 'Authorization: Bearer TOKEN' http://localhost:8000/your-endpoint"
    
else
    echo "❌ Erro ao configurar o plugin:"
    echo "$RESPONSE" | jq '.'
    exit 1
fi
