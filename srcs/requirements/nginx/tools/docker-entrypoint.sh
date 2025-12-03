#!/bin/sh
set -e

# Validate required environment variables
if [ -z "$DOMAIN_NAME" ]; then
	echo "ERROR: DOMAIN_NAME environment variable is not set"
	exit 1
fi

# Generate nginx configuration from template
echo "Generating nginx configuration for ${DOMAIN_NAME}..."
envsubst '${DOMAIN_NAME}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Generate SSL certificate if it doesn't exist
if [ ! -f "/etc/nginx/ssl/nginx.crt" ]; then
	echo "Generating SSL certificate for ${DOMAIN_NAME}..."
	openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
		-keyout /etc/nginx/ssl/nginx.key \
		-out /etc/nginx/ssl/nginx.crt \
		-subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=${DOMAIN_NAME}"
	echo "SSL certificate generated successfully!"
else
	echo "SSL certificate already exists, skipping generation..."
fi

# Start nginx
echo "Starting nginx..."
exec "$@"
