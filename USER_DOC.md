# User Documentation

This document explains how to use and manage the Inception infrastructure as an end user or administrator.

---

## Services Provided by the Stack

The Inception project provides a complete web infrastructure stack running on Docker, featuring the following services:

### Mandatory Services

- **NGINX Web Server** 
  - Acts as the reverse proxy and sole entry point to the infrastructure
  - Serves content over HTTPS (port 443) with TLSv1.2/1.3 encryption
  - Routes requests to WordPress via FastCGI
  - Uses self-signed SSL certificates for secure connections

- **WordPress CMS (with PHP-FPM)**
  - Content management system for creating and managing your website
  - Runs on PHP-FPM (FastCGI Process Manager)
  - Accessible through NGINX on port 9000 (internal)
  - Stores files, themes, plugins, and uploads in persistent volumes

- **MariaDB Database**
  - MySQL-compatible database system
  - Stores all WordPress data (posts, pages, users, settings)
  - Runs on port 3306 (internal, not exposed to host)
  - Data persists in Docker volumes

### Bonus Services

- **Redis Cache**
  - Object caching for WordPress to improve performance
  - Reduces database queries by caching frequently accessed data
  - Runs on port 6379 (internal)

- **Static Website**
  - Simple HTML site served by NGINX
  - Accessible at `/static/` path
  - Demonstrates multi-site capability

**Architecture Overview:**
All services run in isolated Docker containers and communicate over a private Docker network called `inception_network`. Only NGINX's port 443 is exposed to the host machine, ensuring security through isolation.

---

## Starting and Stopping the Project

### Starting the Project

**To start all services:**

```bash
make
```

This command will:
1. Create necessary data directories (`~/data/mariadb`, `~/data/wordpress`, `~/data/static-site`)
2. Build all Docker images from Dockerfiles
3. Start all containers in detached mode (background)

**Expected behavior:**
- Containers start in dependency order (MariaDB → WordPress → NGINX)
- Health checks ensure each service is ready before the next starts
- First startup may take 30-60 seconds as databases initialize

**Access points after startup:**
- **Main WordPress site:** https://mmiilpal.42.fr or https://localhost
- **WordPress admin panel:** https://mmiilpal.42.fr/wp-admin
- **Static site:** https://mmiilpal.42.fr/static/

### Stopping the Project

**To stop all services (preserve data):**

```bash
make down
```

This stops and removes all containers but preserves all data in volumes.

**To stop and remove everything including data:**

```bash
make fclean
```

⚠️ **Warning:** This deletes all data permanently (database, WordPress files, uploads).

**To restart the project:**

```bash
make re
```

This performs a full cleanup and rebuild from scratch.

---

## Accessing the Website and Administration Panel

### Accessing the Main Website

**1. Open your web browser**

**2. Navigate to one of these URLs:**
```
https://mmiilpal.42.fr
```
or
```
https://localhost
```

**3. Handle the SSL certificate warning**

You will see a security warning because the site uses a self-signed SSL certificate. This is **normal and expected** for development environments.

- **Chrome/Edge:** Click "Advanced" → "Proceed to localhost (unsafe)"
- **Firefox:** Click "Advanced" → "Accept the Risk and Continue"
- **Safari:** Click "Show Details" → "visit this website"

