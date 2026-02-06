# 📚 Exemplos de Uso - Openclawd API

Esta pasta contém exemplos práticos de como usar a API Openclawd de diferentes linguagens e ferramentas.

## 🎯 Exemplos Disponíveis

### 1. Script de Teste Bash (`test-remote-api.sh`)

Testa todas as funcionalidades da API usando curl.

**Uso:**
```bash
# Testar servidor local
./test-remote-api.sh localhost

# Testar servidor remoto
./test-remote-api.sh 192.168.1.100

# Com autenticação
# Edite o script e adicione as credenciais
```

**O que testa:**
- ✓ Health check
- ✓ Status do sistema
- ✓ Listar atividades
- ✓ Criar atividade
- ✓ Processar tarefa
- ✓ Acessar dashboard

### 2. Cliente Python (`python_client.py`)

Cliente completo em Python com todas as funcionalidades.

**Requisitos:**
```bash
pip install requests
```

**Uso:**
```bash
# Testar servidor local
python3 python_client.py localhost

# Testar servidor remoto
python3 python_client.py 192.168.1.100

# Com autenticação (edite o arquivo)
# Descomente as linhas:
# username = "admin"
# password = "senha"
```

**Exemplo de integração:**
```python
from python_client import OpenclawdClient

# Conectar
client = OpenclawdClient("192.168.1.100")

# Usar
activities = client.list_activities(limit=10)
print(activities)

# Criar atividade
result = client.create_activity(
    "my_task",
    "Minha tarefa personalizada",
    metadata={"key": "value"}
)
```

### 3. Cliente Node.js (`nodejs_client.js`)

Cliente JavaScript para Node.js.

**Uso:**
```bash
# Testar servidor local
node nodejs_client.js localhost

# Testar servidor remoto
node nodejs_client.js 192.168.1.100

# Com autenticação (edite o arquivo)
# Descomente a linha:
# const client = new OpenclawdClient(server, 'admin', 'senha');
```

**Exemplo de integração:**
```javascript
const OpenclawdClient = require('./nodejs_client');

// Conectar
const client = new OpenclawdClient('192.168.1.100');

// Usar (async/await)
async function run() {
    const activities = await client.listActivities(10);
    console.log(activities);

    // Criar atividade
    const result = await client.createActivity(
        'my_task',
        'Minha tarefa personalizada',
        { key: 'value' }
    );
    console.log(result);
}

run();
```

## 🔧 Configuração

### Servidor Local

Se estiver testando localmente:
```bash
SERVER="localhost"
```

### Servidor Remoto

Se estiver acessando de outra máquina:
```bash
SERVER="192.168.1.100"  # IP do servidor
# ou
SERVER="meu-servidor.local"  # Hostname
```

### Com Autenticação

Se a autenticação estiver ativada:

**Bash/curl:**
```bash
curl -u usuario:senha http://servidor/api/activities
```

**Python:**
```python
client = OpenclawdClient("servidor", "usuario", "senha")
```

**Node.js:**
```javascript
const client = new OpenclawdClient("servidor", "usuario", "senha");
```

## 📝 Endpoints da API

### GET /health
Verifica se o servidor está saudável.

```bash
curl http://servidor/health
```

**Resposta:**
```json
{
  "status": "healthy",
  "timestamp": "2024-02-06T10:00:00.000Z"
}
```

### GET /status
Obtém status do sistema.

```bash
curl http://servidor/status
```

**Resposta:**
```json
{
  "status": "running",
  "version": "1.0.0",
  "activities": {
    "total": 150,
    "running": 5,
    "completed": 140,
    "failed": 5
  }
}
```

### GET /api/activities
Lista atividades.

```bash
curl http://servidor/api/activities?limit=10&status=completed
```

**Parâmetros:**
- `limit` (opcional): Número máximo de atividades (padrão: 50)
- `status` (opcional): Filtrar por status (pending, running, completed, failed)

**Resposta:**
```json
{
  "success": true,
  "count": 10,
  "activities": [
    {
      "id": "uuid-aqui",
      "type": "task",
      "description": "Descrição da atividade",
      "status": "completed",
      "timestamp": "2024-02-06T10:00:00.000Z",
      "metadata": {}
    }
  ]
}
```

### POST /api/activities
Cria uma nova atividade.

```bash
curl -X POST http://servidor/api/activities \
  -H "Content-Type: application/json" \
  -d '{
    "type": "custom_task",
    "description": "Minha tarefa",
    "metadata": {"key": "value"}
  }'
```

**Body:**
```json
{
  "type": "string (obrigatório)",
  "description": "string (obrigatório)",
  "metadata": "object (opcional)"
}
```

**Resposta:**
```json
{
  "success": true,
  "activity": {
    "id": "uuid-gerado",
    "type": "custom_task",
    "description": "Minha tarefa",
    "status": "pending",
    "timestamp": "2024-02-06T10:00:00.000Z",
    "metadata": {"key": "value"}
  }
}
```

### PATCH /api/activities/:id
Atualiza status de uma atividade.

