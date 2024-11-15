#!/bin/sh
APP_WORKING_DIR="/srv/app"
ENV_CONFIG="/run/secrets/app_config"
WEBROOT_PATH="/var/www/certbot"
BASE_SSL_DIR="/etc/letsencrypt/live"
SWARM_SERVICE_NAME="api-gateway" 

log_message() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message"
}

check_domains_in_certificate() {
    for domain in "$DOMAIN" "$API_SUBDOMAIN" "$PORTAINER_SUBDOMAIN"; do
        if ! openssl x509 -in "$SSL_DIR/$CA_SIGN_CERTIFICATE_NAME" -text -noout | grep -q "DNS:$domain"; then
            log_message "ERROR" "Domain $domain is not a Subject Alternative Name (SAN) in an SSL certificate file $CA_SIGN_CERTIFICATE_NAME"
            return 1
        fi
    done
    return 0
}

initialize_env_vars() {
    if [ -e "$ENV_CONFIG" ]; then
        log_message "INFO" "Setting environment variables for $ENV_CONFIG file"
        set -o allexport
        . "$ENV_CONFIG"
        set +o allexport

        # Check for required variables
        REQUIRED_VARS="DOMAIN EMAIL API_SUBDOMAIN PORTAINER_SUBDOMAIN CA_SIGN_CERTIFICATE_NAME"
        for VAR in $REQUIRED_VARS; do
            if [ -z "$(eval echo \$$VAR)" ]; then
                log_message "ERROR" "Error: $VAR is not set in $ENV_CONFIG"
                exit 1
            fi
        done

        log_message "INFO" "All required variables are set."

        log_message "INFO" "Creating SSL directory for $BASE_SSL_DIR/$DOMAIN"
        SSL_DIR="$BASE_SSL_DIR/$DOMAIN"
        mkdir -p "$SSL_DIR"
    else
        log_message "ERROR" "No $ENV_CONFIG found."
        exit 1
    fi
}

create_certificate_authority_certificate() {
    log_message "INFO" "Checking SSL certificate for $DOMAIN to see if it expires within the next 30 days..."
    if ! openssl x509 -checkend 2592000 -noout -in "$SSL_DIR/$CA_SIGN_CERTIFICATE_NAME" || ! check_domains_in_certificate; then

        log_message "INFO" "Requesting certificate for $DOMAIN and additional subdomains"
        
        # Request new or expand existing certificate
        certbot certonly --webroot --webroot-path="$WEBROOT_PATH" --email "$EMAIL" --agree-tos --no-eff-email --expand \
            --force-renewal \
            -d "$DOMAIN" -d "$API_SUBDOMAIN" -d "$PORTAINER_SUBDOMAIN"

        # Check if Certbot command succeeded
        if [ $? -eq 0 ]; then
            log_message "INFO" "Certificate obtained successfully. Updating $SWARM_SERVICE_NAME service to load new certificates."
            docker service update --force $SWARM_SERVICE_NAME || log_message "ERROR" "Failed to update $SWARM_SERVICE_NAME"
        else
            log_message "ERROR" "Failed to obtain certificate for DOMAIN: $DOMAIN API_SUBDOMAIN: $API_SUBDOMAIN PORTAINER_SUBDOMAIN: $PORTAINER_SUBDOMAIN. Entering infinite sleep."
            while :; do
                sleep 1d
            done
        fi
    else
        log_message "INFO" "Certificate for DOMAIN: $DOMAIN API_SUBDOMAIN: $API_SUBDOMAIN PORTAINER_SUBDOMAIN: $PORTAINER_SUBDOMAIN is already valid and not expiring soon."
    fi    
}

renew_certificates_periodically() {
    while :; do
        log_message "INFO" "Attempting to renew Certbot certificates with deploy-hook to update $SWARM_SERVICE_NAME ..."
        certbot renew --deploy-hook "/usr/bin/docker service update --force $SWARM_SERVICE_NAME" --disable-hook-validation

        if [ $? -eq 0 ]; then
            log_message "INFO" "Certificate renewed successfully and $SWARM_SERVICE_NAME service updated."
        else
            log_message "ERROR" "Renewal failed. Retrying in 12 hours."
        fi

        sleep 12h
    done
}

apk update
apk add --no-cache docker

initialize_env_vars

create_certificate_authority_certificate

renew_certificates_periodically
