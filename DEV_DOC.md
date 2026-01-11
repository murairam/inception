# Developer Documentation

This document describes how developers can set up, build, launch, and manage the Inception project infrastructure.

---

## Setting Up the Environment from Scratch

This section covers everything needed to get the project running from a fresh clone.

### Prerequisites

**Required Software:**

- **Docker** (20.10 or higher)
  ```bash
  docker --version
  ```
  Install: https://docs.docker.com/get-docker/

- **Docker Compose** (v2.0 or higher)
  ```bash
  docker compose version
  ```
  Usually included with Docker Desktop

- **Make**
  ```bash
  make --version
  ```
  Install on Linux: `sudo apt-get install make` or `sudo yum install make`

- **Git**
  ```bash
  git --version
  ```
  Install: https://git-scm.com/downloads

**System Requirements:**
- At least 2GB of free disk space
- Sufficient permissions to run Docker commands (user must be in `docker` group)
- Port 443 must be available (not in use by another service)

### Step-by-Step Environment Setup

#### 1. Clone the Repository

```bash
git clone git@github.com:murairam/inception.git
cd inception
```

#### 2. Create Data Directories

The project uses bind mounts to store persistent data on the host machine. Create these directories:

```bash
mkdir -p ~/data/mariadb
mkdir -p ~/data/wordpress
mkdir -p ~/data/static-site
```

**What these directories store:**
- `~/data/mariadb` - MariaDB database files (tables, indexes, system tables)
- `~/data/wordpress` - WordPress installation files, themes, plugins, uploads
- `~/data/static-site` - Static HTML website files

#### 3. Configure Environment Variables

Create the `.env` file in `srcs/` directory:

```bash
cat > srcs/.env << 'EOF'
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
EOF
```

**Environment variable descriptions:**
- `DOMAIN_NAME`: Domain name for the site (used in NGINX config and SSL certificate)
- `MYSQL_DATABASE`: Name of the database to create for WordPress
- `MYSQL_USER`: Database user that WordPress will use
- `WP_ADMIN_USER`: WordPress administrator username
- `WP_ADMIN_EMAIL`: WordPress administrator email
- `WP_USER`: WordPress regular user username
- `WP_USER_EMAIL`: WordPress regular user email
- `DATA_PATH`: Base path for data directories on host

#### 4. Set Up Secret Files

Secrets are stored in separate files for security. Create the `secrets/` directory and populate it:

```bash
mkdir -p secrets
```

**Create each secret file (one password per file, no trailing newline):**

```bash
# MariaDB root password
echo -n "your_secure_root_password_here" > secrets/db_root_password.txt

# MariaDB WordPress user password
echo -n "your_secure_db_password_here" > secrets/db_password.txt

# WordPress admin password
echo -n "your_secure_admin_password_here" > secrets/wp_admin_password.txt

# WordPress regular user password
echo -n "your_secure_user_password_here" > secrets/wp_user_password.txt
```

**Important security notes:**
- Use strong, unique passwords (12+ characters, mixed case, numbers, symbols)
- The `-n` flag prevents adding a newline character
- These files are gitignored and should never be committed
- In production, use proper secret management (Docker secrets, HashiCorp Vault, etc.)

**Verify secrets were created:**
```bash
ls -la secrets/
```

You should see 4 `.txt` files.

#### 5. Configure Domain Name (Optional)

To access the site using the configured domain name instead of `localhost`:

**Edit `/etc/hosts`:**
```bash
sudo nano /etc/hosts
```

**Add this line:**
```
127.0.0.1    mmiilpal.42.fr
```

**Save and exit** (Ctrl+O, Enter, Ctrl+X in nano)

Now you can access the site at `https://mmiilpal.42.fr` instead of `https://localhost`.

#### 6. Verify Setup

**Check all files are in place:**
```bash
# Environment file exists
[ -f srcs/.env ] && echo "✅ .env exists" || echo "❌ .env missing"

# Secret files exist
[ -f secrets/db_root_password.txt ] && echo "✅ db_root_password.txt exists" || echo "❌ missing"
[ -f secrets/db_password.txt ] && echo "✅ db_password.txt exists" || echo "❌ missing"
[ -f secrets/wp_admin_password.txt ] && echo "✅ wp_admin_password.txt exists" || echo "❌ missing"
[ -f secrets/wp_user_password.txt ] && echo "✅ wp_user_password.txt exists" || echo "❌ missing"

# Data directories exist
[ -d ~/data/mariadb ] && echo "✅ mariadb data dir exists" || echo "❌ missing"
[ -d ~/data/wordpress ] && echo "✅ wordpress data dir exists" || echo "❌ missing"
[ -d ~/data/static-site ] && echo "✅ static-site data dir exists" || echo "❌ missing"
```

