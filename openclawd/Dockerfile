# Dockerfile para Openclawd - Versão Segura
FROM node:20-alpine

# Metadata
LABEL maintainer="Openclawd Installation"
LABEL version="1.0.0"
LABEL description="Secure Openclawd Container"

# Instalar dependências necessárias
RUN apk add --no-cache \
    curl \
    tini \
    python3 \
    make \
    g++ && \
    rm -rf /var/cache/apk/*

# Criar usuário não-root
RUN addgroup -S openclawd && \
    adduser -S -G openclawd openclawd

# Criar diretórios necessários
RUN mkdir -p /app /app/data /app/config /app/tmp /logs && \
    chown -R openclawd:openclawd /app /logs

# Configurar diretório de trabalho
WORKDIR /app

# Copiar arquivos de dependências
COPY --chown=openclawd:openclawd package*.json ./

# Instalar dependências
RUN npm install --omit=dev && \
    npm cache clean --force

# Copiar código fonte
COPY --chown=openclawd:openclawd ./src ./src

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
