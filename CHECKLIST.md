# Inception - Checklist

This checklist contains all commands needed to verify the project.

---

## Setup

### 1. Full System Cleanup
```bash
docker stop $(docker ps -qa); docker rm $(docker ps -qa); docker rmi -f $(docker images -qa); docker volume rm $(docker volume ls -q); docker network rm $(docker network ls -q) 2>/dev/null
```

### 2. Build and Start
```bash
make
```

---

## General Instructions Verification

### Check for Forbidden Patterns
```bash
# Should return nothing (no forbidden commands)
grep -r "tail -f\|sleep infinity\|while true" srcs/

# Check for --link (should return nothing)
grep -r "\-\-link" srcs/
```

### Verify Docker Compose Configuration
```bash
# Check no 'network: host' or 'links:' (should return nothing)
grep -E "network:\s*host|links:" srcs/docker-compose.yml

# Check network exists (should show 'networks:')
grep "networks:" srcs/docker-compose.yml
```

### Verify Alpine Base Images
```bash
# Should show all FROM alpine:3.21
grep -h "^FROM" srcs/requirements/*/Dockerfile
```

### Check Entrypoint Scripts
```bash
# Verify exec is used (should show 3 lines ending with exec)
grep -n "^exec" srcs/requirements/*/tools/docker-entrypoint.sh
```

---

## Docker Setup Verification

### Container Status
```bash
# All containers should be running and healthy
docker-compose -f srcs/docker-compose.yml ps
```

### Image Names Match Services
```bash
# Images should be: mariadb, wordpress, nginx, redis
docker images | grep -E "mariadb|wordpress|nginx|redis"
```

### Network Verification
```bash
# Should show inception_network (or srcs_inception_network)
docker network ls | grep inception
```

### Volume Verification
```bash
# Should show 3 volumes
docker volume ls

# Check volume paths (should contain /home/mmiilpal/data/)
docker volume inspect srcs_mariadb_data | grep -A 3 "Options"
docker volume inspect srcs_wordpress_data | grep -A 3 "Options"
```

---

## NGINX with SSL/TLS

### Port 80 Should Fail
```bash
# Should fail to connect
curl -I http://localhost
```

### Port 443 Should Work
```bash
# Should return HTTP/1.1 200 OK
curl -Ik https://localhost
```

### Verify SSL Certificate
```bash
# Check certificate exists
docker exec nginx ls -la /etc/nginx/ssl/
```

### Browser Test
- Visit `https://localhost` or `https://mmiilpal.42.fr`
- Should show WordPress site (NOT installation page)
- Self-signed certificate warning is expected

---

## WordPress Verification

### Check Configuration Exists
```bash
# wp-config.php should exist
docker exec wordpress ls -la /var/www/html/wp-config.php
```

### Verify No NGINX in Dockerfile
```bash
# Should return nothing
grep -i nginx srcs/requirements/wordpress/Dockerfile
```

### Check WordPress Users
```bash
# Should show two users: boss and user
docker exec -it mariadb mariadb -u wpuser -p$(cat secrets/db_password.txt) wordpress -e "SELECT user_login, user_email FROM wp_users;"
```

### Admin Username Validation
- Admin username: `boss`
- Does NOT contain: admin, Admin, administrator, Administrator

### WordPress Functionality Tests
1. **Login as admin (`boss`):**
   - Visit `https://localhost/wp-admin`
   - Edit a page from dashboard
   - Verify changes appear on site

2. **Add comment as regular user:**
   - Login as `user`
   - Add a comment to a post
   - Check it appears (may need approval)

---

## MariaDB Verification

### Check No NGINX in Dockerfile
```bash
# Should return nothing
grep -i nginx srcs/requirements/mariadb/Dockerfile
```

### Root Password Required (Must Fail)
```bash
# This MUST fail
docker exec -it mariadb mariadb -u root
```

### Root Access with Password (Should Work)
```bash
# Should work and show databases
docker exec -it mariadb mariadb -u root -p$(cat secrets/db_root_password.txt) -e "SHOW DATABASES;"
```

### WordPress User Access
```bash
# Quick connection test
docker exec -it mariadb mariadb -u wpuser -p$(cat secrets/db_password.txt) wordpress -e "SELECT 1;"

# Show WordPress tables
docker exec -it mariadb mariadb -u wpuser -p$(cat secrets/db_password.txt) wordpress -e "SHOW TABLES;"
```

---

## Persistence Test

### Stop Everything
```bash
make down
# or
docker-compose -f srcs/docker-compose.yml down
```

### Verify Containers Stopped
```bash
docker ps
```

### Restart
```bash
make
```

