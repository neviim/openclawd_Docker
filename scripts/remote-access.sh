#!/bin/bash

# Script de Gerenciamento de Acesso Remoto
# Autor: Openclawd Team

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Verificar se htpasswd está disponível
check_htpasswd() {
    if ! command -v htpasswd &> /dev/null; then
        log_warning "htpasswd não encontrado. Instalando apache2-utils..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y apache2-utils
        elif command -v yum &> /dev/null; then
            sudo yum install -y httpd-tools
        else
            log_error "Não foi possível instalar htpasswd automaticamente"
            log_info "Por favor instale manualmente: sudo apt-get install apache2-utils"
            exit 1
        fi
    fi
}

# Ativar acesso remoto
enable_remote() {
    log_info "Ativando acesso remoto..."

    # Criar diretórios necessários
    mkdir -p config/nginx/{conf.d,ssl}
    mkdir -p logs/nginx

    # Parar serviços se estiverem rodando
    if docker-compose ps | grep -q "Up"; then
        log_info "Parando serviços..."
        docker-compose down
    fi

    # Iniciar com modo remoto
    log_info "Iniciando serviços com acesso remoto..."
    docker-compose -f docker-compose.yml -f docker-compose.remote.yml up -d

    log_success "Acesso remoto ativado!"
    echo ""
    log_info "Serviços acessíveis em:"

    # Detectar IP da máquina
    IP=$(hostname -I | awk '{print $1}')

    echo "  - Dashboard: http://$IP ou http://$(hostname)"
    echo "  - API: http://$IP/api/ ou http://$(hostname)/api/"
    echo ""
    log_warning "IMPORTANTE: Configure o firewall para permitir acesso à porta 80"
    echo "  sudo ufw allow 80/tcp"
}

# Desativar acesso remoto
disable_remote() {
    log_info "Desativando acesso remoto..."

    docker-compose down

    log_info "Iniciando serviços em modo local..."
    docker-compose up -d

    log_success "Acesso remoto desativado. Serviços acessíveis apenas localmente."
}

# Adicionar usuário para autenticação
add_user() {
    local username="${1:-}"

    if [ -z "$username" ]; then
        read -p "Nome de usuário: " username
    fi

    if [ -z "$username" ]; then
        log_error "Nome de usuário não pode ser vazio"
        exit 1
    fi

    check_htpasswd

    local htpasswd_file="config/nginx/.htpasswd"

    # Criar arquivo se não existir
    if [ ! -f "$htpasswd_file" ]; then
        touch "$htpasswd_file"
    fi

    # Adicionar usuário
    htpasswd -B "$htpasswd_file" "$username"

    log_success "Usuário '$username' adicionado com sucesso"
    log_info "Para ativar a autenticação, edite config/nginx/conf.d/openclawd.conf"
    log_info "e descomente as linhas 'auth_basic'"
}

# Remover usuário
remove_user() {
    local username="${1:-}"

    if [ -z "$username" ]; then
        read -p "Nome de usuário para remover: " username
    fi

    if [ -z "$username" ]; then
        log_error "Nome de usuário não pode ser vazio"
        exit 1
    fi

    local htpasswd_file="config/nginx/.htpasswd"

    if [ ! -f "$htpasswd_file" ]; then
        log_error "Arquivo de usuários não encontrado"
        exit 1
    fi

    htpasswd -D "$htpasswd_file" "$username"
    log_success "Usuário '$username' removido"
}

# Listar usuários
list_users() {
    local htpasswd_file="config/nginx/.htpasswd"

    if [ ! -f "$htpasswd_file" ]; then
        log_warning "Nenhum usuário cadastrado"
        return
    fi

    log_info "Usuários cadastrados:"
    cut -d: -f1 "$htpasswd_file" | while read user; do
        echo "  - $user"
    done
}

# Ativar autenticação
enable_auth() {
    log_info "Ativando autenticação básica..."

    local nginx_conf="config/nginx/conf.d/openclawd.conf"

    if [ ! -f "$nginx_conf" ]; then
        log_error "Arquivo de configuração não encontrado"
        exit 1
    fi

    # Descomentar linhas de autenticação
    sed -i 's/# auth_basic/auth_basic/g' "$nginx_conf"

    log_success "Autenticação ativada"
    log_info "Reiniciando Nginx..."
    docker-compose -f docker-compose.yml -f docker-compose.remote.yml restart nginx-proxy

    log_success "Pronto! Agora é necessário usuário e senha para acessar"
}

# Desativar autenticação
disable_auth() {
    log_info "Desativando autenticação básica..."

    local nginx_conf="config/nginx/conf.d/openclawd.conf"

    if [ ! -f "$nginx_conf" ]; then
        log_error "Arquivo de configuração não encontrado"
        exit 1
    fi

    # Comentar linhas de autenticação
    sed -i 's/^    auth_basic/#    auth_basic/g' "$nginx_conf"

    log_success "Autenticação desativada"
    log_info "Reiniciando Nginx..."
    docker-compose -f docker-compose.yml -f docker-compose.remote.yml restart nginx-proxy

    log_success "Pronto! Acesso sem autenticação"
}