If all checks pass with ✅, you're ready to build!

---

## Building and Launching with Makefile and Docker Compose

### Using the Makefile (Recommended)

The Makefile provides convenient commands for managing the entire project lifecycle.

#### Build Docker Images

```bash
make build
```

**What this does:**
1. Creates data directories (`~/data/mariadb`, `~/data/wordpress`, `~/data/static-site`) if they don't exist
2. Copies static site files from `srcs/requirements/bonus/static-site/www/` to `~/data/static-site/`
3. Builds all Docker images from Dockerfiles:
   - `mariadb` from `srcs/requirements/mariadb/Dockerfile`
   - `nginx` from `srcs/requirements/nginx/Dockerfile`
   - `wordpress` from `srcs/requirements/wordpress/Dockerfile`
   - `redis` from `srcs/requirements/bonus/redis-cache/Dockerfile`

**Expected output:**
```
Building mariadb...
Building wordpress...
Building nginx...
Building redis...
```

#### Start Containers

```bash
make up
```

**What this does:**
1. Starts all containers defined in `srcs/docker-compose.yml`
2. Runs in detached mode (`-d` flag) - containers run in background
3. Containers start in dependency order:
   - MariaDB starts first
   - WordPress waits for MariaDB to be healthy
   - NGINX waits for WordPress to be healthy
   - Redis starts independently

**Expected output:**
```
Creating network "inception_network" done
Creating mariadb ... done
Creating wordpress ... done
Creating nginx ... done
Creating redis ... done
```

#### Build and Start (All-in-One)

```bash
make
# or
make all
```

Equivalent to running `make build` followed by `make up`. **This is the recommended command for first-time setup.**

#### Stop Containers

```bash
make down
```

**What this does:**
- Stops all running containers
- Removes containers
- **Preserves volumes and data**

**When to use:** When you want to stop the infrastructure temporarily but keep all data.

#### Clean Up

```bash
make clean
```

**What this does:**
- Runs `docker compose down`
- Stops and removes containers
- Removes networks
- **Preserves volumes and data directories**

```bash
make fclean
```

**What this does:**
- Runs `docker compose down -v` (removes volumes)
- Removes all data directories:
  - `~/data/mariadb`
  - `~/data/wordpress`
  - `~/data/static-site`
- Removes Docker images

⚠️ **Warning:** This **permanently deletes all data** including database content, WordPress files, and uploads.

**When to use:** When you want to completely reset the project to start fresh.

#### Rebuild from Scratch

```bash
make re
```

Equivalent to `make fclean` followed by `make all`. Completely wipes everything and rebuilds.

#### View Logs

```bash
make logs
```

Follows logs from all containers in real-time. Press `Ctrl+C` to stop.

#### Check Container Status

```bash
make ps
```

Shows all running containers with their names, status, and health.

**Expected output:**
```
NAME        STATUS
mariadb     Up 2 minutes (healthy)
wordpress   Up 2 minutes (healthy)
nginx       Up 2 minutes (healthy)
redis       Up 2 minutes (healthy)
```

### Using Docker Compose Directly

If you prefer to use Docker Compose commands directly:

**Navigate to the srcs directory first:**
```bash
cd srcs/
```

#### Build Images

```bash
docker compose build
```

Builds all services defined in `docker-compose.yml`.

**Build specific service:**
```bash
docker compose build mariadb
docker compose build wordpress
```

**Build without cache (clean build):**
```bash
docker compose build --no-cache
```

#### Start Containers

```bash
docker compose up -d
```

**Flags:**
- `-d`: Detached mode (run in background)
- `--build`: Build images before starting
- `--force-recreate`: Recreate containers even if config hasn't changed

**Start specific service:**
```bash
docker compose up -d nginx
```

#### Stop Containers

```bash
docker compose down
```

**Remove volumes too:**
```bash
docker compose down -v
```

#### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f wordpress

# Last 100 lines
docker compose logs --tail=100 mariadb
```

#### List Containers

```bash
docker compose ps
```

#### Restart Services

```bash
# Restart all
docker compose restart

# Restart specific service
docker compose restart nginx
```

#### Individual Service Operations

```bash
# Stop a service
docker compose stop wordpress

# Start a stopped service  
docker compose start wordpress

