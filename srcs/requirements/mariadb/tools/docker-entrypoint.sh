#!/bin/sh
set -e

if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo "Initializing database..."

	# Read from SECRETS (passwords)
	DB_ROOT_PWD=$(cat /run/secrets/db_root_password)
	DB_PWD=$(cat /run/secrets/db_password)

	# Read from ENVIRONMENT (names)
	# These come from .env via docker-compose
	DB_NAME=${MYSQL_DATABASE}
	DB_USER=${MYSQL_USER}

	# Initialize database
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql

	# Create init SQL
	cat > /tmp/init.sql << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PWD}';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PWD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

	# Run init script
	mysqld --user=mysql --bootstrap < /tmp/init.sql
	rm -f /tmp/init.sql
fi

# Start MariaDB as PID 1
exec "$@"