### Verify Persistence
1. Check containers are running:
   ```bash
   docker-compose -f srcs/docker-compose.yml ps
   ```

2. **Browser test:**
   - Visit WordPress site
   - Previously edited pages should still show changes
   - WordPress should NOT show installation page

---

## Bonus - FTP Server

### Test FTP Connection
```bash
# Install FTP client if needed
# On macOS: brew install inetutils
# On Linux: sudo apt-get install ftp

# Connect to FTP server
ftp localhost 21
# Username: ftpuser
# Password: (from secrets/ftp_user_password.txt)
```

### FTP Commands to Test
```bash
# Once connected to FTP:
ls                          # List WordPress files
cd wp-content              # Navigate to wp-content
cd uploads                 # Navigate to uploads folder
put test.txt               # Upload a file (if you have one)
get wp-config.php          # Download a file (test only - don't edit!)
bye                        # Exit FTP
```

### Verify FTP User Access
```bash
# Check FTP user exists in container
docker exec ftp id ftpuser

# Check FTP user has access to WordPress files
docker exec ftp ls -la /var/www/html | head -10
```

### Browser Upload Test
1. Login to WordPress admin panel
2. Go to Media → Add New
3. Upload an image
4. Verify file appears in: `~/data/wordpress/wp-content/uploads/`
5. Connect via FTP and verify you can see the uploaded file

---

## Bonus - Adminer

### Browser Test
- Visit `http://localhost:8080`
- Should show Adminer login page

### Login to Adminer
```
System: MySQL
Server: mariadb
Username: wpuser
Password: (from secrets/db_password.txt)
Database: wordpress
```

### Test Database Operations
1. **Browse tables:** Click on `wp_users`, `wp_posts`, etc.
2. **Run SQL query:**
   ```sql
   SELECT * FROM wp_users;
   ```
3. **View structure:** Check table schemas
4. **Test root access:** Try logging in as root with root password

### Verify Adminer Container
```bash
# Check Adminer is running
docker exec adminer ps aux | grep nginx

# Check PHP is working
docker exec adminer php83 -v
```

---

## Bonus - cAdvisor (Container Monitoring)

### Browser Test
- Visit `http://localhost:8081`
- Should show cAdvisor dashboard

### What to Check
1. **Docker Containers:** View all running containers
2. **Resource Usage:**
   - CPU usage per container
   - Memory usage per container
   - Network I/O
   - Filesystem usage
3. **Performance Graphs:** Real-time metrics

### Verify Metrics
```bash
# Check cAdvisor is collecting data
curl -s http://localhost:8081/api/v1.3/machine | head -20

# Check container stats
docker stats --no-stream
```

---

## Bonus - Uptime Kuma (Monitoring Dashboard)

### Browser Test
- Visit `http://localhost:3001`
- First time: Should show setup page
- Create admin account

### Setup Monitoring
1. **Add monitors for services:**
   - NGINX: `https://localhost` (HTTPS - Keyword)
   - WordPress: `https://localhost/wp-admin` (HTTPS)
   - MariaDB: `mariadb:3306` (TCP Ping from inside network)
   - Redis: `redis:6379` (TCP Ping)
   - Adminer: `http://localhost:8080` (HTTP)
   - cAdvisor: `http://localhost:8081` (HTTP)

2. **Configure notifications:** (Optional)
   - Email, Slack, Discord, etc.

3. **View Dashboard:**
   - All services should show "UP"
   - Response times displayed
   - Uptime percentages

### Verify Uptime Kuma
```bash
# Check Uptime Kuma is running
docker exec uptime-kuma ps aux | grep node

# Check data persistence
ls -la ~/data/uptime-kuma/ 2>/dev/null || echo "Using Docker volume"
```

---

## Bonus - Redis Cache

### Redis Connectivity
```bash
# Should return PONG
docker exec redis redis-cli ping
```

### Check Cache Keys
```bash
# Should show many WordPress cache keys
docker exec redis redis-cli KEYS '*'
```

### Memory Usage
```bash
# Should show non-zero memory usage
docker exec redis redis-cli INFO memory | grep used_memory_human
```

### Count Cache Entries
```bash
# Should show number of cached items
docker exec redis redis-cli DBSIZE
```

### Verify Redis is Connected to WordPress
```bash
# Check WordPress Redis plugin status
docker exec wordpress wp redis status --allow-root

# Test Redis performance
docker exec redis redis-cli --latency -i 1
```

### Cache Performance Test
1. Visit WordPress site several times
2. Check cache hits increase:
   ```bash
   docker exec redis redis-cli INFO stats | grep keyspace_hits
   docker exec redis redis-cli INFO stats | grep keyspace_misses
   ```
