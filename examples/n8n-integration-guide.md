# Guia de Integração com n8n - WhatsApp Automation Suite

Este guia mostra como automatizar completamente o WhatsApp Automation Suite usando n8n, sem necessidade de código.

## 🎯 Visão Geral

O n8n é uma plataforma de automação visual que permite criar fluxos de trabalho complexos através de uma interface gráfica, integrando perfeitamente com a Evolution API e Chatwoot.

## 🚀 Instalação do n8n

### 1. Instalar n8n via Docker

```bash
# Criar diretório para dados do n8n
mkdir -p n8n-data

# Executar n8n
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -v $(pwd)/n8n-data:/home/node/.n8n \
  -e N8N_BASIC_AUTH_ACTIVE=true \
  -e N8N_BASIC_AUTH_USER=admin \
  -e N8N_BASIC_AUTH_PASSWORD=admin123 \
  n8nio/n8n
```

### 2. Acessar o n8n

- **URL**: http://localhost:5678
- **Usuário**: admin
- **Senha**: admin123

## 🔧 Integração com Evolution API

### 1. Configurar Credenciais

1. No n8n, vá em **Settings** → **Credentials**
2. Clique em **Add Credential**
3. Selecione **HTTP Header Auth**
4. Configure:
   - **Name**: Evolution API
   - **Header Name**: apikey
   - **Header Value**: [sua-chave-api]

### 2. Criar Instância no Evolution API

1. Acesse http://localhost:8080/manager
2. Use sua chave de API para autenticar
3. Clique em **Create Instance**
4. Configure:
   - **Instance Name**: minha-instancia
   - **Token**: [token-gerado]
   - **QR Code**: Habilitado

## 📱 Fluxos de Automação com n8n

### 1. Fluxo: Resposta Automática a Mensagens

#### Configuração do Webhook
1. **Nó Webhook**:
   - **Method**: POST
   - **Path**: /webhook/message
   - **Response Mode**: Respond to Webhook

#### Processamento de Mensagem
2. **Nó Switch**:
   - **Conditions**:
     - `{{ $json.message.type === 'text' }}`
     - `{{ $json.message.text.toLowerCase().includes('preço') }}`
     - `{{ $json.message.text.toLowerCase().includes('entrega') }}`

#### Resposta Automática
3. **Nó HTTP Request**:
   - **Method**: POST
   - **URL**: `http://evolution-api:8080/message/sendText/minha-instancia`
   - **Headers**: 
     - `apikey`: [sua-chave-api]
   - **Body**:
     ```json
     {
       "number": "{{ $json.message.from }}",
       "text": "Resposta automática baseada na mensagem"
     }
     ```

### 2. Fluxo: Integração com Chatwoot

#### Receber Mensagem do WhatsApp
1. **Nó Webhook** (mesmo do fluxo anterior)

#### Criar Conversa no Chatwoot
2. **Nó HTTP Request**:
   - **Method**: POST
   - **URL**: `http://chatwoot-rails:3000/api/v1/accounts/1/conversations`
   - **Headers**:
     - `api_access_token`: [token-chatwoot]
   - **Body**:
     ```json
     {
       "inbox_id": 1,
       "contact_id": "{{ $json.message.from }}",
       "message": {
         "content": "{{ $json.message.text }}"
       }
     }
     ```

### 3. Fluxo: Notificações de Sistema

#### Trigger de Evento
1. **Nó Cron**:
   - **Cron Expression**: `0 */6 * * *` (a cada 6 horas)

#### Verificar Status
2. **Nó HTTP Request**:
   - **Method**: GET
   - **URL**: `http://evolution-api:8080/instance/connectionState/minha-instancia`

#### Enviar Notificação
3. **Nó HTTP Request**:
   - **Method**: POST
   - **URL**: `http://evolution-api:8080/message/sendText/minha-instancia`
   - **Body**:
     ```json
     {
       "number": "5511999999999",
       "text": "Status do sistema: {{ $json.state }}"
     }
     ```

## 🛒 Fluxos para E-commerce

### 1. Confirmação de Pedido

#### Trigger: Nova Venda
1. **Nó Webhook** (recebe dados da loja)

#### Enviar Confirmação
2. **Nó HTTP Request**:
   - **URL**: `http://evolution-api:8080/message/sendText/minha-instancia`
   - **Body**:
     ```json
     {
       "number": "{{ $json.customer.phone }}",
       "text": "✅ Pedido #{{ $json.order.id }} confirmado! Total: R$ {{ $json.order.total }}"
     }
     ```

### 2. Status de Entrega

