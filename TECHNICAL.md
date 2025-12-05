# Inception - Technical Details

This document contains in-depth technical explanations of how each service works, configuration details, and Docker fundamentals.

---

## Table of Contents

- [Docker Fundamentals](#docker-fundamentals)
- [MariaDB Deep Dive](#mariadb-deep-dive)
- [NGINX Deep Dive](#nginx-deep-dive)
- [WordPress Deep Dive](#wordpress-deep-dive)
- [Redis Cache Implementation](#redis-cache-implementation)
- [Core Concepts](#core-concepts)
- [Questions You Should Be Able to Answer](#questions-you-should-be-able-to-answer)

---

## Docker Fundamentals

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

### Why are `tail -f` and `sleep infinity` prohibited?

- `tail -f` - Continuously reads the end of a file (never exits)
- `sleep infinity` - Sleeps forever (never exits)

These commands don't allow proper container shutdown and signal handling.

### What is PID 1?

Every process in Linux gets a process ID. The first one is usually allocated to `systemd` or `init`, which manage all other processes.

**In a Docker container:** PID 1 is the main command and the parent of everything in that container. When PID 1 stops, the container stops.

**Why exec in entrypoint?**
- Proper signal handling, makes the final process PID 1
- Without `exec`, the shell remains as PID 1, and signals don't propagate correctly

---

## MariaDB Deep Dive

### Directory Structure

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

*Without it:* MariaDB can't create the socket and can't start!

### Configuration File (`/etc/my.cnf`)

The custom MariaDB configuration includes:
- `bind-address=0.0.0.0` - Allows connections from any IP (required for Docker inter-container communication)
- `port=3306` - Standard MariaDB port
- `socket=/run/mysqld/mysqld.sock` - Unix socket location for local connections
- Security is maintained through Docker network isolation (port 3306 is not exposed to the host)

### Entrypoint Script Explained

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

### User Permissions

MariaDB runs as the `mysql` user (created by the mariadb package). This is a security measure to ensure the database process doesn't run with root privileges.

---

## NGINX Deep Dive

### SSL Certificate Generation

**Command breakdown:**
```bash
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=XX/ST=State/L=City/O=Organization/CN=localhost"
```

- `req -x509` - Create a self-signed certificate
- `-nodes` - No password for the private key
- `-days 3650` - Valid for 10 years
- `-newkey rsa:2048` - Generate new 2048-bit RSA key
- `-keyout` - Where to save the private key
- `-out` - Where to save the certificate
- `-subj` - Certificate details (Country, State, etc.)

**Security Note:**
This project uses **self-signed certificates** for development/education purposes. Your browser will show a security warning (this is normal!). For production, you'd use:
- Let's Encrypt (free, automated)
- A commercial CA (Certificate Authority)
- Proper domain validation

### Configuration Template

The NGINX configuration uses `nginx.conf.template` with environment variable substitution via `envsubst`. The entrypoint script generates the final `nginx.conf` by replacing `${DOMAIN_NAME}` with your actual domain from the `.env` file.

### Configuration File Deep Dive

The NGINX config has three main parts:

**1. Events Block** - Required by NGINX, sets `worker_connections 1024` (more than enough for this project)

**2. HTTP Block** - Contains server configuration and includes MIME types

**3. Server Block** - The actual web server config:
- **Listen:** Port 443 with SSL (IPv4 and IPv6)
- **Server name:** Your domain (`mmiilpal.42.fr`)
- **SSL config:** Certificate paths + `TLSv1.2 TLSv1.3` only
- **Root:** `/var/www/html` (WordPress files)
- **Index:** `index.php` (default file)

### Location Blocks Explained

```nginx
events {
    worker_connections 1024;
}
```
- Required by NGINX (config won't work without it)
- `worker_connections 1024` - How many simultaneous connections each NGINX worker can handle

```nginx
http {
    include /etc/nginx/mime.types;
}
```
- Contains all web server configuration
- `include /etc/nginx/mime.types` - Tells NGINX what file types are (e.g., `.html` is `text/html`)

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
}
```

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

```nginx
location /static/ {
    alias /var/www/static/;
}
```
Serves static website from `/var/www/static/` (bonus service)

**Important FastCGI parameter:**
- `fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;` - Tells PHP-FPM which file to execute

### Package Flags

**`--no-cache` flag:**
Tells `apk` to not store package cache files after installation. This keeps the Docker image smaller.

---

## WordPress Deep Dive

### What is WordPress?

A CMS (Content Management System) - a no-code visual website builder that uses PHP and MySQL to dynamically generate web pages.

### What is FastCGI?

A service that helps to handle and run PHP. FastCGI is a binary protocol for interfacing interactive programs with a web server. It's faster than traditional CGI because it keeps processes alive between requests.

### PHP-FPM Configuration (`www.conf`)

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

### Dockerfile Details

**`-F` flag:** Runs PHP-FPM in foreground (like `nginx -g "daemon off;"`)

This is critical because Docker needs a foreground process to keep the container running.

### Entrypoint Script

**Step 1: Wait for Database**
- Keep trying to connect to MariaDB
- Sleep 3 seconds between attempts
- Continue only when MariaDB responds

**Step 2: Check if Already Set Up**
- Look for `wp-config.php` file
- If exists, skip setup (already done)
- If missing, do first-time setup

**Step 3: First-Time Setup (if needed)**
- Create `wp-config.php` with database credentials
- Install WordPress with admin user (`boss`)
- Create second user (role: author, username from `WP_USER` env var)
- Mark setup as complete

**Step 4: Start PHP-FPM**
- Hand control to PHP-FPM process
- PHP-FPM runs as PID 1, keeps container alive

**In one sentence:** Wait for database, configure WordPress if needed, start PHP-FPM.

### User Permissions

PHP-FPM runs as the `nobody` user (built-in Alpine user with minimal permissions). This is a security measure to ensure the PHP process doesn't run with elevated privileges.

---

## Redis Cache Implementation

### What is Redis?

**Redis (Remote Dictionary Server)** is an in-memory data structure store used as a cache, database, and message broker. In this project, Redis serves as an object cache for WordPress, significantly improving performance by storing frequently accessed data in RAM instead of querying the database repeatedly.

### Key Benefits

- **Speed:** Sub-millisecond response times (RAM is 1000x faster than disk)
- **Reduced Database Load:** Fewer queries to MariaDB = better performance
- **Scalability:** Handles thousands of requests per second
- **Simple:** Key-value storage with automatic expiration

### How It Works

1. WordPress needs data (e.g., blog post)
2. Check Redis cache first - if found (cache hit), return immediately
3. If not in cache (cache miss), query MariaDB
4. Store result in Redis for next request
5. Subsequent requests skip the database entirely

### WordPress Integration

The Redis Object Cache plugin (`redis-cache`) integrates WordPress with Redis by:
- Hooking into WordPress's object caching system
- Storing frequently accessed objects (posts, options, queries) in Redis
- Automatically invalidating cache when content changes
- Using the `wp_using_ext_object_cache()` function to verify external cache is active

### Testing Cache Performance

```bash
# Flush cache
docker exec redis redis-cli FLUSHALL

# Time a WordPress page load (cache miss)
time curl -k https://localhost > /dev/null

# Time the same page again (cache hit)
time curl -k https://localhost > /dev/null
```

The second request should be noticeably faster!

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

### Docker vs VMs

**Docker containers:**
- Share host kernel
- Lightweight (MBs)
- Start in seconds
- Better resource utilization

**Virtual Machines:**
- Full OS per VM
- Heavy (GBs)
- Start in minutes
- More isolated but more overhead

### Docker Network Types

**Bridge** (what we use):
- Default network driver
- Containers on same bridge can communicate
- Isolated from host network (except exposed ports)
- Built-in DNS for container name resolution

**Host:**
- Container shares host network stack
- No network isolation
- Better performance but less security

**None:**
- No networking
- Completely isolated

---

## Questions You Should Be Able to Answer

### How Docker and docker-compose work

**Docker:**
- Images are read-only templates with instructions for creating containers
- Containers are runnable instances of images
- Layers: Each Dockerfile instruction creates a layer (cached for efficiency)
- Volumes: Persistent data storage outside container lifecycle
- Networks: Virtual networks for container communication

**docker-compose:**
- Tool for defining and running multi-container Docker applications
- Uses YAML file to configure services, networks, volumes
- Single command to start/stop entire application stack
- Handles dependencies between services
- Automatic network creation and DNS resolution

### Difference between Docker image with/without docker-compose

**Without docker-compose:**
- Manual `docker build` for each image
- Manual `docker run` with all flags (ports, volumes, env vars)
- Manual network creation and connection
- Manual management of startup order
- Tedious for multi-container applications

**With docker-compose:**
- Single YAML file defines everything
- `docker-compose up` starts entire stack
- Automatic networking and DNS
- Dependency management (depends_on, healthchecks)
- Easier environment management

### Why this directory structure?

```
srcs/
├── docker-compose.yml      # Orchestration
├── .env                    # Configuration
└── requirements/
    ├── mariadb/            # Service isolation
    ├── nginx/              # Each service self-contained
    └── wordpress/          # Easy to maintain/update
```

**Benefits:**
- Separation of concerns
- Independent service development
- Clear organization
- Follows Docker best practices
- Easy to add new services

### Explain docker-network

In this project, we use a **bridge network** called `inception_network`:
- All containers connected to this network can communicate
- Containers use service names as hostnames (e.g., `mariadb:3306`, `wordpress:9000`)
- Docker's built-in DNS resolves container names to IP addresses
- Network is isolated from host (only port 443 exposed)
- Provides security through isolation

### Why TLSv1.2/1.3 only?

**Security reasons:**
- TLS 1.0 and 1.1 have known vulnerabilities (deprecated in 2020)
- TLS 1.2 and 1.3 use modern encryption algorithms
- TLS 1.3 is faster and more secure (removed legacy cipher suites)
- Compliance with modern security standards

### How to login to database

```bash
# As WordPress user
docker exec -it mariadb mariadb -u wpuser -p

# As root
docker exec -it mariadb mariadb -u root -p

# Direct command execution
docker exec mariadb mariadb -u wpuser -pYourPassword wordpress -e "SELECT * FROM wp_users;"
```

### What happens when you reboot?

1. Docker daemon stops all containers
2. Container processes terminate
3. Container filesystem is ephemeral (lost)
4. **Volumes persist** (data in `~/data/` remains)
5. On restart with `restart: always`:
   - Docker daemon starts containers automatically
   - Containers initialize from images
   - Mount existing volumes (data intact)
   - Services resume with persistent data

**Result:** WordPress posts, database, uploads all survive reboot because they're in volumes.
