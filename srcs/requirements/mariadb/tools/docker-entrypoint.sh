#!/bin/sh
set -e	# "Exit immediately if any command fails"

# Validate required environment variables
if [ -z "$MYSQL_DATABASE" ]; then
	echo "ERROR: MYSQL_DATABASE environment variable is not set"
	exit 1
fi

if [ -z "$MYSQL_USER" ]; then
	echo "ERROR: MYSQL_USER environment variable is not set"
	exit 1
fi

if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo "Initializing database..."

	# Read from SECRETS (passwords)
	if [ ! -f "/run/secrets/db_root_password" ]; then
		echo "ERROR: db_root_password secret file not found"
		exit 1
	fi
	DB_ROOT_PWD=$(cat /run/secrets/db_root_password)

	if [ ! -f "/run/secrets/db_password" ]; then
		echo "ERROR: db_password secret file not found"
		exit 1
	fi
	DB_PWD=$(cat /run/secrets/db_password)

	# Read from ENVIRONMENT (names)
	DB_NAME=${MYSQL_DATABASE}
	DB_USER=${MYSQL_USER}

	echo "Creating database: ${DB_NAME}"
	echo "Creating user: ${DB_USER}"

	# Initialize database
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql

	# Start temporary MariaDB in background
	mariadbd --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0 --port=3306 &
	pid="$!"

	# Wait for MariaDB to start
	echo "Waiting for MariaDB to start..."
		for i in $(seq 30 -1 0); do  # More portable than {30..0}
		if mariadb -u root --skip-password -e 'SELECT 1' &>/dev/null; then
			echo "MariaDB ready!"
			break
		fi
		if [ "$i" -eq 0 ]; then
			echo "ERROR: MariaDB failed to start within timeout"
			exit 1
		fi
		sleep 1
	done

	# Run initialization SQL
	echo "Running initialization script..."
	mariadb -u root <<-'EOSQL'
		-- Secure the installation
		DELETE FROM mysql.user WHERE User='';
		DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
		DROP DATABASE IF EXISTS test;
		DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

		-- Set root password
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PWD}';

		-- Create database
		CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;

		-- Create user
		CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PWD}';

		-- Grant privileges
		GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';

		-- Flush privileges
		FLUSH PRIVILEGES;
	EOSQL

	# Stop temporary MariaDB
	if ! kill -s TERM "$pid" || ! wait "$pid"; then
		echo >&2 'MariaDB init process failed.'
		exit 1
	fi

	echo "Database initialization complete!"
else
	echo "Database already initialized, skipping..."
fi

# Start MariaDB as PID 1
echo "Starting MariaDB..."
exec "$@"
