# WhatsApp Automation Suite

Uma solução completa para automação do WhatsApp usando Evolution API e Chatwoot, containerizada com Docker.

## 📋 Visão Geral

Este projeto integra a Evolution API (para automação do WhatsApp) com o Chatwoot (plataforma de atendimento ao cliente) em uma arquitetura containerizada, proporcionando uma solução robusta para automação de comunicação via WhatsApp.

### 🚀 Funcionalidades

- **Evolution API v2.2.3**: API para automação do WhatsApp
- **Chatwoot v4.5.0**: Plataforma de atendimento ao cliente
- **n8n**: Plataforma de automação visual (sem código)
- **PostgreSQL 16**: Banco de dados principal (com pgvector para Chatwoot)
- **Redis 7.2**: Cache e sessões
- **PgAdmin 8.5**: Interface web para administração do PostgreSQL

## 🏗️ Arquitetura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Evolution     │    │    Chatwoot     │    │      n8n        │
│   API v2.2.3    │◄──►│   v4.5.0        │    │  Automation     │
│   (Port 3005)   │    │   (Port 3000)   │    │  (Port 3007)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │     Redis       │    │    PgAdmin      │
│   16 + pgvector │    │     7.2         │    │     8.5         │
│   (Port 3001)   │    │   (Port 3003)   │    │   (Port 3006)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📦 Pré-requisitos

- Docker 24.0+
- Docker Compose 2.0+
- Git
- 4GB RAM mínimo
- 10GB espaço em disco

## 🛠️ Instalação

### 1. Clone o repositório

```bash
git clone https://github.com/dbx0/whatsapp-automation-suit
cd whatsapp-automation-suit
```

### 2. Configure as variáveis de ambiente

```bash
# Copie os arquivos de exemplo
cp .env.example .env
cp evolution-api/.env.example evolution-api/.env

# Edite as configurações
nano .env
nano evolution-api/.env
```

### 2.1. Configure o range de portas (Opcional)

O sistema permite configurar um range personalizado de portas para evitar conflitos. Por exemplo, para usar o range 7000-7999:

```bash
# Usando o script automatizado (recomendado)
./scripts/setup.sh 7000

# Ou manualmente editando o .env
echo "PORT_RANGE_BASE=7000" >> .env
```

**Mapeamento de portas com PORT_RANGE_BASE=7000:**
- Chatwoot Rails: 7000
- PostgreSQL Chatwoot: 7001
- PostgreSQL Evolution: 7002
- Redis Chatwoot: 7003
- Redis Evolution: 7004
- Evolution API: 7005
- PgAdmin: 7006
- n8n: 7007

**URLs de acesso com range 7000:**
- Evolution API Manager: http://localhost:7005/manager
- Chatwoot: http://localhost:7000
- n8n Automation: http://localhost:7007
- PgAdmin: http://localhost:7006

### 3. Gere as chaves de segurança

**Para Chatwoot (SECRET_KEY_BASE):**
```bash
# Use um gerador online ou execute:
openssl rand -hex 64
```

**Para Evolution API (AUTHENTICATION_API_KEY):**
```bash
# Use um gerador UUID ou execute:
uuidgen
```

### 4. Prepare os diretórios de dados

```bash
# Crie os diretórios necessários
mkdir -p database/chatwoot/{postgres,redis}
mkdir -p database/evolution/{postgres,redis}
mkdir -p evolution-api/evolution_instances
```

### 5. Inicie os serviços

```bash
# Construa e inicie os containers
docker-compose up --build -d

# Aguarde alguns minutos para inicialização completa
```

### 6. Configure o banco de dados do Chatwoot

```bash
# Execute a migração do banco
docker-compose run --rm rails bundle exec rails db:chatwoot_prepare
```

## 🌐 Acessos

Após a instalação, você pode acessar:

**Portas padrão (PORT_RANGE_BASE=3000):**
- **Evolution API Manager**: http://localhost:3005/manager
- **Chatwoot**: http://localhost:3000
- **n8n Automation**: http://localhost:3007
- **PgAdmin**: http://localhost:3006

**Se você configurou um range personalizado (ex: PORT_RANGE_BASE=7000):**
- **Evolution API Manager**: http://localhost:7005/manager
- **Chatwoot**: http://localhost:7000
- **n8n Automation**: http://localhost:7007
- **PgAdmin**: http://localhost:7006

> 💡 **Dica**: Execute `./scripts/setup.sh` para reconfigurar as portas.

### Credenciais padrão:
**PgAdmin:**
- **Email**: admin@admin.com
- **Senha**: admin123

**n8n:**
- **Usuário**: admin
- **Senha**: admin123

## 🔧 Configuração

### Evolution API

1. Acesse o manager em http://localhost:3005/manager (ou porta configurada)
2. Crie uma nova instância
3. Configure a integração com Chatwoot

### Chatwoot

1. Acesse http://localhost:3000 (ou porta configurada)
2. Crie sua conta de administrador
3. Configure um inbox para API
4. Use as configurações fornecidas pela Evolution API

### n8n (Automação Visual)

