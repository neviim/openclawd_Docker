FROM node:20-alpine

# Instalar dependências
RUN apk add --no-cache curl tini

# Criar usuário não-root
RUN addgroup -g 1001 kanban && \
    adduser -D -u 1001 -G kanban kanban

# Criar diretórios
RUN mkdir -p /app /data /logs && \
    chown -R kanban:kanban /app /data /logs

WORKDIR /app

# Copiar package files
COPY --chown=kanban:kanban package*.json ./

# Instalar dependências
RUN npm ci --only=production && \
    npm cache clean --force

# Copiar código
COPY --chown=kanban:kanban . .

# Mudar para usuário não-root
USER kanban

# Expor porta
EXPOSE 8080

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Usar tini
ENTRYPOINT ["/sbin/tini", "--"]

# Comando
CMD ["node", "server.js"]