# Rebuild and restart a service
docker compose up -d --build nginx
```

### Understanding the Build Process

**What happens during `make build`:**

1. **MariaDB image:**
   - Starts from `alpine:3.21`
   - Installs MariaDB and MariaDB client
   - Copies configuration file (`conf/my.cnf`)
   - Copies entrypoint script (`tools/docker-entrypoint.sh`)
   - Sets up healthcheck

2. **WordPress image:**
   - Starts from `alpine:3.21`
   - Installs PHP 8.2, PHP-FPM, and required extensions
   - Downloads and installs WP-CLI
   - Downloads Redis cache plugin
   - Copies configuration files
   - Sets up entrypoint script

3. **NGINX image:**
   - Starts from `alpine:3.21`
   - Installs NGINX and OpenSSL
   - Generates self-signed SSL certificate
   - Copies configuration template
   - Sets up entrypoint script

4. **Redis image:**
   - Starts from `alpine:3.21`
   - Installs Redis
   - Copies configuration file
   - Creates redis user
   - Sets up to run as non-root

**Image naming convention:**
Images are named after their service: `mariadb`, `wordpress`, `nginx`, `redis`

---

## Using Commands to Manage Containers and Volumes

### Container Management Commands

#### Accessing Running Containers

**Enter a container's shell:**
```bash
# Access MariaDB container
docker exec -it mariadb sh

# Access NGINX container
docker exec -it nginx sh

# Access WordPress container
docker exec -it wordpress sh

# Access Redis container
docker exec -it redis sh
```

Once inside, you can run commands, inspect files, and debug issues.

**Execute a single command without entering shell:**
```bash
# Check NGINX configuration
docker exec nginx nginx -t

# View PHP-FPM status
docker exec wordpress php-fpm83 -v

# Check MariaDB version
docker exec mariadb mariadb --version
```

#### Container Inspection

**View detailed container information:**
```bash
docker inspect mariadb
docker inspect wordpress
docker inspect nginx
```

**Check specific properties:**
```bash
# View container IP address
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mariadb

# View container mounts
docker inspect -f '{{json .Mounts}}' wordpress | python -m json.tool

# View container environment variables
docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' wordpress

# Check health status
docker inspect -f '{{.State.Health.Status}}' mariadb
```

#### Viewing Container Logs

**View logs from specific containers:**
```bash
# View all logs
docker logs mariadb
docker logs wordpress
docker logs nginx
docker logs redis

# Follow logs in real-time
docker logs -f mariadb

# View last N lines
docker logs --tail 50 wordpress

# View logs since specific time
docker logs --since 10m nginx

# View logs with timestamps
docker logs -t mariadb
```

#### Container Lifecycle Management

**Stop containers:**
```bash
# Stop specific container
docker stop mariadb
docker stop wordpress
docker stop nginx

# Stop all project containers
docker stop $(docker ps -q --filter "name=mariadb|wordpress|nginx|redis")
```

**Start stopped containers:**
```bash
docker start mariadb
docker start wordpress
docker start nginx
```

**Restart containers:**
```bash
docker restart mariadb
docker restart wordpress
```

**Remove containers:**
```bash
# Remove specific container (must be stopped first)
docker rm mariadb

# Force remove (stops and removes)
docker rm -f wordpress

# Remove all project containers
docker rm -f $(docker ps -aq --filter "name=mariadb|wordpress|nginx|redis")
```

#### Listing Containers

**View running containers:**
```bash
docker ps
```

**View all containers (including stopped):**
```bash
docker ps -a
```

**Filter containers:**
```bash
# Show only project containers
docker ps --filter "name=mariadb|wordpress|nginx|redis"

# Show containers with specific status
docker ps --filter "status=exited"
```

#### Container Resource Usage

**Monitor container resource consumption:**
```bash
# Real-time stats for all containers
docker stats

# Stats for specific containers
docker stats mariadb wordpress nginx

# Non-streaming stats (snapshot)
docker stats --no-stream
```

### Volume Management Commands

#### Listing Volumes

**View all volumes:**
```bash
docker volume ls
```

**Expected output:**
```
DRIVER    VOLUME NAME
local     srcs_mariadb_data
local     srcs_wordpress_data
local     srcs_static_site_data
```

**Filter volumes:**
```bash
# Show only project volumes
docker volume ls --filter name=srcs
```

#### Inspecting Volumes

**View detailed volume information:**
```bash
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data
docker volume inspect srcs_static_site_data
```

**Check volume mount points:**
```bash
# See where volume data is actually stored
docker volume inspect srcs_mariadb_data --format '{{ .Mountpoint }}'

