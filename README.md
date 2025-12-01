# Inception

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Alpine Linux](https://img.shields.io/badge/Alpine_Linux-0D597F?style=for-the-badge&logo=alpine-linux&logoColor=white)
![NGINX](https://img.shields.io/badge/NGINX-009639?style=for-the-badge&logo=nginx&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=for-the-badge&logo=mariadb&logoColor=white)
![WordPress](https://img.shields.io/badge/WordPress-21759B?style=for-the-badge&logo=wordpress&logoColor=white)

A Docker infrastructure project setting up a small network with NGINX, WordPress, and MariaDB.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [About This Project](#about-this-project)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
  - [Environment Variables (.env)](#environment-variables-env)
  - [Secrets Files](#secrets-files)
- [How to Use](#how-to-use)
- [Project Architecture](#project-architecture)
- [Docker Basics](#docker-basics)
- [Service-Specific Details](#service-specific-details)
  - [MariaDB](#mariadb)
  - [NGINX](#nginx)
  - [WordPress](#wordpress)
- [Testing & Verification](#testing--verification)
- [Troubleshooting](#troubleshooting)
- [Useful Docker Commands](#useful-docker-commands)
- [Core Concepts](#core-concepts)
- [Questions You Should Be Able to Answer](#questions-you-should-be-able-to-answer)
- [Resources](#resources)

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

## Quick Start

**TL;DR for the impatient:**

```bash
# Clone and navigate
git clone <your-repo-url>
cd inception

# Create necessary directories
mkdir -p ~/data/mariadb ~/data/wordpress

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
        │   │   └── nginx.conf
        │   └── tools/
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            │   └── www.conf
            └── tools/
                └── docker-entrypoint.sh
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
WP_ADMIN_USER=admin
WP_ADMIN_EMAIL=admin@example.com

# WordPress Regular User
WP_USER=author
WP_USER_EMAIL=author@example.com
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

### Makefile Explanation

The Makefile automates common Docker operations:

```makefile
# Key variables
COMPOSE_FILE = srcs/docker-compose.yml
DATA_PATH = $(HOME)/data

# The 'build' target
build:
    @mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress
    @docker-compose -f $(COMPOSE_FILE) build

# The 'fclean' target (note: requires sudo for data deletion)
fclean: clean
    @docker system prune -af --volumes
    @sudo rm -rf $(DATA_PATH)/mariadb/*
    @sudo rm -rf $(DATA_PATH)/wordpress/*
```

**Why `sudo` for fclean?**
Docker creates files as root inside volumes, so you need elevated permissions to delete them.

---

## Project Architecture

### How the three containers are connected

```
┌─────────────────┐
│  User (browser) │
└────────┬────────┘
         │ HTTPS (port 443) ← Only port exposed to host
         ↓
┌────────────────────┐
│  NGINX container   │
│  (Reverse Proxy)   │
└────────┬───────────┘
         │ FastCGI (port 9000) ← Internal Docker network
         ↓
┌─────────────────────────┐
│ WordPress+PHP-FPM       │
│ container               │
└────────┬────────────────┘
         │ MySQL (port 3306) ← Internal Docker network
         ↓
┌──────────────────┐
│ MariaDB container│
└──────────────────┘
```

**Port Mapping:**
- **External (host machine):** Only port `443` is exposed to your browser
- **Internal (Docker network):** Ports `9000` and `3306` are only accessible between containers
- This means: MariaDB and WordPress are NOT accessible from your host machine directly (security!)

### Network Explanation

All containers are connected via a **Docker bridge network** called `inception_network`. This allows them to:
- Communicate using container names as hostnames (e.g., `mariadb:3306`, `wordpress:9000`)
- Stay isolated from the host network (except for the exposed 443 port)
- Benefit from Docker's built-in DNS resolution

### Volume Contents & Bind Mounts

**Why use bind mounts (`~/data`) instead of Docker volumes?**
- Easier to inspect and backup (just regular directories on your host)
- Simpler for development (you can see the files directly)
- Required by the 42 project specifications
- **Downside:** You need `sudo` to clean up because Docker writes as root

**Volume 1 - MariaDB** (`~/data/mariadb`):
- Database files (actual MySQL/MariaDB data)
- WordPress posts, pages, users, settings
- All stored as database tables

**Volume 2 - WordPress** (`~/data/wordpress`):
- WordPress PHP files
- Themes
- Plugins
- Uploaded media (images, videos)
- `wp-config.php` (WordPress configuration)

---

## Docker Basics

### What goes in a Dockerfile?

- `FROM` - Base image
- `RUN` - Execute commands during build
- `COPY` - Copy files into image
- `EXPOSE` - Document which ports container uses
- `CMD` - What runs when container starts
- `ENTRYPOINT` - Alternative to CMD

**Example:**
```dockerfile
ENTRYPOINT = "python"      # The program
CMD = ["script.py"]        # What to run
# Together: python script.py
```

### What is Alpine?

Alpine is a tiny Linux distribution designed for containers:
- Only ~5MB in size (vs Debian's ~100MB)
- Uses `apk` package manager (not `apt`)
- Security-focused
- Perfect for Docker because it's lightweight

---

## Service-Specific Details

### MariaDB

**`/var/lib/mysql` - Database files**

This is where MariaDB stores:
- All database tables
- User data
- WordPress posts/pages
- Everything persistent

*Without it:* MariaDB can't store any data!

**`/run/mysqld` - Socket file**

This is where MariaDB creates:
- `mysqld.sock` - A special file for local connections
- Process ID file

Think of it like a "mailbox" where programs talk to MariaDB locally.

*Without it:* MariaDB can't create the socket → can't start!

#### MariaDB Entrypoint Script Explained

The entrypoint script (`docker-entrypoint.sh`) does the following:

**On First Run:**
1. Checks if `/var/lib/mysql/mysql` exists (the system database)
2. If not, initializes the database with `mariadb-install-db`
3. Starts MariaDB temporarily in the background
4. Runs initialization SQL to:
   - Secure the installation (remove anonymous users, test databases)
   - Set root password
   - Create the WordPress database
   - Create WordPress user with proper permissions
5. Stops the temporary MariaDB instance
6. Starts MariaDB as PID 1 using `exec`

**On Subsequent Runs:**
- Skips initialization (data already exists)
- Directly starts MariaDB

**Why this approach?**
- Ensures database is properly set up before WordPress tries to connect
- Uses `exec` to replace the shell with MariaDB (proper signal handling)
- Makes the container idempotent (can restart safely)

### NGINX

**`--no-cache` flag:**
Tells `apk` to not store package cache files after installation.

**SSL Certificate Generation:**
- `req -x509` - Create a self-signed certificate
- `-nodes` - No password for the private key
- `-days 365` - Valid for 1 year
- `-newkey rsa:2048` - Generate new 2048-bit RSA key
- `-keyout` - Where to save the private key
- `-out` - Where to save the certificate
- `-subj` - Certificate details (Country, State, etc.)

**⚠️ Security Note:**
This project uses **self-signed certificates** for development/education purposes. Your browser will show a security warning (this is normal!). For production, you'd use:
- Let's Encrypt (free, automated)
- A commercial CA (Certificate Authority)
- Proper domain validation

#### NGINX Configuration Summary

The NGINX config has three main parts:

**1. Events Block** - Required by NGINX, sets `worker_connections 1024` (more than enough for this project)

**2. HTTP Block** - Contains server configuration and includes MIME types

**3. Server Block** - The actual web server config:
- **Listen:** Port 443 with SSL (IPv4 and IPv6)
- **Server name:** Your domain (`mmiilpal.42.fr`)
- **SSL config:** Certificate paths + `TLSv1.2 TLSv1.3` only ✓
- **Root:** `/var/www/html` (WordPress files)
- **Index:** `index.php` (default file)

**Key Location Blocks:**

```nginx
location / {
    try_files $uri $uri/ /index.php?$args;
}
```
Tries to serve files directly, otherwise sends to WordPress (enables "pretty URLs")

```nginx
location ~ \.php$ {
    fastcgi_pass wordpress:9000;
    # ... other FastCGI params
}
```
Forwards all `.php` requests to WordPress container on port 9000 via FastCGI

<details>
<summary>📄 Click to see full NGINX config explanation</summary>

**`events` block:**
```nginx
events {
    worker_connections 1024;
}
```
- Required by NGINX (config won't work without it)
- `worker_connections 1024` - How many simultaneous connections each NGINX worker can handle

**`http` block:**
```nginx
http {
    include /etc/nginx/mime.types;
```
- Contains all web server configuration
- `include /etc/nginx/mime.types` - Tells NGINX what file types are (e.g., `.html` is `text/html`)

**`server` block:**
```nginx
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name mmiilpal.42.fr;

    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    root /var/www/html;
    index index.php;
```

**Location blocks:**
- `location /` - Try to serve file → directory → send to index.php
- `location ~ \.php$` - Forward PHP requests to `wordpress:9000` via FastCGI
- `fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;` - Tells PHP-FPM which file to execute

</details>

### WordPress

**What is WordPress?**
A CMS (Content Management System) - a no-code visual website builder.

**What is FastCGI?**
A service that helps to handle and run PHP.

**User Permissions:**
- MariaDB: Runs as `mysql` user (created by mariadb package)
- PHP-FPM: Runs as `nobody` user (built-in Alpine user with minimal permissions)

#### PHP-FPM Configuration (`www.conf`)

**`[www]`**
Section header - Names this PHP-FPM pool "www" (you can have multiple pools, but we only need one)

**`user = nobody` / `group = nobody`**
Security - PHP-FPM worker processes run as the `nobody` user/group (not root). This matches the ownership of `/var/www/html`.

**`listen = 9000`**
Critical! - PHP-FPM listens on port 9000. This is where NGINX forwards PHP requests to (`fastcgi_pass wordpress:9000;`). Alternative: Could use a Unix socket instead of TCP port, but port 9000 is simpler for Docker networking.

**`listen.owner = nobody` / `listen.group = nobody`**
Socket permissions - If using Unix socket, set ownership. Not strictly needed for TCP port 9000, but doesn't hurt.

**`pm = dynamic`**
Process Manager mode - `dynamic` means PHP-FPM automatically adjusts the number of child processes based on demand.
- Options: `static` (fixed workers), `dynamic` (adjusts based on load), `ondemand` (spawns workers only when needed)

**`pm.max_children = 5`**
Maximum workers - At most 5 PHP-FPM processes can run simultaneously. For a small project, 5 is plenty.

**`pm.start_servers = 2`**
Initial workers - Start with 2 PHP-FPM processes when container launches.

**`pm.min_spare_servers = 1` / `pm.max_spare_servers = 3`**
Spare workers - Keep between 1-3 idle processes ready to handle requests. If all workers are busy, spawn more (up to `max_children`). Think of it like: always keep 1-3 employees on standby, hire more if needed (max 5 total).

**`clear_env = no`**
Environment variables - `no` means PHP-FPM passes environment variables to PHP scripts. WordPress needs env vars like `MYSQL_DATABASE`, `MYSQL_USER`, etc. from docker-compose. Default is `yes` (clears env vars for security), but we need them for configuration.

#### Dockerfile

**`-F` flag:** Runs PHP-FPM in foreground (like `nginx -g "daemon off;"`)

#### Entrypoint Script

**Step 1: Wait for Database**
- Keep trying to connect to MariaDB
- Sleep 3 seconds between attempts
- Continue only when MariaDB responds

**Step 2: Check if Already Set Up**
- Look for `wp-config.php` file
- If exists → skip setup (already done)
- If missing → do first-time setup

**Step 3: First-Time Setup (if needed)**
- Create `wp-config.php` with database credentials
- Install WordPress with admin user
- Create second user (regular author)
- Mark setup as complete

**Step 4: Start PHP-FPM**
- Hand control to PHP-FPM process
- PHP-FPM runs as PID 1, keeps container alive

**In one sentence:** Wait for database → configure WordPress if needed → start PHP-FPM.

---

## Testing & Verification

Once everything is running, verify your setup:

**1. Check container status:**
```bash
make ps
# Expected output:
# NAME                IMAGE               STATUS
# mariadb            mariadb             Up X minutes
# wordpress          wordpress           Up X minutes
# nginx              nginx               Up X minutes
```

**2. Access the website:**
- Open your browser to `https://localhost` or `https://mmiilpal.42.fr` (if you added it to `/etc/hosts`)
- You'll see a security warning (normal for self-signed certificates) - click "Advanced" and proceed
- You should see your WordPress site!

**3. Login to WordPress admin:**
- Navigate to `https://localhost/wp-admin`
- Use the admin credentials from your secrets

**4. Check database connection:**
```bash
docker exec -it mariadb mariadb -u wpuser -p
# Enter the password from secrets/db_password.txt
# Once in:
mysql> SHOW DATABASES;
mysql> USE wordpress;
mysql> SHOW TABLES;
```

**5. View logs:**
```bash
make logs
# Should show all three containers running without errors
```

**Common success indicators:**
- ✅ No container restarts (check `STATUS` in `make ps`)
- ✅ WordPress installation page appears (or existing site if already set up)
- ✅ NGINX shows "ready for connections" in logs
- ✅ MariaDB shows "ready for connections" in logs
- ✅ WordPress shows "MariaDB is up!" in logs

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
**Problem:** Can't access `~/data/mariadb` or `~/data/wordpress`

**Solutions:**
```bash
# Create directories with proper permissions
mkdir -p ~/data/mariadb ~/data/wordpress
chmod 755 ~/data/mariadb ~/data/wordpress

# If issues persist, check Docker has permission to access your home directory
```

### Self-signed certificate warnings
**Problem:** Browser shows "Your connection is not private"

**This is expected!** Self-signed certificates always trigger this warning. Click "Advanced" → "Proceed to localhost (unsafe)" to continue.

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

### make fclean asks for password
**Problem:** Prompted for password during cleanup

**This is normal!** The Makefile uses `sudo` to delete Docker-created files (they're owned by root). Enter your macOS password.

---

## Useful Docker Commands

**Container Management:**
```bash
# List all containers (including stopped)
docker ps -a

# Stop a specific container
docker stop nginx

# Start a specific container
docker start nginx

# Restart a container
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

**Volume Management:**
```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect mariadb_data

# Remove unused volumes
docker volume prune
```

**Image Management:**
```bash
# List images
docker images

# Remove image
docker rmi inception-nginx

# Remove unused images
docker image prune -a
```

**System Cleanup:**
```bash
# Remove everything unused (be careful!)
docker system prune -a --volumes

# Check disk usage
docker system df
```

---

## Core Concepts

### What is SSL/TLS?

**SSL (Secure Sockets Layer)** - An encryption-based internet security protocol. It is the predecessor to TLS encryption that is used today.

**TLS (Transport Layer Security)** - The updated version of SSL (since 1999). The two are closely related; the name change signified a change in ownership.

A website with SSL/TLS has "HTTPS" in the URL instead of "HTTP".

**How it works:**
- Encrypts data that is transmitted
- Verifies that the two communicating devices are who they claim to be by initiating a handshake
- Signs the data to ensure it is not tampered with before reaching the recipient

### Why are `tail -f` and `sleep infinity` prohibited?

- `tail -f` - Continuously reads the end of a file (never exits)
- `sleep infinity` - Sleeps forever (never exits)

These commands don't allow proper container shutdown and signal handling.

### What is PID 1?

Every process in Linux gets a process ID. The first one is usually allocated to `systemd` or `init`, which manage all other processes.

**In a Docker container:** PID 1 is the main command and the parent of everything in that container. When PID 1 stops, the container stops.

---

## Questions You Should Be Able to Answer

**How Docker and docker-compose work:**
- Understand images vs containers, layers, networking, volumes

**Difference between Docker image with/without docker-compose:**
- **Without:** manual `docker build`, `docker run`, manual networking
- **With:** orchestration, automatic networking, dependencies, easier management

**Benefit of Docker vs VMs:**
- Lighter weight, faster startup, share host kernel, easier portability

**Why this directory structure?**
- Separates concerns, keeps services independent, follows best practices

**Explain docker-network:**
- Bridge network allows containers to communicate by name (mariadb:3306, wordpress:9000)

**Why TLSv1.2/1.3 only?**
- Security - older versions have known vulnerabilities

**How to login to database:**
```bash
docker exec -it mariadb mariadb -u wpuser -p
```

**What happens when you reboot?**
- Volumes persist data, containers restart automatically (`restart: always`)

**Why exec in entrypoint?**
- Proper signal handling, makes the final process PID 1

**Why no tail -f?**
- Not a real service, prevents proper shutdown, hacky workaround

---

## Resources

**Documentation:**
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Volumes](https://docs.docker.com/engine/storage/volumes/)
- [NGINX Beginner's Guide](https://nginx.org/en/docs/beginners_guide.html)
- [Cloudflare - What is SSL?](https://www.cloudflare.com/en-gb/learning/ssl/what-is-ssl/)

**Tutorials & Guides:**
- [Docker Curriculum](https://docker-curriculum.com/?source=post_page-----cfda98d9f4ac--------------------------------#introduction)
- [Inception Tutorial (GradeMe)](https://tuto.grademe.fr/inception/#)

**Articles:**
- [The Linux Process Journey: PID 1 & Init](https://medium.com/@boutnaruthe-linux-process-journey-pid-1-init-60765a069f17)
- [Docker Processes in a Container](https://cloud.theodo.com/en/blog/docker-processes-container)
- [Benchmarking Debian vs Alpine as Base Docker Image](https://nickjanetakis.com/blog/benchmarking-debian-vs-alpine-as-a-base-docker-image)
- [Alpine vs Debian: What They Actually Do](https://hoop.dev/blog/what-alpine-debian-actually-does-and-when-to-use-it/)
- [Linux Beyond the Basics: cgroups](https://medium.com/@weidagang/linux-beyond-the-basics-cgroups-f157d93bd755)
- [Unveiling 42 Network: Inception - A Dive into Docker and Docker Compose](https://medium.com/@afatir.ahmedfatir/unveiling-42-the-network-inception-a-dive-into-docker-and-docker-compose-cfda98d9f4ac)

**Videos:**
- [Docker Crash Course](https://www.youtube.com/watch?v=pg19Z8LL06w)
- [Rapid Docker Tutorial](https://www.youtube.com/watch?v=DQdB7wFEygo)
- [Tutorial about NGINX](https://www.youtube.com/watch?v=iInUBOVeBCc)
- [Docker Lecture: What Containers Are Made From (Excellent)](https://www.youtube.com/watch?v=sK5i-N34im8)
- [NGINX Explained in 100 Seconds](https://www.youtube.com/watch?v=JKxlsvZXG7c)
- [Proxy vs Reverse Proxy](https://www.youtube.com/watch?v=4NB0NDtOwIQ)
- [FastCGI Crash Course](https://www.youtube.com/watch?v=hEXBgQ71rvE)

**Additional Resources:**
- [NGINX Request Processing](https://nginx.org/en/docs/http/request_processing.html)

---

## Contributing & Screenshots

**Note:** This is an educational project for 42 School. If you're working on the same project, use this as a reference but write your own code - that's how you learn!

**Want to see it in action?**
Run `make` and visit `https://localhost` - you'll see WordPress running in all its containerized glory!

---

## License

This project is open source and available for educational purposes.


