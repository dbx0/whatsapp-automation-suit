#!/bin/bash

# ============================================================================
# WHATSAPP AUTOMATION SUITE - PORT RANGE SETUP SCRIPT
# ============================================================================
# Este script facilita a configuração do range de portas para os containers
# ============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para exibir mensagens coloridas
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
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================================================${NC}"
}

# Verificar se o arquivo .env existe
if [ ! -f ".env" ]; then
    print_error "Arquivo .env não encontrado!"
    print_message "Copiando env.example para .env..."
    cp env.example .env
fi

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

# Função principal
main() {
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
    print_message "Atualizando arquivo .env..."
    
    # Verificar se a variável já existe no .env
    if grep -q "^PORT_RANGE_BASE=" .env; then
        # Atualizar valor existente
        sed -i.bak "s/^PORT_RANGE_BASE=.*/PORT_RANGE_BASE=$PORT_RANGE_BASE/" .env
    else
        # Adicionar nova variável
        echo "" >> .env
        echo "# ============================================================================" >> .env
        echo "# PORT RANGE CONFIGURATION" >> .env
        echo "# ============================================================================" >> .env
        echo "PORT_RANGE_BASE=$PORT_RANGE_BASE" >> .env
    fi
    
    # Remover backup se existir
    rm -f .env.bak
    
    print_message "Arquivo .env atualizado com sucesso!"
    echo ""
    
    # Exibir mapeamento de portas
    show_port_mapping "$PORT_RANGE_BASE"
    
    print_header "PRÓXIMOS PASSOS"
    echo "1. Execute: docker-compose up -d"
    echo "2. Acesse os serviços nas URLs mostradas acima"
    echo "3. Para parar: docker-compose down"
    echo ""
    print_message "Configuração concluída!"
}

# Executar função principal
main "$@"