# View all volume options (including bind mount path)
docker volume inspect srcs_mariadb_data --format '{{ json .Options }}' | python -m json.tool
```

**Expected output shows bind mount:**
```json
{
  "type": "none",
  "o": "bind",
  "device": "/home/mmiilpal/data/mariadb"
}
```

#### Removing Volumes

**Remove specific volume:**
```bash
# Must stop and remove containers first
docker volume rm srcs_mariadb_data
```

**Remove all unused volumes:**
```bash
docker volume prune
```

⚠️ **Warning:** This permanently deletes volume data.

**Remove volumes when stopping containers:**
```bash
cd srcs/
docker compose down -v
```

#### Backing Up Volumes

**Backup volume data (using bind mounts):**
```bash
# Since we use bind mounts, just copy the directories
cp -r ~/data/mariadb ~/data/mariadb-backup-$(date +%Y%m%d-%H%M%S)
cp -r ~/data/wordpress ~/data/wordpress-backup-$(date +%Y%m%d-%H%M%S)
cp -r ~/data/static-site ~/data/static-site-backup-$(date +%Y%m%d-%H%M%S)
```

**Backup using tar:**
```bash
tar -czf mariadb-backup-$(date +%Y%m%d).tar.gz ~/data/mariadb
tar -czf wordpress-backup-$(date +%Y%m%d).tar.gz ~/data/wordpress
```

**Restore from backup:**
```bash
# Stop containers first
make down

