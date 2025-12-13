# Developer Documentation

## Overview

This document provides technical information for developers who want to set up, build, and modify the Inception project.

---

## Prerequisites

Before starting, ensure you have the following installed:

### Required Software

- **Docker** (20.10 or higher)
  ```bash
  docker --version
  ```

- **Docker Compose** (v2.0 or higher)
  ```bash
  docker compose version
  ```

- **Make**
  ```bash
  make --version
  ```

- **Git**
  ```bash
  git --version
  ```

### System Requirements

- At least 2GB of free disk space
- Sufficient permissions to run Docker commands
- Port 443 must be available

---

## Environment Setup from Scratch

### 1. Clone the Repository

```bash
git clone <repository-url>
cd inception
```

### 2. Create Data Directories

Create the directories where Docker volumes will store persistent data:

```bash
mkdir -p ~/data/mariadb
mkdir -p ~/data/wordpress
mkdir -p ~/data/static-site
```

### 3. Configure Environment Variables

Create or modify the `.env` file in `srcs/`:

```bash
# srcs/.env
DOMAIN_NAME=mmiilpal.42.fr

# Database configuration
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser

# WordPress Admin User
WP_ADMIN_USER=boss
WP_ADMIN_EMAIL=boss@example.com

# WordPress Regular User
WP_USER=user
WP_USER_EMAIL=user@example.com

# Path to data
DATA_PATH=${HOME}/data
```

### 4. Set Up Secrets

Create the `secrets/` directory and add password files:

```bash
mkdir -p secrets
```

Create each secret file (one password per file, no newlines):

**secrets/db_root_password.txt**
```
your_secure_root_password
```

**secrets/db_password.txt**
```
your_secure_db_password
```

**secrets/wp_admin_password.txt**
```
your_secure_admin_password
```

**secrets/wp_user_password.txt**
```
your_secure_user_password
```

**Important:** Use strong, unique passwords for production environments.

### 5. Configure Domain Name (Optional)

Add the domain to your `/etc/hosts` file:

```bash
sudo nano /etc/hosts
```

Add:
```
127.0.0.1    mmiilpal.42.fr
```

---

## Building and Launching

### Using the Makefile

The Makefile provides convenient commands for managing the project.

#### Build Docker Images

```bash
make build
```

This command:
1. Creates data directories if they don't exist
2. Copies static site files to `~/data/static-site/`
3. Builds all Docker images from Dockerfiles

#### Start Containers

```bash
make up
```

Starts all containers in detached mode (`-d`).

#### Build and Start (All-in-One)

```bash
make
# or
make all
```

Runs both `make build` and `make up`.

#### Stop Containers

```bash
make down
```

Stops all running containers without removing volumes.

#### Clean Up

```bash
# Remove containers and networks
make clean

# Full cleanup (removes volumes and data)
make fclean
```

**Warning:** `make fclean` deletes all data in `~/data/mariadb`, `~/data/wordpress`, and `~/data/static-site`.

#### Rebuild from Scratch

```bash
make re
```

Equivalent to `make fclean` followed by `make all`.

#### View Logs

```bash
make logs
```

Follows logs from all containers in real-time.

#### Check Container Status

```bash
make ps
```

Shows running containers and their health status.

---

## Docker Compose Commands

### Manual Container Management

If you prefer using Docker Compose directly:

```bash
cd srcs/

# Build images
docker compose build

# Start containers
docker compose up -d

# Stop containers
docker compose down

# View logs
docker compose logs -f

# List containers
docker compose ps

# Restart a specific service
docker compose restart nginx
```

### Individual Service Operations

```bash
# Restart a single service
docker compose restart mariadb

# View logs for one service
docker compose logs -f wordpress

# Rebuild and restart a service
docker compose up -d --build nginx
```

---

## Container Management

### Accessing Containers

Execute commands inside running containers:

```bash
# Access MariaDB shell
docker exec -it mariadb sh

# Access NGINX shell
docker exec -it nginx sh

# Access WordPress shell
docker exec -it wordpress sh

# Access Redis CLI
docker exec -it redis redis-cli
```

### Database Operations

**Connect to MariaDB:**
```bash
docker exec -it mariadb mariadb -u wpuser -p
# Enter password from secrets/db_password.txt
```

**Common SQL commands:**
```sql
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
SELECT * FROM wp_users;
EXIT;
```

### Volume Management

**List volumes:**
```bash
docker volume ls
```

**Inspect a volume:**
```bash
docker volume inspect inception_mariadb_data
docker volume inspect inception_wordpress_data
```

**Remove all volumes (WARNING: deletes data):**
```bash
docker volume prune
```

---

## Project Data Storage

### Volume Locations

All persistent data is stored using bind mounts:

| Container | Host Path | Container Path | Purpose |
|-----------|-----------|----------------|---------|
| MariaDB | `~/data/mariadb` | `/var/lib/mysql` | Database files |
| WordPress | `~/data/wordpress` | `/var/www/html` | WordPress files, themes, plugins, uploads |
| Static Site | `~/data/static-site` | (mounted to NGINX) | Static HTML files |

### How Data Persists

The project uses **bind mounts** (not Docker-managed volumes):
- Data is stored directly on your host machine at `~/data/`
- Survives container restarts and rebuilds
- Easy to backup by copying the `~/data/` directory
- Deleted only when you run `make fclean` or manually delete the directories

---

## Network Architecture

### Docker Network

All containers communicate over a bridge network named `inception_network`.

