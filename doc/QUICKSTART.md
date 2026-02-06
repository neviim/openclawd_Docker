# 🚀 Guia de Início Rápido - Openclawd

## Instalação em 5 Minutos

### 1. Navegar até o projeto
```bash
cd ~/Developer/openclawd_Docker
```

### 2. Inicializar configuração
```bash
./scripts/manage.sh init
```

### 3. Construir as imagens
```bash
./scripts/manage.sh build
```

### 4. Iniciar os serviços
```bash
./scripts/manage.sh start
```

### 5. Acessar o sistema

**Dashboard Kanban:**
- URL: http://localhost:8080
- Monitoramento visual de todas as atividades

**API Openclawd:**
- URL: http://localhost:3000
- Health: http://localhost:3000/health
- Status: http://localhost:3000/status

## 📝 Comandos Essenciais

```bash
# Ver status
./scripts/manage.sh status

# Ver logs
./scripts/manage.sh logs

# Parar serviços
./scripts/manage.sh stop

# Reiniciar serviços
./scripts/manage.sh restart

# Health check
./scripts/manage.sh health

# Criar backup
./scripts/manage.sh backup

# Menu interativo
./scripts/manage.sh menu
```

## 🎯 Testando a API

### Criar uma atividade
```bash
curl -X POST http://localhost:3000/api/activities \
  -H "Content-Type: application/json" \
  -d '{
    "type": "test",
    "description": "Minha primeira atividade",
    "metadata": {"teste": true}
  }'
```

### Listar atividades
```bash
curl http://localhost:3000/api/activities
```

### Processar uma tarefa
```bash
curl -X POST http://localhost:3000/api/process \
  -H "Content-Type: application/json" \
  -d '{
    "task": "test_task",
    "data": {"input": "hello world"}
  }'
```

## 🎨 Dashboard Kanban

Abra http://localhost:8080 no navegador para ver:

- ✅ Todas as atividades organizadas em colunas (Pendente, Em Progresso, Concluído, Falhou)
- ✅ Atualizações em tempo real via WebSocket
- ✅ Estatísticas do sistema
- ✅ Histórico completo de atividades

## 🔧 Solução Rápida de Problemas

### Porta já em uso
```bash
# Parar serviços
./scripts/manage.sh stop

# Editar portas no .env
nano .env

# Reiniciar
./scripts/manage.sh start
```

### Serviço não inicia
```bash
# Ver logs detalhados
./scripts/manage.sh logs <nome-do-servico>

# Exemplo:
./scripts/manage.sh logs openclawd
```

### Limpar e recomeçar
```bash
./scripts/manage.sh clean
./scripts/manage.sh init
./scripts/manage.sh build
./scripts/manage.sh start
```

## 📚 Próximos Passos

1. Leia o [README.md](README.md) completo
2. Configure backup automático
3. Personalize as configurações em `config/`
4. Integre com seus sistemas

## 🆘 Ajuda

Para mais detalhes, consulte:
- README.md - Documentação completa
- ./scripts/manage.sh - Digite sem argumentos para ver todos os comandos

## 🎉 Pronto!

Você agora tem uma instalação completa do Openclawd com:
- ✅ Containerização segura com Docker
- ✅ Monitoramento visual Kanban
- ✅ API REST completa
- ✅ Sistema de logs centralizado
- ✅ Banco de dados PostgreSQL
- ✅ Cache Redis
- ✅ Scripts de gerenciamento

Divirta-se! 🚀