#### Se instalado localmente:
1. Acesse http://localhost:3007 (ou porta configurada)
2. Faça login com as credenciais padrão
3. Configure as credenciais da Evolution API
4. Crie seus primeiros fluxos de automação

#### Se usando instância externa:
1. Acesse a URL configurada no setup
2. Configure as credenciais da Evolution API
3. Crie seus fluxos de automação

#### Gerenciamento do n8n:
```bash
# Verificar status
./scripts/manage-n8n.sh status

# Iniciar n8n local
./scripts/manage-n8n.sh start

# Parar n8n local
./scripts/manage-n8n.sh stop

# Ver logs
./scripts/manage-n8n.sh logs

# Backup dos fluxos
./scripts/manage-n8n.sh backup
```

#### Guia completo:
Consulte `examples/n8n-integration-guide.md` para instruções detalhadas

## 🔗 Integração Evolution API + Chatwoot

### Configuração Automática

Se a opção "Automatically Creates" estiver habilitada na Evolution API, o inbox será criado automaticamente no Chatwoot.

### Configuração Manual

1. No Chatwoot, vá em **Settings** → **Inbox** → **Add an Inbox**
2. Escolha **API** como tipo
3. Configure:
   - **Channel Name**: Nome da instância da Evolution API
   - **Webhook URL**: `https://sua-url-evolution/chatwoot/webhook/instance`

## 📱 Conectando WhatsApp

1. No Chatwoot, vá em **Contacts** → **New Contact**
2. Adicione um contato com o número do WhatsApp
3. Clique no contato → **New Message**
4. Escolha o inbox criado e envie a mensagem "iniciar"
5. Escaneie o QR Code gerado

## 🔒 Segurança

### Variáveis de Ambiente Críticas

- `SECRET_KEY_BASE`: Chave secreta do Chatwoot
- `AUTHENTICATION_API_KEY`: Chave de autenticação da Evolution API
- `POSTGRES_PASSWORD`: Senha do PostgreSQL
- `REDIS_PASSWORD`: Senha do Redis

### Recomendações de Segurança

1. **Altere todas as senhas padrão** antes de usar em produção
2. **Use HTTPS** em ambiente de produção
3. **Configure firewall** adequadamente
4. **Mantenha as imagens atualizadas**
5. **Faça backup regular** dos dados

## 📊 Monitoramento

### Logs dos Serviços

```bash
# Ver logs de todos os serviços
docker-compose logs -f

# Ver logs de um serviço específico
docker-compose logs -f evolution
docker-compose logs -f chatwoot-rails
```

### Status dos Containers

```bash
docker-compose ps
```

## 🔄 Atualizações

### Atualizar o Projeto

```bash
git pull origin main
docker-compose down
docker-compose up --build -d
```

### Backup e Restore

```bash
# Backup
docker-compose exec postgres-chatwoot pg_dump -U postgres chatwoot > backup_chatwoot.sql
docker-compose exec postgres-evolution pg_dump -U postgres evolution > backup_evolution.sql

# Restore
docker-compose exec -T postgres-chatwoot psql -U postgres chatwoot < backup_chatwoot.sql
docker-compose exec -T postgres-evolution psql -U postgres evolution < backup_evolution.sql
```

### Remoção Completa (Purge)

⚠️ **ATENÇÃO**: O script de purge remove **PERMANENTEMENTE** todos os dados!

```bash
./scripts/purge.sh
```

**O que o script de purge remove:**
- ✅ Todos os containers Docker
- ✅ Todos os volumes de dados
- ✅ Todos os arquivos de configuração (.env)
- ✅ Todos os logs
- ✅ Todas as imagens Docker
- ✅ Todas as redes Docker
- ✅ Todos os diretórios de dados
- ✅ Todos os arquivos temporários

**Confirmação dupla de segurança:**
O script requer duas confirmações:
1. Digite `PURGE` para confirmar
2. Digite `CONFIRMO` para finalizar

**Após o purge:**
```bash
# Para reinstalar limpo
./scripts/deploy.sh
```

## 🐛 Solução de Problemas

### Problemas Comuns

1. **Erro de conexão com banco de dados**
   ```bash
   docker-compose restart postgres-chatwoot postgres-evolution
   ```

2. **QR Code não aparece**
   - Verifique se a instância está ativa no Evolution API
   - Confirme se o webhook está configurado corretamente

3. **Chatwoot não carrega**
   ```bash
   docker-compose run --rm rails bundle exec rails db:chatwoot_prepare
   ```

### Logs de Debug

```bash
# Ver logs detalhados
docker-compose logs --tail=100 -f [service-name]
```

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 🙏 Agradecimentos

- [Evolution API](https://github.com/EvolutionAPI/evolution-api) - API para automação do WhatsApp
- [Chatwoot](https://github.com/chatwoot/chatwoot) - Plataforma de atendimento ao cliente

## 📞 Suporte

Para suporte e dúvidas:

- Abra uma [issue](https://github.com/dbx0/whatsapp-automation-suit/issues)
- Consulte a [documentação](docs/)
- Verifique os [exemplos](examples/)

---

**⚠️ Importante**: Este projeto é para fins educacionais e de desenvolvimento. Para uso em produção, certifique-se de configurar adequadamente a segurança e seguir as melhores práticas.
