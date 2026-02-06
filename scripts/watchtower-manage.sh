#!/bin/bash

# Script de Gerenciamento do Watchtower
# Autor: Openclawd Team

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

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Verificar se Watchtower está rodando
is_running() {
    docker ps | grep -q "openclawd-watchtower"
}

# Status do Watchtower
status() {
    log_info "Status do Watchtower"
    echo ""

    if is_running; then
        log_success "Watchtower está RODANDO"
        echo ""
        docker ps --filter "name=openclawd-watchtower" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
        echo ""

        # Mostrar últimas atividades
        log_info "Últimas 20 linhas do log:"
        docker logs --tail 20 openclawd-watchtower 2>&1 | tail -20
    else
        log_warning "Watchtower NÃO está rodando"
        echo ""
        log_info "Para iniciar: $0 start"
    fi
}

# Iniciar Watchtower
start() {
    log_info "Iniciando Watchtower..."

    if is_running; then
        log_warning "Watchtower já está rodando"
        return
    fi

    docker compose up -d watchtower
    sleep 2

    if is_running; then
        log_success "Watchtower iniciado com sucesso"
        log_info "Modo: ${WATCHTOWER_MODE:-monitor-only}"
        log_info "Agendamento: Diariamente às 2h da manhã"
    else
        log_error "Falha ao iniciar Watchtower"
        exit 1
    fi
}

# Parar Watchtower
stop() {
    log_info "Parando Watchtower..."

    if ! is_running; then
        log_warning "Watchtower não está rodando"
        return
    fi

    docker compose stop watchtower
    log_success "Watchtower parado"
}

# Reiniciar Watchtower
restart() {
    log_info "Reiniciando Watchtower..."
    stop
    sleep 2
    start
}

# Ver logs
logs() {
    local lines="${1:-100}"

    if ! is_running; then
        log_warning "Watchtower não está rodando"
        log_info "Mostrando logs históricos..."
    fi

    if [ "$lines" = "follow" ]; then
        log_info "Seguindo logs em tempo real (Ctrl+C para sair)..."
        docker logs -f openclawd-watchtower 2>&1
    else
        log_info "Mostrando últimas $lines linhas..."
        docker logs --tail "$lines" openclawd-watchtower 2>&1
    fi
}

# Atualizar agora (forçar verificação)
update_now() {
    log_info "Forçando verificação de atualizações..."

    if ! is_running; then
        log_error "Watchtower não está rodando"
        log_info "Inicie primeiro: $0 start"
        exit 1
    fi

    # Enviar sinal USR1 para forçar verificação
    docker kill -s USR1 openclawd-watchtower

    log_success "Sinal de verificação enviado"
    log_info "Aguarde alguns instantes e verifique os logs: $0 logs"
}

# Ativar modo automático
enable_auto_update() {
    log_info "Ativando atualizações automáticas..."

    # Atualizar .env
    if grep -q "WATCHTOWER_MONITOR_ONLY" .env 2>/dev/null; then
        sed -i 's/WATCHTOWER_MONITOR_ONLY=.*/WATCHTOWER_MONITOR_ONLY=false/' .env
    else
        echo "WATCHTOWER_MONITOR_ONLY=false" >> .env
    fi

    log_success "Modo automático ativado"
    log_warning "ATENÇÃO: Watchtower irá atualizar containers automaticamente!"
    log_info "Reinicie o Watchtower: $0 restart"
}

# Ativar modo monitoramento
enable_monitor_only() {
    log_info "Ativando modo apenas monitoramento..."

    # Atualizar .env
    if grep -q "WATCHTOWER_MONITOR_ONLY" .env 2>/dev/null; then
        sed -i 's/WATCHTOWER_MONITOR_ONLY=.*/WATCHTOWER_MONITOR_ONLY=true/' .env
    else
        echo "WATCHTOWER_MONITOR_ONLY=true" >> .env
    fi

    log_success "Modo monitoramento ativado"
    log_info "Watchtower irá apenas notificar sobre atualizações disponíveis"
    log_info "Reinicie o Watchtower: $0 restart"
}

