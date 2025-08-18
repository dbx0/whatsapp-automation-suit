#!/bin/bash

# ============================================================================
# WHATSAPP AUTOMATION SUITE - SETUP SCRIPT
# ============================================================================
# Script para configuração inicial do projeto
# ============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Verificar se o Docker está instalado
check_docker() {
    print_message "Verificando se o Docker está instalado..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker não está instalado. Por favor, instale o Docker primeiro."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose não está instalado. Por favor, instale o Docker Compose primeiro."
        exit 1
    fi
    
    print_message "Docker e Docker Compose encontrados!"
}

# Verificar se os arquivos de configuração existem
check_config_files() {
    print_message "Verificando arquivos de configuração..."
    
    if [ ! -f ".env" ]; then
        print_warning "Arquivo .env não encontrado. Copiando de env.example..."
        cp env.example .env
        print_message "Arquivo .env criado. Por favor, edite as configurações."
    fi
    
    if [ ! -f "evolution-api/.env" ]; then
        print_warning "Arquivo evolution-api/.env não encontrado. Copiando de env.example..."
        cp evolution-api/env.example evolution-api/.env
        print_message "Arquivo evolution-api/.env criado. Por favor, edite as configurações."
    fi
}

# Função para validar se a porta é um número válido
validate_port() {
    local port=$1
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1024 ] || [ "$port" -gt 65535 ]; then
        print_error "Porta inválida! Deve ser um número entre 1024 e 65535."
        return 1
    fi
    return 0
}

# Função para verificar se as portas estão disponíveis
check_port_availability() {
    local base_port=$1
    local ports=($base_port $((base_port + 1)) $((base_port + 2)) $((base_port + 3)) $((base_port + 4)) $((base_port + 5)) $((base_port + 6)) $((base_port + 7)))
    
    print_message "Verificando disponibilidade das portas..."
    
    for port in "${ports[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            print_warning "Porta $port já está em uso!"
            return 1
        fi
    done
    
    print_message "Todas as portas estão disponíveis!"
    return 0
}

# Função para exibir o mapeamento de portas
show_port_mapping() {
    local base_port=$1
    print_header "MAPA DE PORTAS CONFIGURADO"
    echo "Base Port: $base_port"
    echo ""
    echo "Serviço                    | Porta Externa | Porta Interna"
    echo "---------------------------|---------------|---------------"
    echo "Chatwoot Rails             | $base_port     | 3000"
    echo "PostgreSQL Chatwoot        | $((base_port + 1))     | 5432"
    echo "PostgreSQL Evolution       | $((base_port + 2))     | 5432"
    echo "Redis Chatwoot             | $((base_port + 3))     | 6379"
    echo "Redis Evolution            | $((base_port + 4))     | 6379"
    echo "Evolution API              | $((base_port + 5))     | 8080"
    echo "PgAdmin                    | $((base_port + 6))     | 80"
    echo "n8n (opcional)             | $((base_port + 7))     | 5678"
    echo ""
    echo "URLs de acesso:"
    echo "Chatwoot: http://localhost:$base_port"
    echo "Evolution API: http://localhost:$((base_port + 5))"
    echo "PgAdmin: http://localhost:$((base_port + 6))"
    echo "n8n: http://localhost:$((base_port + 7))"
    echo ""
}

# Função para atualizar as variáveis de porta no arquivo .env
update_env_file() {
    local base_port=$1
    
    print_message "Atualizando arquivo .env..."
    
    # Criar arquivo temporário
    local temp_file=$(mktemp)
    
    # Processar o arquivo .env linha por linha
    while IFS= read -r line; do
        case "$line" in
            # Atualizar PORT_RANGE_BASE
            PORT_RANGE_BASE=*)
                echo "PORT_RANGE_BASE=$base_port" >> "$temp_file"
                ;;
            # Remover variáveis individuais existentes
            PORT_CHATWOOT=*|PORT_POSTGRES_CHATWOOT=*|PORT_POSTGRES_EVOLUTION=*|PORT_REDIS_CHATWOOT=*|PORT_REDIS_EVOLUTION=*|PORT_EVOLUTION_API=*|PORT_PGADMIN=*|PORT_N8N=*)
                # Pular estas linhas (serão adicionadas novamente)
                ;;
            # Manter outras linhas inalteradas
            *)
                echo "$line" >> "$temp_file"
                ;;
        esac
    done < .env
    
    # Adicionar variáveis individuais no final
    echo "" >> "$temp_file"
    echo "# Portas individuais dos serviços" >> "$temp_file"
    echo "PORT_CHATWOOT=$base_port" >> "$temp_file"
    echo "PORT_POSTGRES_CHATWOOT=$((base_port + 1))" >> "$temp_file"
    echo "PORT_POSTGRES_EVOLUTION=$((base_port + 2))" >> "$temp_file"
    echo "PORT_REDIS_CHATWOOT=$((base_port + 3))" >> "$temp_file"
    echo "PORT_REDIS_EVOLUTION=$((base_port + 4))" >> "$temp_file"
    echo "PORT_EVOLUTION_API=$((base_port + 5))" >> "$temp_file"
    echo "PORT_PGADMIN=$((base_port + 6))" >> "$temp_file"
    echo "PORT_N8N=$((base_port + 7))" >> "$temp_file"
    
    # Substituir o arquivo original
    mv "$temp_file" .env
    
    print_message "Arquivo .env atualizado com sucesso!"
}

