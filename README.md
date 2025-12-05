# Inception

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Alpine Linux](https://img.shields.io/badge/Alpine_Linux-0D597F?style=for-the-badge&logo=alpine-linux&logoColor=white)
![NGINX](https://img.shields.io/badge/NGINX-009639?style=for-the-badge&logo=nginx&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=for-the-badge&logo=mariadb&logoColor=white)
![WordPress](https://img.shields.io/badge/WordPress-21759B?style=for-the-badge&logo=wordpress&logoColor=white)
![42 Project](https://img.shields.io/badge/42-Project-000000?style=for-the-badge)

A Docker infrastructure project setting up a small network with NGINX, WordPress, and MariaDB using Docker Compose.

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [How to Use](#how-to-use)
- [Project Overview](#project-overview)
- [Testing & Verification](#testing--verification)
- [Troubleshooting](#troubleshooting)
- [Useful Docker Commands](#useful-docker-commands)
- [Documentation](#documentation)
- [Resources](#resources)

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

## Quick Start

**For the impatient:**

```bash
# Clone and navigate
git clone git@github.com:murairam/inception.git
cd inception

# Create necessary directories
mkdir -p ~/data/mariadb ~/data/wordpress ~/data/static-site

# Set up your .env file and secrets (see Configuration section)
# Then:
make

# Access your site at https://localhost
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

## License

This project is open source and available for educational purposes.

**Academic Integrity Notice:** This is a 42 School project. If you're working on the same assignment, use this as a reference but write your own code - that's how you learn!

---

**Author:** mmiilpal | **School:** 42 | **Project:** Inception