# Remove old data
rm -rf ~/data/mariadb/*

# Restore from backup
cp -r ~/data/mariadb-backup-20260111-143022/* ~/data/mariadb/

# Start containers
make up
```

### Network Management Commands

#### Inspecting Networks

**View all networks:**
```bash
docker network ls
```

**Inspect project network:**
```bash
docker network inspect inception_network
```

**View which containers are on the network:**
```bash
docker network inspect inception_network --format '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{"\n"}}{{end}}'
```

**Expected output:**
```
mariadb 172.18.0.2/16
wordpress 172.18.0.3/16
nginx 172.18.0.4/16
redis 172.18.0.5/16
```

#### Testing Network Connectivity

**Test connectivity between containers:**
```bash
# From WordPress to MariaDB
docker exec wordpress ping -c 3 mariadb

# From NGINX to WordPress
docker exec nginx ping -c 3 wordpress

# Check if port is accessible
docker exec wordpress nc -zv mariadb 3306
```

### Database Operations

**Connect to MariaDB:**
```bash\ndocker exec -it mariadb mariadb -u wpuser -p
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

---

## Identifying Where Data is Stored and How It Persists

### Understanding Data Persistence

The Inception project uses **bind mounts** to store persistent data on the host machine. This means data is stored directly in directories on your computer, not inside Docker's internal storage.

**Why bind mounts?**
- Data survives container deletion
- Easy to backup (just copy directories)
- Easy to inspect (files are directly accessible)
- Subject requirement: \"Your volumes will be available in the /home/login/data folder\"

### Data Storage Locations

**All project data is stored in:** `~/data/` or `${HOME}/data/`

**Directory structure:**
```
~/data/
├── mariadb/        # MariaDB database files
├── wordpress/      # WordPress installation
└── static-site/    # Static HTML files
```

#### MariaDB Data (`~/data/mariadb`)

**What's stored here:**
- Database files for the `wordpress` database
- System databases (`mysql`, `performance_schema`, etc.)
- Table data, indexes, and metadata
- Binary logs and transaction logs

**Container mount point:** `/var/lib/mysql`

**Key files:**
```
~/data/mariadb/
├── aria_log.00000001
├── aria_log_control
├── ib_buffer_pool
├── ibdata1                 # InnoDB system tablespace
├── ib_logfile0             # InnoDB redo log
├── ib_logfile1
├── mysql/                  # System database
├── performance_schema/     # Performance monitoring
└── wordpress/              # WordPress database
    ├── wp_comments.ibd
    ├── wp_options.ibd
    ├── wp_posts.ibd
    ├── wp_users.ibd
    └── ... (other WordPress tables)
```

**Viewing database files:**
```bash
ls -lh ~/data/mariadb/
du -sh ~/data/mariadb/
```

**Typical size:** 50-200 MB depending on content

#### WordPress Data (`~/data/wordpress`)

**What's stored here:**
- WordPress core files (PHP application)
- wp-config.php (database configuration)
- Themes and plugins
- Uploaded media files
- User-generated content

**Container mount point:** `/var/www/html`

**Key directories:**
```
~/data/wordpress/
├── wp-admin/               # WordPress admin interface
├── wp-content/
│   ├── plugins/            # Installed plugins
│   │   └── redis-cache/    # Redis cache plugin
│   ├── themes/             # WordPress themes
│   │   ├── twentytwentyfour/
│   │   └── twentytwentythree/
│   └── uploads/            # Media uploads (images, etc.)
│       └── 2026/
│           └── 01/         # Organized by year/month
├── wp-includes/            # WordPress core libraries
├── wp-config.php           # Configuration file
├── index.php               # Main entry point
└── ... (other WordPress files)
```

**Viewing WordPress files:**
```bash
ls -lh ~/data/wordpress/
du -sh ~/data/wordpress/wp-content/uploads/
```

**Typical size:** 50-100 MB (grows with uploads)

#### Static Site Data (`~/data/static-site`)

**What's stored here:**
- HTML files
- CSS stylesheets
- Images and assets
- JavaScript files

**Container mount point:** `/usr/share/nginx/html` (in NGINX container)

**Example structure:**
```
~/data/static-site/
├── index.html
├── styles.css
├── Elmo.png
└── ... (other static files)
```

### How Data Persists

**Docker Compose volume configuration** (in `srcs/docker-compose.yml`):

```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${DATA_PATH}/mariadb

  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${DATA_PATH}/wordpress

  static_site_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${DATA_PATH}/static-site
```

**What this means:**
- `type: none` + `o: bind` = bind mount (not Docker-managed)
- `device:` specifies the host directory path
- `${DATA_PATH}` resolves to `~/data` from `.env` file

### Data Lifecycle

**What happens when:**

1. **First `make` run:**
   - Directories created if they don't exist
   - MariaDB initializes database files
   - WordPress downloads and installs
   - Static site files copied

2. **Container restart (`make down` + `make up`):**
   - Data directories unchanged
   - Containers read existing data
   - WordPress sees existing installation
   - MariaDB loads existing databases

3. **Container rebuild:**
   - If using `make clean`: Data preserved
   - If using `make fclean`: **Data deleted permanently**

4. **Manual data deletion:**
   ```bash
   rm -rf ~/data/mariadb/*
   # Data gone forever (unless backed up)
   ```

### Verifying Data Persistence

**Test data persistence:**

1. **Create test content:**
   ```bash
   # Create a post in WordPress admin panel
   # Upload an image
   ```

2. **Stop containers:**
   ```bash
   make down
   ```

3. **Verify files still exist:**
   ```bash
   ls -lh ~/data/mariadb/
   ls -lh ~/data/wordpress/wp-content/uploads/
   ```

4. **Restart containers:**
   ```bash
   make up
   ```

5. **Verify content survived:**
   - Check WordPress site
   - Post and images should still be there

### Accessing Data Directly

**You can directly access files on the host:**

```bash
# View wp-config.php
cat ~/data/wordpress/wp-config.php

# Check WordPress uploads
ls ~/data/wordpress/wp-content/uploads/

# View database directory size
du -sh ~/data/mariadb/

# Search for files
find ~/data/wordpress -name \"*.jpg\"
```

**Modifying files directly:**
```bash
# Edit WordPress theme file
nano ~/data/wordpress/wp-content/themes/twentytwentyfour/style.css

# Changes take effect immediately (no container restart needed)
```

### Data Backup Best Practices

**Regular backups:**
```bash
#!/bin/bash
# backup.sh

BACKUP_DIR=~/backups
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p $BACKUP_DIR

# Stop containers for consistent backup
make down

# Backup data directories
tar -czf $BACKUP_DIR/inception-backup-$DATE.tar.gz ~/data/

# Restart containers
make up

echo \"Backup saved to: $BACKUP_DIR/inception-backup-$DATE.tar.gz\"
```

### Troubleshooting Data Issues

**Permission problems:**
```bash
# Fix permissions
sudo chown -R $USER:$USER ~/data/
chmod -R 755 ~/data/
```

**Data corruption:**
```bash
# If MariaDB won't start, check logs
docker logs mariadb

# May need to restore from backup or rebuild
make fclean
make
```

**Disk space issues:**
```bash
# Check available space
df -h ~/data/

# Check size of each service
du -sh ~/data/mariadb
du -sh ~/data/wordpress
du -sh ~/data/static-site
```

---

## Additional Resources

- **Main documentation:** [README.md](README.md)
- **User guide:** [USER_DOC.md](USER_DOC.md)
- **Technical details:** [TECHNICAL.md](TECHNICAL.md)
- **Architecture:** [ARCHITECTURE.md](ARCHITECTURE.md)

**Official Documentation:**
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Volumes](https://docs.docker.com/storage/volumes/)
- [Docker Bind Mounts](https://docs.docker.com/storage/bind-mounts/)