# Configurar range de portas
configure_port_range() {
    print_header "CONFIGURAÇÃO DE RANGE DE PORTAS"
    echo ""
    
    # Verificar se foi fornecido um argumento
    if [ $# -eq 1 ]; then
        PORT_RANGE_BASE=$1
    else
        # Solicitar input do usuário
        echo "Configure o range de portas para os containers."
        echo "Exemplo: Para usar o range 7000-7999, digite 7000"
        echo ""
        read -p "Digite a porta base (padrão: 3000): " PORT_RANGE_BASE
        PORT_RANGE_BASE=${PORT_RANGE_BASE:-3000}
    fi
    
    # Validar a porta
    if ! validate_port "$PORT_RANGE_BASE"; then
        exit 1
    fi
    
    # Verificar disponibilidade das portas
    if ! check_port_availability "$PORT_RANGE_BASE"; then
        print_warning "Algumas portas estão em uso. Continue mesmo assim? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_message "Configuração cancelada."
            exit 1
        fi
    fi
    
    # Atualizar o arquivo .env
    update_env_file "$PORT_RANGE_BASE"
    echo ""
    
    # Exibir mapeamento de portas
    show_port_mapping "$PORT_RANGE_BASE"
    
    # Salvar a porta base para uso posterior
    echo "$PORT_RANGE_BASE" > .port_base
}

# Gerar chaves de segurança
generate_security_keys() {
    print_message "Gerando chaves de segurança..."
    
    # Gerar SECRET_KEY_BASE para Chatwoot
    if grep -q "replace_with_lengthy_secure_hex_key_here" .env; then
        SECRET_KEY=$(openssl rand -hex 64)
        sed -i.bak "s/replace_with_lengthy_secure_hex_key_here/$SECRET_KEY/" .env
        print_message "SECRET_KEY_BASE gerada e configurada."
    fi
    
    # Gerar AUTHENTICATION_API_KEY para Evolution API
    if grep -q "GENERATE_YOUR_API_KEY_HERE" evolution-api/.env; then
        API_KEY=$(uuidgen)
        sed -i.bak "s/GENERATE_YOUR_API_KEY_HERE/$API_KEY/" evolution-api/.env
        print_message "AUTHENTICATION_API_KEY gerada e configurada."
    fi
}

# Configurar n8n
configure_n8n() {
    print_message "Configurando n8n..."
    
    echo ""
    print_message "Escolha uma opção para o n8n:"
    echo "  1) Instalar n8n localmente (recomendado)"
    echo "  2) Usar instância n8n existente"
    echo "  3) Pular configuração do n8n"
    echo ""
    
    read -p "Digite sua escolha (1-3): " n8n_choice
    
    case $n8n_choice in
        1)
            print_message "Instalando n8n localmente..."
            mkdir -p n8n-data
            N8N_ENABLED=true
            N8N_URL="http://localhost:5678"
            ;;
        2)
            print_message "Configurando para instância n8n existente..."
            read -p "Digite a URL do seu n8n (ex: http://meu-n8n.com): " n8n_url
            N8N_ENABLED=false
            N8N_URL="$n8n_url"
            ;;
        3)
            print_message "Pulando configuração do n8n..."
            N8N_ENABLED=false
            N8N_URL=""
            ;;
        *)
            print_error "Opção inválida. Usando instalação local padrão."
            mkdir -p n8n-data
            N8N_ENABLED=true
            N8N_URL="http://localhost:5678"
            ;;
    esac
    
    # Salvar configuração do n8n
    echo "N8N_ENABLED=$N8N_ENABLED" >> .env
    echo "N8N_URL=$N8N_URL" >> .env
    
    print_message "Configuração do n8n concluída!"
}

