#!/bin/sh
set -e	# "Exit immediately if any command fails"

# Read secrets
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)


echo "Waiting for MariaDB to be ready..."
until mariadb -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" -e "SELECT 1" >/dev/null 2>&1; do
	echo "MariaDB is unavailable - sleeping"
	sleep 3
done
echo "MariaDB is up!"

if [ ! -f /var/www/html/wp-config.php ]; then
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

	echo "WordPress configuration complete!"
else
    echo "WordPress already configured, skipping..."
fi

echo "Starting PHP-FPM..."
exec "$@"
