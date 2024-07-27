#!/bin/sh
APP_WORKING_DIR="/srv/app"
CERTBOT_DIR="$APP_WORKING_DIR/site-reliability-tools/security"
ENV_CONFIG=$CERTBOT_DIR/.env
WEBROOT_PATH="/var/www/certbot"

domain_in_certificate() {
    local domain=$1
    echo "Checking sub domain $domain"
    openssl x509 -in "$LETSENCRYPT_PATH/fullchain.pem" -text -noout | grep -q "DNS:$domain"
}

# Initial environment variables from .env file
if [ -e $ENV_CONFIG ]; then
    echo "Setting environment variables for $ENV_CONFIG file"
    set -o allexport
    . $ENV_CONFIG
    set +o allexport

    # Check for required variables
    REQUIRED_VARS="DOMAIN EMAIL API_SUBDOMAIN PORTAINER_SUBDOMAIN"
    for VAR in $REQUIRED_VARS; do
        if [ -z "$(eval echo \$$VAR)" ]; then
            echo "Error: $VAR is not set in $ENV_CONFIG"
            exit 1
        fi
    done

    LETSENCRYPT_PATH="/etc/letsencrypt/live/$DOMAIN"

    echo "All required variables are set."
else
    echo "No $ENV_CONFIG found."
    exit 1
fi

echo "Starting Certbot script..."

# Check if the certificate is about to expire or if there are new domains
if [ ! -d "$LETSENCRYPT_PATH" ] || \ 
    ! openssl x509 -checkend 2592000 -noout -in "$LETSENCRYPT_PATH/fullchain.pem" || \
    ! domain_in_certificate $DOMAIN || \
    ! domain_in_certificate $API_SUBDOMAIN || \
    ! domain_in_certificate $PORTAINER_SUBDOMAIN; then
    
    echo "Requesting certificate for $DOMAIN and additional subdomains"

    # Request new or expand existing certificate
    certbot certonly --webroot --webroot-path=$WEBROOT_PATH --email $EMAIL --agree-tos --no-eff-email --expand -d $DOMAIN -d $API_SUBDOMAIN -d $PORTAINER_SUBDOMAIN

    # Suspend container on failure
    if [ $? -ne 0 ]; then
        echo "Failed to obtain certificate for DOMAIN: $DOMAIN API_SUBDOMAIN: $API_SUBDOMAIN PORTAINER_SUBDOMAIN: $PORTAINER_SUBDOMAIN. Entering infinite sleep."
        while :; do
            sleep 1d
        done
    fi
else
    echo "Certificate for domains are already valid and not expiring soon."
fi

while :; do
    echo "Attempting to renew Certbot certification ..."
    certbot renew
    sleep 12h
done
