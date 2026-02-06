# 🔄 Watchtower - Monitoramento Automático de Atualizações

O Watchtower monitora automaticamente seus containers Docker e pode atualiz��-los quando novas versões estiverem disponíveis.

## 📋 Índice

- [O que é Watchtower](#o-que-é-watchtower)
- [Como Funciona](#como-funciona)
- [Configuração](#configuração)
- [Uso](#uso)
- [Modos de Operação](#modos-de-operação)
- [Notificações](#notificações)
- [Políticas de Atualização](#políticas-de-atualização)
- [Comandos](#comandos)
- [Solução de Problemas](#solução-de-problemas)

## 🎯 O que é Watchtower

Watchtower é uma aplicação que monitora seus containers Docker em execução e verifica se há atualizações disponíveis para as imagens. Quando detecta uma atualização, pode:

- **Modo Monitoramento**: Apenas notificar sobre atualizações disponíveis
- **Modo Automático**: Baixar e aplicar atualizações automaticamente

## ⚙️ Como Funciona

```
┌─────────────────────────────────────────────────────┐
│                   Watchtower                         │
│                                                      │
│  1. Verifica Docker Hub periodicamente              │
│  2. Compara versões das imagens                     │
│  3. Detecta atualizações disponíveis                │
│  4. Notifica ou aplica atualizações                 │
│  5. Mantém logs de todas as operações               │
│                                                      │
└─────────────────────────────────────────────────────┘
          ▼                    ▼                 ▼
    ┌─────────┐          ┌─────────┐      ┌─────────┐
    │Openclawd         │ Kanban  │      │PostgreSQL
    │   App   │          │ Monitor │      │  (skip) │
    └─────────┘          └─────────┘      └─────────┘
      ✓ Enabled           ✓ Enabled        ✗ Disabled
```

## 🚀 Configuração

### Configuração Padrão

O Watchtower já vem pré-configurado com:

- **Agendamento**: Diariamente às 2h da manhã
- **Modo**: Apenas Monitoramento (monitor-only)
- **Cleanup**: Remove imagens antigas automaticamente
- **Rolling Restart**: Reinicia containers um por vez

### Containers Monitorados

Por padrão:

- ✅ **Openclawd App** - Monitorado e pode ser atualizado
- ✅ **Kanban Monitor** - Monitorado e pode ser atualizado
- ❌ **PostgreSQL** - Desabilitado (requer backup manual)
- ❌ **Redis** - Desabilitado (não crítico)
- ❌ **Fluent Bit** - Desabilitado (auxiliar)

### Arquivo de Configuração

Edite `config/watchtower/config.json` para personalizar:

```json
{
  "schedule": {
    "cron": "0 0 2 * * *",
    "description": "Verifica atualizações diariamente às 2h"
  },
  "policies": {
    "cleanup_old_images": true,
    "rolling_restart": true,
    "monitor_only": false
  }
}
```

## 📝 Uso

### Script de Gerenciamento

Use o script dedicado:

```bash
cd ~/Developer/openclawd_Docker
./scripts/watchtower-manage.sh <comando>
```

### Comandos Principais

```bash
# Ver status
./scripts/watchtower-manage.sh status

# Iniciar Watchtower
./scripts/watchtower-manage.sh start

# Parar Watchtower
./scripts/watchtower-manage.sh stop

# Ver logs
./scripts/watchtower-manage.sh logs

# Seguir logs em tempo real
./scripts/watchtower-manage.sh logs follow

# Forçar verificação agora
./scripts/watchtower-manage.sh update-now

# Menu interativo
./scripts/watchtower-manage.sh menu
```

## 🎛️ Modos de Operação

### Modo Monitoramento (Padrão)

Apenas notifica sobre atualizações disponíveis, sem aplicar:

```bash
./scripts/watchtower-manage.sh enable-monitor
./scripts/watchtower-manage.sh restart
```

**Vantagens:**
- ✅ Seguro - você controla quando atualizar
- ✅ Recebe notificações de atualizações
- ✅ Sem risco de downtime inesperado

**Recomendado para:** Produção, ambientes críticos

### Modo Automático

Aplica atualizações automaticamente:

```bash
./scripts/watchtower-manage.sh enable-auto
./scripts/watchtower-manage.sh restart
```

**Vantagens:**
- ✅ Sempre atualizado
- ✅ Sem intervenção manual
- ✅ Correções de segurança automáticas

**Desvantagens:**
- ⚠️ Pode causar downtime
- ⚠️ Atualizações podem introduzir bugs

**Recomendado para:** Desenvolvimento, teste

## 🔔 Notificações

### Configurar Notificações

```bash
./scripts/watchtower-manage.sh configure-notifications
```

### Opções Disponíveis

#### 1. Email (SMTP)

```bash
# Configurar via script
./scripts/watchtower-manage.sh configure-notifications
# Escolha opção 1 e preencha:
# - Servidor SMTP
# - Porta (587 ou 465)
# - Email de origem
# - Email de destino
# - Senha
```

Ou manualmente no `.env`:
```bash
WATCHTOWER_NOTIFICATION_URL="smtp://user:pass@smtp.gmail.com:587/?to=admin@example.com"
```

#### 2. Slack

```bash
# Criar Webhook no Slack:
# 1. Acesse https://api.slack.com/apps
# 2. Crie um app e ative Incoming Webhooks
# 3. Copie a URL do Webhook

# Configurar
WATCHTOWER_NOTIFICATION_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

#### 3. Discord

```bash
# Criar Webhook no Discord:
# 1. Configurações do Canal > Integrações > Webhooks
# 2. Criar Webhook e copiar URL

# Configurar
WATCHTOWER_NOTIFICATION_URL="https://discord.com/api/webhooks/YOUR/WEBHOOK"
```

#### 4. Telegram

```bash
# Criar Bot:
# 1. Fale com @BotFather no Telegram
# 2. Crie um bot e obtenha o token
# 3. Obtenha seu chat ID com @userinfobot

# Configurar
WATCHTOWER_NOTIFICATION_URL="telegram://TOKEN@telegram?chats=CHAT_ID"
```

### Testar Notificações

Após configurar, force uma verificação:

```bash
./scripts/watchtower-manage.sh update-now
./scripts/watchtower-manage.sh logs
```

## 📜 Políticas de Atualização

### Personalizar Políticas

Edite `docker-compose.yml` para cada container:

#### Habilitar Atualizações

```yaml
labels:
  - "com.centurylinklabs.watchtower.enable=true"
```

#### Desabilitar Atualizações

```yaml
labels:
  - "com.centurylinklabs.watchtower.enable=false"
```

#### Lifecycle Hooks

Execute scripts antes/depois da atualização:

```yaml
labels:
  - "com.centurylinklabs.watchtower.lifecycle.pre-update=/scripts/backup.sh"
  - "com.centurylinklabs.watchtower.lifecycle.post-update=/scripts/verify.sh"
```

### Containers Específicos

Para atualizar apenas containers específicos:

```bash
# Editar docker-compose.yml
# Adicionar label no container desejado:
labels:
  - "com.centurylinklabs.watchtower.enable=true"

# Reiniciar container
docker compose up -d nome-do-container

# Reiniciar Watchtower
./scripts/watchtower-manage.sh restart
```

## 🛠️ Comandos Avançados

### Via Docker Compose

```bash
# Iniciar apenas Watchtower
docker compose up -d watchtower

# Parar Watchtower
docker compose stop watchtower

# Ver logs
docker compose logs -f watchtower

# Remover Watchtower
docker compose rm -f watchtower
```

### Via Docker Direto

```bash
# Status
docker ps -f name=openclawd-watchtower

# Logs
docker logs openclawd-watchtower

# Forçar verificação (enviar sinal)
docker kill -s USR1 openclawd-watchtower

# Parar
docker stop openclawd-watchtower

# Remover
docker rm openclawd-watchtower
```

### Verificar Atualizações Manualmente

```bash
# Ver se há atualizações disponíveis para uma imagem
docker pull nome-da-imagem:tag
docker images

# Comparar com imagem atual
docker inspect container-name | grep Image
```

## 📊 Monitoramento

### Ver Atividades do Watchtower

```bash
# Logs em tempo real
./scripts/watchtower-manage.sh logs follow

# Últimas 50 linhas
./scripts/watchtower-manage.sh logs 50

# Informações completas
./scripts/watchtower-manage.sh info
```

### Listar Containers Monitorados

```bash
./scripts/watchtower-manage.sh list-containers
```

### Histórico de Atualizações

```bash
# Ver logs de atualizações anteriores
cat logs/watchtower/watchtower.log

# Filtrar apenas atualizações
docker logs openclawd-watchtower 2>&1 | grep -i "updated"
```

## 🔧 Personalização

### Alterar Agendamento

Edite `docker-compose.yml`:

```yaml
watchtower:
  command: --schedule "0 0 4 * * *" --cleanup --debug
  # Executa às 4h da manhã diariamente
```

Formatos de agendamento (Cron):
```
* * * * * *
│ │ │ │ │ │
│ │ │ │ │ └─ Dia da semana (0-6)
│ │ │ │ └─── Mês (1-12)
│ │ │ └───── Dia do mês (1-31)
│ │ └─────── Hora (0-23)
│ └───────── Minuto (0-59)
└─────────── Segundo (0-59)
```

Exemplos:
```bash
# A cada 6 horas
--schedule "0 0 */6 * * *"

# Segunda, Quarta e Sexta às 3h
--schedule "0 0 3 * * 1,3,5"

# Primeiro dia do mês às 2h
--schedule "0 0 2 1 * *"
```

### Alterar Intervalo de Poll

```yaml
environment:
  - WATCHTOWER_POLL_INTERVAL=7200  # 2 horas em segundos
```

### Habilitar Debug

```yaml
environment:
  - WATCHTOWER_DEBUG=true
  - WATCHTOWER_TRACE=true
```

## 🚨 Solução de Problemas

### Watchtower não inicia

```bash
# Verificar logs
./scripts/watchtower-manage.sh logs

# Verificar se Docker socket está acessível
ls -la /var/run/docker.sock

# Verificar permissões
docker ps
```

### Atualizações não são aplicadas

```bash
# Verificar modo
grep WATCHTOWER_MONITOR_ONLY .env

# Se true, está em modo monitoramento apenas
# Alterar para false para aplicar atualizações

# Verificar labels dos containers
./scripts/watchtower-manage.sh list-containers

# Forçar verificação
./scripts/watchtower-manage.sh update-now
```

### Notificações não funcionam

```bash
# Verificar configuração
grep WATCHTOWER_NOTIFICATION_URL .env

# Testar URL manualmente (Slack/Discord)
curl -X POST -H 'Content-Type: application/json' \
  -d '{"text":"Teste"}' \
  URL_DO_WEBHOOK

# Ver logs para erros
./scripts/watchtower-manage.sh logs | grep -i notification
```

### Container atualizado quebrou

```bash
# Parar Watchtower
./scripts/watchtower-manage.sh stop

# Ver versões antigas disponíveis
docker images | grep nome-do-container

# Fazer rollback manual
docker compose down nome-do-container
docker tag imagem:tag-antiga imagem:tag-atual
docker compose up -d nome-do-container

# Ou restaurar do backup
./scripts/manage.sh restore backup-file.tar.gz
```

## 🛡️ Segurança e Melhores Práticas

### Recomendações

1. **Modo Monitoramento em Produção**
   ```bash
   ./scripts/watchtower-manage.sh enable-monitor
   ```
   - Sempre use modo monitoramento em produção
   - Aplique atualizações manualmente após testes

2. **Backup Antes de Atualizar**
   ```bash
   ./scripts/manage.sh backup
   ./scripts/watchtower-manage.sh update-now
   ```

3. **Desabilitar Banco de Dados**
   - PostgreSQL e Redis não devem ser atualizados automaticamente
   - Sempre faça backup antes de atualizar banco de dados

4. **Testar em Ambiente de Desenvolvimento**
   - Teste atualizações primeiro em dev/staging
   - Depois aplique em produção

5. **Monitorar Logs**
   ```bash
   ./scripts/watchtower-manage.sh logs follow
   ```

6. **Notificações Ativas**
   - Configure notificações para saber de atualizações
   - Use Slack, Discord ou Email

7. **Rolling Restart**
   - Mantido habilitado por padrão
   - Evita downtime total

### Checklist de Segurança

- [ ] Watchtower em modo monitoramento
- [ ] Notificações configuradas
- [ ] Banco de dados desabilitado
- [ ] Backups automáticos configurados
- [ ] Logs monitorados regularmente
- [ ] Agendamento fora de horário de pico

## 📚 Recursos Adicionais

- [Documentação Oficial do Watchtower](https://containrrr.dev/watchtower/)
- [Shoutrrr - Sistema de Notificações](https://containrrr.dev/shoutrrr/)
- [Docker Hub - Atualizações de Imagens](https://hub.docker.com/)

## 🎯 Casos de Uso

### Caso 1: Desenvolvimento Local

```bash
# Habilitar atualizações automáticas
./scripts/watchtower-manage.sh enable-auto
./scripts/watchtower-manage.sh restart

# Sempre ter a versão mais recente
# Ideal para desenvolvimento e testes
```

### Caso 2: Servidor de Produção

```bash
# Modo monitoramento + Notificações
./scripts/watchtower-manage.sh enable-monitor
./scripts/watchtower-manage.sh configure-notifications
./scripts/watchtower-manage.sh restart

# Recebe notificações quando há atualizações
# Aplica manualmente após validação
```

### Caso 3: Servidor de Staging

```bash
# Automático mas com notificações
./scripts/watchtower-manage.sh enable-auto
./scripts/watchtower-manage.sh configure-notifications
./scripts/watchtower-manage.sh restart

# Atualiza automaticamente
# Notifica para validar após atualização
```

## 📖 Glossário

- **Poll**: Verificação periódica por atualizações
- **Monitor-only**: Modo que apenas monitora, sem aplicar atualizações
- **Rolling Restart**: Reiniciar containers um por vez
- **Cleanup**: Remover imagens antigas após atualização
- **Lifecycle Hooks**: Scripts executados antes/depois de atualizações

## 🎉 Conclusão

O Watchtower mantém seu Openclawd sempre atualizado com as últimas correções de segurança e melhorias, de forma automatizada e segura.

**Para começar:**

```bash
# 1. Ver status
./scripts/watchtower-manage.sh status

# 2. Configurar modo (recomendado: monitor)
./scripts/watchtower-manage.sh enable-monitor

# 3. Configurar notificações
./scripts/watchtower-manage.sh configure-notifications

# 4. Iniciar
./scripts/watchtower-manage.sh start

# 5. Acompanhar
./scripts/watchtower-manage.sh logs follow
```

**Pronto!** Seu sistema agora está sendo monitorado 24/7 para atualizações! 🚀
