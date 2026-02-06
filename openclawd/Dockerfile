# Dockerfile para Openclawd - Versão Segura
FROM node:20-alpine AS builder

# Metadata
LABEL maintainer="Openclawd Installation"
LABEL version="1.0.0"
LABEL description="Secure Openclawd Container"

# Instalar dependências de build
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git

# Criar diretório de trabalho
WORKDIR /build

# Copiar arquivos de dependências
COPY package*.json ./

# Instalar dependências
RUN npm ci --only=production && \
    npm cache clean --force

# Copiar código fonte
COPY . .

# Build da aplicação (se necessário)
RUN npm run build 2>/dev/null || echo "No build script found"

# Estágio final - imagem mínima
FROM node:20-alpine

# Instalar apenas o necessário
RUN apk add --no-cache \
    curl \
    tini && \
    rm -rf /var/cache/apk/*

# Criar usuário não-root
RUN addgroup -g 1000 openclawd && \
    adduser -D -u 1000 -G openclawd openclawd

# Criar diretórios necessários
RUN mkdir -p /app /app/data /app/config /app/tmp /logs && \
    chown -R openclawd:openclawd /app /logs

# Configurar diretório de trabalho
WORKDIR /app

# Copiar da fase de build
COPY --from=builder --chown=openclawd:openclawd /build/node_modules ./node_modules
COPY --from=builder --chown=openclawd:openclawd /build/dist ./dist 2>/dev/null || true
COPY --from=builder --chown=openclawd:openclawd /build/src ./src 2>/dev/null || true
COPY --chown=openclawd:openclawd . .

# Mudar para usuário não-root
USER openclawd

# Expor porta
EXPOSE 3000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Usar tini como init
ENTRYPOINT ["/sbin/tini", "--"]

# Comando de inicialização
CMD ["node", "src/index.js"]