**Why this happens:**
The project uses a self-signed SSL certificate generated locally. In production, you would use a certificate from a trusted Certificate Authority (like Let's Encrypt).

### Accessing the WordPress Administration Panel

**1. Navigate to the admin URL:**
```
https://mmiilpal.42.fr/wp-admin
```
or
```
https://localhost/wp-admin
```

**2. Accept the SSL certificate warning** (same as above)

**3. Log in with administrator credentials:**
- **Username:** `boss` (defined in `srcs/.env` as `WP_ADMIN_USER`)
- **Password:** Found in `secrets/wp_admin_password.txt`

**4. You now have full administrative access to:**
- Create and edit posts and pages
- Install and configure themes
- Install and activate plugins
- Manage users
- Configure WordPress settings

### Accessing the Static Website (Bonus)

A simple static HTML site is available at:
```
https://mmiilpal.42.fr/static/
```
or
```
https://localhost/static/
```

This demonstrates NGINX's ability to serve multiple sites from the same server.

---

## Locating and Managing Credentials

### Where Credentials Are Stored

All sensitive passwords are stored in the `secrets/` directory at the root of the project. This directory contains plain text files, with **one password per file** and **no newlines**.

**Directory structure:**
```
secrets/
├── db_root_password.txt      # MariaDB root password
├── db_password.txt            # MariaDB user password (for WordPress)
├── wp_admin_password.txt      # WordPress administrator password
└── wp_user_password.txt       # WordPress regular user password
```

**Viewing credentials:**
```bash
# View WordPress admin password
cat secrets/wp_admin_password.txt

# View database password
cat secrets/db_password.txt

# View all secrets
ls -la secrets/
```

**Security note:**
- These files are excluded from Git via `.gitignore`
- Never commit passwords to version control
- In production, use proper secret management (e.g., Docker secrets, vault services)

### WordPress User Accounts

The project automatically creates two WordPress users during initialization:

**Administrator Account:**
- **Username:** `boss` (configurable in `srcs/.env` as `WP_ADMIN_USER`)
- **Email:** `boss@example.com` (configurable in `srcs/.env`)
- **Password:** Located in `secrets/wp_admin_password.txt`
- **Role:** Administrator
- **Capabilities:** Full site control, install plugins/themes, manage users, modify settings

**Regular User Account:**
- **Username:** `user` (configurable in `srcs/.env` as `WP_USER`)
- **Email:** `user@example.com` (configurable in `srcs/.env`)
- **Password:** Located in `secrets/wp_user_password.txt`
- **Role:** Author/Contributor
- **Capabilities:** Create and edit own posts, upload media

### Database Credentials

**MariaDB Configuration:**
- **Database Name:** `wordpress` (from `srcs/.env` variable `MYSQL_DATABASE`)
- **Database User:** `wpuser` (from `srcs/.env` variable `MYSQL_USER`)
- **User Password:** Located in `secrets/db_password.txt`
- **Root Password:** Located in `secrets/db_root_password.txt`
- **Host:** `mariadb:3306` (Docker network DNS name)

**Accessing the database manually:**
```bash
# Connect as WordPress user
docker exec -it mariadb mariadb -u wpuser -p
# Enter password from secrets/db_password.txt

# Connect as root
docker exec -it mariadb mariadb -u root -p
# Enter password from secrets/db_root_password.txt
```

### Managing and Changing Credentials

**To change a password:**

1. **Stop the containers:**
   ```bash
   make down
   ```

2. **Edit the secret file:**
   ```bash
   echo "new_password_here" > secrets/wp_admin_password.txt
   ```

3. **Clean and rebuild** (required for database passwords):
   ```bash
   make fclean
   make
   ```

**Note:** Changing WordPress user passwords after initial setup requires either:
- Using WordPress admin panel (Users → Edit User → Set new password)
- Or a complete rebuild with `make fclean && make`

---

## Checking That Services Are Running Correctly

### Quick Health Check

**View all container statuses:**

```bash
make ps
```

**Expected output:**
```
NAME        IMAGE       STATUS
mariadb     mariadb     Up X minutes (healthy)
nginx       nginx       Up X minutes (healthy)
wordpress   wordpress   Up X minutes (healthy)
redis       redis       Up X minutes (healthy)
```

**What to look for:**
- ✅ `Up` status means container is running
- ✅ `(healthy)` means health checks are passing
- ❌ `Restarting` means the container is crashing
- ❌ `Exited` means the container stopped

### Detailed Service Verification

#### 1. Check NGINX (Web Server)

**Test HTTPS connection:**
```bash
curl -Ik https://localhost
```

**Expected output:**
```
HTTP/1.1 200 OK
Server: nginx
```

**Check NGINX logs:**
```bash
docker logs nginx
```

**Look for:**
- `nginx: configuration file ... test is successful`
- No error messages about port binding or SSL certificates

#### 2. Check MariaDB (Database)

**Test database connectivity:**
```bash
docker exec mariadb mariadb -u wpuser -p$(cat secrets/db_password.txt) -e "SELECT 1"
```

**Expected output:**
```
+---+
| 1 |
+---+
| 1 |
+---+
```

**Check MariaDB logs:**
```bash
docker logs mariadb
```

**Look for:**
- `mysqld: ready for connections` (appears twice during startup)
- No errors about permissions or data corruption

#### 3. Check WordPress (Application)

**Verify WordPress is responding:**
```bash
curl -Ik https://localhost | grep -i "x-powered-by"
```

**Expected output:**
```
X-Powered-By: PHP/8.2.x
```

**Check WordPress logs:**
```bash
docker logs wordpress
```

**Look for:**
- `MariaDB is up!`
- `WordPress is already installed`
- No PHP errors or database connection failures

#### 4. Check Redis (Cache) - Bonus

**Test Redis connectivity:**
```bash
docker exec redis redis-cli ping
```

**Expected output:**
```
PONG
```

**Check cached keys (after using WordPress):**
```bash
docker exec redis redis-cli KEYS '*' | head -10
```

**Expected:** Should show WordPress cache keys like `wp:options:*`, `wp:posts:*`

### Monitor All Service Logs in Real-Time

**Follow logs from all containers:**
```bash
make logs
```

Press `Ctrl+C` to stop following logs.

**Follow logs from a specific service:**
```bash
docker logs -f mariadb
docker logs -f wordpress  
docker logs -f nginx
docker logs -f redis
```

### Success Indicators Checklist

✅ **Infrastructure is healthy when:**
- All containers show `Up` and `(healthy)` status
- NGINX responds with `HTTP/1.1 200 OK` on port 443
- MariaDB accepts connections and queries
- WordPress loads at https://localhost
- WordPress admin panel accessible at https://localhost/wp-admin
- Redis responds with `PONG` to ping command
- No containers are restarting repeatedly
- Logs show no critical errors

❌ **Common warning signs:**
- Containers showing `Restarting` or `Exited` status
- Error messages in logs about connection failures
- HTTP 502/503 errors when accessing the website
- Database connection errors in WordPress logs
- Port binding errors in NGINX logs

### Troubleshooting Commands

**Check detailed container status:**
```bash
docker ps -a
```

**Inspect specific container:**
```bash
docker inspect mariadb
```

**Check Docker networks:**
```bash
docker network ls
docker network inspect inception_network
```

**Check Docker volumes:**
```bash
docker volume ls
docker volume inspect srcs_mariadb_data
```

**View resource usage:**
```bash
docker stats
```

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
