# Guia de Instalação - WhatsApp Automation Suite

Este guia fornece instruções detalhadas para instalar e configurar o WhatsApp Automation Suite em seu ambiente.

## 📋 Pré-requisitos

### Requisitos do Sistema
- **Sistema Operacional**: Linux (Ubuntu 20.04+), macOS 10.15+, ou Windows 10/11 com WSL2
- **RAM**: Mínimo 4GB, recomendado 8GB+
- **Espaço em Disco**: Mínimo 10GB livre
- **Processador**: 2 cores mínimo, 4 cores recomendado

### Software Necessário
- **Docker**: Versão 24.0 ou superior
- **Docker Compose**: Versão 2.0 ou superior
- **Git**: Para clonar o repositório

## 🚀 Instalação Rápida

### 1. Clone o Repositório

```bash
git clone <repository-url>
cd whatsapp-automation-suit
```

### 2. Execute o Script de Configuração

```bash
./scripts/setup.sh
```

O script irá:
- Verificar se o Docker está instalado
- Criar arquivos de configuração
- Gerar chaves de segurança automaticamente
- Criar diretórios necessários
- Construir e iniciar os containers
- Configurar o banco de dados

## 🔧 Instalação Manual

Se preferir fazer a instalação manualmente, siga estes passos:

### 1. Preparar o Ambiente

```bash
# Criar diretórios necessários
mkdir -p database/chatwoot/{postgres,redis,init}
mkdir -p database/evolution/{postgres,redis,init}
mkdir -p evolution-api/{evolution_instances,logs}
```

### 2. Configurar Variáveis de Ambiente

```bash
# Copiar arquivos de exemplo
cp env.example .env
cp evolution-api/env.example evolution-api/.env

# Editar configurações
nano .env
nano evolution-api/.env
```

### 3. Gerar Chaves de Segurança

```bash
# Para Chatwoot (SECRET_KEY_BASE)
openssl rand -hex 64

# Para Evolution API (AUTHENTICATION_API_KEY)
uuidgen
```

### 4. Iniciar os Serviços

```bash
# Construir e iniciar containers
docker-compose up --build -d

# Aguardar inicialização (2-3 minutos)
sleep 180
```

### 5. Configurar Banco de Dados

```bash
# Executar migração do Chatwoot
docker-compose run --rm chatwoot-rails bundle exec rails db:chatwoot_prepare
```

## 🌐 Acessos

Após a instalação, você pode acessar:

| Serviço | URL | Descrição |
|---------|-----|-----------|
| Evolution API Manager | http://localhost:8080/manager | Gerenciador da Evolution API |
| Chatwoot | http://localhost:8081 | Interface do Chatwoot |
| PgAdmin | http://localhost:8082 | Administração do PostgreSQL |

### Credenciais Padrão

**PgAdmin:**
- Email: `admin@admin.com`
- Senha: `admin123`

## 🔧 Configuração Inicial

### 1. Configurar Evolution API

1. Acesse http://localhost:8080/manager
2. Crie uma nova instância
3. Configure a integração com Chatwoot

### 2. Configurar Chatwoot

1. Acesse http://localhost:8081
2. Crie sua conta de administrador
3. Configure um inbox para API
4. Use as configurações fornecidas pela Evolution API

### 3. Conectar WhatsApp

1. No Chatwoot, vá em **Contacts** → **New Contact**
2. Adicione um contato com o número do WhatsApp
3. Clique no contato → **New Message**
4. Escolha o inbox criado e envie a mensagem "iniciar"
5. Escaneie o QR Code gerado

## 🔒 Configurações de Segurança

### Alterar Senhas Padrão

**PgAdmin:**
```bash
# Editar arquivo .env
PGADMIN_EMAIL=seu-email@exemplo.com
PGADMIN_PASSWORD=sua-senha-segura
```

**PostgreSQL:**
```bash
# Editar arquivo .env
POSTGRES_PASSWORD=sua-senha-postgres-segura
EVOLUTION_POSTGRES_PASSWORD=sua-senha-evolution-segura
```

**Redis:**
```bash
# Editar arquivo .env
REDIS_PASSWORD=sua-senha-redis-segura
```

### Configurar HTTPS (Produção)

1. Obter certificados SSL
2. Configurar Nginx para HTTPS
3. Atualizar variáveis de ambiente

## 📊 Monitoramento

### Verificar Status dos Serviços

```bash
# Status dos containers
docker-compose ps

# Logs em tempo real
docker-compose logs -f

# Logs de um serviço específico
docker-compose logs -f evolution-api
```

### Health Checks

```bash
# Verificar saúde dos serviços
curl http://localhost:8080/health
curl http://localhost:8081/health
curl http://localhost:8082/health
```

## 🔄 Manutenção

### Backup

```bash
# Executar backup completo
./scripts/backup.sh
```

### Atualizações

```bash
# Parar serviços
docker-compose down

# Atualizar código
git pull origin main

# Reconstruir e iniciar
docker-compose up --build -d
```

### Limpeza

```bash
# Limpar containers não utilizados
docker system prune -f

# Limpar volumes não utilizados
docker volume prune -f
```

## 🐛 Solução de Problemas

### Problemas Comuns

**1. Erro de conexão com banco de dados**
```bash
# Reiniciar containers de banco
docker-compose restart postgres-chatwoot postgres-evolution
```

**2. QR Code não aparece**
- Verifique se a instância está ativa no Evolution API
- Confirme se o webhook está configurado corretamente

**3. Chatwoot não carrega**
```bash
# Reexecutar migração
docker-compose run --rm chatwoot-rails bundle exec rails db:chatwoot_prepare
```

**4. Containers não iniciam**
```bash
# Verificar logs
docker-compose logs

# Verificar recursos do sistema
docker system df
```

### Logs de Debug

```bash
# Logs detalhados
docker-compose logs --tail=100 -f [service-name]

# Logs com timestamp
docker-compose logs -t -f [service-name]
```

## 📞 Suporte

Se encontrar problemas:

1. Verifique os logs dos containers
2. Consulte a documentação
3. Abra uma issue no repositório
4. Verifique se todos os pré-requisitos estão atendidos

## 🔗 Links Úteis

- [Documentação da Evolution API](https://doc.evolution-api.com/)
- [Documentação do Chatwoot](https://www.chatwoot.com/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