# Configurar notificações
configure_notifications() {
    log_info "Configurar Notificações"
    echo ""
    echo "Watchtower suporta notificações via:"
    echo "  1) Email"
    echo "  2) Slack"
    echo "  3) Discord"
    echo "  4) Telegram"
    echo "  5) Outros (Shoutrrr)"
    echo ""
    read -p "Escolha uma opção (1-5) ou Enter para pular: " choice

    case $choice in
        1)
            read -p "Servidor SMTP: " smtp_server
            read -p "Porta SMTP: " smtp_port
            read -p "Email de origem: " email_from
            read -p "Email de destino: " email_to
            read -sp "Senha SMTP: " smtp_password
            echo ""

            NOTIFICATION_URL="smtp://${email_from}:${smtp_password}@${smtp_server}:${smtp_port}/?to=${email_to}"
            ;;
        2)
            read -p "Slack Webhook URL: " slack_url
            NOTIFICATION_URL="$slack_url"
            ;;
        3)
            read -p "Discord Webhook URL: " discord_url
            NOTIFICATION_URL="$discord_url"
            ;;
        4)
            read -p "Telegram Bot Token: " telegram_token
            read -p "Telegram Chat ID: " telegram_chat
            NOTIFICATION_URL="telegram://${telegram_token}@telegram?chats=${telegram_chat}"
            ;;
        5)
            read -p "URL Shoutrrr: " shoutrrr_url
            NOTIFICATION_URL="$shoutrrr_url"
            ;;
        *)
            log_info "Notificações não configuradas"
            return
            ;;
    esac

    # Atualizar .env
    if grep -q "WATCHTOWER_NOTIFICATION_URL" .env 2>/dev/null; then
        sed -i "s|WATCHTOWER_NOTIFICATION_URL=.*|WATCHTOWER_NOTIFICATION_URL=$NOTIFICATION_URL|" .env
    else
        echo "WATCHTOWER_NOTIFICATION_URL=$NOTIFICATION_URL" >> .env
    fi

    log_success "Notificações configuradas"
    log_info "Reinicie o Watchtower: $0 restart"
}

# Listar containers monitorados
list_containers() {
    log_info "Containers Monitorados pelo Watchtower"
    echo ""

    echo "✓ Habilitados para atualização:"
    docker ps --filter "label=com.centurylinklabs.watchtower.enable=true" \
        --format "  - {{.Names}} ({{.Image}})" || echo "  Nenhum"

    echo ""
    echo "✗ Desabilitados:"
    docker ps --filter "label=com.centurylinklabs.watchtower.enable=false" \
        --format "  - {{.Names}} ({{.Image}})" || echo "  Nenhum"

    echo ""
    echo "? Sem label (seguirá configuração global):"
    docker ps --format "{{.Names}}\t{{.Label \"com.centurylinklabs.watchtower.enable\"}}" | \
        awk '$2 == "" {print "  - " $1}' || echo "  Nenhum"
}

# Habilitar container específico
enable_container() {
    local container="${1:-}"

    if [ -z "$container" ]; then
        read -p "Nome do container: " container
    fi

    if [ -z "$container" ]; then
        log_error "Nome do container não pode ser vazio"
        exit 1
    fi

    log_info "Habilitando $container para atualizações..."

    # Precisamos editar o docker-compose.yml
    log_warning "Edite o docker-compose.yml e adicione:"
    echo ""
    echo "    labels:"
    echo "      - \"com.centurylinklabs.watchtower.enable=true\""
    echo ""
    log_info "Depois execute: docker compose up -d $container"
}

