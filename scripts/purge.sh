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

# Função para mostrar menu de seleção
show_menu() {
    print_header "PURGE - WHATSAPP AUTOMATION SUITE"
    echo ""
    echo "Escolha o tipo de remoção:"
    echo ""
    echo "  1) Purge completa (remove TUDO)"
    echo "  2) Purge seletiva (escolha o que remover)"
    echo "  3) Verificar recursos do projeto"
    echo "  4) Sair"
    echo ""
}

# Função para mostrar menu de purge seletiva
show_selective_menu() {
    print_header "PURGE SELETIVA - WHATSAPP AUTOMATION SUITE"
    echo ""
    echo "Escolha o que deseja remover:"
    echo ""
    echo "  1) Apenas containers (mantém dados)"
    echo "  2) Containers + Volumes (mantém imagens)"
    echo "  3) Containers + Volumes + Redes"
    echo "  4) Containers + Volumes + Redes + Imagens"
    echo "  5) Tudo (purge completa)"
    echo "  6) Apenas dados locais (diretórios)"
    echo "  7) Voltar ao menu principal"
    echo ""
}

# Função para confirmar ação
confirm_action() {
    local action=$1
    echo ""
    print_warning "Você está prestes a executar: $action"
    read -p "Deseja continuar? (y/N): " confirmation
    
    if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
        print_message "Operação cancelada."
        return 1
    fi
    return 0
}

# Função para confirmar a ação de purge completa
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
    
    # Remover containers com label específica do projeto
    print_message "Removendo containers do WhatsApp Automation Suite..."
    docker ps -a --filter "label=whatsapp-automation-suite=true" --format "{{.Names}}" | while read container; do
        if [ -n "$container" ]; then
            print_message "Removendo container: $container"
            docker rm -f "$container" 2>/dev/null || true
        fi
    done
    
    print_message "Containers removidos!"
}

# Função para remover volumes
remove_volumes() {
    print_message "Removendo volumes..."
    
    # Remover apenas volumes com label específica do projeto
    print_message "Removendo volumes do WhatsApp Automation Suite..."
    local volumes=$(docker volume ls --filter "label=whatsapp-automation-suite=true" --format "{{.Name}}")
    
    if [ -n "$volumes" ]; then
        echo "$volumes" | while read volume; do
            if [ -n "$volume" ]; then
                print_message "Removendo volume: $volume"
                docker volume rm "$volume" 2>/dev/null || true
            fi
        done
        print_message "Volumes removidos!"
    else
        print_message "Nenhum volume do projeto encontrado."
    fi
}

# Função para remover imagens
remove_images() {
    print_message "Removendo imagens..."
    
    # Remover apenas imagens que foram usadas por containers com label específica
    print_message "Removendo imagens do WhatsApp Automation Suite..."
    
    local images=$(docker ps -a --filter "label=whatsapp-automation-suite=true" --format "{{.Image}}" | sort -u)
    
    if [ -n "$images" ]; then
        echo "$images" | while read image; do
            if [ -n "$image" ]; then
                print_message "Removendo imagem: $image"
                docker rmi "$image" 2>/dev/null || true
            fi
        done
        print_message "Imagens removidas!"
    else
        print_message "Nenhuma imagem do projeto encontrada."
    fi
}

