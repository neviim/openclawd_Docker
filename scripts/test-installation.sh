#!/bin/bash

# Script de Teste Completo da Instalação Openclawd
# Verifica se todos os componentes estão funcionando corretamente

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Contadores
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

log_test() {
    echo -e "${CYAN}[TEST]${NC} $1"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

run_test() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    log_test "$1"
}

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_separator() {
    echo -e "${BLUE}───────────────────────────────────────────────────────────${NC}"
}

# Início dos testes
print_header "TESTE COMPLETO DA INSTALAÇÃO OPENCLAUDE"

# 1. Verificar estrutura de arquivos
print_header "1. VERIFICAÇÃO DE ESTRUTURA DE ARQUIVOS"

run_test "Verificar docker-compose.yml"
if [ -f "docker-compose.yml" ]; then
    log_success "docker-compose.yml encontrado"
else
    log_error "docker-compose.yml não encontrado"
fi

run_test "Verificar docker-compose.remote.yml"
if [ -f "docker-compose.remote.yml" ]; then
    log_success "docker-compose.remote.yml encontrado"
else
    log_error "docker-compose.remote.yml não encontrado"
fi

run_test "Verificar script de gerenciamento"
if [ -x "scripts/manage.sh" ]; then
    log_success "scripts/manage.sh encontrado e executável"
else
    log_error "scripts/manage.sh não encontrado ou não executável"
fi

run_test "Verificar script de acesso remoto"
if [ -x "scripts/remote-access.sh" ]; then
    log_success "scripts/remote-access.sh encontrado e executável"
else
    log_error "scripts/remote-access.sh não encontrado ou não executável"
fi

run_test "Verificar Dockerfile do Openclawd"
if [ -f "openclawd/Dockerfile" ]; then
    log_success "openclawd/Dockerfile encontrado"
else
    log_error "openclawd/Dockerfile não encontrado"
fi

run_test "Verificar Dockerfile do Kanban"
if [ -f "kanban-monitor/Dockerfile" ]; then
    log_success "kanban-monitor/Dockerfile encontrado"
else
    log_error "kanban-monitor/Dockerfile não encontrado"
fi

run_test "Verificar diretórios necessários"
REQUIRED_DIRS=("config" "data" "logs" "openclawd" "kanban-monitor" "scripts")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        log_success "Diretório $dir existe"
    else
        log_error "Diretório $dir não existe"
    fi
done

# 2. Verificar dependências
print_header "2. VERIFICAÇÃO DE DEPENDÊNCIAS"

run_test "Verificar Docker"
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    log_success "Docker instalado: $DOCKER_VERSION"
else
    log_error "Docker não instalado"
fi

run_test "Verificar Docker Compose"
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version)
    else
        COMPOSE_VERSION=$(docker compose version)
    fi
    log_success "Docker Compose instalado: $COMPOSE_VERSION"
else
    log_error "Docker Compose não instalado"
fi

run_test "Verificar permissões de usuário Docker"
if docker ps &> /dev/null; then
    log_success "Usuário tem permissão para executar Docker"
else
    log_error "Usuário não tem permissão para executar Docker"
    log_info "Execute: sudo usermod -aG docker \$USER && newgrp docker"
fi

# 3. Verificar arquivos de configuração
print_header "3. VERIFICAÇÃO DE CONFIGURAÇÕES"

run_test "Verificar configuração do Nginx"
if [ -f "config/nginx/nginx.conf" ]; then
    log_success "config/nginx/nginx.conf encontrado"
else
    log_error "config/nginx/nginx.conf não encontrado"
fi

run_test "Verificar configuração do PostgreSQL"
if [ -f "config/postgres/init.sql" ]; then
    log_success "config/postgres/init.sql encontrado"
else
    log_error "config/postgres/init.sql não encontrado"
fi

run_test "Verificar configuração do Fluent Bit"
if [ -f "config/fluent-bit/fluent-bit.conf" ]; then
    log_success "config/fluent-bit/fluent-bit.conf encontrado"
