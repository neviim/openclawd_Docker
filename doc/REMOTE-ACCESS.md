# 🌐 Guia de Acesso Remoto - Openclawd

Este guia explica como configurar e usar o Openclawd de outras máquinas na rede.

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Configuração Rápida](#configuração-rápida)
- [Configuração Detalhada](#configuração-detalhada)
- [Segurança](#segurança)
- [Exemplos de Uso](#exemplos-de-uso)
- [Solução de Problemas](#solução-de-problemas)

## 🎯 Visão Geral

O Openclawd pode ser acessado de outras máquinas através de:

1. **Modo Direto**: Expondo as portas diretamente (simples, menos seguro)
2. **Modo Proxy**: Usando Nginx como reverse proxy (recomendado, mais seguro)

### Arquitetura de Acesso Remoto

```
┌─────────────────────────────────────────────────────┐
│                  Máquina Cliente                    │
│              curl http://servidor/api/              │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼ Porta 80
┌─────────────────────────────────────────────────────┐
│              Servidor Openclawd                     │
│                                                     │
│  ┌────────────────────────────────────────────┐     │
│  │         Nginx Reverse Proxy                │     │
│  │  - Rate Limiting                           │     │
│  │  - Autenticação (opcional)                 │     │
│  │  - SSL/TLS (opcional)                      │     │
│  │  - CORS                                    │     │
│  └───────────┬──────────────┬─────────────────┘     │
│              │              │                       │
│         ┌────▼────┐   ┌────▼────────┐               │
│         │Openclawd│   │   Kanban    │               │
│         │   API   │   │  Dashboard  │               │
│         └─────────┘   └─────────────┘               │
└─────────────────────────────────────────────────────┘
```

## 🚀 Configuração Rápida

### Passo 1: Ativar Acesso Remoto

```bash
cd ~/Developer/openclawd_Docker
./scripts/remote-access.sh enable
```

### Passo 2: Configurar Firewall

```bash
# Ubuntu/Debian
sudo ufw allow 80/tcp
sudo ufw reload

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --reload
```

### Passo 3: Descobrir seu IP

```bash
# Ver IP da máquina
hostname -I

# Ou
ip addr show
```

### Passo 4: Acessar de Outra Máquina

```bash
# Substituir 192.168.1.100 pelo IP do servidor
curl http://192.168.1.100/api/activities
```

**Pronto!** Você já pode acessar o Openclawd remotamente.

## ⚙️ Configuração Detalhada

### Modo 1: Acesso Direto (Sem Nginx)

Expõe as portas 3000 e 8080 diretamente:

```bash
# Editar docker-compose.yml
# Trocar de:
#   ports:
#     - "3000:3000"
# Para:
#   ports:
#     - "0.0.0.0:3000:3000"

# Ou usar o override
docker compose -f docker-compose.yml -f docker-compose.remote.yml up -d
```

**Acessar:**
- Dashboard: `http://SEU_IP:8080`
- API: `http://SEU_IP:3000/api/activities`

### Modo 2: Com Nginx (Recomendado)

Usa Nginx como proxy reverso na porta 80:

```bash
./scripts/remote-access.sh enable
```

**Acessar:**
- Dashboard: `http://SEU_IP`
- API: `http://SEU_IP/api/activities`

**Vantagens:**
- ✅ Porta padrão (80)
- ✅ Rate limiting
- ✅ Autenticação opcional
- ✅ SSL/TLS fácil de configurar
- ✅ Logs centralizados
- ✅ CORS configurável

## 🔒 Segurança

### 1. Ativar Autenticação Básica

```bash
# Adicionar usuário
./scripts/remote-access.sh add-user admin

# Digite a senha quando solicitado

# Ativar autenticação
./scripts/remote-access.sh enable-auth

# Listar usuários
./scripts/remote-access.sh list-users
```

**Usar com autenticação:**
```bash
curl -u admin:senha http://SEU_IP/api/activities
```

### 2. Configurar CORS

```bash
./scripts/remote-access.sh configure-cors
```

Opções:
- Permitir todos os domínios: `*`
- Domínios específicos: `https://app1.com,https://app2.com`

### 3. Configurar HTTPS/SSL

#### Usando Let's Encrypt (Recomendado):

```bash
# Instalar certbot
sudo apt-get install certbot

# Obter certificado
sudo certbot certonly --standalone -d seu-dominio.com

# Copiar certificados
sudo cp /etc/letsencrypt/live/seu-dominio.com/fullchain.pem config/nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/seu-dominio.com/privkey.pem config/nginx/ssl/key.pem
sudo chown $USER:$USER config/nginx/ssl/*.pem

# Descomentar seção HTTPS no arquivo:
nano config/nginx/conf.d/openclawd.conf

# Reiniciar
docker compose -f docker-compose.yml -f docker-compose.remote.yml restart nginx-proxy
```

#### Usando Certificado Auto-assinado (Desenvolvimento):

```bash
# Gerar certificado
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout config/nginx/ssl/key.pem \
  -out config/nginx/ssl/cert.pem \
  -subj "/CN=localhost"

# Descomentar seção HTTPS no nginx
# Reiniciar serviço
```

### 4. Restringir IPs

Editar `config/nginx/conf.d/openclawd.conf`:

```nginx
# Adicionar dentro do bloco location /api/
allow 192.168.1.0/24;  # Permitir rede local
allow 10.0.0.0/8;      # Permitir rede interna
deny all;              # Negar todo o resto
```

### 5. Rate Limiting

Já configurado por padrão:
- API: 30 requisições por minuto
- Geral: 100 requisições por minuto

Ajustar em `config/nginx/nginx.conf`:

```nginx
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=30r/m;
```

## 📝 Exemplos de Uso

### De Outra Máquina Linux/Mac

```bash
# Definir IP do servidor
SERVER="192.168.1.100"

# Listar atividades
curl http://$SERVER/api/activities

# Com autenticação
curl -u admin:senha http://$SERVER/api/activities

# Criar atividade
curl -X POST http://$SERVER/api/activities \
  -H "Content-Type: application/json" \
  -d '{
    "type": "remote_task",
    "description": "Tarefa criada remotamente",
    "metadata": {"source": "curl"}
  }'

# Ver apenas atividades concluídas
curl http://$SERVER/api/activities?status=completed

# Health check
curl http://$SERVER/health

# Status do sistema
curl http://$SERVER/status
```

### De Windows (PowerShell)

```powershell
# Definir servidor
$SERVER = "192.168.1.100"

# Listar atividades
Invoke-RestMethod -Uri "http://$SERVER/api/activities"

# Com autenticação
$cred = Get-Credential
Invoke-RestMethod -Uri "http://$SERVER/api/activities" -Credential $cred

# Criar atividade
$body = @{
    type = "remote_task"
    description = "Tarefa do Windows"
    metadata = @{ source = "powershell" }
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://$SERVER/api/activities" `
    -Method Post `
    -ContentType "application/json" `
    -Body $body
```

### De Python

```python
import requests

SERVER = "http://192.168.1.100"

# Sem autenticação
response = requests.get(f"{SERVER}/api/activities")
activities = response.json()
print(activities)

# Com autenticação
response = requests.get(
    f"{SERVER}/api/activities",
    auth=("admin", "senha")
)

# Criar atividade
data = {
    "type": "python_task",
    "description": "Tarefa criada via Python",
    "metadata": {"language": "python"}
}
response = requests.post(
    f"{SERVER}/api/activities",
    json=data
)
print(response.json())
```

### De JavaScript/Node.js

```javascript
const SERVER = "http://192.168.1.100";

// Usando fetch
async function listActivities() {
    const response = await fetch(`${SERVER}/api/activities`);
    const data = await response.json();
    console.log(data);
}

// Com autenticação
async function listActivitiesAuth() {
    const auth = btoa("admin:senha");
    const response = await fetch(`${SERVER}/api/activities`, {
        headers: {
            "Authorization": `Basic ${auth}`
        }
    });
    const data = await response.json();
    console.log(data);
}

// Criar atividade
async function createActivity() {
    const response = await fetch(`${SERVER}/api/activities`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            type: "js_task",
            description: "Tarefa JavaScript",
            metadata: { language: "javascript" }
        })
    });
    const data = await response.json();
    console.log(data);
}
```

## 🛠️ Comandos Úteis

```bash
# Ver informações de acesso
./scripts/remote-access.sh info

# Menu interativo
./scripts/remote-access.sh menu

# Desativar acesso remoto
./scripts/remote-access.sh disable

# Ver logs do Nginx
docker compose logs -f nginx-proxy

# Ver estatísticas do Nginx
curl http://localhost/nginx_status
```

## 🔍 Solução de Problemas

### Não Consigo Acessar de Outra Máquina

1. **Verificar se o serviço está rodando:**
```bash
docker compose ps
```

2. **Testar localmente:**
```bash
curl http://localhost/health
```

3. **Verificar firewall:**
```bash
sudo ufw status
# Deve mostrar: 80/tcp ALLOW
```

4. **Verificar IP:**
```bash
hostname -I
# Use este IP de outras máquinas
```

5. **Ping da outra máquina:**
```bash
ping SEU_IP
```

### Erro 502 Bad Gateway

```bash
# Verificar se backend está rodando
docker compose ps

# Ver logs
docker compose logs openclawd
docker compose logs kanban-monitor

# Reiniciar serviços
docker compose restart
```

### Erro 401 Unauthorized

Autenticação está ativada. Use:
```bash
curl -u usuario:senha http://SEU_IP/api/activities
```

Ou desative:
```bash
./scripts/remote-access.sh disable-auth
```

### Erro 429 Too Many Requests

Rate limit atingido. Aguarde um minuto ou ajuste o limite em:
`config/nginx/nginx.conf`

### CORS Error no Browser

```bash
./scripts/remote-access.sh configure-cors
# Escolha permitir todos os domínios
```

### Performance Lenta

```bash
# Ver estatísticas
docker stats

# Verificar logs do Nginx
docker compose logs nginx-proxy | grep -i slow

# Aumentar rate limit se necessário
nano config/nginx/nginx.conf
```

## 📊 Monitoramento

### Logs

```bash
# Logs da API
tail -f logs/activity.log

# Logs do Nginx
tail -f logs/nginx/access.log
tail -f logs/nginx/error.log

# Logs em tempo real
./scripts/manage.sh logs
```

### Métricas

```bash
# Status do Nginx
curl http://localhost/nginx_status

# Métricas do sistema
curl http://SEU_IP/api/stats

# Dashboard visual
# Abra http://SEU_IP no navegador
```

## 🔐 Melhores Práticas de Segurança

1. ✅ **SEMPRE** use autenticação em ambientes de produção
2. ✅ **SEMPRE** use HTTPS/SSL em redes públicas
3. ✅ Configure rate limiting adequado
4. ✅ Mantenha os logs e monitore acessos suspeitos
5. ✅ Use senhas fortes
6. ✅ Restrinja IPs se possível
7. ✅ Mantenha o sistema atualizado
8. ✅ Faça backups regulares

## 🌟 Cenários de Uso

### 1. Acesso na Rede Local (Casa/Escritório)

```bash
# Configuração simples, sem autenticação
./scripts/remote-access.sh enable

# Acessar de qualquer dispositivo na rede
# Celular, tablet, outro computador
```

### 2. Servidor em Produção (Internet)

```bash
# Ativar acesso remoto
./scripts/remote-access.sh enable

# Configurar HTTPS
# (seguir instruções acima)

# Ativar autenticação
./scripts/remote-access.sh add-user admin
./scripts/remote-access.sh enable-auth

# Configurar firewall robusto
sudo ufw default deny incoming
sudo ufw allow 22/tcp  # SSH
sudo ufw allow 80/tcp  # HTTP
sudo ufw allow 443/tcp # HTTPS
sudo ufw enable
```

### 3. Integração com Aplicações

```bash
# Configurar CORS
./scripts/remote-access.sh configure-cors

# Criar usuário de API
./scripts/remote-access.sh add-user api-user

# Usar nas aplicações
curl -u api-user:senha http://SEU_IP/api/...
```

## 📚 Recursos Adicionais

- [Nginx Documentation](https://nginx.org/en/docs/)
- [Let's Encrypt](https://letsencrypt.org/)
- [OWASP Security](https://owasp.org/)

## 🆘 Suporte

Se encontrar problemas:

1. Verifique esta documentação
2. Execute: `./scripts/remote-access.sh info`
3. Verifique logs: `./scripts/manage.sh logs`
4. Teste health: `curl http://localhost/health`

## 🎉 Pronto!

Agora você pode acessar o Openclawd de qualquer máquina na sua rede (ou internet, se configurado)!

**URLs Úteis:**
- Dashboard: `http://SEU_IP`
- API: `http://SEU_IP/api/activities`
- Health: `http://SEU_IP/health`
- Status: `http://SEU_IP/status`
