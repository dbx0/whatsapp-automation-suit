#!/bin/bash

# ============================================================================
# WHATSAPP AUTOMATION SUITE - BACKUP SCRIPT
# ============================================================================
# Script para backup dos dados do projeto
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

# Configurações
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="whatsapp_automation_backup_$DATE"

# Criar diretório de backup se não existir
create_backup_dir() {
    print_message "Criando diretório de backup..."
    mkdir -p "$BACKUP_DIR"
}

# Backup do banco de dados Chatwoot
backup_chatwoot_database() {
    print_message "Fazendo backup do banco de dados Chatwoot..."
    
    if docker-compose ps postgres-chatwoot | grep -q "Up"; then
        docker-compose exec -T postgres-chatwoot pg_dump -U postgres chatwoot > "$BACKUP_DIR/${BACKUP_NAME}_chatwoot.sql"
        print_message "Backup do Chatwoot concluído: ${BACKUP_NAME}_chatwoot.sql"
    else
        print_warning "Container postgres-chatwoot não está rodando. Pulando backup do Chatwoot."
    fi
}

# Backup do banco de dados Evolution
backup_evolution_database() {
    print_message "Fazendo backup do banco de dados Evolution..."
    
    if docker-compose ps postgres-evolution | grep -q "Up"; then
        docker-compose exec -T postgres-evolution pg_dump -U postgres evolution > "$BACKUP_DIR/${BACKUP_NAME}_evolution.sql"
        print_message "Backup do Evolution concluído: ${BACKUP_NAME}_evolution.sql"
    else
        print_warning "Container postgres-evolution não está rodando. Pulando backup do Evolution."
    fi
}

# Backup dos dados do Redis
backup_redis_data() {
    print_message "Fazendo backup dos dados do Redis..."
    
    # Backup Redis Chatwoot
    if docker-compose ps redis-chatwoot | grep -q "Up"; then
        docker-compose exec redis-chatwoot redis-cli --rdb /data/dump.rdb
        docker cp $(docker-compose ps -q redis-chatwoot):/data/dump.rdb "$BACKUP_DIR/${BACKUP_NAME}_redis_chatwoot.rdb"
        print_message "Backup do Redis Chatwoot concluído: ${BACKUP_NAME}_redis_chatwoot.rdb"
    fi
    
    # Backup Redis Evolution
    if docker-compose ps redis-evolution | grep -q "Up"; then
        docker-compose exec redis-evolution redis-cli --rdb /data/dump.rdb
        docker cp $(docker-compose ps -q redis-evolution):/data/dump.rdb "$BACKUP_DIR/${BACKUP_NAME}_redis_evolution.rdb"
        print_message "Backup do Redis Evolution concluído: ${BACKUP_NAME}_redis_evolution.rdb"
    fi
}

# Backup das instâncias da Evolution API
backup_evolution_instances() {
    print_message "Fazendo backup das instâncias da Evolution API..."
    
    if [ -d "evolution-api/evolution_instances" ]; then
        tar -czf "$BACKUP_DIR/${BACKUP_NAME}_evolution_instances.tar.gz" -C evolution-api evolution_instances
        print_message "Backup das instâncias concluído: ${BACKUP_NAME}_evolution_instances.tar.gz"
    else
        print_warning "Diretório evolution-api/evolution_instances não encontrado."
    fi
}

# Backup dos logs
backup_logs() {
    print_message "Fazendo backup dos logs..."
    
    if [ -d "evolution-api/logs" ]; then
        tar -czf "$BACKUP_DIR/${BACKUP_NAME}_logs.tar.gz" -C evolution-api logs
        print_message "Backup dos logs concluído: ${BACKUP_NAME}_logs.tar.gz"
    fi
}

# Criar arquivo de metadados do backup
create_backup_metadata() {
    print_message "Criando metadados do backup..."
    
    cat > "$BACKUP_DIR/${BACKUP_NAME}_metadata.txt" << EOF
WhatsApp Automation Suite - Backup Metadata
===========================================

Data/Hora do Backup: $(date)
Versão do Sistema: 1.0.0

Containers Status:
$(docker-compose ps)

Arquivos de Backup:
- ${BACKUP_NAME}_chatwoot.sql (Banco de dados Chatwoot)
- ${BACKUP_NAME}_evolution.sql (Banco de dados Evolution)
- ${BACKUP_NAME}_redis_chatwoot.rdb (Redis Chatwoot)
- ${BACKUP_NAME}_redis_evolution.rdb (Redis Evolution)
- ${BACKUP_NAME}_evolution_instances.tar.gz (Instâncias Evolution)
- ${BACKUP_NAME}_logs.tar.gz (Logs do sistema)

Informações do Sistema:
- Docker Version: $(docker --version)
- Docker Compose Version: $(docker-compose --version)
- Sistema Operacional: $(uname -a)

EOF

    print_message "Metadados criados: ${BACKUP_NAME}_metadata.txt"
}

# Limpar backups antigos
cleanup_old_backups() {
    print_message "Limpando backups antigos (mantendo últimos 7 dias)..."
    
    find "$BACKUP_DIR" -name "whatsapp_automation_backup_*" -type f -mtime +7 -delete
    
    print_message "Limpeza concluída!"
}

# Mostrar resumo do backup
show_backup_summary() {
    print_header "BACKUP CONCLUÍDO!"
    
    echo ""
    print_message "Arquivos de backup criados em: $BACKUP_DIR"
    echo ""
    
    if [ -f "$BACKUP_DIR/${BACKUP_NAME}_chatwoot.sql" ]; then
        echo "✓ Backup do Chatwoot: ${BACKUP_NAME}_chatwoot.sql"
    fi
    
    if [ -f "$BACKUP_DIR/${BACKUP_NAME}_evolution.sql" ]; then
        echo "✓ Backup do Evolution: ${BACKUP_NAME}_evolution.sql"
    fi
    
    if [ -f "$BACKUP_DIR/${BACKUP_NAME}_redis_chatwoot.rdb" ]; then
        echo "✓ Backup do Redis Chatwoot: ${BACKUP_NAME}_redis_chatwoot.rdb"
    fi
    
    if [ -f "$BACKUP_DIR/${BACKUP_NAME}_redis_evolution.rdb" ]; then
        echo "✓ Backup do Redis Evolution: ${BACKUP_NAME}_redis_evolution.rdb"
    fi
    
    if [ -f "$BACKUP_DIR/${BACKUP_NAME}_evolution_instances.tar.gz" ]; then
        echo "✓ Backup das instâncias: ${BACKUP_NAME}_evolution_instances.tar.gz"
    fi
    
    if [ -f "$BACKUP_DIR/${BACKUP_NAME}_logs.tar.gz" ]; then
        echo "✓ Backup dos logs: ${BACKUP_NAME}_logs.tar.gz"
    fi
    
    echo ""
    print_message "Tamanho total do backup:"
    du -sh "$BACKUP_DIR/${BACKUP_NAME}"*
    echo ""
}

# Função principal
main() {
    print_header "WHATSAPP AUTOMATION SUITE - BACKUP"
    
    create_backup_dir
    backup_chatwoot_database
    backup_evolution_database
    backup_redis_data
    backup_evolution_instances
    backup_logs
    create_backup_metadata
    cleanup_old_backups
    show_backup_summary
}

# Executar função principal
main "$@"
