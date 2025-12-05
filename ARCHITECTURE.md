# Inception - Architecture Details

This document provides an in-depth look at the project architecture, container connections, network topology, and volume management.

---

## Table of Contents

- [System Overview](#system-overview)
- [Container Architecture](#container-architecture)
- [Network Topology](#network-topology)
- [Volume Management](#volume-management)
- [Port Mapping](#port-mapping)
- [Service Dependencies](#service-dependencies)
- [Data Flow](#data-flow)

---

## System Overview

The Inception project creates a multi-container Docker infrastructure with the following services:
- **NGINX** - Web server and reverse proxy (handles HTTPS)
- **WordPress** - CMS with PHP-FPM
- **MariaDB** - Database backend
- **Redis** - Object cache (bonus)
- **Static Site** - Simple HTML site (bonus)

All services run on Alpine Linux 3.21 for minimal footprint and security.

---

## Container Architecture

### Visual Representation

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
│ container               │  │ Redis protocol (port 6379)
└────────┬────────────────┘  │ ← Internal Docker network
         │                    │
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

### Container Details

| Container | Base Image | Purpose | Exposed Ports | Internal Ports |
|-----------|------------|---------|---------------|----------------|
| nginx | Alpine 3.21 | Web server, SSL termination | 443 (HTTPS) | 443 |
| wordpress | Alpine 3.21 | WordPress with PHP-FPM | None | 9000 (FastCGI) |
| mariadb | Alpine 3.21 | Database server | None | 3306 (MySQL) |
| redis | Alpine 3.21 | Object cache | None | 6379 (Redis) |
| static-site | Alpine 3.21 | Static HTML site | None | 80 (HTTP) |

---

## Network Topology

### Bridge Network: `inception_network`

All containers are connected via a custom Docker bridge network. This provides:
- **Container-to-container communication** using service names as hostnames
- **DNS resolution** automatically handled by Docker
- **Network isolation** from the host and other Docker networks
- **Security** through controlled port exposure

### DNS Resolution

Docker's built-in DNS server resolves container names:
- `mariadb:3306` → Internal IP of mariadb container
- `wordpress:9000` → Internal IP of wordpress container
- `redis:6379` → Internal IP of redis container

This allows services to communicate without hardcoded IP addresses.

### Network Configuration in docker-compose.yml

```yaml
networks:
  inception_network:
    driver: bridge
    name: inception_network

services:
  nginx:
    networks:
      - inception_network
  # ... other services
```

---

## Volume Management

### Why Bind Mounts?

The project uses bind mounts (`~/data`) instead of Docker-managed volumes:
- **Easier to inspect and backup** (just regular directories on your host)
- **Simpler for development** (you can see the files directly)
- **Required by 42 project specifications**
- **Portability** across different systems using `${DATA_PATH}` variable

**Downside:** May need `sudo` to clean up if Docker writes files as root.

### Volume Implementation

The volumes use bind mounts configured in docker-compose.yml with `driver_opts`:

```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${DATA_PATH}/mariadb
```

The `${DATA_PATH}` variable from `.env` (set to `${HOME}/data`) is used as the `device` path, making the configuration portable across different systems.

### Volume Breakdown

#### Volume 1: MariaDB Data (`~/data/mariadb`)

**Location:** `/var/lib/mysql` inside container

**Contains:**
- Database files (actual MySQL/MariaDB data)
- WordPress posts, pages, users, settings
- All database tables and indexes
- System databases (mysql, information_schema, etc.)

**Why it's needed:**
Without this volume, all database data would be lost when the container restarts.

#### Volume 2: WordPress Data (`~/data/wordpress`)

**Location:** `/var/www/html` inside container

**Contains:**
- WordPress PHP files
- Themes and plugins
- Uploaded media (images, videos, documents)
- `wp-config.php` (WordPress configuration)
- `.htaccess` file

**Why it's needed:**
Preserves WordPress installation, customizations, and uploaded content across container restarts.

#### Volume 3: Static Site Data (`~/data/static-site`)

**Location:** `/var/www/static` inside nginx container

**Contains:**
- Static HTML files
- Images and assets
- CSS/JS files for the bonus static website

**Why it's needed:**
Serves the bonus static website at `https://mmiilpal.42.fr/static/`

---

## Port Mapping

### External Port (Host → Container)

Only **one port** is exposed to the host machine:

```
Host Port 443 → NGINX Container Port 443
```

This means:
- Only HTTPS traffic from your browser reaches the infrastructure
- HTTP (port 80) is not available (intentional security measure)
- MariaDB and WordPress are completely isolated from the host

### Internal Ports (Container → Container)

Within the Docker network, containers communicate using these ports:

| Service | Port | Protocol | Used By |
|---------|------|----------|---------|
| mariadb | 3306 | MySQL | WordPress |
| wordpress | 9000 | FastCGI | NGINX |
| redis | 6379 | Redis | WordPress |
| static-site | 80 | HTTP | NGINX (internal proxy) |

**Important:** These ports are **NOT** accessible from the host machine. They only work within the Docker network.

### Why This Design?

- **Security:** Database and application server are not directly accessible from the internet
- **Single Entry Point:** All traffic goes through NGINX, which acts as a gatekeeper
- **SSL Termination:** NGINX handles HTTPS, internal traffic can be unencrypted (faster)
- **Best Practice:** Follows the principle of least exposure

---

## Service Dependencies

### Startup Order with Health Checks

The project uses Docker's `depends_on` with `condition: service_healthy` to ensure proper startup order:

```yaml
services:
  mariadb:
    # No dependencies - starts first
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 5s
      timeout: 5s
      retries: 10

  wordpress:
    depends_on:
      mariadb:
        condition: service_healthy  # Waits for MariaDB
    healthcheck:
      test: ["CMD-SHELL", "pidof php-fpm"]
      interval: 5s
      timeout: 5s
      retries: 10

  nginx:
    depends_on:
      wordpress:
        condition: service_healthy  # Waits for WordPress
```

### Startup Sequence

1. **MariaDB** starts first
   - Initializes database (if first run)
   - Health check verifies connection
   - Marked as "healthy" when ready

2. **WordPress** starts after MariaDB is healthy
   - Connects to database
   - Installs/configures WordPress (if needed)
   - Starts PHP-FPM
   - Health check verifies PHP-FPM is running

3. **NGINX** starts after WordPress is healthy
   - Generates SSL certificate (if needed)
   - Loads configuration
   - Starts accepting HTTPS connections

4. **Redis** starts independently (no dependencies)
   - WordPress connects to it once running

### Why Health Checks Matter

Without health checks:
- WordPress might try to connect before MariaDB is ready → connection errors
- NGINX might forward requests before WordPress is ready → 502 Bad Gateway
- Container might appear "running" but service isn't actually functional

With health checks:
- Each service waits for its dependencies to be fully operational
- Reduces startup errors and race conditions
- Provides clear status indicators (`docker ps` shows "healthy")

---

## Data Flow

### Request Flow: User → WordPress

1. **User types `https://mmiilpal.42.fr` in browser**
   - Browser sends HTTPS request to port 443

2. **Request reaches NGINX container**
   - NGINX terminates SSL/TLS connection
   - Decrypts HTTPS traffic
   - Checks location blocks for routing

3. **NGINX routes to WordPress**
   - For `.php` files: Forwards to `wordpress:9000` via FastCGI
   - For static files: Serves directly from `/var/www/html`

4. **WordPress processes request**
   - PHP-FPM executes WordPress PHP code
   - WordPress checks Redis cache first
   - If cache miss: Queries MariaDB at `mariadb:3306`
   - Generates HTML response

5. **Response flows back**
   - WordPress → NGINX (FastCGI)
   - NGINX encrypts response with SSL
   - NGINX → User's browser (HTTPS)

### Database Query Flow

```
WordPress → "Do I have this in cache?"
    ↓ (yes) → Redis → Return cached data
    ↓ (no)
MariaDB → Query database → Store result in Redis → Return data
```

### File Upload Flow

1. User uploads image to WordPress
2. WordPress saves file to `/var/www/html/wp-content/uploads/`
3. File is written to `~/data/wordpress/` volume (persistent)
4. Database record created in MariaDB
5. Future requests for the image:
   - NGINX serves directly from `/var/www/html/...` (no PHP needed)

---

## Configuration Management

### Environment Variables (.env)

The `.env` file in `srcs/` contains non-sensitive configuration:
- `DOMAIN_NAME` - Domain for NGINX and WordPress
- `MYSQL_DATABASE` - Database name
- `MYSQL_USER` - Database username (not password)
- `WP_ADMIN_USER`, `WP_USER` - WordPress usernames
- `DATA_PATH` - Path for volume bind mounts

### Docker Secrets (secrets/)

Sensitive data is stored in separate files:
- `db_root_password.txt` - MariaDB root password
- `db_password.txt` - WordPress database user password
- `wp_admin_password.txt` - WordPress admin password
- `wp_user_password.txt` - WordPress regular user password

**Why separate secrets?**
- Avoids accidentally committing passwords to Git
- Docker Compose can mount these as read-only files in containers
- Better security practice than environment variables
- Easier to rotate credentials

### How Secrets are Mounted

```yaml
services:
  mariadb:
    secrets:
      - db_root_password
      - db_password

secrets:
  db_root_password:
    file: ../secrets/db_root_password.txt
```

Inside container: `/run/secrets/db_root_password`

---

## Restart Policy

All services use `restart: always`:

```yaml
services:
  nginx:
    restart: always
```

**What this means:**
- If container crashes → Docker automatically restarts it
- On system reboot → Docker automatically starts containers
- Manual stops (`docker stop`) → Won't auto-restart until manual start
- Ensures high availability

---

## Summary

The Inception architecture follows these principles:
- **Single entry point** (NGINX on port 443)
- **Network isolation** (internal communication only)
- **Persistent data** (volumes survive restarts)
- **Health-based dependencies** (proper startup order)
- **Security by default** (minimal exposure, SSL/TLS, isolated network)
- **Separation of concerns** (each service in its own container)

This design is production-ready, scalable, and follows Docker best practices.