# Mostrar informações de acesso
show_info() {
    log_info "Informações de Acesso Remoto"
    echo ""

    # Detectar IP
    IP=$(hostname -I | awk '{print $1}')
    HOSTNAME=$(hostname)

    echo "════════════════════════════════════════════════"
    echo "URLs de Acesso:"
    echo "════════════════════════════════════════════════"
    echo ""
    echo "Dashboard Kanban:"
    echo "  http://$IP"
    echo "  http://$HOSTNAME"
    echo ""
    echo "API Openclawd:"
    echo "  http://$IP/api/activities"
    echo "  http://$HOSTNAME/api/activities"
    echo ""
    echo "Health Check:"
    echo "  http://$IP/health"
    echo ""
    echo "Status:"
    echo "  http://$IP/status"
    echo ""
    echo "════════════════════════════════════════════════"
    echo "Exemplos de Uso:"
    echo "════════════════════════════════════════════════"
    echo ""
    echo "# Listar atividades de outra máquina"
    echo "curl http://$IP/api/activities"
    echo ""
    echo "# Criar nova atividade"
    echo "curl -X POST http://$IP/api/activities \\"
    echo "  -H 'Content-Type: application/json' \\"
    echo "  -d '{\"type\": \"test\", \"description\": \"Teste remoto\"}'"
    echo ""
    echo "════════════════════════════════════════════════"

    # Status da autenticação
    if grep -q "^    auth_basic" config/nginx/conf.d/openclawd.conf 2>/dev/null; then
        log_warning "Autenticação: ATIVADA"
        echo "Use: curl -u usuario:senha http://$IP/api/activities"
    else
        log_info "Autenticação: DESATIVADA"
    fi

    echo ""
    echo "════════════════════════════════════════════════"
    log_warning "SEGURANÇA:"
    echo "  1. Configure o firewall: sudo ufw allow 80/tcp"
    echo "  2. Considere ativar autenticação: $0 enable-auth"
    echo "  3. Para HTTPS, configure certificados SSL"
    echo "════════════════════════════════════════════════"
}

# Configurar CORS
configure_cors() {
    log_info "Configurando CORS..."

    read -p "Permitir acesso de todos os domínios? (s/N): " allow_all

    if [[ $allow_all =~ ^[Ss]$ ]]; then
        export ALLOWED_ORIGINS="*"
        log_success "CORS configurado para permitir todos os domínios"
    else
        read -p "Digite os domínios permitidos (separados por vírgula): " origins
        export ALLOWED_ORIGINS="$origins"
        log_success "CORS configurado para: $origins"
    fi

    # Atualizar .env
    if grep -q "ALLOWED_ORIGINS" .env; then
        sed -i "s/ALLOWED_ORIGINS=.*/ALLOWED_ORIGINS=$ALLOWED_ORIGINS/" .env
    else
        echo "ALLOWED_ORIGINS=$ALLOWED_ORIGINS" >> .env
    fi

    log_info "Reiniciando serviços..."
    docker-compose -f docker-compose.yml -f docker-compose.remote.yml restart openclawd
}

# Menu principal
show_menu() {
    echo ""
    echo "════════════════════════════════════════════════"
    echo "  Gerenciamento de Acesso Remoto"
    echo "════════════════════════════════════════════════"
    echo ""
    echo "1) Ativar Acesso Remoto"
    echo "2) Desativar Acesso Remoto"
    echo "3) Mostrar Informações de Acesso"
    echo ""
    echo "Autenticação:"
    echo "4) Adicionar Usuário"
    echo "5) Remover Usuário"
    echo "6) Listar Usuários"
    echo "7) Ativar Autenticação"
    echo "8) Desativar Autenticação"
    echo ""
    echo "9) Configurar CORS"
    echo "0) Sair"
    echo ""
    read -p "Escolha uma opção: " choice

    case $choice in
        1) enable_remote ;;
        2) disable_remote ;;
        3) show_info ;;
        4) add_user ;;
        5) remove_user ;;
        6) list_users ;;
        7) enable_auth ;;
        8) disable_auth ;;
        9) configure_cors ;;
        0) exit 0 ;;
        *) log_error "Opção inválida" ;;
    esac
}

# Main
case "${1:-}" in
    enable)
        enable_remote
        ;;
    disable)
        disable_remote
        ;;
    info)
        show_info
        ;;
    add-user)
        add_user "${2:-}"
        ;;
    remove-user)
        remove_user "${2:-}"
        ;;
    list-users)
        list_users
        ;;
    enable-auth)
        enable_auth
        ;;
    disable-auth)
        disable_auth
        ;;
    configure-cors)
        configure_cors
        ;;
    menu)
        while true; do
            show_menu
            echo ""
            read -p "Pressione Enter para continuar..."
        done
        ;;
    *)
        echo "Script de Gerenciamento de Acesso Remoto"
        echo ""
        echo "Uso: $0 {enable|disable|info|add-user|remove-user|list-users|enable-auth|disable-auth|configure-cors|menu}"
        echo ""
        echo "Comandos:"
        echo "  enable          - Ativar acesso remoto"
        echo "  disable         - Desativar acesso remoto"
        echo "  info            - Mostrar informações de acesso"
        echo "  add-user        - Adicionar usuário para autenticação"
        echo "  remove-user     - Remover usuário"
        echo "  list-users      - Listar usuários cadastrados"
        echo "  enable-auth     - Ativar autenticação básica"
        echo "  disable-auth    - Desativar autenticação básica"
        echo "  configure-cors  - Configurar CORS"
        echo "  menu            - Menu interativo"
        echo ""
        echo "Exemplos:"
        echo "  $0 enable                    # Ativar acesso remoto"
        echo "  $0 add-user admin            # Adicionar usuário 'admin'"
        echo "  $0 enable-auth               # Ativar autenticação"
        echo "  $0 info                      # Ver informações"
        exit 1
        ;;
esac
