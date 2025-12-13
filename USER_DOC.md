# User Documentation

## Overview

This Inception project provides a complete web infrastructure stack running on Docker, featuring:

- **WordPress CMS** - Content management system for creating and managing your website
- **MariaDB Database** - MySQL-compatible database storing WordPress data
- **NGINX Web Server** - Reverse proxy serving your website over HTTPS (port 443)
- **Redis Cache** - Performance optimization for WordPress
- **Static Website** - Simple HTML site accessible at `/static/`

All services run in isolated Docker containers and communicate over a private network.

---

## Quick Start

### Starting the Project

To start all services:

```bash
make
```

This will:
1. Create necessary data directories
2. Build all Docker images
3. Start all containers in the background

The project will be accessible at:
- **Main WordPress site:** https://mmiilpal.42.fr or https://localhost
- **WordPress admin:** https://mmiilpal.42.fr/wp-admin
- **Static site:** https://mmiilpal.42.fr/static/

### Stopping the Project

To stop all services:

```bash
make down
```

This stops all containers but preserves your data.

---

## Accessing the Website

### Main Website

Open your browser and navigate to:
```
https://mmiilpal.42.fr
```
or
```
https://localhost
```

**Note:** You'll see a security warning because the site uses a self-signed SSL certificate. This is normal for development. Click "Advanced" and "Proceed to localhost (unsafe)" to continue.

### WordPress Administration Panel

To access the WordPress admin dashboard:

1. Navigate to: https://mmiilpal.42.fr/wp-admin
2. Login with admin credentials (see "Managing Credentials" section)
3. You can now manage posts, pages, themes, and plugins

### Static Website

A simple static HTML site is available at:
```
https://mmiilpal.42.fr/static/
```

---

## Managing Credentials

### Location of Credentials

All passwords are stored securely in the `secrets/` directory at the project root:

```
secrets/
├── db_root_password.txt      # MariaDB root password
├── db_password.txt            # Database user password
├── wp_admin_password.txt      # WordPress admin password
└── wp_user_password.txt       # WordPress regular user password
```

### WordPress Users

The project creates two WordPress users:

**Administrator Account:**
- **Username:** boss (defined in srcs/.env as `WP_ADMIN_USER`)
- **Email:** boss@example.com
- **Password:** Located in `secrets/wp_admin_password.txt`
- **Capabilities:** Full administrative access

**Regular User Account:**
- **Username:** user (defined in srcs/.env as `WP_USER`)
- **Email:** user@example.com
- **Password:** Located in `secrets/wp_user_password.txt`
- **Capabilities:** Standard user access

### Database Credentials

**Database Configuration:**
- **Database name:** wordpress (from srcs/.env)
- **Database user:** wpuser (from srcs/.env)
- **User password:** Located in `secrets/db_password.txt`
- **Root password:** Located in `secrets/db_root_password.txt`

---

## Checking Service Status

### View Running Containers

```bash
make ps
```

Expected output - all containers should show status "Up" and "(healthy)":
```
NAME        STATUS
mariadb     Up X minutes (healthy)
nginx       Up X minutes (healthy)
wordpress   Up X minutes (healthy)
redis       Up X minutes (healthy)
```

### View Service Logs

To see logs from all services in real-time:

```bash
make logs
```

To view logs from a specific service:

```bash
docker logs mariadb
docker logs wordpress
docker logs nginx
docker logs redis
```

### Success Indicators

Your infrastructure is working correctly when:
- All containers show "Up" status with "(healthy)"
- NGINX logs show "ready for connections"
- MariaDB logs show "ready for connections"
- WordPress site loads at https://localhost
- You can login to wp-admin

---

## Troubleshooting

### Website Won't Load

**Check containers are running:**
```bash
make ps
```

**Check NGINX logs:**
```bash
docker logs nginx
```

**Restart the project:**
```bash
make down
make
```

### "Connection Refused" Error

Wait 30-60 seconds after starting. The services need time to initialize, especially MariaDB on first run.

### Can't Login to WordPress

1. Verify credentials in `secrets/wp_admin_password.txt`
2. Check WordPress container logs:
   ```bash
   docker logs wordpress
   ```
3. Ensure MariaDB is healthy:
   ```bash
   docker ps
   ```

### Port 443 Already in Use

Another service is using port 443. Find and stop it:
```bash
sudo lsof -i :443
```

### SSL Certificate Warning

This is normal for self-signed certificates in development. Click "Advanced" → "Proceed to localhost (unsafe)" in your browser.

---

## Data Management

### Where Data is Stored

All persistent data is stored in:
```
~/data/
├── mariadb/        # Database files
├── wordpress/      # WordPress files, uploads, themes, plugins
└── static-site/    # Static HTML files
```

### Backing Up Your Data

To backup your data:
```bash
# Backup database
cp -r ~/data/mariadb ~/data/mariadb-backup-$(date +%Y%m%d)

# Backup WordPress files
cp -r ~/data/wordpress ~/data/wordpress-backup-$(date +%Y%m%d)
```

### Resetting the Project

**Warning:** This will delete all your data!

```bash
make fclean
```

This removes all containers, volumes, and data. Use with caution.

---

## Domain Configuration

### Using Custom Domain (mmiilpal.42.fr)

To access the site using `https://mmiilpal.42.fr` instead of `https://localhost`, add this line to your `/etc/hosts` file:

```bash
sudo nano /etc/hosts
```

Add:
```
127.0.0.1    mmiilpal.42.fr
```

Save and exit. Now you can access the site at https://mmiilpal.42.fr

---

## Performance Features

### Redis Cache

Redis is configured to cache WordPress database queries, significantly improving page load times.

**Check Redis is working:**
```bash
docker exec redis redis-cli ping
```

Expected output: `PONG`

**View cached keys:**
```bash
docker exec redis redis-cli KEYS '*'
```

---

## Support

For technical issues or questions:
1. Check the logs: `make logs`
2. Review the developer documentation: `DEV_DOC.md`
3. Consult the project README: `README.md`
4. Review technical details: `TECHNICAL.md` and `ARCHITECTURE.md`