# Criar diretórios necessários
create_directories() {
    print_message "Criando diretórios necessários..."
    
    mkdir -p database/chatwoot/{postgres,redis,init}
    mkdir -p database/evolution/{postgres,redis,init}
    mkdir -p evolution-api/{evolution_instances,logs}
    
    # Criar diretório n8n apenas se for instalar localmente
    if [ "$N8N_ENABLED" = "true" ]; then
        mkdir -p n8n-data
    fi
    
    print_message "Diretórios criados com sucesso!"
}

# Verificar permissões
check_permissions() {
    print_message "Verificando permissões dos diretórios..."
    
    # Definir permissões adequadas para os diretórios de dados
    chmod 755 database/
    chmod 755 evolution-api/
    
    print_message "Permissões configuradas!"
}

# Construir e iniciar containers
build_and_start() {
    print_message "Construindo e iniciando containers..."
    
    # Parar containers existentes se houver
    docker-compose down 2>/dev/null || true
    
    # Construir e iniciar baseado na configuração do n8n
    if [ "$N8N_ENABLED" = "true" ]; then
        print_message "Iniciando com n8n local..."
        docker-compose --profile n8n up --build -d
    else
        print_message "Iniciando sem n8n..."
        docker-compose up --build -d
    fi
    
    print_message "Containers iniciados! Aguarde alguns minutos para inicialização completa."
}

# Configurar banco de dados do Chatwoot
setup_chatwoot_database() {
    print_message "Configurando banco de dados do Chatwoot..."
    
    # Aguardar o PostgreSQL estar pronto
    print_message "Aguardando PostgreSQL estar pronto..."
    sleep 30
    
    # Executar migração do banco
    docker-compose run --rm chatwoot-rails bundle exec rails db:chatwoot_prepare
    
    print_message "Banco de dados do Chatwoot configurado!"
}

# Mostrar informações finais
show_final_info() {
    print_header "CONFIGURAÇÃO CONCLUÍDA!"
    
    # Obter a porta base configurada
    if [ -f ".port_base" ]; then
        PORT_BASE=$(cat .port_base)
    else
        PORT_BASE=3000
    fi
    
    echo ""
    print_message "Seus serviços estão disponíveis em:"
    echo "  • Evolution API Manager: http://localhost:$((PORT_BASE + 5))/manager"
    echo "  • Chatwoot: http://localhost:$PORT_BASE"
    echo "  • PgAdmin: http://localhost:$((PORT_BASE + 6))"
    
    # Mostrar informações do n8n baseado na configuração
    if [ "$N8N_ENABLED" = "true" ]; then
        echo "  • n8n Automation: http://localhost:$((PORT_BASE + 7))"
    elif [ -n "$N8N_URL" ]; then
        echo "  • n8n Automation: $N8N_URL"
    else
        echo "  • n8n: Não configurado"
    fi
    echo ""
    
    print_message "Credenciais padrão:"
    echo "  • PgAdmin - Email: admin@admin.com, Senha: admin123"
    
    # Mostrar credenciais do n8n apenas se estiver instalado localmente
    if [ "$N8N_ENABLED" = "true" ]; then
        echo "  • n8n - Usuário: admin, Senha: admin123"
    fi
    echo ""
    
    print_warning "IMPORTANTE:"
    echo "  • Altere as senhas padrão antes de usar em produção"
    echo "  • Configure HTTPS para uso em produção"
    echo "  • Faça backup regular dos dados"
    echo ""
    
    print_message "Para verificar o status dos containers:"
    echo "  docker-compose ps"
    echo ""
    
    print_message "Para ver logs:"
    echo "  docker-compose logs -f"
    echo ""
    
    print_message "Para parar os serviços:"
    echo "  docker-compose down"
    echo ""
    
    # Limpar arquivo temporário
    rm -f .port_base
}

# Função principal
main() {
    print_header "WHATSAPP AUTOMATION SUITE - SETUP"
    
    check_docker
    check_config_files
    configure_port_range "$@"
    generate_security_keys
    configure_n8n
    create_directories
    check_permissions
    build_and_start
    setup_chatwoot_database
    show_final_info
}

# Executar função principal
main "$@"