**Inspect the network:**
```bash
docker network inspect inception_network
```

**Container Communication:**
- Containers use service names as hostnames
- MariaDB accessible at `mariadb:3306`
- WordPress accessible at `wordpress:9000`
- Redis accessible at `redis:6379`
- NGINX is the only service exposed to the host (port 443)

---

## Service Details

### NGINX (Port 443)

**Dockerfile:** `srcs/requirements/nginx/Dockerfile`

- Base image: `alpine:3.21`
- Listens on port 443 (HTTPS only)
- SSL/TLS configuration for TLSv1.2 and TLSv1.3
- Routes requests to WordPress (FastCGI on port 9000)
- Serves static site at `/static/`

**Configuration:**
- Template: `srcs/requirements/nginx/conf/nginx.conf.template`
- Entrypoint: `srcs/requirements/nginx/tools/docker-entrypoint.sh`

### MariaDB (Port 3306)

**Dockerfile:** `srcs/requirements/mariadb/Dockerfile`

- Base image: `alpine:3.21`
- Internal port: 3306 (not exposed to host)
- Healthcheck verifies database connectivity
- Data stored in `~/data/mariadb`

**Configuration:**
- Config: `srcs/requirements/mariadb/conf/my.cnf`
- Entrypoint: `srcs/requirements/mariadb/tools/docker-entrypoint.sh`

### WordPress (Port 9000)

**Dockerfile:** `srcs/requirements/wordpress/Dockerfile`

- Base image: `alpine:3.21`
- PHP-FPM running on port 9000
- WP-CLI installed for WordPress management
- Redis object cache plugin configured
- Data stored in `~/data/wordpress`

**Configuration:**
- PHP-FPM config: `srcs/requirements/wordpress/conf/www.conf`
- Entrypoint: `srcs/requirements/wordpress/tools/docker-entrypoint.sh`

### Redis (Port 6379)

**Dockerfile:** `srcs/requirements/bonus/redis-cache/Dockerfile`

- Base image: `alpine:3.21`
- Internal port: 6379
- Provides object caching for WordPress

**Configuration:**
- Config: `srcs/requirements/bonus/redis-cache/conf/redis.conf`

---

## Debugging and Troubleshooting

### Check Container Logs

```bash
# All containers
make logs

# Specific container
docker logs mariadb
docker logs nginx
docker logs wordpress
docker logs redis
```

### Verify Container Health

```bash
# Quick status check
make ps

# Detailed inspection
docker inspect mariadb
docker inspect wordpress
```

### Test Services Manually

**Test MariaDB connection:**
```bash
docker exec mariadb mariadb -u wpuser -p$(cat secrets/db_password.txt) -e "SELECT 1"
```

**Test Redis:**
```bash
docker exec redis redis-cli ping
```

**Test NGINX:**
```bash
curl -k https://localhost
```

### Common Issues

**Port 443 already in use:**
```bash
sudo lsof -i :443
# Kill the process using the port
```

**Permission denied on data directories:**
```bash
chmod 755 ~/data/mariadb ~/data/wordpress ~/data/static-site
```

**Container keeps restarting:**
```bash
# Check logs for errors
docker logs <container-name>

# Check healthcheck status
docker inspect <container-name> | grep -A 10 Health
```

---

## Development Workflow

### Making Changes to Dockerfiles

1. Edit the Dockerfile in `srcs/requirements/<service>/`
2. Rebuild the specific service:
   ```bash
   docker compose -f srcs/docker-compose.yml build <service>
   ```
3. Restart the service:
   ```bash
   docker compose -f srcs/docker-compose.yml up -d <service>
   ```

### Modifying Configuration Files

1. Edit config files in `srcs/requirements/<service>/conf/`
2. Restart the affected service:
   ```bash
   docker compose -f srcs/docker-compose.yml restart <service>
   ```

### Testing Changes

```bash
# Rebuild everything
make re

# Check logs for errors
make logs

# Verify services
make ps
```

---

## Project Structure Reference

```
inception/
├── Makefile                    # Build automation
├── README.md                   # Project overview
├── USER_DOC.md                 # User documentation
├── DEV_DOC.md                  # Developer documentation (this file)
├── ARCHITECTURE.md             # Architectural details
├── TECHNICAL.md                # Technical deep dive
├── CHECKLIST.md                # Compliance checklist
├── secrets/                    # Passwords (gitignored)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
├── data/                       # Persistent data (gitignored)
│   ├── mariadb/
│   ├── wordpress/
│   └── static-site/
└── srcs/
    ├── .env                    # Environment variables (gitignored)
    ├── docker-compose.yml      # Service orchestration
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── bonus/
            ├── redis-cache/
            └── static-site/
```

---

## Best Practices

1. **Never commit secrets** - Keep `.env` and `secrets/` in `.gitignore`
2. **Use specific image tags** - Avoid `:latest` tag (we use `alpine:3.21`)
3. **Implement health checks** - All services have health checks configured
4. **Run as non-root when possible** - Redis runs as `redis` user
5. **Use Docker secrets** - Passwords stored in separate files, mounted as secrets
6. **Keep containers single-purpose** - One service per container
7. **Use bind mounts for development** - Easier debugging and backups
8. **Log to stdout/stderr** - Docker handles log collection

---

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Alpine Linux Packages](https://pkgs.alpinelinux.org/packages)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)
- [WordPress Developer Resources](https://developer.wordpress.org/)
- [Redis Documentation](https://redis.io/documentation)
