#!/bin/bash

# ============================================================================
# WHATSAPP AUTOMATION SUITE - PURGE SCRIPT
# ============================================================================
# Script para remover completamente todos os dados e containers
# ⚠️ ATENÇÃO: Este script irá APAGAR TODOS os dados permanentemente!
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

# Função para confirmar a ação
confirm_purge() {
    print_header "⚠️  PURGE COMPLETA - ATENÇÃO ⚠️"
    echo ""
    print_warning "Este script irá REMOVER PERMANENTEMENTE:"
    echo "  • Todos os containers Docker"
    echo "  • Todos os volumes de dados"
    echo "  • Todos os arquivos de configuração"
    echo "  • Todos os logs"
    echo "  • Todos os backups"
    echo ""
    print_error "⚠️  ESTA AÇÃO NÃO PODE SER DESFEITA! ⚠️"
    echo ""
    
    read -p "Digite 'PURGE' para confirmar a remoção completa: " confirmation
    
    if [ "$confirmation" != "PURGE" ]; then
        print_message "Operação cancelada pelo usuário."
        exit 0
    fi
    
    echo ""
    print_warning "Última chance! Digite 'CONFIRMO' para continuar: "
    read -p "" final_confirmation
    
    if [ "$final_confirmation" != "CONFIRMO" ]; then
        print_message "Operação cancelada pelo usuário."
        exit 0
    fi
}

# Função para parar e remover containers
stop_and_remove_containers() {
    print_message "Parando e removendo containers..."
    
    # Parar todos os containers do projeto
    docker-compose down --remove-orphans 2>/dev/null || true
    
    # Remover containers específicos se ainda existirem
    local containers=(
        "chatwoot-rails"
        "chatwoot-sidekiq"
        "chatwoot-base"
        "evolution-api"
        "postgres-chatwoot"
        "postgres-evolution"
        "redis-chatwoot"
        "redis-evolution"
        "pgadmin"
        "n8n"
    )
    
    for container in "${containers[@]}"; do
        if docker ps -a --format "table {{.Names}}" | grep -q "^$container$"; then
            print_message "Removendo container: $container"
            docker rm -f "$container" 2>/dev/null || true
        fi
    done
    
    print_message "Containers removidos!"
}

# Função para remover volumes
remove_volumes() {
    print_message "Removendo volumes..."
    
    # Remover volumes específicos do projeto
    local volumes=(
        "whatsapp-automation-suit_chatwoot_postgres_data"
        "whatsapp-automation-suit_chatwoot_redis_data"
        "whatsapp-automation-suit_evolution_postgres_data"
        "whatsapp-automation-suit_evolution_redis_data"
        "whatsapp-automation-suit_evolution_instances"
    )
    
    for volume in "${volumes[@]}"; do
        if docker volume ls --format "table {{.Name}}" | grep -q "^$volume$"; then
            print_message "Removendo volume: $volume"
            docker volume rm "$volume" 2>/dev/null || true
        fi
    done
    
    print_message "Volumes removidos!"
}

# Função para remover imagens
remove_images() {
    print_message "Removendo imagens..."
    
    # Remover imagens específicas do projeto
    local images=(
        "chatwoot/chatwoot:v4.0.4"
        "atendai/evolution-api:v2.2.0"
        "pgvector/pgvector:pg16"
        "postgres:16-alpine"
        "redis:7.2-alpine"
        "dpage/pgadmin4:8.5"
        "n8nio/n8n:latest"
    )
    
    for image in "${images[@]}"; do
        if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^$image$"; then
            print_message "Removendo imagem: $image"
            docker rmi "$image" 2>/dev/null || true
        fi
    done
    
    print_message "Imagens removidas!"
}

# Função para remover redes
remove_networks() {
    print_message "Removendo redes..."
    
    # Remover rede específica do projeto
    if docker network ls --format "table {{.Name}}" | grep -q "^whatsapp-network$"; then
        print_message "Removendo rede: whatsapp-network"
        docker network rm whatsapp-network 2>/dev/null || true
    fi
    
    print_message "Redes removidas!"
}

