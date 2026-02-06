#!/bin/bash

# Script de Gerenciamento do Openclawd
# Autor: Neviim 
# Versão: 1.0.0

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções auxiliares
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar dependências
check_dependencies() {
    log_info "Verificando dependências..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker não está instalado!"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose não está instalado!"
        exit 1
    fi

    log_success "Todas as dependências estão instaladas"
}

# Inicializar configuração
init_config() {
    log_info "Inicializando configuração..."

    # Criar arquivo de secrets se não existir
    mkdir -p config/secrets

    if [ ! -f config/secrets/db_password.txt ]; then
        openssl rand -base64 32 > config/secrets/db_password.txt
        log_success "Senha do banco de dados gerada"
    fi

    # Criar arquivo .env se não existir
    if [ ! -f .env ]; then
        cat > .env << EOF
# Openclawd Configuration
NODE_ENV=production
LOG_LEVEL=info
REDIS_PASSWORD=$(openssl rand -base64 32)
MONITOR_INTERVAL=5000

# Portas
OPENCLAUDE_PORT=3000
KANBAN_PORT=8080

# Timezone
TZ=America/Sao_Paulo
EOF
        log_success "Arquivo .env criado"
    fi

    # Criar diretórios necessários
    mkdir -p data/{openclawd,kanban,postgres,redis}
    mkdir -p logs
    mkdir -p config/{openclawd,kanban,fluent-bit,postgres}

    log_success "Configuração inicializada"
}

# Build das imagens
build_images() {
    log_info "Construindo imagens Docker..."
    docker-compose build --no-cache
    log_success "Imagens construídas com sucesso"
}

# Iniciar serviços
start_services() {
    log_info "Iniciando serviços..."
    docker-compose up -d

    log_info "Aguardando serviços ficarem saudáveis..."
    sleep 5

    docker-compose ps
    log_success "Serviços iniciados"

    echo ""
    log_info "Acesse os serviços:"
    echo "  - Openclawd: http://localhost:3000"
    echo "  - Kanban Monitor: http://localhost:8080"
}

# Parar serviços
stop_services() {
    log_info "Parando serviços..."
    docker-compose down
    log_success "Serviços parados"
}

# Reiniciar serviços
restart_services() {
    log_info "Reiniciando serviços..."
    docker-compose restart
    log_success "Serviços reiniciados"
}

# Status dos serviços
status_services() {
    log_info "Status dos serviços:"
    docker-compose ps

    echo ""
    log_info "Logs recentes:"
    docker-compose logs --tail=20
}

# Ver logs
view_logs() {
    SERVICE=${1:-}

    if [ -z "$SERVICE" ]; then
        docker-compose logs -f
    else
        docker-compose logs -f "$SERVICE"
    fi
}

# Limpar dados
clean_data() {
    log_warning "ATENÇÃO: Isso irá remover todos os dados!"
    read -p "Tem certeza? (s/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Ss]$ ]]; then
        log_info "Parando serviços..."
        docker-compose down -v

        log_info "Removendo dados..."
        rm -rf data/{openclawd,kanban,postgres,redis}/*
        rm -rf logs/*

        log_success "Dados removidos"
    else
        log_info "Operação cancelada"
    fi
}

# Backup
backup_data() {
    BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
    log_info "Criando backup em $BACKUP_DIR..."

    mkdir -p "$BACKUP_DIR"

    # Backup dos dados
    cp -r data "$BACKUP_DIR/"
    cp -r config "$BACKUP_DIR/"
    cp .env "$BACKUP_DIR/" 2>/dev/null || true

    # Criar tarball
    tar -czf "$BACKUP_DIR.tar.gz" -C backups "$(basename "$BACKUP_DIR")"
    rm -rf "$BACKUP_DIR"

    log_success "Backup criado: $BACKUP_DIR.tar.gz"
}

# Restaurar backup
restore_backup() {
    BACKUP_FILE=${1:-}

    if [ -z "$BACKUP_FILE" ]; then
        log_error "Especifique o arquivo de backup"
        echo "Uso: $0 restore <arquivo-backup.tar.gz>"
        exit 1
    fi

    if [ ! -f "$BACKUP_FILE" ]; then
        log_error "Arquivo de backup não encontrado: $BACKUP_FILE"
        exit 1
    fi

    log_warning "ATENÇÃO: Isso irá sobrescrever os dados atuais!"
    read -p "Tem certeza? (s/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Ss]$ ]]; then
        log_info "Parando serviços..."
        docker-compose down

        log_info "Restaurando backup..."
        TEMP_DIR=$(mktemp -d)
        tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

        cp -r "$TEMP_DIR"/*/data/* data/
        cp -r "$TEMP_DIR"/*/config/* config/
        cp "$TEMP_DIR"/*/.env .env 2>/dev/null || true

        rm -rf "$TEMP_DIR"

        log_success "Backup restaurado"
        log_info "Reiniciando serviços..."
        start_services
    else
        log_info "Operação cancelada"
    fi
}