```bash
curl -X PATCH http://servidor/api/activities/uuid-aqui \
  -H "Content-Type: application/json" \
  -d '{
    "status": "completed",
    "result": {"success": true}
  }'
```

### POST /api/process
Processa uma tarefa.

```bash
curl -X POST http://servidor/api/process \
  -H "Content-Type: application/json" \
  -d '{
    "task": "process_data",
    "data": {"input": "value"}
  }'
```

**Resposta:**
```json
{
  "success": true,
  "result": {
    "taskId": "uuid-gerado",
    "task": "process_data",
    "processed": true,
    "timestamp": "2024-02-06T10:00:00.000Z"
  }
}
```

## 🎨 Exemplos Práticos

### Exemplo 1: Monitorar Atividades

```bash
#!/bin/bash
SERVER="192.168.1.100"

# Loop infinito monitorando
while true; do
    echo "=== $(date) ==="
    curl -s http://$SERVER/api/activities?limit=5 | jq '.activities[] | {type, description, status}'
    sleep 5
done
```

### Exemplo 2: Criar Múltiplas Tarefas

```python
from python_client import OpenclawdClient
import time

client = OpenclawdClient("192.168.1.100")

# Criar 10 tarefas
for i in range(10):
    result = client.create_activity(
        f"batch_task_{i}",
        f"Tarefa em lote número {i+1}",
        metadata={"batch": "test", "index": i}
    )
    print(f"Criada: {result['activity']['id']}")
    time.sleep(1)
```

### Exemplo 3: Integração com Webhook

```javascript
const OpenclawdClient = require('./nodejs_client');
const express = require('express');

const app = express();
const client = new OpenclawdClient('192.168.1.100');

app.use(express.json());

// Webhook recebe dados e cria atividade
app.post('/webhook', async (req, res) => {
    try {
        const result = await client.createActivity(
            'webhook_event',
            `Evento recebido: ${req.body.event}`,
            req.body
        );
        res.json({ success: true, activityId: result.activity.id });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

app.listen(3001, () => {
    console.log('Webhook rodando na porta 3001');
});
```

### Exemplo 4: Dashboard CLI

```python
#!/usr/bin/env python3
from python_client import OpenclawdClient
import time
import os

client = OpenclawdClient("192.168.1.100")

while True:
    os.system('clear')
    print("="*60)
    print("Openclawd Dashboard")
    print("="*60)

    # Status
    status = client.get_status()
    print(f"\nStatus: {status['status']}")

    # Atividades
    activities = client.list_activities(10)
    print(f"\nÚltimas Atividades ({activities['count']}):")

    for act in activities['activities'][:5]:
        status_icon = {
            'pending': '⏳',
            'running': '🔄',
            'completed': '✅',
            'failed': '❌'
        }.get(act['status'], '❓')

        print(f"{status_icon} [{act['type']}] {act['description'][:40]}")

    print("\n" + "="*60)
    time.sleep(5)
```

## 🔐 Segurança

### Usando HTTPS

Se configurou SSL:
```bash
# Bash
curl https://servidor/api/activities

# Python
client = OpenclawdClient("servidor")
client.base_url = "https://servidor"

# Node.js
const client = new OpenclawdClient("servidor");
client.baseUrl = "https://servidor";
```

### Ignorar Certificado Auto-assinado (Desenvolvimento)

**Bash:**
```bash
curl -k https://servidor/api/activities
```

**Python:**
```python
import requests
requests.get("https://servidor/api/activities", verify=False)
```

**Node.js:**
```javascript
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
```

## 📊 Monitoramento

### Script de Monitoramento Contínuo

```bash
#!/bin/bash
SERVER="192.168.1.100"
LOG_FILE="monitor.log"

echo "Iniciando monitoramento de $SERVER..."

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    # Health check
    if curl -sf http://$SERVER/health > /dev/null; then
        STATUS="OK"
    else
        STATUS="DOWN"
    fi

    # Obter métricas
    METRICS=$(curl -s http://$SERVER/status | jq -r '.activities.total')

    # Log
    echo "$TIMESTAMP | Status: $STATUS | Activities: $METRICS" | tee -a $LOG_FILE

    sleep 10
done
```

## 🆘 Solução de Problemas

### Connection Refused
```bash
# Verificar se servidor está rodando
curl http://servidor/health

# Se não funcionar, verificar firewall
ping servidor
```

### 401 Unauthorized
```bash
# Autenticação está ativada, use credenciais
curl -u usuario:senha http://servidor/api/activities
```

### CORS Error (Browser)
```bash
# Configure CORS no servidor
./scripts/remote-access.sh configure-cors
```

## 📚 Recursos

- [README Principal](../README.md)
- [Guia de Acesso Remoto](../doc/REMOTE-ACCESS.md)
- [API Documentation](../docs/API.md)

## 🤝 Contribuindo

Adicione seus próprios exemplos! Exemplos em outras linguagens são bem-vindos:
- Go
- Rust
- PHP
- Ruby
- Java
- C#

Envie seus exemplos via pull request!
