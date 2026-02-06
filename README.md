# 🚀 Openclawd - Instalação Completa e Segura

Sistema completo de execução do Openclawd em containers Docker com monitoramento Kanban em tempo real.

> **Baseado em [OpenClaw.ai](https://openclaw.ai/)** - Sistema de automação com IA

## 📋 Índice

- [Características](#características)
- [Arquitetura](#arquitetura)
- [Pré-requisitos](#pré-requisitos)
- [Instalação Rápida](#instalação-rápida)
- [Uso](#uso)
- [Configuração](#configuração)
- [Monitoramento](#monitoramento)
- [Segurança](#segurança)
- [Backup e Restauração](#backup-e-restauração)
- [Solução de Problemas](#solução-de-problemas)
- [Documentação Adicional](#documentação-adicional)

## ✨ Características

- **🐳 Containerizado**: Todos os serviços executam em containers Docker isolados
- **🔒 Seguro**: Implementação com best practices de segurança
- **📊 Monitoramento Kanban**: Interface visual para acompanhar todas as atividades em tempo real
- **📝 Logs Centralizados**: Sistema completo de coleta e processamento de logs
- **💾 Persistência**: Banco de dados PostgreSQL para histórico de atividades
- **🔄 Cache Redis**: Sistema de cache para melhor performance
- **🎯 API REST**: Interface completa para integração
- **🔌 WebSocket**: Atualizações em tempo real no dashboard
- **📦 Backup Automático**: Scripts para backup e restauração
- **🛠️ Fácil Gerenciamento**: Script único para todas as operações

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│                    Docker Network                       │
│                                                         │
│  ┌──────────────┐    ┌──────────────┐                   │
│  │  Openclawd   │◄───┤   Kanban     │                   │
│  │     App      │    │   Monitor    │                   │
│  │ (Port 3000)  │    │  (Port 8080) │                   │
│  └──────┬───────┘    └──────┬───────┘                   │
│         │                   │                           │
│         └──────┬────────────┘                           │
│                │                                        │
│         ┌──────▼────────┬──────────────┐                │
│         │               │              │                │
│    ┌────▼─────┐    ┌────▼────┐   ┌─────▼──────┐         │
│    │PostgreSQL│    │ Redis   │   │   Fluent   │         │
│    │          │    │ Cache   │   │    Bit     │         │
│    └──────────┘    └─────────┘   └────────────┘         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Componentes

1. **Openclawd App** (Port 3000)
   - Servidor Node.js/Express
   - API REST completa
   - Sistema de rastreamento de atividades
   - Logging estruturado

2. **Kanban Monitor** (Port 8080)
   - Dashboard web interativo
   - WebSocket para atualizações em tempo real
   - SQLite para persistência local
   - Visualização estilo Kanban

3. **PostgreSQL**
   - Banco de dados principal
   - Histórico de atividades
   - Métricas de sistema
   - Retenção de 30 dias

4. **Redis**
   - Cache de dados
   - Filas de processamento
   - Session storage

5. **Fluent Bit**
   - Coleta de logs
   - Processamento e agregação
   - Export para diferentes destinos

## 🔧 Pré-requisitos

- Docker 20.10+
- Docker Compose 2.0+
- 2GB RAM mínimo
- 10GB espaço em disco
- Linux/macOS/Windows com WSL2

### Verificar instalação:

```bash
docker --version
docker compose --version
```

## 🚀 Instalação Rápida

### 1. Navegar até o diretório do projeto:

```bash
cd ~/Developer/openclawd_Docker
```

### 2. Tornar o script executável:

```bash
chmod +x scripts/manage.sh
```

### 3. Inicializar a configuração:

```bash
./scripts/manage.sh init
```

Este comando irá:
- Criar arquivos de configuração
- Gerar senhas seguras
- Criar diretórios necessários
- Configurar permissões

### 4. Build das imagens:

```bash
./scripts/manage.sh build
```

### 5. Iniciar os serviços:

```bash
./scripts/manage.sh start
```

### 6. Acessar:

- **Openclawd API**: http://localhost:3000
- **Kanban Monitor**: http://localhost:8080

## 📖 Uso

### Script de Gerenciamento

O script `manage.sh` é a ferramenta principal para gerenciar todo o sistema:

```bash
./scripts/manage.sh <comando>
```

#### Comandos Disponíveis:

| Comando | Descrição |
|---------|-----------|
| `init` | Inicializar configuração |
| `build` | Build das imagens Docker |
| `start` | Iniciar todos os serviços |
| `stop` | Parar todos os serviços |
| `restart` | Reiniciar serviços |
| `status` | Ver status dos serviços |
| `logs` | Ver logs (opcional: logs <serviço>) |
| `health` | Health check de todos os serviços |
| `backup` | Criar backup completo |
| `restore` | Restaurar de backup |
| `update` | Atualizar sistema |
| `clean` | Limpar todos os dados |
| `menu` | Menu interativo |

### Exemplos:

```bash
# Ver logs de um serviço específico
./scripts/manage.sh logs openclawd

# Ver logs de todos os serviços
./scripts/manage.sh logs

# Status dos serviços
./scripts/manage.sh status

# Health check
./scripts/manage.sh health

# Menu interativo
./scripts/manage.sh menu
```

### API do Openclawd

#### Endpoints Principais:

**Health Check:**
```bash
curl http://localhost:3000/health
```

**Status da Aplicação:**
```bash
curl http://localhost:3000/status
```

**Listar Atividades:**
```bash
curl http://localhost:3000/api/activities?limit=50
```

**Criar Atividade:**
```bash
curl -X POST http://localhost:3000/api/activities \
  -H "Content-Type: application/json" \
  -d '{
    "type": "custom_task",
    "description": "Minha tarefa personalizada",
    "metadata": {"key": "value"}
  }'
```

**Processar Tarefa:**
```bash
curl -X POST http://localhost:3000/api/process \
  -H "Content-Type: application/json" \
  -d '{
    "task": "process_data",
    "data": {"input": "test"}
  }'
```

### Dashboard Kanban

Acesse http://localhost:8080 para ver:

- **Colunas Kanban**: Pendente, Em Progresso, Concluído, Falhou
- **Atualizações em Tempo Real**: WebSocket para updates instantâneos
- **Estatísticas**: Total de atividades, status, métricas
- **Filtros**: Por status, tipo, período
- **Detalhes**: Click em qualquer atividade para ver detalhes

## ⚙️ Configuração

### Arquivo .env

Criado automaticamente pelo comando `init`. Edite conforme necessário:

```bash
# Ambiente
NODE_ENV=production
LOG_LEVEL=info

# Senhas (geradas automaticamente)
REDIS_PASSWORD=<gerado>

# Portas
OPENCLAUDE_PORT=3000
KANBAN_PORT=8080

# Monitoramento
MONITOR_INTERVAL=5000

# Timezone
TZ=America/Sao_Paulo
```

### Configurações Avançadas

#### Openclawd

Edite `config/openclawd/config.json`:

```json
{
  "maxActivities": 1000,
  "cleanupInterval": 3600000,
  "logRotation": {
    "enabled": true,
    "maxFiles": 10,
    "maxSize": "10m"
  }
}
```

#### Kanban Monitor

Edite `config/kanban/config.json`:

```json
{
  "refreshInterval": 5000,
  "maxActivitiesDisplay": 100,
  "columns": [
    {"name": "Pendente", "color": "#94a3b8"},
    {"name": "Em Progresso", "color": "#3b82f6"},
    {"name": "Concluído", "color": "#22c55e"},
    {"name": "Falhou", "color": "#ef4444"}
  ]
}
```

## 📊 Monitoramento

### Logs

Os logs são armazenados em `logs/`:

- `activity.log` - Todas as atividades
- `error.log` - Apenas erros
- `combined.log` - Log combinado

**Ver logs em tempo real:**
```bash
./scripts/manage.sh logs
```

**Logs de um serviço específico:**
```bash
./scripts/manage.sh logs openclawd
./scripts/manage.sh logs kanban-monitor
```

### Métricas

Acesse as métricas via API:

```bash
# Estatísticas gerais
curl http://localhost:8080/api/stats

# Métricas do sistema (últimas 24h)
curl http://localhost:8080/api/metrics?hours=24

# Dados do Kanban
curl http://localhost:8080/api/kanban
```

### Health Checks

Todos os serviços possuem health checks:

```bash
# Via script
./scripts/manage.sh health

# Manualmente
curl http://localhost:3000/health
curl http://localhost:8080/health
```

## 🔒 Segurança

### Medidas Implementadas:

1. **Containers Isolados**
   - Rede Docker privada
   - Sem comunicação externa desnecessária

2. **Usuários Não-Root**
   - Todos os containers executam como usuário não privilegiado
   - UIDs únicos para cada serviço

3. **Capabilities Limitadas**
   - Drop ALL capabilities por padrão
   - Apenas NET_BIND_SERVICE onde necessário

4. **Read-Only Filesystems**
   - Containers principais com filesystem read-only
   - tmpfs para arquivos temporários

5. **Secrets Management**
   - Senhas armazenadas em arquivos secretos
   - Não commitadas no git
   - Geradas automaticamente

6. **Security Headers**
   - Helmet.js para headers de segurança
   - CORS configurado
   - Rate limiting

7. **Atualizações**
   - Imagens base Alpine Linux (mínimas)
   - Atualizações regulares recomendadas

### Hardening Adicional:

```bash
# Scan de vulnerabilidades
docker scan openclawd-app:latest

# Audit de segurança
docker compose exec openclawd npm audit

# Verificar permissões
ls -la data/ config/
```

## 💾 Backup e Restauração

### Criar Backup

```bash
./scripts/manage.sh backup
```

Cria um arquivo `backups/YYYYMMDD_HHMMSS.tar.gz` contendo:
- Dados de todos os serviços
- Configurações
- Arquivo .env

### Restaurar Backup

```bash
./scripts/manage.sh restore backups/20240206_143022.tar.gz
```

⚠️ **ATENÇÃO**: Isso irá sobrescrever todos os dados atuais!

### Backup Automatizado

Configure um cron job para backups automáticos:

```bash
# Editar crontab
crontab -e

# Adicionar (backup diário às 2AM)
0 2 * * * /home/neviim/Developer/openclawd_Docker/scripts/manage.sh backup
```

### Retenção de Backups

```bash
# Manter apenas últimos 7 backups
cd ~/Developer/openclawd_Docker/backups
ls -t | tail -n +8 | xargs rm -f
```

## 🔧 Solução de Problemas

### Serviço não inicia

```bash
# Ver logs detalhados
./scripts/manage.sh logs <serviço>

# Verificar status
docker compose ps

# Reiniciar serviço específico
docker compose restart <serviço>
```

### Erro de conexão entre serviços

```bash
# Verificar rede
docker network inspect openclawd_Docker_openclawd-network

# Testar conectividade
docker compose exec openclawd ping kanban-monitor
```

### Disco cheio

```bash
# Limpar dados antigos
./scripts/manage.sh clean

# Limpar imagens não utilizadas
docker system prune -a

# Verificar uso de disco
docker system df
```

### Performance lenta

```bash
# Verificar recursos
docker stats

# Aumentar recursos no docker-compose.yml
services:
  openclawd:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
```

### Kanban Monitor não atualiza

1. Verificar se Openclawd está respondendo:
```bash
curl http://localhost:3000/health
```

2. Verificar WebSocket no navegador (F12 Console)

3. Reiniciar ambos os serviços:
```bash
./scripts/manage.sh restart
```

### Logs crescendo demais

```bash
# Configurar rotação de logs no docker-compose.yml
services:
  openclawd:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## 🛠️ Desenvolvimento

### Modo de Desenvolvimento

```bash
# Iniciar em modo dev com hot reload
docker compose -f docker-compose.yml -f docker-compose.dev.yml up
```

### Executar Testes

```bash
# Openclawd
docker compose exec openclawd npm test

# Kanban Monitor
docker compose exec kanban-monitor npm test
```

### Adicionar Novos Serviços

1. Adicionar ao `docker-compose.yml`
2. Criar Dockerfile se necessário
3. Atualizar documentação
4. Testar integração

## 📚 Recursos Adicionais

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [OWASP Security](https://owasp.org/)

## 📝 Licença

MIT License - veja LICENSE para detalhes.

## 👥 Suporte

Para problemas ou dúvidas:
1. Verificar esta documentação
2. Consultar logs: `./scripts/manage.sh logs`
3. Executar health check: `./scripts/manage.sh health`

## 🎯 Próximos Passos

Após a instalação, você pode:

1. ✅ Acessar o Dashboard Kanban em http://localhost:8080
2. ✅ Testar a API em http://localhost:3000
3. ✅ Configurar backup automático
4. ✅ Personalizar as colunas do Kanban
5. ✅ Integrar com seus sistemas existentes
6. ✅ Monitorar as atividades em tempo real

## 🚀 Quick Start

```bash
cd ~/Developer/openclawd_Docker
chmod +x scripts/manage.sh
./scripts/manage.sh init
./scripts/manage.sh build
./scripts/manage.sh start
```

Acesse: http://localhost:8080

Pronto! 🎉

## 📚 Documentação Adicional

Toda a documentação complementar está organizada na pasta `doc/`:

- **[doc/QUICKSTART.md](doc/QUICKSTART.md)** - Guia de início rápido em 5 minutos
- **[doc/REMOTE-ACCESS.md](doc/REMOTE-ACCESS.md)** - Guia completo de acesso remoto
- **[doc/ACESSO-REMOTO-RAPIDO.md](doc/ACESSO-REMOTO-RAPIDO.md)** - Acesso remoto em 3 passos
- **[doc/WATCHTOWER.md](doc/WATCHTOWER.md)** - Guia completo do Watchtower
- **[doc/TESTING.md](doc/TESTING.md)** - Guia de testes da instalação
- **[doc/IMPLEMENTATION-SUMMARY.md](doc/IMPLEMENTATION-SUMMARY.md)** - Resumo completo da implementação
- **[examples/README.md](examples/README.md)** - Exemplos de uso da API