# Atualizar sistema
update_system() {
    log_info "Atualizando sistema..."

    # Pull das últimas imagens
    docker-compose pull

    # Rebuild
    build_images

    # Restart
    restart_services

    log_success "Sistema atualizado"
}

# Health check
health_check() {
    log_info "Verificando saúde dos serviços..."

    # Openclawd
    if curl -sf http://localhost:3000/health > /dev/null; then
        log_success "Openclawd: OK"
    else
        log_error "Openclawd: FALHOU"
    fi

    # Kanban Monitor
    if curl -sf http://localhost:8080/health > /dev/null; then
        log_success "Kanban Monitor: OK"
    else
        log_error "Kanban Monitor: FALHOU"
    fi

    # PostgreSQL
    if docker-compose exec -T postgres pg_isready -U openclawd > /dev/null 2>&1; then
        log_success "PostgreSQL: OK"
    else
        log_error "PostgreSQL: FALHOU"
    fi

    # Redis
    if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
        log_success "Redis: OK"
    else
        log_error "Redis: FALHOU"
    fi
}

# Menu interativo
show_menu() {
    echo ""
    echo "======================================"
    echo "  Openclawd Management Script"
    echo "======================================"
    echo ""
    echo "1) Inicializar Configuração"
    echo "2) Build Imagens"
    echo "3) Iniciar Serviços"
    echo "4) Parar Serviços"
    echo "5) Reiniciar Serviços"
    echo "6) Status dos Serviços"
    echo "7) Ver Logs"
    echo "8) Health Check"
    echo "9) Backup"
    echo "10) Restaurar Backup"
    echo "11) Atualizar Sistema"
    echo "12) Limpar Dados"
    echo "0) Sair"
    echo ""
    read -p "Escolha uma opção: " choice

    case $choice in
        1) init_config ;;
        2) build_images ;;
        3) start_services ;;
        4) stop_services ;;
        5) restart_services ;;
        6) status_services ;;
        7) view_logs ;;
        8) health_check ;;
        9) backup_data ;;
        10)
            read -p "Arquivo de backup: " backup_file
            restore_backup "$backup_file"
            ;;
        11) update_system ;;
        12) clean_data ;;
        0) exit 0 ;;
        *) log_error "Opção inválida" ;;
    esac
}

# Main
main() {
    check_dependencies

    case "${1:-}" in
        init)
            init_config
            ;;
        build)
            build_images
            ;;
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        status)
            status_services
            ;;
        logs)
            view_logs "${2:-}"
            ;;
        health)
            health_check
            ;;
        backup)
            backup_data
            ;;
        restore)
            restore_backup "${2:-}"
            ;;
        update)
            update_system
            ;;
        clean)
            clean_data
            ;;
        menu)
            while true; do
                show_menu
                echo ""
                read -p "Pressione Enter para continuar..."
            done
            ;;
        *)
            echo "Openclawd Management Script"
            echo ""
            echo "Uso: $0 {init|build|start|stop|restart|status|logs|health|backup|restore|update|clean|menu}"
            echo ""
            echo "Comandos:"
            echo "  init      - Inicializar configuração"
            echo "  build     - Build das imagens Docker"
            echo "  start     - Iniciar serviços"
            echo "  stop      - Parar serviços"
            echo "  restart   - Reiniciar serviços"
            echo "  status    - Status dos serviços"
            echo "  logs      - Ver logs (opcional: logs <serviço>)"
            echo "  health    - Health check dos serviços"
            echo "  backup    - Criar backup"
            echo "  restore   - Restaurar backup"
            echo "  update    - Atualizar sistema"
            echo "  clean     - Limpar dados"
            echo "  menu      - Menu interativo"
            exit 1
            ;;
    esac
}

main "$@"
