# 🚀 Guia Rápido - Acesso Remoto em 3 Passos

## ⚡ Configuração Rápida

### Passo 1: Ativar Acesso Remoto
```bash
cd ~/Developer/openclawd_Docker
./scripts/remote-access.sh enable
```

### Passo 2: Configurar Firewall
```bash
sudo ufw allow 80/tcp
```

### Passo 3: Descobrir seu IP
```bash
hostname -I
```

**Pronto!** Agora acesse de outra máquina:

```bash
# Substituir 192.168.1.100 pelo seu IP
curl http://192.168.1.100/api/activities
```

---

## 🌐 URLs de Acesso

**De outra máquina na rede:**

- **Dashboard:** `http://SEU_IP/`
- **API:** `http://SEU_IP/api/activities`
- **Status:** `http://SEU_IP/status`
- **Health:** `http://SEU_IP/health`

---

## 🔧 Comandos Úteis

```bash
# Ver informações completas
./scripts/remote-access.sh info

# Menu interativo
./scripts/remote-access.sh menu

# Desativar acesso remoto
./scripts/remote-access.sh disable
```

---

## 🔒 Adicionar Segurança (Opcional)

### Adicionar Autenticação
```bash
# Criar usuário
./scripts/remote-access.sh add-user admin

# Ativar autenticação
./scripts/remote-access.sh enable-auth

# Usar com autenticação
curl -u admin:senha http://SEU_IP/api/activities
```

---

## 📝 Exemplos Práticos

### Bash/Curl
```bash
# Listar atividades
curl http://192.168.1.100/api/activities

# Criar atividade
curl -X POST http://192.168.1.100/api/activities \
  -H "Content-Type: application/json" \
  -d '{"type": "test", "description": "Teste remoto"}'
```

### Python
```bash
cd examples
python3 python_client.py 192.168.1.100
```

### Node.js
```bash
cd examples
node nodejs_client.js 192.168.1.100
```

### Script de Teste Completo
```bash
cd examples
./test-remote-api.sh 192.168.1.100
```

---

## 🆘 Problemas?

### Não consigo acessar

1. **Verificar se está rodando:**
```bash
./scripts/manage.sh status
```

2. **Testar localmente primeiro:**
```bash
curl http://localhost/health
```

3. **Verificar firewall:**
```bash
sudo ufw status
```

4. **Ver logs:**
```bash
./scripts/manage.sh logs
```

### Erro "Connection refused"

```bash
# Verificar se serviço está ativo
docker compose ps

# Reiniciar
./scripts/manage.sh restart
```

### Erro "401 Unauthorized"

Autenticação está ativada. Use:
```bash
curl -u usuario:senha http://SEU_IP/api/activities
```

Ou desative:
```bash
./scripts/remote-access.sh disable-auth
```

---

## 📚 Documentação Completa

Para mais detalhes, veja:

- **[REMOTE-ACCESS.md](./REMOTE-ACCESS.md)** - Guia completo de acesso remoto
- **[README.md](README.md)** - Documentação principal
- **[examples/README.md](examples/README.md)** - Exemplos de código

---

## ✅ Checklist

- [ ] Acesso remoto ativado (`./scripts/remote-access.sh enable`)
- [ ] Firewall configurado (`sudo ufw allow 80/tcp`)
- [ ] IP do servidor descoberto (`hostname -I`)
- [ ] Teste de outra máquina funcionando (`curl http://SEU_IP/health`)
- [ ] Dashboard acessível no navegador (`http://SEU_IP`)
- [ ] (Opcional) Autenticação configurada
- [ ] (Opcional) HTTPS configurado

---

## 🎯 Próximos Passos

Depois de configurar o acesso remoto:

1. ✅ Testar API de outra máquina
2. ✅ Acessar Dashboard no navegador
3. ✅ Integrar com suas aplicações
4. ✅ Configurar monitoramento
5. ✅ Configurar backups automáticos

**Divirta-se!** 🚀
