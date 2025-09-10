# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-09-10

### Adicionado
- ✅ Sistema de cache configurável para validação de tokens
- ✅ Timeout configurável para requisições HTTP (1-300 segundos)
- ✅ Opção de SSL verification configurável
- ✅ Retry automático para requisições falhadas (até 2 tentativas)
- ✅ Suporte a múltiplos escopos obrigatórios separados por vírgula
- ✅ Logging estruturado com níveis configuráveis (debug, info, warn, error)
- ✅ Sistema de métricas integrado para monitoramento
- ✅ Headers de contexto para serviços downstream:
  - `X-Authenticated-User`: Username ou subject do token
  - `X-Authenticated-Client`: Client ID que validou o token
  - `X-User-Scopes`: Escopos disponíveis no token
- ✅ Códigos de erro padronizados e estruturados
- ✅ Documentação completa com exemplos práticos

### Alterado
- 🔄 Tratamento de erros melhorado com códigos específicos
- 🔄 Resposta de erro estruturada em formato JSON
- 🔄 Performance otimizada com cache e retry logic
- 🔄 Campo `scope` renomeado para `scopes` para melhor clareza
- 🔄 Logs mais informativos com dados estruturados
- 🔄 Validação de entrada mais robusta

### Melhorado
- 🚀 Performance geral com cache inteligente
- 🚀 Confiabilidade com retry automático
- 🚀 Observabilidade com métricas e logs estruturados
- 🚀 Segurança com validação de SSL opcional
- 🚀 Usabilidade com headers de contexto
- 🚀 Manutenibilidade com código mais estruturado

### Configurações Adicionais
```json
{
  "timeout": 10,           // Novo: timeout configurável
  "ssl_verify": false,     // Novo: verificação SSL opcional
  "cache_ttl": 300,        // Novo: TTL do cache em segundos
  "enable_metrics": true,  // Novo: habilitar métricas
  "log_level": "info",     // Novo: nível de log configurável
  "scopes": "read,write"   // Alterado: múltiplos escopos
}
```

### Métricas Disponíveis
- `rhsso_requests_total`: Total de requisições processadas
- `rhsso_successful_validations_total`: Validações bem-sucedidas
- `rhsso_errors_total`: Erros por tipo e código
- `rhsso_processing_time_seconds`: Tempo de processamento

### Compatibilidade
- ✅ Totalmente compatível com versões anteriores
- ✅ Kong 3.x+ suportado
- ✅ Configurações antigas continuam funcionando

## [0.1.5] - 2025-09-09

### Inicial
- Implementação básica do plugin Kong RHSSO
- Validação de tokens via endpoint de introspecção
- Suporte a múltiplos clientes e realms
- Validação básica de escopo único
- Configuração via schema básico
