#!/bin/sh
APP_WORKING_DIR="/srv/app"
CERTBOT_DIR="$APP_WORKING_DIR/site-reliability-tools/security"
ENV_CONFIG="/run/secrets/app_config"
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

<<<<<<< Updated upstream
    # Check for required variables
    REQUIRED_VARS="DOMAIN EMAIL API_SUBDOMAIN PORTAINER_SUBDOMAIN"
    for VAR in $REQUIRED_VARS; do
        if [ -z "$(eval echo \$$VAR)" ]; then
            echo "Error: $VAR is not set in $ENV_CONFIG"
            exit 1
=======
        # Check for required variables
        REQUIRED_VARS="DOMAIN EMAIL API_SUBDOMAIN PORTAINER_SUBDOMAIN CA_SIGN_CERTIFICATE_NAME"
        for VAR in $REQUIRED_VARS; do
            if [ -z "$(eval echo \$$VAR)" ]; then
                log_message "ERROR" "Error: $VAR is not set in $ENV_CONFIG"
                exit 1
            fi
        done

        log_message "INFO" "All required variables are set."
    else
        log_message "ERROR" "No $ENV_CONFIG found."
        exit 1
    fi
}


# set_ssl_path() {
#     log_message "INFO" "Checking if this machine matches the production DOMAIN: $DOMAIN"
#     CURRENT_HOSTNAME=$(hostname)

#     if [ "$CURRENT_HOSTNAME" != "$DOMAIN" ]; then
#         log_message "INFO" "This machine does not match the Production DOMAIN. Expected: $DOMAIN, Found: $CURRENT_HOSTNAME. Defaulting to local domain: $LOCAL_DOMAIN"
#         IS_LOCAL=1
#         DOMAIN=$LOCAL_DOMAIN
#     fi

#     SSL_PATH="/etc/letsencrypt/live/$DOMAIN"
#     log_message "INFO" "Setting SSL_PATH to $SSL_PATH ..."
# }

# create_self_signed_certificate() {
#     log_message "INFO" "Creating self-signed certificate for localhost in $SSL_PATH/$SELF_SIGN_CERTIFICATE_KEY_NAME"
#     mkdir -p "$SSL_PATH" || { log_message "ERROR" "Could not create directory $SSL_PATH"; exit 1; }
#     openssl req -newkey rsa:2048 -nodes -keyout ${SSL_PATH}/${SELF_SIGN_CERTIFICATE_KEY_NAME} -x509 -days 365 -out ${SSL_PATH}/${SELF_SIGN_CERTIFICATE_NAME} -subj "/C=US/ST=Florida/L=Orlando/O=Me Dot Com/OU=IT/CN=localhost" || { log_message "ERROR" "Failed to create self-signed certificate"; exit 1; }
# }

create_certificate_authority_certificate() {
    log_message "INFO" "Requesting certificate for $DOMAIN and additional subdomains"
    if [ ! -d "$SSL_PATH" ] || \ 
        ! openssl x509 -checkend 2592000 -noout -in "$SSL_PATH/fullchain.pem" || \
        ! is_domain_in_ca_certificate $DOMAIN || \
        ! is_domain_in_ca_certificate "$API_SUBDOMAIN.$DOMAIN" || \
        ! is_domain_in_ca_certificate "$PORTAINER_SUBDOMAIN.$DOMAIN"; then

        # Request new or expand existing certificate
        certbot certonly --webroot --webroot-path=$WEBROOT_PATH --email $EMAIL --agree-tos --no-eff-email --expand -d $DOMAIN -d $API_SUBDOMAIN -d $PORTAINER_SUBDOMAIN

        # Suspend container on failure
        if [ $? -ne 0 ]; then
            log_message "WARN" "Failed to obtain certificate for DOMAIN: $DOMAIN API_SUBDOMAIN: $API_SUBDOMAIN PORTAINER_SUBDOMAIN: $PORTAINER_SUBDOMAIN. Entering infinite sleep."
            while :; do
                sleep 1d
            done
>>>>>>> Stashed changes
        fi
    done

    LETSENCRYPT_PATH="/etc/letsencrypt/live/$DOMAIN"

<<<<<<< Updated upstream
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
=======
create_certificate_authority_certificate

# set_ssl_path

# log_message "INFO" "Creating certificate..."
# if [ $IS_LOCAL -eq 0 ]; then
#     create_certificate_authority_certificate
# else
#     create_self_signed_certificate
# fi
>>>>>>> Stashed changes

while :; do
    echo "Attempting to renew Certbot certification ..."
    certbot renew
    sleep 12h
done
