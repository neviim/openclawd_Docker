#!/bin/bash

# Script de Instalação Rápida do Openclawd
# Execute: ./install.sh

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
   ___                    ____ _                 _
  / _ \ _ __   ___ _ __  / ___| | __ _ _   _  __| | ___
 | | | | '_ \ / _ \ '_ \| |   | |/ _` | | | |/ _` |/ _ \
 | |_| | |_) |  __/ | | | |___| | (_| | |_| | (_| |  __/
  \___/| .__/ \___|_| |_|\____|_|\__,_|\__,_|\__,_|\___|
       |_|

  Instalação Completa e Segura

EOF
echo -e "${NC}"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Verificar Docker
echo -e "${BLUE}[1/5]${NC} Verificando dependências..."
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker não encontrado!${NC}"
    echo "Por favor, instale o Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${YELLOW}Docker Compose não encontrado!${NC}"
    echo "Por favor, instale o Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

echo -e "${GREEN}✓ Docker e Docker Compose instalados${NC}"

# Tornar script executável
chmod +x scripts/manage.sh

# Inicializar configuração
echo -e "\n${BLUE}[2/5]${NC} Inicializando configuração..."
./scripts/manage.sh init
echo -e "${GREEN}✓ Configuração inicializada${NC}"

# Build
echo -e "\n${BLUE}[3/5]${NC} Construindo imagens Docker..."
echo "Isso pode levar alguns minutos..."
./scripts/manage.sh build
echo -e "${GREEN}✓ Imagens construídas${NC}"

# Iniciar serviços
echo -e "\n${BLUE}[4/5]${NC} Iniciando serviços..."
./scripts/manage.sh start

# Aguardar serviços ficarem prontos
echo -e "\n${BLUE}[5/5]${NC} Aguardando serviços ficarem prontos..."
sleep 10

# Health check
./scripts/manage.sh health

# Sucesso
echo -e "\n${GREEN}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}     Instalação Concluída com Sucesso! 🎉${NC}"
echo -e "${GREEN}════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}📊 Dashboard Kanban:${NC} http://localhost:8080"
echo -e "${BLUE}🔌 API Openclawd:${NC} http://localhost:3000"
echo ""
echo -e "${YELLOW}Comandos úteis:${NC}"
echo "  ./scripts/manage.sh status  - Ver status"
echo "  ./scripts/manage.sh logs    - Ver logs"
echo "  ./scripts/manage.sh stop    - Parar serviços"
echo "  ./scripts/manage.sh menu    - Menu interativo"
echo ""
echo -e "${BLUE}📚 Documentação:${NC}"
echo "  README.md           - Documentação completa"
echo "  doc/QUICKSTART.md   - Guia rápido"
echo ""
echo -e "${GREEN}Acesse o Dashboard Kanban em seu navegador:${NC}"
echo -e "${BLUE}http://localhost:8080${NC}"
echo ""
