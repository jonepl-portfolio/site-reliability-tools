#!/bin/sh
APP_WORKING_DIR="/srv/app"
CERTBOT_DIR="$APP_WORKING_DIR/site-reliability-tools/security"
ENV_CONFIG="/run/secrets/app_config"

log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message"
}

# Initial environment variables from .env file
if [ -e $ENV_CONFIG ]; then
    log_message "Setting environment variables for $ENV_CONFIG file"
    set -o allexport
    . $ENV_CONFIG
    set +o allexport

    # Check for required variables
    REQUIRED_VARS="DOMAIN API_SUBDOMAIN PORTAINER_SUBDOMAIN"
    for VAR in $REQUIRED_VARS; do
        if [ -z "$(eval echo \$$VAR)" ]; then
            log_message "Error: $VAR is not set in $ENV_CONFIG"
            exit 1
        fi
    done

    SELF_SIGNED_CERT_PATH="/etc/letsencrypt/live/$DOMAIN"

    log_message "All required variables are set."
else
    log_message "No $ENV_CONFIG found."
    exit 1
fi

log_message "Starting self-signed certificate generation script..."

# Create the certificates directory if it doesn't exist
mkdir -p "$SELF_SIGNED_CERT_PATH" || {
    log_message "Failed to create directory: $SELF_SIGNED_CERT_PATH"
    exit 1
}

# Generate a self-signed certificate if it doesn't exist or is about to expire
if [ ! -f "$SELF_SIGNED_CERT_PATH/localhost.crt" ] || ! openssl x509 -checkend 2592000 -noout -in "$SELF_SIGNED_CERT_PATH/localhost.crt"; then
    log_message "Generating self-signed certificate for localhost"
    openssl req -newkey rsa:2048 -nodes -keyout ${SELF_SIGNED_CERT_PATH}/localhost.key -x509 -days 365 -out ${SELF_SIGNED_CERT_PATH}/localhost.crt -subj "/C=US/ST=Florida/L=Orlando/O=Me Dot Com/OU=IT/CN=localhost"
    if [ $? -ne 0 ]; then
        log_message "Failed to generate self-signed certificate for localhost. Entering infinite sleep."
        while :; do
            sleep 1d
        done
    fi
else
    log_message "Self-signed certificate for localhost is already valid and not expiring soon."
fi

while :; do
    log_message "Checking for self-signed certificate renewal..."
    sleep 12h
done