# Função para remover redes
remove_networks() {
    print_message "Removendo redes..."
    
    # Remover apenas redes com label específica do projeto
    print_message "Removendo redes do WhatsApp Automation Suite..."
    local networks=$(docker network ls --filter "label=whatsapp-automation-suite=true" --format "{{.Name}}")
    
    if [ -n "$networks" ]; then
        echo "$networks" | while read network; do
            if [ -n "$network" ]; then
                print_message "Removendo rede: $network"
                docker network rm "$network" 2>/dev/null || true
            fi
        done
        print_message "Redes removidas!"
    else
        print_message "Nenhuma rede do projeto encontrada."
    fi
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

# Função para verificar recursos do projeto
check_project_resources() {
    print_header "RECURSOS DO WHATSAPP AUTOMATION SUITE"
    echo ""
    
    # Verificar containers
    print_message "Containers:"
    local containers=$(docker ps -a --filter "label=whatsapp-automation-suite=true" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}")
    if [ -n "$containers" ]; then
        echo "$containers"
    else
        echo "  Nenhum container encontrado."
    fi
    echo ""
    
    # Verificar volumes
    print_message "Volumes:"
    local volumes=$(docker volume ls --filter "label=whatsapp-automation-suite=true" --format "table {{.Name}}\t{{.Driver}}")
    if [ -n "$volumes" ]; then
        echo "$volumes"
    else
        echo "  Nenhum volume encontrado."
    fi
    echo ""
    
    # Verificar redes
    print_message "Redes:"
    local networks=$(docker network ls --filter "label=whatsapp-automation-suite=true" --format "table {{.Name}}\t{{.Driver}}")
    if [ -n "$networks" ]; then
        echo "$networks"
    else
        echo "  Nenhuma rede encontrada."
    fi
    echo ""
    
    # Verificar imagens
    print_message "Imagens:"
    local images=$(docker ps -a --filter "label=whatsapp-automation-suite=true" --format "{{.Image}}" | sort -u)
    if [ -n "$images" ]; then
        echo "$images" | while read image; do
            if [ -n "$image" ]; then
                echo "  $image"
            fi
        done
    else
        echo "  Nenhuma imagem encontrada."
    fi
    echo ""
    
    # Verificar diretórios
    print_message "Diretórios locais:"
    local directories=(
        "database"
        "evolution-api/evolution_instances"
        "evolution-api/logs"
        "n8n-data"
    )
    
    local found_dirs=()
    for dir in "${directories[@]}"; do
        if [ -e "$dir" ]; then
            found_dirs+=("$dir")
        fi
    done
    
    if [ ${#found_dirs[@]} -gt 0 ]; then
        for dir in "${found_dirs[@]}"; do
            echo "  $dir"
        done
    else
        echo "  Nenhum diretório encontrado."
    fi
    echo ""
    
    # Mostrar estatísticas
    print_message "Estatísticas:"
    local container_count=$(docker ps -a --filter "label=whatsapp-automation-suite=true" --format "{{.Names}}" | wc -l)
    local volume_count=$(docker volume ls --filter "label=whatsapp-automation-suite=true" --format "{{.Name}}" | wc -l)
    local network_count=$(docker network ls --filter "label=whatsapp-automation-suite=true" --format "{{.Name}}" | wc -l)
    local image_count=$(docker ps -a --filter "label=whatsapp-automation-suite=true" --format "{{.Image}}" | sort -u | wc -l)
    
    echo "  Containers: $container_count"
    echo "  Volumes: $volume_count"
    echo "  Redes: $network_count"
    echo "  Imagens únicas: $image_count"
    echo ""
}

# Função para verificar se tudo foi removido
verify_cleanup() {
    print_message "Verificando limpeza..."
    
    local remaining_items=()
    
    # Verificar containers com label específica
    if docker ps -a --filter "label=whatsapp-automation-suite=true" --format "{{.Names}}" | grep -q .; then
        remaining_items+=("containers")
    fi
    
    # Verificar volumes com label específica
    if docker volume ls --filter "label=whatsapp-automation-suite=true" --format "{{.Name}}" | grep -q .; then
        remaining_items+=("volumes")
    fi
    
    # Verificar redes com label específica
    if docker network ls --filter "label=whatsapp-automation-suite=true" --format "{{.Name}}" | grep -q .; then
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

# Função para executar purge completa
execute_full_purge() {
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

# Função para executar purge seletiva
execute_selective_purge() {
    while true; do
        show_selective_menu
        read -p "Digite sua escolha (1-7): " choice
        
        case $choice in
            1)
                if confirm_action "Remover apenas containers"; then
                    stop_and_remove_containers
                fi
                ;;
            2)
                if confirm_action "Remover containers e volumes"; then
                    stop_and_remove_containers
                    remove_volumes
                fi
                ;;
            3)
                if confirm_action "Remover containers, volumes e redes"; then
                    stop_and_remove_containers
                    remove_volumes
                    remove_networks
                fi
                ;;
            4)
                if confirm_action "Remover containers, volumes, redes e imagens"; then
                    stop_and_remove_containers
                    remove_volumes
                    remove_networks
                    remove_images
                fi
                ;;
            5)
                if confirm_action "Executar purge completa (TUDO)"; then
                    print_warning "⚠️  ATENÇÃO: Esta ação irá remover TODOS os dados permanentemente!"
                    read -p "Digite 'PURGE' para confirmar: " confirmation
                    if [ "$confirmation" = "PURGE" ]; then
                        execute_full_purge
                        return
                    else
                        print_message "Purge completa cancelada."
                    fi
                fi
                ;;
            6)
                if confirm_action "Remover apenas diretórios de dados locais"; then
                    remove_data_directories
                fi
                ;;
            7)
                return
                ;;
            *)
                print_error "Opção inválida. Digite um número entre 1 e 7."
                ;;
        esac
        
        echo ""
        read -p "Pressione Enter para continuar..."
        echo ""
    done
}

# Função principal
main() {
    while true; do
        show_menu
        read -p "Digite sua escolha (1-4): " choice
        
        case $choice in
            1)
                execute_full_purge
                break
                ;;
            2)
                execute_selective_purge
                ;;
            3)
                check_project_resources
                echo ""
                read -p "Pressione Enter para continuar..."
                ;;
            4)
                print_message "Saindo..."
                exit 0
                ;;
            *)
                print_error "Opção inválida. Digite um número entre 1 e 4."
                ;;
        esac
        
        echo ""
    done
}

# Executar função principal
main "$@"