#### Trigger: Atualização de Status
1. **Nó Webhook** (recebe atualização de entrega)

#### Enviar Status
2. **Nó HTTP Request**:
   - **URL**: `http://evolution-api:8080/message/sendText/minha-instancia`
   - **Body**:
     ```json
     {
       "number": "{{ $json.customer.phone }}",
       "text": "🚚 Seu pedido #{{ $json.order.id }} está {{ $json.status }}"
     }
     ```

## 📊 Fluxos de Analytics

### 1. Relatório Diário

#### Trigger: Diário
1. **Nó Cron**: `0 8 * * *` (8h da manhã)

#### Coletar Dados
2. **Nó HTTP Request**:
   - **URL**: `http://evolution-api:8080/chat/find/minha-instancia`

#### Processar e Enviar
3. **Nó Function** (processar dados)
4. **Nó HTTP Request** (enviar relatório)

### 2. Métricas de Performance

#### Coletar Métricas
1. **Nó HTTP Request** (dados do Chatwoot)
2. **Nó HTTP Request** (dados da Evolution API)

#### Gerar Relatório
3. **Nó Function** (calcular métricas)
4. **Nó Email** ou **HTTP Request** (enviar relatório)

## 🔔 Fluxos de Notificação

### 1. Alerta de Estoque Baixo

#### Trigger: Sistema de Estoque
1. **Nó Webhook** (recebe alerta)

#### Notificar Administradores
2. **Nó HTTP Request**:
   - **URL**: `http://evolution-api:8080/message/sendText/minha-instancia`
   - **Body**:
     ```json
     {
       "number": "5511999999999",
       "text": "⚠️ Estoque baixo: {{ $json.product.name }} - {{ $json.quantity }} unidades"
     }
     ```

### 2. Backup Automático

#### Trigger: Diário
1. **Nó Cron**: `0 2 * * *` (2h da manhã)

#### Executar Backup
2. **Nó Execute Command**:
   - **Command**: `./scripts/backup.sh`

#### Notificar Sucesso/Falha
3. **Nó Switch** (verificar resultado)
4. **Nó HTTP Request** (enviar notificação)

## 🎨 Templates de Fluxos

### Template 1: Atendimento Básico
```
Webhook → Switch (tipo de mensagem) → HTTP Request (resposta)
```

### Template 2: Integração Completa
```
Webhook → Chatwoot (criar conversa) → HTTP Request (resposta) → Chatwoot (atualizar)
```

### Template 3: Sistema de Tickets
```
Webhook → Switch (prioridade) → Chatwoot (criar ticket) → HTTP Request (notificar)
```

## 🔧 Configurações Avançadas

### 1. Variáveis de Ambiente no n8n

Configure no n8n:
- `EVOLUTION_API_URL`: http://evolution-api:8080
- `EVOLUTION_API_KEY`: [sua-chave]
- `CHATWOOT_URL`: http://chatwoot-rails:3000
- `CHATWOOT_TOKEN`: [token-chatwoot]

### 2. Tratamento de Erros

Use nós **Error Trigger** para:
- Falhas de conexão
- Mensagens inválidas
- Timeouts
- Rate limiting

### 3. Rate Limiting

Configure nos nós HTTP Request:
- **Timeout**: 30 segundos
- **Retry**: 3 tentativas
- **Delay**: 1 segundo entre tentativas

## 📱 Exemplos de Fluxos Prontos

### Fluxo 1: Resposta Automática Inteligente
```
Webhook → Switch (palavras-chave) → HTTP Request (resposta personalizada)
```

### Fluxo 2: Integração com CRM
```
Webhook → Chatwoot (criar contato) → CRM (sincronizar) → HTTP Request (confirmação)
```

### Fluxo 3: Sistema de Agendamento
```
Webhook → Switch (agendamento) → Calendar (verificar disponibilidade) → HTTP Request (confirmação)
```

## 🚀 Próximos Passos

1. **Instale o n8n** seguindo o guia acima
2. **Configure as credenciais** da Evolution API
3. **Crie sua primeira instância** no Evolution API
4. **Teste um fluxo simples** de resposta automática
5. **Expanda gradualmente** para fluxos mais complexos

## 💡 Dicas Importantes

- **Teste sempre** os fluxos antes de ativar
- **Use variáveis** para facilitar manutenção
- **Monitore os logs** do n8n e Evolution API
- **Faça backup** dos fluxos regularmente
- **Documente** seus fluxos para facilitar manutenção

Com o n8n, você pode automatizar praticamente qualquer processo relacionado ao WhatsApp sem escrever uma linha de código!