# Função para remover diretórios de dados
remove_data_directories() {
    print_message "Removendo diretórios de dados..."
    
    local directories=(
        "database"
        "evolution-api/evolution_instances"
        "evolution-api/logs"
        "n8n-data"
        "evolution-api/.env"
        ".env"
    )
    
    for dir in "${directories[@]}"; do
        if [ -e "$dir" ]; then
            print_message "Removendo: $dir"
            rm -rf "$dir"
        fi
    done
    
    print_message "Diretórios de dados removidos!"
}

# Função para limpar arquivos temporários
cleanup_temp_files() {
    print_message "Limpando arquivos temporários..."
    
    local temp_files=(
        ".port_base"
        "*.bak"
        "*.tmp"
    )
    
    for pattern in "${temp_files[@]}"; do
        if ls $pattern 2>/dev/null; then
            print_message "Removendo arquivos: $pattern"
            rm -f $pattern
        fi
    done
    
    print_message "Arquivos temporários removidos!"
}

# Função para limpar Docker system
cleanup_docker_system() {
    print_message "Limpando sistema Docker..."
    
    # Remover containers parados
    docker container prune -f 2>/dev/null || true
    
    # Remover redes não utilizadas
    docker network prune -f 2>/dev/null || true
    
    # Remover volumes não utilizados
    docker volume prune -f 2>/dev/null || true
    
    # Remover imagens não utilizadas
    docker image prune -f 2>/dev/null || true
    
    print_message "Sistema Docker limpo!"
}

# Função para verificar se tudo foi removido
verify_cleanup() {
    print_message "Verificando limpeza..."
    
    local remaining_items=()
    
    # Verificar containers
    if docker ps -a --format "table {{.Names}}" | grep -E "(chatwoot|evolution|postgres|redis|pgadmin|n8n)" >/dev/null 2>&1; then
        remaining_items+=("containers")
    fi
    
    # Verificar volumes
    if docker volume ls --format "table {{.Name}}" | grep -E "(whatsapp|chatwoot|evolution)" >/dev/null 2>&1; then
        remaining_items+=("volumes")
    fi
    
    # Verificar redes
    if docker network ls --format "table {{.Name}}" | grep -E "(whatsapp)" >/dev/null 2>&1; then
        remaining_items+=("networks")
    fi
    
    # Verificar diretórios
    if [ -d "database" ] || [ -d "evolution-api/evolution_instances" ] || [ -d "n8n-data" ]; then
        remaining_items+=("directories")
    fi
    
    if [ ${#remaining_items[@]} -eq 0 ]; then
        print_message "✅ Limpeza completa realizada com sucesso!"
    else
        print_warning "⚠️  Alguns itens ainda permanecem:"
        for item in "${remaining_items[@]}"; do
            echo "  - $item"
        done
        print_message "Execute o script novamente se necessário."
    fi
}

# Função para mostrar informações finais
show_final_info() {
    print_header "PURGE CONCLUÍDA!"
    
    echo ""
    print_message "Todos os dados foram removidos permanentemente."
    echo ""
    print_message "Para reinstalar o sistema:"
    echo "  ./scripts/deploy.sh"
    echo ""
    print_message "Para configuração manual:"
    echo "  ./scripts/setup.sh"
    echo ""
    print_warning "Lembre-se de configurar as variáveis de ambiente antes de reinstalar."
}

# Função principal
main() {
    print_header "WHATSAPP AUTOMATION SUITE - PURGE"
    
    confirm_purge
    stop_and_remove_containers
    remove_volumes
    remove_images
    remove_networks
    remove_data_directories
    cleanup_temp_files
    cleanup_docker_system
    verify_cleanup
    show_final_info
}

# Executar função principal
main "$@"
