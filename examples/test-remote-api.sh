#!/bin/bash

# Script de Teste da API Remota do Openclawd
# Execute: ./test-remote-api.sh <IP_DO_SERVIDOR>

set -e

# Configuração
SERVER="${1:-localhost}"
BASE_URL="http://${SERVER}"

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

echo "════════════════════════════════════════════════"
echo "  Teste da API Remota Openclawd"
echo "  Servidor: $BASE_URL"
echo "════════════════════════════════════════════════"
echo ""

# Teste 1: Health Check
log_test "1. Health Check..."
if curl -sf "${BASE_URL}/health" > /dev/null; then
    log_success "Servidor está saudável"
else
    log_error "Servidor não responde"
    exit 1
fi

# Teste 2: Status
log_test "2. Status do Sistema..."
STATUS=$(curl -s "${BASE_URL}/status")
if [ -n "$STATUS" ]; then
    log_success "Status obtido"
    echo "$STATUS" | jq '.' 2>/dev/null || echo "$STATUS"
else
    log_error "Falha ao obter status"
fi

# Teste 3: Listar Atividades
log_test "3. Listar Atividades..."
ACTIVITIES=$(curl -s "${BASE_URL}/api/activities?limit=5")
if [ -n "$ACTIVITIES" ]; then
    COUNT=$(echo "$ACTIVITIES" | jq '.count' 2>/dev/null || echo "?")
    log_success "Atividades listadas: $COUNT"
    echo "$ACTIVITIES" | jq '.' 2>/dev/null || echo "$ACTIVITIES"
else
    log_error "Falha ao listar atividades"
fi

# Teste 4: Criar Atividade
log_test "4. Criar Nova Atividade..."
NEW_ACTIVITY=$(curl -s -X POST "${BASE_URL}/api/activities" \
    -H "Content-Type: application/json" \
    -d '{
        "type": "test_remote",
        "description": "Teste de acesso remoto - '"$(date)"'",
        "metadata": {"source": "test-script", "hostname": "'"$(hostname)"'"}
    }')

if echo "$NEW_ACTIVITY" | jq -e '.success' > /dev/null 2>&1; then
    ACTIVITY_ID=$(echo "$NEW_ACTIVITY" | jq -r '.activity.id')
    log_success "Atividade criada: $ACTIVITY_ID"
    echo "$NEW_ACTIVITY" | jq '.'
else
    log_error "Falha ao criar atividade"
fi

# Teste 5: Processar Tarefa
log_test "5. Processar Tarefa..."
RESULT=$(curl -s -X POST "${BASE_URL}/api/process" \
    -H "Content-Type: application/json" \
    -d '{
        "task": "test_task",
        "data": {"test": true, "timestamp": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"}
    }')

if echo "$RESULT" | jq -e '.success' > /dev/null 2>&1; then
    log_success "Tarefa processada"
    echo "$RESULT" | jq '.'
else
    log_error "Falha ao processar tarefa"
fi

# Teste 6: Dashboard Kanban
log_test "6. Dashboard Kanban..."
if curl -sf "${BASE_URL}/" > /dev/null; then
    log_success "Dashboard acessível em ${BASE_URL}/"
else
    log_error "Dashboard não acessível"
fi

echo ""
echo "════════════════════════════════════════════════"
echo "  Resumo dos Testes"
echo "════════════════════════════════════════════════"
echo ""
echo "✓ Servidor: $BASE_URL"
echo "✓ Acesse o Dashboard: ${BASE_URL}/"
echo "✓ API Endpoint: ${BASE_URL}/api/"
echo ""
echo "Exemplos de uso:"
echo ""
echo "# Listar atividades"
echo "curl ${BASE_URL}/api/activities"
echo ""
echo "# Criar atividade"
echo "curl -X POST ${BASE_URL}/api/activities \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"type\": \"task\", \"description\": \"Minha tarefa\"}'"
echo ""
echo "════════════════════════════════════════════════"
