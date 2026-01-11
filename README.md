*This project has been created as part of the 42 curriculum by mmiilpal*

# Inception

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Alpine Linux](https://img.shields.io/badge/Alpine_Linux-0D597F?style=for-the-badge&logo=alpine-linux&logoColor=white)
![NGINX](https://img.shields.io/badge/NGINX-009639?style=for-the-badge&logo=nginx&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=for-the-badge&logo=mariadb&logoColor=white)
![WordPress](https://img.shields.io/badge/WordPress-21759B?style=for-the-badge&logo=wordpress&logoColor=white)
![42 Project](https://img.shields.io/badge/42-Project-000000?style=for-the-badge)

---

## Description

The **Inception** project is a system administration exercise that challenges you to set up a small infrastructure composed of different services using Docker Compose. The goal is to virtualize multiple Docker images by creating them in a personal virtual machine, deepening your understanding of containerization, networking, and service orchestration.

This project implements a complete web infrastructure featuring:
- **NGINX** web server with TLSv1.2/1.3 SSL encryption acting as the sole entry point
- **WordPress** content management system with PHP-FPM for dynamic content
- **MariaDB** database for persistent data storage
- **Redis** cache for WordPress performance optimization (bonus)
- **Static website** served alongside WordPress (bonus)

All services run in isolated Docker containers built from scratch (no pre-built images from Docker Hub), communicate over a dedicated Docker network, and store data in persistent volumes. The infrastructure demonstrates modern microservices architecture principles while maintaining security through proper isolation and secret management.

---

## Table of Contents

- [Description](#description)
- [Instructions](#instructions)
- [Features](#features)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [How to Use](#how-to-use)
- [Project Overview](#project-overview)
- [Testing & Verification](#testing--verification)
- [Troubleshooting](#troubleshooting)
- [Useful Docker Commands](#useful-docker-commands)
- [Documentation](#documentation)
- [Resources](#resources)
- [Project Description & Design Choices](#project-description--design-choices)

---

## Features

- **Multi-container Docker infrastructure** orchestrated with Docker Compose
- **NGINX web server** with TLSv1.2/1.3 SSL encryption
- **WordPress CMS** with PHP-FPM
- **MariaDB database** for persistent data storage
- **Redis object cache** for WordPress performance optimization
- **Static website** served alongside WordPress
- **Alpine Linux base** for minimal footprint and security
- **Automatic container restarts** and health checks
- **Persistent storage** using Docker volumes
- **Isolated network** with service-based DNS resolution

---

## Prerequisites

Before you start, make sure you have these installed:

- **Docker** (20.10 or higher)
- **Docker Compose** (v2.0 or higher)
- **Make** (for running Makefile commands)
- **Git** (to clone the repository)

Your system should have:
- At least 2GB of free disk space
- Sufficient permissions to run Docker commands

---

## Instructions

### Prerequisites

Before you start, make sure you have these installed:

- **Docker** (20.10 or higher)
- **Docker Compose** (v2.0 or higher)
- **Make** (for running Makefile commands)
- **Git** (to clone the repository)

Your system should have:
- At least 2GB of free disk space
- Sufficient permissions to run Docker commands
- Port 443 available

### Installation & Setup

**1. Clone and navigate to the project:**

```bash
git clone git@github.com:murairam/inception.git
cd inception
```

**2. Create necessary data directories:**

```bash
mkdir -p ~/data/mariadb ~/data/wordpress ~/data/static-site
```

**3. Configure environment variables:**

Create a `.env` file in the `srcs/` directory:

```bash
# Domain Configuration
DOMAIN_NAME=mmiilpal.42.fr

# Database Configuration
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser

# WordPress Admin User
WP_ADMIN_USER=boss
WP_ADMIN_EMAIL=boss@example.com

# WordPress Regular User
WP_USER=user
WP_USER_EMAIL=user@example.com

# Path to data directories
DATA_PATH=${HOME}/data
```

**4. Create secret files:**

Create these files in the `secrets/` directory (one password per file, no newlines):

```bash
echo "your_root_password" > secrets/db_root_password.txt
echo "your_db_password" > secrets/db_password.txt
echo "your_admin_password" > secrets/wp_admin_password.txt
echo "your_user_password" > secrets/wp_user_password.txt
```

**5. Build and start the infrastructure:**

```bash
make
```

**6. Access your site:**

Open your browser to `https://localhost` or `https://mmiilpal.42.fr` (you'll need to accept the self-signed certificate warning).

### Compilation & Execution

The project uses a Makefile to simplify Docker operations:

- `make` or `make all` - Build images and start all containers
- `make build` - Build Docker images only
- `make up` - Start containers (must build first)
- `make down` - Stop all containers
- `make clean` - Stop and remove containers/networks
- `make fclean` - Full cleanup including volumes and data
- `make re` - Clean and rebuild everything
- `make logs` - View container logs in real-time
- `make ps` - Show running containers

### Stopping the Infrastructure

```bash
make down  # Stop containers, keep data
make clean  # Stop and remove containers
make fclean  # Complete cleanup including data
```

---

## Project Structure

```
inception/
├── Makefile
├── README.md
├── EVALUATION.md           # Evaluation commands and checklist
├── TECHNICAL.md            # Deep technical explanations
├── ARCHITECTURE.md         # Detailed architecture documentation
├── secrets/
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        │       └── docker-entrypoint.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── nginx.conf.template
        │   └── tools/
        │       └── docker-entrypoint.sh
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── www.conf
        │   └── tools/
        │       └── docker-entrypoint.sh
        └── bonus/
            ├── redis-cache/
            │   ├── Dockerfile
            │   └── conf/
            └── static-site/
                ├── Dockerfile
                ├── conf/
                │   └── nginx.conf
                └── www/
                    ├── index.html
                    └── Elmo.png
```

---

## Configuration

### Environment Variables (.env)

Create a `.env` file in the `srcs/` directory with the following variables:

```bash
# Domain Configuration
DOMAIN_NAME=mmiilpal.42.fr

# Database Configuration
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser

# WordPress Admin User
WP_ADMIN_USER=boss
WP_ADMIN_EMAIL=boss@example.com

# WordPress Regular User
WP_USER=user
WP_USER_EMAIL=user@example.com

# Path to data directories
DATA_PATH=${HOME}/data
```

**Note:** The actual passwords are stored in separate secret files (see below) for better security.

### Secrets Files

Create these files in the `secrets/` directory (one password per file, no newlines):

**`secrets/db_root_password.txt`**
```
your_root_password_here
```

**`secrets/db_password.txt`**
```
your_database_user_password_here
```

**`secrets/wp_admin_password.txt`**
```
your_wordpress_admin_password_here
```

**`secrets/wp_user_password.txt`**
```
your_wordpress_user_password_here
```

**Why separate secret files?**
- Docker secrets provide better security than environment variables
- Passwords aren't accidentally committed to Git
- Easier to manage sensitive data in production

---

## How to Use

**Start your project:**
```bash
make
```
This runs `make all` which builds and starts everything.

**Stop containers:**
```bash
make down
```

**View logs:**
```bash
make logs
```

**Clean everything and rebuild:**
```bash
make re
```

**Full cleanup (remove data too):**
```bash
make fclean
```

### What Each Target Does

- `all` - Default, builds and starts
- `build` - Creates the data directories and builds Docker images
- `up` - Starts containers in detached mode (-d)
- `down` - Stops containers
- `clean` - Stops and removes containers/networks
- `fclean` - Full cleanup including volumes and data directories
- `re` - Clean everything and rebuild from scratch
- `logs` - Follow logs in real-time
- `ps` - Show running containers

**Note about data cleanup:**
If you encounter permission issues when deleting data directories, you may need to use `sudo` since Docker can create files as root inside volumes.

---

## Project Overview

### Container Architecture

```
┌─────────────────┐
│  User (browser) │
└────────┬────────┘
         │ HTTPS (port 443) ← Only port exposed to host
         ↓
┌────────────────────────────┐
│  NGINX container           │
│  (Reverse Proxy)           │
│  - Routes / → WordPress    │
│  - Routes /static/ → HTML  │
└────────┬───────────────────┘
         │ FastCGI (port 9000) ← Internal Docker network
         ↓
┌─────────────────────────┐
│ WordPress+PHP-FPM       │──┐
│ container               │  │ Redis (port 6379)
└────────┬────────────────┘  │
         │                    ↓
         │              ┌──────────────────┐
         │              │ Redis container  │
         │              └──────────────────┘
         │
         │ MySQL (port 3306) ← Internal Docker network
         ↓
┌──────────────────┐
│ MariaDB container│
└──────────────────┘
```

### Key Architecture Points

**Port Mapping:**
- **External (host machine):** Only port `443` is exposed to your browser
- **Internal (Docker network):** Ports `9000` and `3306` are only accessible between containers
- This means: MariaDB and WordPress are NOT accessible from your host machine directly (security!)

**Container Dependencies & Health Checks:**
- **MariaDB** starts first (no dependencies) with a healthcheck that verifies database connectivity
- **WordPress** waits for MariaDB to be healthy before starting (depends_on with service_healthy condition)
- **NGINX** waits for WordPress to be healthy before starting
- This ensures proper startup order and prevents connection errors

**Network:**
All containers are connected via a **Docker bridge network** called `inception_network`. This allows them to:
- Communicate using container names as hostnames (e.g., `mariadb:3306`, `wordpress:9000`)
- Stay isolated from the host network (except for the exposed 443 port)
- Benefit from Docker's built-in DNS resolution

**Volumes:**
- **MariaDB** (`~/data/mariadb`) - Database files, WordPress content (posts, users, settings)
- **WordPress** (`~/data/wordpress`) - WordPress PHP files, themes, plugins, uploaded media
- **Static Site** (`~/data/static-site`) - Static HTML files and assets

For detailed architecture information, see [ARCHITECTURE.md](ARCHITECTURE.md).

---

## Testing & Verification

Once everything is running, verify your setup:

**1. Check container status:**
```bash
make ps
# Expected: All containers running and healthy
```

**2. Access the website:**
- Open your browser to `https://localhost` or `https://mmiilpal.42.fr` (if you added it to `/etc/hosts`)
- You'll see a security warning (normal for self-signed certificates) - click "Advanced" and proceed
- You should see your WordPress site!
- **Bonus:** Access the static site at `https://localhost/static/` or `https://mmiilpal.42.fr/static/`

**3. Login to WordPress admin:**
- Navigate to `https://localhost/wp-admin`
- Use the admin credentials from your secrets (username: `boss`)

**4. Check database connection:**
```bash
# Connect to MariaDB container
docker exec -it mariadb mariadb -u wpuser -p
# Enter the password from secrets/db_password.txt

# Once connected, run these SQL commands:
mysql> SHOW DATABASES;
mysql> USE wordpress;
mysql> SHOW TABLES;
mysql> SELECT * FROM wp_users;  # See WordPress users
mysql> EXIT;
```

**5. Test Redis cache:**
```bash
# Verify Redis is running
docker exec redis redis-cli ping
# Expected: PONG

# Check cached keys (after using WordPress)
docker exec redis redis-cli KEYS '*'
# Expected: Many keys like wp:options:*, wp:posts:*, etc.
```

**Common success indicators:**
- No container restarts (check `STATUS` in `make ps`)
- WordPress installation page appears (or existing site if already set up)
- NGINX shows "ready for connections" in logs
- MariaDB shows "ready for connections" in logs
- WordPress shows "MariaDB is up!" in logs

For complete evaluation commands, see [EVALUATION.md](EVALUATION.md).

---

## Troubleshooting

### WordPress can't connect to MariaDB
**Problem:** WordPress logs show "MariaDB is unavailable"

**Solutions:**
- Wait longer (MariaDB takes ~10-15 seconds to initialize on first run)
- Check MariaDB container is running: `docker ps`
- Verify database credentials match between docker-compose and secrets
- Check network: `docker network inspect inception_network`

### Port 443 already in use
**Problem:** `Error: bind: address already in use`

**Solutions:**
```bash
# Find what's using port 443
sudo lsof -i :443

# If it's another service, stop it or change the port in docker-compose.yml
```

### Permission denied errors
**Problem:** Can't access `~/data/mariadb`, `~/data/wordpress`, or `~/data/static-site`

**Solutions:**
```bash
# Create directories with proper permissions
mkdir -p ~/data/mariadb ~/data/wordpress ~/data/static-site
chmod 755 ~/data/mariadb ~/data/wordpress ~/data/static-site

# If issues persist, check Docker has permission to access your home directory
```

### Self-signed certificate warnings
**Problem:** Browser shows "Your connection is not private"

**This is expected!** Self-signed certificates always trigger this warning. Click "Advanced" and "Proceed to localhost (unsafe)" to continue.

### Container keeps restarting
**Problem:** Container repeatedly crashes

**Debug steps:**
```bash
# Check specific container logs
docker logs mariadb
docker logs wordpress
docker logs nginx

# Check container exit code
docker ps -a

# Inspect container
docker inspect mariadb
```

---

## Useful Docker Commands

**Container Management:**
```bash
# List all containers (including stopped)
docker ps -a

# Stop/start/restart a container
docker stop nginx
docker start nginx
docker restart mariadb

# Remove a container
docker rm -f wordpress
```

**Logs and Debugging:**
```bash
# Follow logs for specific container
docker logs -f mariadb

# Show last 50 lines
docker logs --tail 50 wordpress

# Execute command inside container
docker exec -it nginx sh

# Inspect container details
docker inspect nginx
```

**Network Management:**
```bash
# List networks
docker network ls

# Inspect network
docker network inspect inception_network

# See which containers are on a network
docker network inspect inception_network | grep Name
```

**System Cleanup:**
```bash
# Remove everything unused (be careful!)
docker system prune -a --volumes

# Check disk usage
docker system df
```

---

## Documentation

This project includes detailed documentation split across multiple files:

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Detailed architecture explanations
  - Network topology and container connections
  - Volume management and data flow
  - Port mapping and service dependencies

- **[TECHNICAL.md](TECHNICAL.md)** - Deep technical details
  - Docker fundamentals
  - Service-specific configurations (MariaDB, NGINX, WordPress, Redis)
  - Core concepts (SSL/TLS, PID 1, etc.)
  - FAQ and technical questions

- **[CHECKLIST.md](CHECKLIST.md)** - Checklist
  - Complete checklist for project compability with the subject
  - Verification commands
  - Expected outputs and success indicators

---

## Resources

### Official Documentation
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Volumes](https://docs.docker.com/engine/storage/volumes/)
- [NGINX Beginner's Guide](https://nginx.org/en/docs/beginners_guide.html)
- [NGINX Request Processing](https://nginx.org/en/docs/http/request_processing.html)

### Security & Encryption
- [Cloudflare - What is SSL?](https://www.cloudflare.com/en-gb/learning/ssl/what-is-ssl/)

### Tutorials & Guides
- [Docker Curriculum](https://docker-curriculum.com/?source=post_page-----cfda98d9f4ac--------------------------------#introduction)
- [Inception Tutorial (GradeMe)](https://tuto.grademe.fr/inception/#)

### Technical Articles
- [The Linux Process Journey: PID 1 & Init](https://medium.com/@boutnaruthe-linux-process-journey-pid-1-init-60765a069f17)
- [Docker Processes in a Container](https://cloud.theodo.com/en/blog/docker-processes-container)
- [Benchmarking Debian vs Alpine as Base Docker Image](https://nickjanetakis.com/blog/benchmarking-debian-vs-alpine-as-a-base-docker-image)
- [Alpine vs Debian: What They Actually Do](https://hoop.dev/blog/what-alpine-debian-actually-does-and-when-to-use-it/)
- [Linux Beyond the Basics: cgroups](https://medium.com/@weidagang/linux-beyond-the-basics-cgroups-f157d93bd755)
- [Unveiling 42 Network: Inception - A Dive into Docker and Docker Compose](https://medium.com/@afatir.ahmedfatir/unveiling-42-the-network-inception-a-dive-into-docker-and-docker-compose-cfda98d9f4ac)

### Redis & Caching
- [Caching: In-Memory and Redis Caches](https://medium.com/the-modern-scientist/caching-a-dive-into-in-memory-and-redis-caches-7b9491a1fa1b)
- [Redis Cache Plugin for WordPress](https://wordpress.org/plugins/redis-cache/)
- [Set up a Redis Cache in Docker](https://github.com/AzureAD/microsoft-identity-web/wiki/Set-up-a-Redis-cache-in-Docker)

### Video Tutorials
- [Docker Crash Course](https://www.youtube.com/watch?v=pg19Z8LL06w)
- [Rapid Docker Tutorial](https://www.youtube.com/watch?v=DQdB7wFEygo)
- [Tutorial about NGINX](https://www.youtube.com/watch?v=iInUBOVeBCc)
- [Docker Lecture: What Containers Are Made From (Excellent)](https://www.youtube.com/watch?v=sK5i-N34im8)
- [NGINX Explained in 100 Seconds](https://www.youtube.com/watch?v=JKxlsvZXG7c)
- [Proxy vs Reverse Proxy](https://www.youtube.com/watch?v=4NB0NDtOwIQ)
- [FastCGI Crash Course](https://www.youtube.com/watch?v=hEXBgQ71rvE)

### Community Resources
- [Awesome Docker - Curated List of Docker Resources](https://github.com/veggiemonk/awesome-docker)
- [Awesome Selfhosted - Self-hosted Software List](https://github.com/awesome-selfhosted/awesome-selfhosted)

### AI Usage in This Project

Artificial Intelligence tools were used throughout this project to enhance development efficiency and code quality:

**Tasks where AI was used:**
- **Documentation Writing:** AI assisted in structuring and writing comprehensive documentation (README.md, TECHNICAL.md, ARCHITECTURE.md) by suggesting clear explanations of Docker concepts, formatting markdown tables, and organizing content logically
- **Configuration Optimization:** AI helped optimize Docker configurations, suggesting best practices for NGINX configs, PHP-FPM settings, and MariaDB tuning parameters
- **Debugging Support:** AI was consulted when troubleshooting container connectivity issues, permission problems, and service health checks
- **Shell Script Refinement:** AI reviewed and improved the docker-entrypoint.sh scripts for better error handling and signal management
- **Security Best Practices:** AI provided guidance on implementing proper secret management, TLS configuration, and container security measures
- **Resource Research:** AI helped find and validate relevant documentation, articles, and tutorials for Docker, NGINX, WordPress, and MariaDB

**Parts of the project involving AI:**
- All documentation files (README.md, TECHNICAL.md, ARCHITECTURE.md, USER_DOC.md, DEV_DOC.md)
- Refinement of configuration files (nginx.conf, php.ini, redis.conf)
- Optimization of entrypoint scripts for proper PID 1 handling
- Troubleshooting and debugging complex networking issues

**AI tools used:**
- GitHub Copilot (code suggestions, inline documentation)
- ChatGPT/Claude (architectural decisions, documentation, debugging assistance)

**Note:** While AI provided significant assistance, all final implementation decisions, testing, and validation were performed manually. The core Dockerfiles, docker-compose.yml, and architectural design were developed with human oversight to ensure they met project requirements.

---

## About This Project

This is my implementation of the **Inception project** from 42 School. The goal is to set up a small infrastructure using Docker Compose with the following requirements:

- Each service runs in a dedicated container
- Containers are built from either Alpine or Debian (I chose Alpine)
- Custom Dockerfiles for each service (no pre-built images from Docker Hub)
- Containers must restart automatically on crash
- TLSv1.2 or TLSv1.3 only for NGINX
- A Docker network to connect all services
- Volumes for persistent data storage

This project teaches Docker fundamentals, networking, and system administration.

---

## Project Description & Design Choices

### Why Docker?

This project uses **Docker containers** instead of traditional virtual machines to create an isolated, reproducible infrastructure. Below are the key architectural decisions and comparisons that shaped this implementation.

### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker Containers | Our Choice |
|--------|------------------|-------------------|------------|
| **Overhead** | Heavy - runs full OS with kernel | Lightweight - shares host kernel | ✅ Docker |
| **Startup Time** | Minutes (full OS boot) | Seconds (process startup) | ✅ Docker |
| **Resource Usage** | High - each VM reserves RAM/CPU | Low - uses only what's needed | ✅ Docker |
| **Isolation** | Complete OS-level isolation | Process-level isolation | ✅ Docker |
| **Portability** | VM images (large, platform-specific) | Dockerfiles (small, reproducible) | ✅ Docker |
| **Use Case** | Different OS, strong isolation | Microservices, development | ✅ Docker |

**Why Docker for this project:**
- Each service (NGINX, WordPress, MariaDB) is a lightweight container
- Fast startup and rebuild times during development
- Containers share the host kernel, reducing overhead
- Easy to reproduce the exact environment using Dockerfiles
- Perfect for microservices architecture

### Secrets vs Environment Variables

| Aspect | Environment Variables | Docker Secrets | Our Choice |
|--------|----------------------|----------------|------------|
| **Storage** | Plain text in .env or docker-compose.yml | Encrypted at rest, mounted in memory | ✅ Secrets |
| **Visibility** | Visible in `docker inspect` and process list | Not visible in inspect or logs | ✅ Secrets |
| **Version Control** | Risk of accidental commit | Separate files, gitignored | ✅ Secrets |
| **Access** | Available as environment variables | Mounted as files in `/run/secrets/` | ✅ Secrets |
| **Security** | ⚠️ Low - easily exposed | ✅ High - encrypted and secure | ✅ Secrets |

**Our implementation:**
- All passwords stored in `secrets/` directory
- Mounted to containers via Docker secrets
- Never committed to Git (`.gitignore` excludes `secrets/*.txt`)
- Non-sensitive config (domain, usernames) use environment variables in `.env`

```yaml
# Example from docker-compose.yml
secrets:
  db_password:
    file: ../secrets/db_password.txt
  wp_admin_password:
    file: ../secrets/wp_admin_password.txt
```

### Docker Network vs Host Network

| Aspect | Host Network | Docker Bridge Network | Our Choice |
|--------|--------------|----------------------|------------|
| **Isolation** | No isolation - uses host's network stack | Isolated network namespace | ✅ Bridge |
| **Port Conflicts** | Can conflict with host services | Internal ports isolated | ✅ Bridge |
| **Security** | Services exposed to host network | Only exposed ports accessible | ✅ Bridge |
| **DNS Resolution** | Manual IP management | Automatic service name DNS | ✅ Bridge |
| **Performance** | Slightly faster (no NAT) | Minimal overhead with NAT | ✅ Bridge |

**Our implementation:**
- Custom bridge network: `inception_network`
- Containers communicate using service names (e.g., `mariadb:3306`, `wordpress:9000`)
- Only NGINX port 443 exposed to host
- MariaDB and WordPress ports remain internal (secure by default)

```yaml
# Example inter-container communication
# WordPress connects to MariaDB using hostname
DB_HOST=mariadb:3306

# NGINX proxies to WordPress using hostname
fastcgi_pass wordpress:9000;
```

**Why we avoid host network:**
- Subject explicitly forbids `network: host`
- Breaks container isolation
- Makes the infrastructure non-portable
- Exposes all services directly to the host

### Docker Volumes vs Bind Mounts

| Aspect | Docker-Managed Volumes | Bind Mounts | Our Choice |
|--------|------------------------|-------------|------------|
| **Location** | Docker's internal directory (`/var/lib/docker/volumes/`) | User-specified host path | ✅ Bind Mounts |
| **Portability** | More portable across systems | Path must exist on host | ⚠️ Trade-off |
| **Backup** | Requires Docker commands | Simple directory copy | ✅ Bind Mounts |
| **Performance** | Optimized by Docker | Direct host filesystem access | ✅ Bind Mounts |
| **Visibility** | Hidden in Docker internals | Easily browsable at `~/data/` | ✅ Bind Mounts |
| **Permissions** | Docker manages | Manual setup required | ⚠️ Trade-off |

**Our implementation:**
- Bind mounts to `~/data/` (as required by subject)
- Easy access and backup: just copy `~/data/mariadb`, `~/data/wordpress`
- Data persists even if containers are removed
- Clear visibility of what's stored

```yaml
# Example bind mount configuration
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${DATA_PATH}/mariadb
```

**Subject requirement:**
> "Your volumes will be available in the /home/login/data folder of the host machine using Docker."

This mandates bind mounts to a specific host path rather than Docker-managed volumes.

### Additional Design Choices

**Base Image: Alpine Linux 3.21**
- Minimal attack surface (5MB base image vs 124MB for Debian)
- Faster builds and deployments
- Security-focused with musl libc
- apk package manager is simple and fast

**Health Checks:**
- Every service has a health check defined
- Ensures services start in correct order
- WordPress waits for MariaDB to be healthy
- NGINX waits for WordPress to be healthy

**Single Process per Container (PID 1):**
- No process managers like `systemd` or `supervisord`
- Daemons run in foreground mode (`nginx -g "daemon off;"`, `php-fpm83 -F`)
- No hacky patches like `tail -f` or `sleep infinity`
- Proper signal handling for graceful shutdown

**Security:**
- NGINX is the only entrypoint (port 443)
- TLSv1.2 and TLSv1.3 only (no outdated SSL/TLS)
- No hardcoded passwords in Dockerfiles
- Redis runs as non-root user
- Self-signed certificates for development (would use Let's Encrypt in production)

---

## License

This project is open source and available for educational purposes.

**Academic Integrity Notice:** This is a 42 School project. If you're working on the same assignment, use this as a reference but write your own code - that's how you learn!

---

**Author:** mmiilpal | **School:** 42 | **Project:** Inception
