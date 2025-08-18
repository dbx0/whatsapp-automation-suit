# ============================================================================
# NGINX DOCKERFILE - WHATSAPP AUTOMATION SUITE
# ============================================================================
# Dockerfile otimizado para o proxy reverso Nginx
# ============================================================================

# Usar a versão mais recente e estável do Nginx Alpine
FROM nginx:1.25-alpine

# ============================================================================
# METADATA
# ============================================================================
LABEL maintainer="WhatsApp Automation Suite Team"
LABEL description="Nginx reverse proxy for WhatsApp Automation Suite"
LABEL version="1.0.0"

# ============================================================================
# SECURITY UPDATES
# ============================================================================

# Atualizar o sistema e instalar dependências de segurança
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
        curl \
        openssl \
        ca-certificates \
        tzdata && \
    rm -rf /var/cache/apk/*

# ============================================================================
# CONFIGURATION
# ============================================================================

# Remover configuração padrão
RUN rm -f /etc/nginx/conf.d/default.conf

# Copiar configuração personalizada
COPY nginx.conf /etc/nginx/nginx.conf

# Criar diretórios necessários
RUN mkdir -p /var/log/nginx && \
    mkdir -p /var/cache/nginx && \
    mkdir -p /etc/nginx/conf.d

# ============================================================================
# SECURITY HARDENING
# ============================================================================

# Criar usuário não-root para o Nginx
RUN addgroup -g 1001 -S nginx && \
    adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx

# Definir permissões adequadas
RUN chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d && \
    chmod -R 755 /var/cache/nginx && \
    chmod -R 755 /var/log/nginx

# ============================================================================
# HEALTH CHECK
# ============================================================================

# Adicionar health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# ============================================================================
# EXPOSE PORTS
# ============================================================================

# Expor portas
EXPOSE 8080 8081 8082

# ============================================================================
# STARTUP
# ============================================================================

# Usar usuário não-root
USER nginx

# Comando de inicialização
CMD ["nginx", "-g", "daemon off;"]
