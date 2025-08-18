#!/bin/bash

# ============================================================================
# WHATSAPP AUTOMATION SUITE - N8N MANAGEMENT SCRIPT
# ============================================================================
# Script para gerenciar o n8n (iniciar, parar, status)
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

# Verificar se o arquivo .env existe
check_env_file() {
    if [ ! -f ".env" ]; then
        print_error "Arquivo .env não encontrado. Execute o setup primeiro."
        exit 1
    fi
    
    # Carregar variáveis do .env
    source .env
}

# Função para mostrar status do n8n
show_status() {
    print_header "STATUS DO N8N"
    
    if [ "$N8N_ENABLED" = "true" ]; then
        print_message "n8n está configurado para rodar localmente"
        
        # Verificar se o container está rodando
        if docker ps | grep -q "n8n"; then
            print_message "✅ Container n8n está rodando"
            print_message "URL: http://localhost:5678"
            print_message "Usuário: admin"
            print_message "Senha: admin123"
        else
            print_warning "❌ Container n8n não está rodando"
            print_message "Execute: ./scripts/manage-n8n.sh start"
        fi
    elif [ -n "$N8N_URL" ]; then
        print_message "n8n está configurado para usar instância externa"
        print_message "URL: $N8N_URL"
    else
        print_warning "n8n não está configurado"
        print_message "Execute o setup para configurar o n8n"
    fi
}

# Função para iniciar o n8n
start_n8n() {
    print_header "INICIANDO N8N"
    
    if [ "$N8N_ENABLED" = "true" ]; then
        print_message "Iniciando container n8n..."
        docker-compose --profile n8n up -d n8n
        
        print_message "Aguardando n8n inicializar..."
        sleep 30
        
        if docker ps | grep -q "n8n"; then
            print_message "✅ n8n iniciado com sucesso!"
            print_message "URL: http://localhost:5678"
            print_message "Usuário: admin"
            print_message "Senha: admin123"
        else
            print_error "❌ Falha ao iniciar n8n"
            print_message "Verifique os logs: docker-compose logs n8n"
        fi
    else
        print_warning "n8n não está configurado para rodar localmente"
        print_message "Configure o n8n no arquivo .env ou execute o setup"
    fi
}

# Função para parar o n8n
stop_n8n() {
    print_header "PARANDO N8N"
    
    if [ "$N8N_ENABLED" = "true" ]; then
        print_message "Parando container n8n..."
        docker-compose stop n8n
        
        if ! docker ps | grep -q "n8n"; then
            print_message "✅ n8n parado com sucesso!"
        else
            print_error "❌ Falha ao parar n8n"
        fi
    else
        print_warning "n8n não está rodando localmente"
    fi
}

# Função para reiniciar o n8n
restart_n8n() {
    print_header "REINICIANDO N8N"
    
    stop_n8n
    sleep 5
    start_n8n
}

# Função para mostrar logs do n8n
show_logs() {
    print_header "LOGS DO N8N"
    
    if [ "$N8N_ENABLED" = "true" ]; then
        if docker ps | grep -q "n8n"; then
            docker-compose logs -f n8n
        else
            print_warning "Container n8n não está rodando"
        fi
    else
        print_warning "n8n não está configurado para rodar localmente"
    fi
}

# Função para backup dos fluxos do n8n
backup_n8n() {
    print_header "BACKUP DO N8N"
    
    if [ "$N8N_ENABLED" = "true" ]; then
        if [ -d "n8n-data" ]; then
            BACKUP_DIR="./backups"
            DATE=$(date +%Y%m%d_%H%M%S)
            BACKUP_NAME="n8n_backup_$DATE"
            
            mkdir -p "$BACKUP_DIR"
            
            print_message "Criando backup dos fluxos do n8n..."
            tar -czf "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" -C n8n-data .
            
            print_message "✅ Backup criado: $BACKUP_DIR/${BACKUP_NAME}.tar.gz"
        else
            print_warning "Diretório n8n-data não encontrado"
        fi
    else
        print_warning "n8n não está configurado para rodar localmente"
    fi
}

# Função para mostrar ajuda
show_help() {
    print_header "AJUDA - GERENCIAMENTO DO N8N"
    
    echo ""
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponíveis:"
    echo "  status    - Mostra o status atual do n8n"
    echo "  start     - Inicia o n8n local"
    echo "  stop      - Para o n8n local"
    echo "  restart   - Reinicia o n8n local"
    echo "  logs      - Mostra os logs do n8n"
    echo "  backup    - Faz backup dos fluxos do n8n"
    echo "  help      - Mostra esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 status"
    echo "  $0 start"
    echo "  $0 logs"
    echo ""
}

# Função principal
main() {
    # Verificar se o arquivo .env existe
    check_env_file
    
    # Verificar argumentos
    case "${1:-help}" in
        status)
            show_status
            ;;
        start)
            start_n8n
            ;;
        stop)
            stop_n8n
            ;;
        restart)
            restart_n8n
            ;;
        logs)
            show_logs
            ;;
        backup)
            backup_n8n
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Comando inválido: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Executar função principal
main "$@"
