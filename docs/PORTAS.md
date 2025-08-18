# Configuração de Range de Portas

## Visão Geral

O WhatsApp Automation Suite permite configurar um range personalizado de portas para evitar conflitos com outros serviços em execução no seu sistema.

## Como Funciona

O sistema usa uma variável de ambiente `PORT_RANGE_BASE` que define a porta inicial do range. Todas as outras portas são calculadas automaticamente a partir dessa base.

### Mapeamento de Portas

| Serviço | Porta Externa | Porta Interna | Descrição |
|---------|---------------|---------------|-----------|
| Chatwoot Rails | `PORT_RANGE_BASE` | 3000 | Interface web do Chatwoot |
| PostgreSQL Chatwoot | `PORT_RANGE_BASE + 1` | 5432 | Banco de dados do Chatwoot |
| PostgreSQL Evolution | `PORT_RANGE_BASE + 2` | 5432 | Banco de dados da Evolution API |
| Redis Chatwoot | `PORT_RANGE_BASE + 3` | 6379 | Cache do Chatwoot |
| Redis Evolution | `PORT_RANGE_BASE + 4` | 6379 | Cache da Evolution API |
| Evolution API | `PORT_RANGE_BASE + 5` | 8080 | API de automação do WhatsApp |
| PgAdmin | `PORT_RANGE_BASE + 6` | 80 | Interface de administração do PostgreSQL |
| n8n | `PORT_RANGE_BASE + 7` | 5678 | Plataforma de automação visual |

## Exemplos de Configuração

### Range 3000-3007 (Padrão)
```bash
PORT_RANGE_BASE=3000
```

**URLs de acesso:**
- Chatwoot: http://localhost:3000
- Evolution API: http://localhost:3005
- PgAdmin: http://localhost:3006
- n8n: http://localhost:3007

### Range 7000-7007
```bash
PORT_RANGE_BASE=7000
```

**URLs de acesso:**
- Chatwoot: http://localhost:7000
- Evolution API: http://localhost:7005
- PgAdmin: http://localhost:7006
- n8n: http://localhost:7007

### Range 8000-8007
```bash
PORT_RANGE_BASE=8000
```

**URLs de acesso:**
- Chatwoot: http://localhost:8000
- Evolution API: http://localhost:8005
- PgAdmin: http://localhost:8006
- n8n: http://localhost:8007

## Configuração Automática

### Usando o Script

O script `setup.sh` facilita a configuração:

```bash
# Configurar range 7000-7007
./scripts/setup.sh 7000

# Configurar range 8000-8007
./scripts/setup.sh 8000

# Executar interativamente
./scripts/setup.sh
```

### Configuração Manual

1. Edite o arquivo `.env`:
```bash
nano .env
```

2. Adicione ou modifique a linha:
```bash
PORT_RANGE_BASE=7000
```

3. Salve o arquivo e reinicie os containers:
```bash
docker-compose down
docker-compose up -d
```

## Verificação de Portas

### Verificar Mapeamento Atual
```bash
./scripts/setup.sh
```

### Verificar Portas em Uso
```bash
# Verificar se as portas estão disponíveis
lsof -i :7000
lsof -i :7001
lsof -i :7002
# ... etc
```

### Verificar Status dos Containers
```bash
docker-compose ps
```

## Solução de Problemas

### Porta Já em Uso

Se uma porta estiver em uso, você pode:

1. **Parar o serviço que está usando a porta:**
```bash
# Encontrar o processo
lsof -i :7000

# Parar o processo
kill -9 <PID>
```

2. **Usar um range diferente:**
```bash
./scripts/setup.sh 8000
```

### Containers Não Iniciam

1. **Verificar logs:**
```bash
docker-compose logs
```

2. **Verificar configuração de portas:**
```bash
cat .env | grep PORT_RANGE_BASE
```

3. **Reiniciar com configuração limpa:**
```bash
docker-compose down
docker-compose up -d
```

## Considerações de Segurança

### Portas Privilegiadas
- Evite usar portas abaixo de 1024 (portas privilegiadas)
- O range recomendado é 3000-9999

### Firewall
- Configure seu firewall para permitir acesso às portas do range
- Em produção, considere usar um proxy reverso

### Acesso Externo
- Por padrão, os serviços são acessíveis apenas via localhost
- Para acesso externo, configure adequadamente seu firewall e proxy

## Migração de Configuração

### Alterar Range Existente

1. **Parar os containers:**
```bash
docker-compose down
```

2. **Atualizar configuração:**
```bash
./scripts/setup.sh 8000
```

3. **Reiniciar:**
```bash
docker-compose up -d
```

### Backup e Restauração

1. **Backup da configuração atual:**
```bash
cp .env .env.backup
```

2. **Restaurar configuração:**
```bash
cp .env.backup .env
docker-compose up -d
```

## Scripts Úteis

### Verificar Configuração Atual
```bash
#!/bin/bash
if [ -f ".env" ]; then
    PORT_BASE=$(grep "^PORT_RANGE_BASE=" .env | cut -d'=' -f2)
    echo "Range de portas atual: $PORT_BASE"
    echo "URLs de acesso:"
    echo "- Chatwoot: http://localhost:$PORT_BASE"
    echo "- Evolution API: http://localhost:$((PORT_BASE + 5))"
    echo "- PgAdmin: http://localhost:$((PORT_BASE + 6))"
    echo "- n8n: http://localhost:$((PORT_BASE + 7))"
else
    echo "Arquivo .env não encontrado"
fi
```

### Testar Conectividade
```bash
#!/bin/bash
PORT_BASE=$(grep "^PORT_RANGE_BASE=" .env | cut -d'=' -f2)
echo "Testando conectividade..."
curl -s http://localhost:$PORT_BASE > /dev/null && echo "Chatwoot: OK" || echo "Chatwoot: ERRO"
curl -s http://localhost:$((PORT_BASE + 5)) > /dev/null && echo "Evolution API: OK" || echo "Evolution API: ERRO"
curl -s http://localhost:$((PORT_BASE + 6)) > /dev/null && echo "PgAdmin: OK" || echo "PgAdmin: ERRO"
curl -s http://localhost:$((PORT_BASE + 7)) > /dev/null && echo "n8n: OK" || echo "n8n: ERRO"
```