# Informações
info() {
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  Informações do Watchtower"
    echo "═══════════════════════════════════════════════════════"
    echo ""

    # Status
    if is_running; then
        echo "Status: ${GREEN}RODANDO${NC}"
    else
        echo "Status: ${RED}PARADO${NC}"
    fi

    # Modo
    MONITOR_MODE=$(grep "WATCHTOWER_MONITOR_ONLY" .env 2>/dev/null | cut -d= -f2 || echo "false")
    if [ "$MONITOR_MODE" = "true" ]; then
        echo "Modo: ${YELLOW}Apenas Monitoramento${NC}"
        echo "  └─ Notifica sobre atualizações, mas não aplica"
    else
        echo "Modo: ${GREEN}Automático${NC}"
        echo "  └─ Aplica atualizações automaticamente"
    fi

    # Agendamento
    echo ""
    echo "Agendamento: Diariamente às 2h da manhã"
    echo "Intervalo de Poll: 3600s (1 hora)"

    # Notificações
    if grep -q "WATCHTOWER_NOTIFICATION_URL" .env 2>/dev/null; then
        echo "Notificações: ${GREEN}CONFIGURADAS${NC}"
    else
        echo "Notificações: ${YELLOW}NÃO CONFIGURADAS${NC}"
    fi

    # Containers
    echo ""
    ENABLED=$(docker ps --filter "label=com.centurylinklabs.watchtower.enable=true" --quiet | wc -l)
    DISABLED=$(docker ps --filter "label=com.centurylinklabs.watchtower.enable=false" --quiet | wc -l)
    echo "Containers habilitados: $ENABLED"
    echo "Containers desabilitados: $DISABLED"

    echo ""
    echo "═══════════════════════════════════════════════════════"
}

# Menu
menu() {
    while true; do
        echo ""
        echo "═══════════════════════════════════════════════════════"
        echo "  Gerenciamento do Watchtower"
        echo "═══════════════════════════════════════════════════════"
        echo ""
        echo "1) Status"
        echo "2) Iniciar"
        echo "3) Parar"
        echo "4) Reiniciar"
        echo "5) Ver Logs"
        echo "6) Atualizar Agora"
        echo "7) Listar Containers"
        echo ""
        echo "8) Ativar Modo Automático"
        echo "9) Ativar Modo Monitoramento"
        echo "10) Configurar Notificações"
        echo ""
        echo "11) Informações"
        echo "0) Sair"
        echo ""
        read -p "Escolha uma opção: " choice

        case $choice in
            1) status ;;
            2) start ;;
            3) stop ;;
            4) restart ;;
            5) logs follow ;;
            6) update_now ;;
            7) list_containers ;;
            8) enable_auto_update ;;
            9) enable_monitor_only ;;
            10) configure_notifications ;;
            11) info ;;
            0) exit 0 ;;
            *) log_error "Opção inválida" ;;
        esac

        echo ""
        read -p "Pressione Enter para continuar..."
    done
}

# Main
case "${1:-}" in
    status)
        status
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    logs)
        logs "${2:-100}"
        ;;
    update-now)
        update_now
        ;;
    enable-auto)
        enable_auto_update
        ;;
    enable-monitor)
        enable_monitor_only
        ;;
    configure-notifications)
        configure_notifications
        ;;
    list-containers)
        list_containers
        ;;
    enable-container)
        enable_container "${2:-}"
        ;;
    info)
        info
        ;;
    menu)
        menu
        ;;
    *)
        echo "Script de Gerenciamento do Watchtower"
        echo ""
        echo "Uso: $0 {comando}"
        echo ""
        echo "Comandos:"
        echo "  status                  - Ver status do Watchtower"
        echo "  start                   - Iniciar Watchtower"
        echo "  stop                    - Parar Watchtower"
        echo "  restart                 - Reiniciar Watchtower"
        echo "  logs [linhas|follow]    - Ver logs"
        echo "  update-now              - Forçar verificação agora"
        echo "  enable-auto             - Ativar atualizações automáticas"
        echo "  enable-monitor          - Ativar modo monitoramento"
        echo "  configure-notifications - Configurar notificações"
        echo "  list-containers         - Listar containers monitorados"
        echo "  enable-container <nome> - Habilitar container específico"
        echo "  info                    - Mostrar informações"
        echo "  menu                    - Menu interativo"
        echo ""
        echo "Exemplos:"
        echo "  $0 status               # Ver status"
        echo "  $0 logs follow          # Seguir logs em tempo real"
        echo "  $0 update-now           # Forçar verificação"
        echo "  $0 menu                 # Menu interativo"
        exit 1
        ;;
esac