else
    log_error "config/fluent-bit/fluent-bit.conf não encontrado"
fi

# 4. Verificar serviços (se estiverem rodando)
print_header "4. VERIFICAÇÃO DE SERVIÇOS"

log_info "Verificando se os serviços estão rodando..."
if docker-compose ps 2>/dev/null | grep -q "Up" || docker compose ps 2>/dev/null | grep -q "Up"; then
    log_info "Serviços estão rodando. Executando testes..."

    run_test "Openclawd App"
    if docker ps | grep -q "openclawd-app"; then
        log_success "Container openclawd-app está rodando"

        # Testar API
        if curl -sf http://localhost:3000/health > /dev/null 2>&1; then
            log_success "Openclawd API respondendo"
        else
            log_error "Openclawd API não está respondendo"
        fi
    else
        log_error "Container openclawd-app não está rodando"
    fi

    run_test "Kanban Monitor"
    if docker ps | grep -q "kanban-monitor"; then
        log_success "Container kanban-monitor está rodando"

        # Testar dashboard
        if curl -sf http://localhost:8080/health > /dev/null 2>&1; then
            log_success "Kanban Dashboard respondendo"
        else
            log_error "Kanban Dashboard não está respondendo"
        fi
    else
        log_error "Container kanban-monitor não está rodando"
    fi

    run_test "PostgreSQL"
    if docker ps | grep -q "openclawd-postgres"; then
        log_success "Container PostgreSQL está rodando"

        # Testar conexão
        if docker-compose exec -T postgres pg_isready -U openclawd > /dev/null 2>&1; then
            log_success "PostgreSQL aceitando conexões"
        else
            log_error "PostgreSQL não está aceitando conexões"
        fi
    else
        log_error "Container PostgreSQL não está rodando"
    fi

    run_test "Redis"
    if docker ps | grep -q "openclawd-redis"; then
        log_success "Container Redis está rodando"

        # Testar ping
        if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
            log_success "Redis respondendo a ping"
        else
            log_error "Redis não está respondendo"
        fi
    else
        log_error "Container Redis não está rodando"
    fi

    # Testes de API
    print_header "5. TESTES DE API"

    run_test "GET /health"
    if HEALTH=$(curl -sf http://localhost:3000/health 2>&1); then
        log_success "Health check passou"
        echo "     Resposta: $HEALTH"
    else
        log_error "Health check falhou"
    fi

    run_test "GET /status"
    if STATUS=$(curl -sf http://localhost:3000/status 2>&1); then
        log_success "Status endpoint funcionando"
        echo "     Resposta: $STATUS"
    else
        log_error "Status endpoint falhou"
    fi

    run_test "GET /api/activities"
    if ACTIVITIES=$(curl -sf http://localhost:3000/api/activities 2>&1); then
        log_success "Lista de atividades funcionando"
        COUNT=$(echo "$ACTIVITIES" | jq -r '.count' 2>/dev/null || echo "?")
        echo "     Atividades: $COUNT"
    else
        log_error "Lista de atividades falhou"
    fi

    run_test "POST /api/activities"
    if RESULT=$(curl -sf -X POST http://localhost:3000/api/activities \
        -H "Content-Type: application/json" \
        -d '{"type":"test","description":"Teste de instalação"}' 2>&1); then
        log_success "Criação de atividade funcionando"
        ID=$(echo "$RESULT" | jq -r '.activity.id' 2>/dev/null || echo "?")
        echo "     ID criado: ${ID:0:8}..."
    else
        log_error "Criação de atividade falhou"
    fi

    # Testes do Dashboard
    print_header "6. TESTES DO DASHBOARD KANBAN"

    run_test "GET / (Dashboard)"
    if curl -sf http://localhost:8080/ > /dev/null 2>&1; then
        log_success "Dashboard Kanban acessível"
    else
        log_error "Dashboard Kanban não acessível"
    fi

    run_test "GET /api/kanban"
    if KANBAN=$(curl -sf http://localhost:8080/api/kanban 2>&1); then
        log_success "API Kanban funcionando"
    else
        log_error "API Kanban falhou"
    fi

else
    log_warning "Serviços não estão rodando"
    log_info "Execute './scripts/manage.sh start' para iniciar os serviços"
    log_info "Pulando testes de serviços..."
fi

# 5. Verificar exemplos
print_header "7. VERIFICAÇÃO DE EXEMPLOS"

run_test "Script de teste remoto"
if [ -x "examples/test-remote-api.sh" ]; then
    log_success "examples/test-remote-api.sh executável"
else
    log_error "examples/test-remote-api.sh não executável"
fi

run_test "Cliente Python"
if [ -x "examples/python_client.py" ]; then
    log_success "examples/python_client.py executável"
else
    log_error "examples/python_client.py não executável"
fi

run_test "Cliente Node.js"
if [ -x "examples/nodejs_client.js" ]; then
    log_success "examples/nodejs_client.js executável"
else
    log_error "examples/nodejs_client.js não executável"
fi

# 6. Verificar documentação
print_header "8. VERIFICAÇÃO DE DOCUMENTAÇÃO"

DOCS=("README.md" "doc/QUICKSTART.md" "doc/REMOTE-ACCESS.md" "doc/ACESSO-REMOTO-RAPIDO.md" "doc/TESTING.md" "doc/WATCHTOWER.md" "doc/IMPLEMENTATION-SUMMARY.md" "LICENSE")
for doc in "${DOCS[@]}"; do
    run_test "Documentação: $doc"
    if [ -f "$doc" ]; then
        log_success "$doc encontrado"
    else
        log_error "$doc não encontrado"
    fi
done

# Relatório final
print_header "RELATÓRIO FINAL"

echo ""
echo -e "${CYAN}Testes Executados:${NC} $TESTS_TOTAL"
echo -e "${GREEN}Testes Aprovados:${NC} $TESTS_PASSED"
echo -e "${RED}Testes Falhados:${NC}  $TESTS_FAILED"
echo ""

PERCENTAGE=$(( TESTS_PASSED * 100 / TESTS_TOTAL ))
echo -e "${CYAN}Taxa de Sucesso:${NC} $PERCENTAGE%"
echo ""

print_separator

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                        ║${NC}"
    echo -e "${GREEN}║  ✓ INSTALAÇÃO VALIDADA COM SUCESSO!                   ║${NC}"
    echo -e "${GREEN}║                                                        ║${NC}"
    echo -e "${GREEN}║  Todos os componentes estão funcionando corretamente  ║${NC}"
    echo -e "${GREEN}║                                                        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 0
elif [ $PERCENTAGE -ge 80 ]; then
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                                                        ║${NC}"
    echo -e "${YELLOW}║  ! INSTALAÇÃO PARCIALMENTE FUNCIONAL                  ║${NC}"
    echo -e "${YELLOW}║                                                        ║${NC}"
    echo -e "${YELLOW}║  Alguns testes falharam, mas o sistema está operável  ║${NC}"
    echo -e "${YELLOW}║                                                        ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Recomendações:${NC}"
    echo "  - Verifique os logs: ./scripts/manage.sh logs"
    echo "  - Execute novamente após corrigir os problemas"
    echo ""
    exit 1
else
    echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                        ║${NC}"
    echo -e "${RED}║  ✗ INSTALAÇÃO COM PROBLEMAS                           ║${NC}"
    echo -e "${RED}║                                                        ║${NC}"
    echo -e "${RED}║  Muitos testes falharam. Verifique a instalação.      ║${NC}"
    echo -e "${RED}║                                                        ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${RED}Ações recomendadas:${NC}"
    echo "  1. Verifique as dependências: Docker, Docker Compose"
    echo "  2. Execute: ./scripts/manage.sh init"
    echo "  3. Execute: ./scripts/manage.sh build"
    echo "  4. Execute: ./scripts/manage.sh start"
    echo "  5. Execute este teste novamente"
    echo ""
    exit 2
fi
