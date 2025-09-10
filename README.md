
# Kong RHSSO Plugin

Plugin Kong para autenticação via Red Hat Single Sign-On (Keycloak) com suporte a múltiplos clientes, validação de escopos, cache e métricas.

## Funcionalidades

- ✅ Validação de tokens JWT via endpoint de introspecção do RHSSO/Keycloak
- ✅ Suporte a múltiplos realms e clientes
- ✅ Validação de escopos obrigatórios (múltiplos escopos suportados)
- ✅ Cache configurável para melhor performance
- ✅ Timeout configurável para requisições HTTP
- ✅ SSL verification opcional
- ✅ Retry automático para requisições falhadas
- ✅ Logging estruturado e métricas integradas
- ✅ Headers de contexto para serviços downstream

## Configuração

### Esquema de Configuração

```json
{
  "rhsso_base_url": "https://keycloak.example.com/auth",
  "timeout": 10,
  "ssl_verify": false,
  "cache_ttl": 300,
  "enable_metrics": true,
  "log_level": "info",
  "clients": [
    {
      "client_id": "your-client-id",
      "client_secret": "your-client-secret", 
      "realm": "your-realm",
      "scopes": "read,write,admin"
    }
  ]
}
```

### Parâmetros de Configuração

| Parâmetro | Tipo | Obrigatório | Padrão | Descrição |
|-----------|------|-------------|--------|-----------|
| `rhsso_base_url` | string | Sim | - | URL base do RHSSO/Keycloak |
| `timeout` | number | Não | 10 | Timeout para requisições em segundos (1-300) |
| `ssl_verify` | boolean | Não | false | Verificar certificados SSL |
| `cache_ttl` | number | Não | 300 | TTL do cache em segundos (0 para desabilitar) |
| `enable_metrics` | boolean | Não | true | Habilitar coleta de métricas |
| `log_level` | string | Não | info | Nível de log (debug, info, warn, error) |
| `clients` | array | Sim | - | Lista de clientes configurados |

### Configuração de Clientes

| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `client_id` | string | Sim | ID do cliente no RHSSO |
| `client_secret` | string | Sim | Secret do cliente (criptografado) |
| `realm` | string | Sim | Nome do realm |
| `scopes` | string | Não | Escopos obrigatórios separados por vírgula |

## Instalação e Configuração

### Para subir um Kong local

```bash
docker-compose up -d
```

### Adicionar o plugin via API REST do Kong

```bash
curl -X POST http://localhost:8001/services/{service-id}/plugins \
  -H "Content-Type: application/json" \
  -d '{
    "name": "kong-rhsso",
    "config": {
      "rhsso_base_url": "https://keycloak.example.com/auth",
      "timeout": 10,
      "ssl_verify": false,
      "cache_ttl": 300,
      "enable_metrics": true,
      "log_level": "info",
      "clients": [
        {
          "client_id": "frontend-app",
          "client_secret": "your-client-secret",
          "realm": "master",
          "scopes": "read,write"
        },
        {
          "client_id": "backend-service", 
          "client_secret": "another-secret",
          "realm": "services",
          "scopes": "admin"
        }
      ]
    }
  }'
```

### Configuração Avançada

#### Cache Configuration
```json
{
  "cache_ttl": 600,  // Cache por 10 minutos
  // ou
  "cache_ttl": 0     // Desabilitar cache
}
```

#### Multiple Scopes
```json
{
  "scopes": "read,write,admin"  // Todos os escopos são obrigatórios
}
```

#### SSL e Timeout
```json
{
  "ssl_verify": true,
  "timeout": 30      // 30 segundos de timeout
}
```

## Headers Adicionados

O plugin adiciona os seguintes headers para serviços downstream:

- `X-Authenticated-User`: Username ou subject do token
- `X-Authenticated-Client`: Client ID que validou o token
- `X-User-Scopes`: Escopos disponíveis no token

## Códigos de Erro

| Código | Descrição |
|--------|-----------|
| COD-01 | Token inválido ou expirado |
| COD-02 | Acesso não autorizado - escopo insuficiente |
| COD-03 | Falha ao validar o token |
| COD-04 | Formato do token inválido |
| COD-05 | Token é obrigatório |
| COD-06 | Erro de rede |
| COD-07 | Resposta inválida do servidor |

## Métricas

O plugin coleta as seguintes métricas (quando `enable_metrics: true`):

- `rhsso_requests_total`: Total de requisições processadas
- `rhsso_successful_validations_total`: Validações bem-sucedidas
- `rhsso_errors_total`: Total de erros por tipo
- `rhsso_processing_time_seconds`: Tempo de processamento

## Uso da API

### Exemplo de requisição autenticada

```bash
curl -H "Authorization: Bearer your-jwt-token" \
     http://localhost:8000/your-protected-endpoint
```

### Listar plugins habilitados

```bash
curl localhost:8001/plugins/enabled | jq
```

### Verificar configuração do plugin

```bash
curl localhost:8001/services/{service-id}/plugins | jq '.data[] | select(.name=="kong-rhsso")'
```

## Desenvolvimento

### Estrutura do Projeto

```
kong-rhsso/
├── kong/
│   └── plugins/
│       └── kong-rhsso/
│           ├── handler.lua     # Lógica principal do plugin
│           └── schema.lua      # Esquema de configuração
├── docker-compose.yml         # Ambiente de desenvolvimento
├── kong-plugin-kong-rhsso-*.rockspec  # Especificação LuaRocks
└── README.md
```

### Build e Deploy

```bash
# Build do rockspec
luarocks make kong-plugin-kong-rhsso-0.2.0-1.rockspec

# Upload para repositório (se configurado)
luarocks upload kong-plugin-kong-rhsso-0.2.0-1.rockspec
```

## Troubleshooting

### Logs Estruturados

O plugin gera logs estruturados em formato JSON para facilitar análise:

```bash
# Ver logs do Kong
docker-compose logs -f kong

# Filtrar logs do plugin
docker-compose logs kong | grep "kong-rhsso"
```

### Problemas Comuns

1. **Token não é aceito**: Verifique se o client_id/secret estão corretos
2. **Erro de SSL**: Configure `ssl_verify: false` para desenvolvimento
3. **Timeout**: Aumente o valor de `timeout` se a rede for lenta
4. **Cache issues**: Defina `cache_ttl: 0` para desabilitar durante debug

## Contribuição

Para contribuir com o projeto:

1. Fork o repositório
2. Crie uma branch para sua feature
3. Implemente testes
4. Submeta um Pull Request

## Licença

MIT License - veja arquivo LICENSE para detalhes.

## Contato

Para dúvidas ou suporte: pedrofarbo@gmail.com

---

**Versão**: 0.2.0  
**Compatibilidade**: Kong 3.x+  
**Status**: Production Ready
