#!/bin/bash
set -e

# Read FTP password from Docker secret
FTP_PASSWORD=$(cat /run/secrets/ftp_user_password)

# Set default FTP user if not provided
FTP_USER=${FTP_USER:-ftpuser}

echo "Setting up FTP server..."

# Create FTP user if it doesn't exist
if ! id "$FTP_USER" &>/dev/null; then
    echo "Creating FTP user: $FTP_USER"
    adduser -D -h /var/www/html "$FTP_USER"
    echo "$FTP_USER:$FTP_PASSWORD" | chpasswd
fi

# Set proper ownership for WordPress directory
# The FTP user needs access to WordPress files
chown -R "$FTP_USER:$FTP_USER" /var/www/html

# Ensure the vsftpd secure chroot directory exists
mkdir -p /var/run/vsftpd/empty

echo "FTP server configured successfully"
echo "FTP user: $FTP_USER"
echo "WordPress directory: /var/www/html"

# Execute vsftpd in foreground (proper PID 1)
exec "$@"
