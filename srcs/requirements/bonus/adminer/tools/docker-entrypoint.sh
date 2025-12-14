#!/bin/sh

# Start PHP-FPM in background
php-fpm83 -F &

# Start nginx in foreground
exec nginx -g "daemon off;"
