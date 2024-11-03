FROM debian:latest

# Install required packages
RUN apt-get update && apt-get install -y \
    certbot \
    openssl \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /srv/app/site-reliability-tools/security \
    /var/www/certbot

# Copy your script into the container
COPY security/certbot.sh /srv/app/certbot.sh
RUN chmod +x /srv/app/certbot.sh

ENV ENV_CONFIG="/run/secrets/app_config"
ENV DOMAIN="localdomain.com"
ENV LOCAL_DOMAIN="localhost"
ENV EMAIL="example@example.com"
ENV API_SUBDOMAIN="api"
ENV PORTAINER_SUBDOMAIN="portainer"
ENV SELF_SIGN_CERTIFICATE_KEY_NAME="localhost.key"
ENV SELF_SIGN_CERTIFICATE_NAME="localhost.crt"

# Set the default command to run your script
CMD ["/srv/app/certbot.sh"]