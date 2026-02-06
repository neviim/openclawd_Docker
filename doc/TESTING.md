# 🧪 Guia de Testes - Openclawd

Documentação completa dos testes da instalação.

## 📋 Visão Geral

O sistema inclui testes automatizados que verificam:
- ✅ Estrutura de arquivos
- ✅ Dependências do sistema
- ✅ Configurações
- ✅ Serviços em execução
- ✅ APIs funcionais
- ✅ Dashboard Kanban
- ✅ Exemplos de código
- ✅ Documentação

## 🚀 Executar Testes

### Teste Completo

```bash
cd ~/Developer/openclawd_Docker
./scripts/test-installation.sh
```

Este script executa todos os testes e gera um relatório completo.

### Resultado dos Testes

O script mostra:
- **Verde (✓)**: Teste passou
- **Vermelho (✗)**: Teste falhou
- **Amarelo (!)**: Aviso

**Relatório Final:**
```
Testes Executados: X
Testes Aprovados: Y
Testes Falhados: Z
Taxa de Sucesso: XX%
```

### Status de Sucesso

- **100%**: ✅ Instalação perfeita
- **80-99%**: ⚠️ Instalação funcional, alguns problemas menores
- **< 80%**: ❌ Instalação com problemas, requer correção

## 📝 Categorias de Testes

### 1. Estrutura de Arquivos

Verifica se todos os arquivos necessários existem:
- docker-compose.yml
- docker-compose.remote.yml
- Dockerfiles
- Scripts
- Diretórios

### 2. Dependências

Verifica:
- Docker instalado e versão
- Docker Compose instalado e versão
- Permissões do usuário

### 3. Configurações

Verifica arquivos de configuração:
- Nginx
- PostgreSQL
- Fluent Bit
- Watchtower

### 4. Serviços (se rodando)

Testa cada serviço:
- Openclawd App
- Kanban Monitor
- PostgreSQL
- Redis
- Watchtower

### 5. APIs

Testa endpoints:
- GET /health
- GET /status
- GET /api/activities
- POST /api/activities
- POST /api/process

### 6. Dashboard

Verifica:
- Acesso ao dashboard
- API do Kanban
- WebSocket

### 7. Exemplos

Verifica scripts de exemplo:
- test-remote-api.sh
- python_client.py
- nodejs_client.js

### 8. Documentação

Verifica presença de:
- README.md (raiz)
- doc/QUICKSTART.md
- doc/REMOTE-ACCESS.md
- doc/WATCHTOWER.md
- doc/TESTING.md
- doc/IMPLEMENTATION-SUMMARY.md
- doc/ACESSO-REMOTO-RAPIDO.md
- LICENSE

## 🔍 Testes Individuais

### Testar Docker

```bash
docker --version
docker ps
```

### Testar Serviços

```bash
# Via script
./scripts/manage.sh status
./scripts/manage.sh health

# Manual
docker compose ps
docker compose logs openclawd
```

### Testar API

```bash
# Health check
curl http://localhost:3000/health

# Status
curl http://localhost:3000/status

# Listar atividades
curl http://localhost:3000/api/activities

# Criar atividade
curl -X POST http://localhost:3000/api/activities \
  -H "Content-Type: application/json" \
  -d '{"type":"test","description":"Teste"}'
```

### Testar Dashboard

```bash
# Verificar acesso
curl http://localhost:8080/health

# Abrir no navegador
xdg-open http://localhost:8080  # Linux
open http://localhost:8080      # Mac
start http://localhost:8080     # Windows
```

### Testar Watchtower

```bash
./scripts/watchtower-manage.sh status
./scripts/watchtower-manage.sh logs
```

### Testar Acesso Remoto

```bash
# De outra máquina
cd examples
./test-remote-api.sh SEU_IP
```

## 🧩 Testes de Integração

### Fluxo Completo

```bash
# 1. Inicializar
./scripts/manage.sh init

# 2. Build
./scripts/manage.sh build

# 3. Iniciar
./scripts/manage.sh start

# 4. Testar
./scripts/test-installation.sh

# 5. Testar API
./examples/test-remote-api.sh localhost

# 6. Testar Watchtower
./scripts/watchtower-manage.sh status
```

### Teste de Carga (Opcional)

```bash
# Instalar apache bench
sudo apt-get install apache2-utils

# Teste simples
ab -n 1000 -c 10 http://localhost:3000/health

# Teste de API
ab -n 100 -c 5 -p post-data.json -T application/json \
  http://localhost:3000/api/activities
```

### Teste de Stress (Opcional)

```bash
# Usando hey (instalar: go install github.com/rakyll/hey@latest)
hey -n 10000 -c 100 http://localhost:3000/health
```

