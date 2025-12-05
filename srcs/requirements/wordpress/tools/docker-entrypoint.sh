#!/bin/sh
set -e	# "Exit immediately if any command fails"

# Validate required environment variables
if [ -z "$DOMAIN_NAME" ]; then
	echo "ERROR: DOMAIN_NAME environment variable is not set"
	exit 1
fi

if [ -z "$MYSQL_DATABASE" ]; then
	echo "ERROR: MYSQL_DATABASE environment variable is not set"
	exit 1
fi

if [ -z "$MYSQL_USER" ]; then
	echo "ERROR: MYSQL_USER environment variable is not set"
	exit 1
fi

if [ -z "$WP_ADMIN_USER" ]; then
	echo "ERROR: WP_ADMIN_USER environment variable is not set"
	exit 1
fi

if [ -z "$WP_ADMIN_EMAIL" ]; then
	echo "ERROR: WP_ADMIN_EMAIL environment variable is not set"
	exit 1
fi

if [ -z "$WP_USER" ]; then
	echo "ERROR: WP_USER environment variable is not set"
	exit 1
fi

if [ -z "$WP_USER_EMAIL" ]; then
	echo "ERROR: WP_USER_EMAIL environment variable is not set"
	exit 1
fi

# Read secrets
if [ ! -f "/run/secrets/db_password" ]; then
	echo "ERROR: db_password secret file not found"
	exit 1
fi
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

if [ ! -f "/run/secrets/wp_admin_password" ]; then
	echo "ERROR: wp_admin_password secret file not found"
	exit 1
fi
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)

if [ ! -f "/run/secrets/wp_user_password" ]; then
	echo "ERROR: wp_user_password secret file not found"
	exit 1
fi
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)


echo "Waiting for MariaDB to be ready..."
RETRY_COUNT=0
MAX_RETRIES=60
until mariadb -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" -e "SELECT 1" >/dev/null 2>&1; do
	RETRY_COUNT=$((RETRY_COUNT + 1))
	if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
		echo "ERROR: MariaDB did not become available within timeout (${MAX_RETRIES} attempts)"
		exit 1
	fi
	echo "MariaDB is unavailable - sleeping (attempt $RETRY_COUNT/$MAX_RETRIES)"
	sleep 3
done
echo "MariaDB is up!"

# Wait for Redis (optional but good practice)
if [ ! -f /var/www/html/wp-config.php ]; then
	echo "Waiting for Redis to be ready..."
	REDIS_RETRY=0
	MAX_REDIS_RETRIES=30
	while ! redis-cli -h redis -p 6379 ping >/dev/null 2>&1; do
		REDIS_RETRY=$((REDIS_RETRY + 1))
		if [ $REDIS_RETRY -ge $MAX_REDIS_RETRIES ]; then
			echo "WARNING: Redis did not become available, continuing anyway..."
			break
		fi
		echo "Redis is unavailable - sleeping (attempt $REDIS_RETRY/$MAX_REDIS_RETRIES)"
		sleep 2
	done
	if redis-cli -h redis -p 6379 ping >/dev/null 2>&1; then
		echo "Redis is up!"
	fi

	echo "Configuring WordPress..."

	wp config create \
		--dbname="${MYSQL_DATABASE}" \
		--dbuser="${MYSQL_USER}" \
		--dbpass="${MYSQL_PASSWORD}" \
		--dbhost=mariadb \
		--allow-root

	wp core install \
		--url="${DOMAIN_NAME}" \
		--title="Inception" \
		--admin_user="${WP_ADMIN_USER}" \
		--admin_password="${WP_ADMIN_PASSWORD}" \
		--admin_email="${WP_ADMIN_EMAIL}" \
		--skip-email \
		--allow-root

	wp user create \
		"${WP_USER}" \
		"${WP_USER_EMAIL}" \
		--role=author \
		--user_pass="${WP_USER_PASSWORD}" \
		--allow-root

	# Install and activate Redis Object Cache plugin
	echo "Installing Redis Object Cache plugin..."
	wp plugin install redis-cache --activate --allow-root

	# Add Redis configuration to wp-config.php
	echo "Configuring Redis connection..."
	wp config set WP_REDIS_HOST "${REDIS_HOST}" --allow-root
	wp config set WP_REDIS_PORT "${REDIS_PORT}" --raw --allow-root
	wp config set WP_REDIS_DATABASE 0 --raw --allow-root
	wp config set WP_REDIS_TIMEOUT 1 --raw --allow-root
	wp config set WP_REDIS_READ_TIMEOUT 1 --raw --allow-root

	echo "Enabling Redis object cache..."
	wp redis enable --allow-root

	chown -R nobody:nobody /var/www/html

	echo "WordPress configuration complete!"
else
    echo "WordPress already configured, skipping..."
fi

echo "Starting PHP-FPM..."
exec "$@"