3. Cache hit ratio should increase with more page views

---

## Bonus - Static Website

### Browser Test
- Visit `https://localhost/static/`
- Should display static HTML page

### Verify Files Exist
```bash
# Check static files in volume
ls -la ~/data/static-site/
```

---

## Complete Bonus Verification Script

Copy-paste this entire block to test all bonus services:

```bash
echo "======================================="
echo "    BONUS SERVICES VERIFICATION"
echo "======================================="

echo -e "\n=== 1. Redis Cache ==="
echo "Ping Redis:"
docker exec redis redis-cli ping
echo "Cache entries:"
docker exec redis redis-cli DBSIZE
echo "Memory usage:"
docker exec redis redis-cli INFO memory | grep used_memory_human
echo "WordPress Redis status:"
docker exec wordpress wp redis status --allow-root 2>/dev/null || echo "Check manually"

echo -e "\n=== 2. FTP Server ==="
echo "FTP service status:"
docker exec ftp pgrep vsftpd && echo "FTP is running ✓" || echo "FTP is not running ✗"
echo "FTP user check:"
docker exec ftp id ftpuser
echo "WordPress files accessible:"
docker exec ftp ls -la /var/www/html | head -5

echo -e "\n=== 3. Adminer ==="
echo "Adminer HTTP response:"
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 && echo " - Adminer is accessible ✓"
echo "Visit: http://localhost:8080"

echo -e "\n=== 4. Static Website ==="
echo "Static site HTTP response:"
curl -k -s -o /dev/null -w "%{http_code}" https://localhost/static/ && echo " - Static site is accessible ✓"
echo "Static files in volume:"
ls -lh ~/data/static-site/ 2>/dev/null || docker exec nginx ls -lh /var/www/static/

echo -e "\n=== 5. cAdvisor ==="
echo "cAdvisor HTTP response:"
curl -s -o /dev/null -w "%{http_code}" http://localhost:8081 && echo " - cAdvisor is accessible ✓"
echo "Visit: http://localhost:8081"

echo -e "\n=== 6. Uptime Kuma ==="
echo "Uptime Kuma HTTP response:"
curl -s -o /dev/null -w "%{http_code}" http://localhost:3001 && echo " - Uptime Kuma is accessible ✓"
echo "Visit: http://localhost:3001"

echo -e "\n======================================="
echo "  All bonus services checked!"
echo "======================================="
echo -e "\nManual browser tests required:"
echo "  - Adminer: http://localhost:8080"
echo "  - cAdvisor: http://localhost:8081"
echo "  - Uptime Kuma: http://localhost:3001"
echo "  - Static Site: https://localhost/static/"
echo "  - FTP: ftp localhost 21 (user: ftpuser)"
```

---

## Quick Verification Script

Copy-paste this entire block for quick checks:

```bash
echo "=== Container Status ==="
docker-compose -f srcs/docker-compose.yml ps

echo -e "\n=== Image Names ==="
docker images | grep -E "mariadb|wordpress|nginx|redis"

echo -e "\n=== Network ==="
docker network ls | grep inception

echo -e "\n=== Volumes ==="
docker volume ls

echo -e "\n=== Port 80 (should fail) ==="
curl -I http://localhost 2>&1 | head -1

echo -e "\n=== Port 443 (should work) ==="
curl -Ik https://localhost 2>&1 | head -1

echo -e "\n=== WordPress Users ==="
docker exec mariadb mariadb -u wpuser -p$(cat secrets/db_password.txt) wordpress -e "SELECT user_login FROM wp_users;"

echo -e "\n=== Redis Status ==="
docker exec redis redis-cli ping
docker exec redis redis-cli DBSIZE

echo -e "\n=== Volume Paths ==="
docker volume inspect srcs_wordpress_data | grep device
```

---

## Common Questions

**Q: How does Docker work?**
- Containerization technology that packages applications with dependencies
- Uses namespaces and cgroups for isolation
- Lighter than VMs (shares host kernel)

**Q: Docker vs docker-compose?**
- Docker: Build/run individual containers manually
- docker-compose: Orchestrate multiple containers with one YAML file

**Q: What is docker-network?**
- Allows containers to communicate using service names as hostnames
- Bridge network isolates containers from host
- Internal DNS resolution provided by Docker

**Q: Why TLSv1.2/1.3 only?**
- Security: Older versions have known vulnerabilities
- Modern encryption standards

**Q: What is the domain name configuration?**
- Domain: `mmiilpal.42.fr`
- Points to `127.0.0.1` (localhost)
- Configured in `/etc/hosts`