## 🐛 Debug de Falhas

### Se os testes falharem:

1. **Ver logs detalhados:**
```bash
./scripts/manage.sh logs
```

2. **Verificar serviços específicos:**
```bash
docker compose logs openclawd
docker compose logs kanban-monitor
```

3. **Reiniciar serviços:**
```bash
./scripts/manage.sh restart
```

4. **Limpar e recomeçar:**
```bash
./scripts/manage.sh stop
./scripts/manage.sh clean
./scripts/manage.sh init
./scripts/manage.sh build
./scripts/manage.sh start
```

5. **Executar testes novamente:**
```bash
./scripts/test-installation.sh
```

## 📊 Testes de Performance

### Medir Latência da API

```bash
time curl http://localhost:3000/health
```

### Monitorar Recursos

```bash
# Ver uso de recursos
docker stats

# Ver uso específico
docker stats openclawd-app kanban-monitor
```

### Verificar Tempo de Resposta

```bash
# Instalar wrk (benchmark tool)
sudo apt-get install wrk

# Teste de 30 segundos
wrk -t4 -c100 -d30s http://localhost:3000/health
```

## 🔄 Testes de Atualização

### Testar Watchtower

```bash
# 1. Verificar versão atual
docker images | grep openclawd

# 2. Forçar verificação
./scripts/watchtower-manage.sh update-now

# 3. Ver logs
./scripts/watchtower-manage.sh logs

# 4. Verificar se atualizou
docker images | grep openclawd
```

### Testar Rollback

```bash
# 1. Fazer backup
./scripts/manage.sh backup

# 2. Simular atualização problemática
# (quebrar algo intencionalmente)

# 3. Restaurar
./scripts/manage.sh restore backup-file.tar.gz

# 4. Testar novamente
./scripts/test-installation.sh
```

## 📋 Checklist de Testes

Antes de deploy em produção:

- [ ] Teste de instalação passou (100%)
- [ ] Todos os serviços iniciando corretamente
- [ ] API respondendo em todas as rotas
- [ ] Dashboard Kanban acessível
- [ ] Acesso remoto funcionando (se aplicável)
- [ ] Watchtower configurado e rodando
- [ ] Notificações do Watchtower funcionando (se configuradas)
- [ ] Backup criado e testado restauração
- [ ] Logs sendo gerados corretamente
- [ ] Health checks passando
- [ ] Performance aceitável (< 100ms para /health)
- [ ] Documentação lida e compreendida

## 🎯 Testes Específicos por Cenário

### Desenvolvimento Local

```bash
./scripts/test-installation.sh
./scripts/manage.sh logs
```

### Servidor de Staging

```bash
./scripts/test-installation.sh
./examples/test-remote-api.sh localhost
./scripts/watchtower-manage.sh status
```

### Servidor de Produção

```bash
# Teste completo
./scripts/test-installation.sh

# Health checks
./scripts/manage.sh health

# Monitoramento
./scripts/watchtower-manage.sh status

# Backup
./scripts/manage.sh backup

# Acesso remoto
./examples/test-remote-api.sh SEU_IP

# Performance
wrk -t4 -c100 -d30s http://localhost:3000/health
```

## 📚 Ferramentas de Teste Recomendadas

### API Testing
- **curl**: Testes manuais simples
- **Postman**: Interface gráfica para APIs
- **Insomnia**: Alternativa ao Postman
- **httpie**: curl mais amigável

### Load Testing
- **apache bench (ab)**: Simples e rápido
- **wrk**: Mais avançado
- **hey**: Modern e fácil
- **k6**: Scripts em JavaScript

### Monitoring
- **docker stats**: Uso de recursos
- **ctop**: top para containers
- **lazydocker**: TUI para Docker
- **portainer**: Interface web

## 🆘 Troubleshooting

### Teste falha: "Docker não está instalado"

```bash
# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

### Teste falha: "Permissão negada"

```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Teste falha: "Container não está rodando"

```bash
./scripts/manage.sh start
sleep 10
./scripts/test-installation.sh
```

### Teste falha: "API não responde"

```bash
# Verificar se está rodando
docker ps | grep openclawd

# Ver logs
docker logs openclawd-app

# Reiniciar
docker compose restart openclawd
```

## 🎉 Conclusão

Os testes garantem que sua instalação do Openclawd está funcionando perfeitamente!

**Execução rápida:**

```bash
# Tudo em um comando
cd ~/Developer/openclawd_Docker && ./scripts/test-installation.sh
```

Se todos os testes passarem, você está pronto para usar o Openclawd! 🚀
