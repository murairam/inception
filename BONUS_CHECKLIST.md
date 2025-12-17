# Inception - Bonus Services Checklist

Complete testing guide for all 6 bonus services.

---

## Overview

Your Inception project includes 5 bonus services:
1. **Redis Cache** - Object caching for WordPress
2. **FTP Server** - File transfer access to WordPress files
3. **Adminer** - Database management tool
4. **Static Website** - Simple HTML site served via NGINX
5. **cAdvisor** - Container monitoring and resource usage

---

## 1. Redis Cache Testing

### Quick Verification
```bash
# Test Redis connectivity
docker exec redis redis-cli ping
# Expected output: PONG

# Check number of cached items
docker exec redis redis-cli DBSIZE
# Expected: Should show a number > 0 after visiting WordPress

# View cache keys
docker exec redis redis-cli KEYS '*'
# Expected: Should show WordPress cache keys like "wp:*"
```

### Memory and Performance
```bash
# Check Redis memory usage
docker exec redis redis-cli INFO memory | grep used_memory_human
# Expected: Shows memory usage (e.g., "1.23M")

# Check cache statistics
docker exec redis redis-cli INFO stats | grep keyspace
# Expected: Shows hits and misses

# Monitor real-time commands
docker exec redis redis-cli MONITOR
# (Press Ctrl+C to stop)
```

### WordPress Integration
```bash
# Check WordPress Redis plugin status
docker exec wordpress wp redis status --allow-root
# Expected: "Status: Connected" or similar

# Enable Redis if not enabled
docker exec wordpress wp redis enable --allow-root

# Flush Redis cache
docker exec wordpress wp redis flush --allow-root
```

### Performance Test
1. Visit WordPress site multiple times
2. Check that cache hit ratio increases:
```bash
docker exec redis redis-cli INFO stats | grep keyspace_hits
docker exec redis redis-cli INFO stats | grep keyspace_misses
```
3. Calculate hit ratio: hits / (hits + misses)
4. Should improve with repeated visits

### Browser Verification
1. Visit WordPress site: `https://localhost`
2. Check page load times (should be faster on subsequent loads)
3. Install a caching plugin dashboard to see Redis statistics

---

## 2. FTP Server Testing

### Check FTP Service Status
```bash
# Verify FTP process is running
docker exec ftp pgrep vsftpd
# Expected: Returns a process ID number

# Check FTP user exists
docker exec ftp id ftpuser
# Expected: Shows user info

# Verify FTP has access to WordPress files
docker exec ftp ls -la /var/www/html | head -10
# Expected: Shows WordPress files owned by ftpuser
```

### Connect via FTP Client

#### Option 1: Command-line FTP
```bash
ftp localhost 21
# Username: ftpuser
# Password: (from secrets/ftp_user_password.txt)
```

#### FTP Commands to Test
```bash
# Once connected:
ls                          # List files
pwd                         # Show current directory
cd wp-content              # Navigate to directory
cd uploads                 # Go to uploads folder
get wp-config.php test.php # Download a file (test only!)
put localfile.txt          # Upload a file (if you have one)
mkdir test_directory       # Create directory
rmdir test_directory       # Remove directory
bye                        # Exit FTP
```

#### Option 2: FileZilla or GUI FTP Client
```
Host: localhost
Port: 21
Username: ftpuser
Password: (from secrets/ftp_user_password.txt)
```

### Test File Permissions
```bash
# Upload a test file via FTP, then check:
docker exec ftp ls -l /var/www/html/test_file.txt
# Expected: File owned by ftpuser

# Verify WordPress can access FTP-uploaded files
docker exec wordpress ls -l /var/www/html/test_file.txt
# Expected: File visible to WordPress
```

### WordPress Upload Test
1. Login to WordPress admin: `https://localhost/wp-admin`
2. Go to **Media → Add New**
3. Upload an image
4. Connect via FTP and verify file exists in `wp-content/uploads/YYYY/MM/`

### Common FTP Commands Reference
```
USER username    - Login with username
PASS password    - Provide password
LIST             - List files in current directory
RETR filename    - Download file
STOR filename    - Upload file
CWD directory    - Change directory
PWD              - Print working directory
DELE filename    - Delete file
MKD directory    - Make directory
RMD directory    - Remove directory
QUIT             - Disconnect
```

---

## 3. Adminer Testing

### Basic Access
```bash
# Check Adminer HTTP response
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080
# Expected: 200

# Check Adminer container is running
docker ps | grep adminer
# Expected: Shows running container
```

### Browser Access
Visit: `http://localhost:8080`

### Login Credentials

#### As WordPress User
```
System: MySQL
Server: mariadb
Username: wpuser
Password: (from secrets/db_password.txt)
Database: wordpress
```

#### As Root User
```
System: MySQL
Server: mariadb
Username: root
Password: (from secrets/db_root_password.txt)
Database: (leave blank to see all)
```

### Database Operations to Test

#### 1. Browse Tables
- Click on `wordpress` database
- Browse tables: `wp_users`, `wp_posts`, `wp_options`, etc.
- Verify data is present

#### 2. Execute SQL Queries
```sql
-- View all users
SELECT user_login, user_email, user_registered FROM wp_users;

-- Count posts
SELECT COUNT(*) FROM wp_posts WHERE post_status = 'publish';

-- View site settings
SELECT option_name, option_value FROM wp_options 
WHERE option_name IN ('siteurl', 'home', 'blogname');

-- Check table sizes
SELECT 
    table_name, 
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS "Size (MB)"
FROM information_schema.TABLES 
WHERE table_schema = "wordpress"
ORDER BY (data_length + index_length) DESC;
```

#### 3. View Table Structure
- Click on any table name
- Click "Show structure"
- Verify column definitions, indexes, and keys

#### 4. Export Database
- Select database
- Click "Export"
- Choose format (SQL, CSV, etc.)
- Download backup

#### 5. Import Data (Optional)
- Click "Import"
- Upload SQL file
- Execute

### Security Verification
```bash
# Verify Adminer container has no unnecessary privileges
docker inspect adminer | grep -i privilege
# Expected: Should not show privileged mode

# Check Adminer PHP version
docker exec adminer php83 -v
# Expected: Shows PHP 8.3.x
```

### Performance Check
```bash
# Check Adminer response time
time curl -s http://localhost:8080 > /dev/null
# Expected: < 1 second

# Check memory usage
docker stats adminer --no-stream
# Expected: Low memory usage (< 100MB)
```

---

## 4. Static Website Testing

### Basic Access
```bash
# Check static site HTTP response
curl -k -s -o /dev/null -w "%{http_code}" https://localhost/static/
# Expected: 200

# View static site content
curl -k https://localhost/static/
# Expected: Shows HTML content

# Download static page
curl -k https://localhost/static/ > static_page.html
```

### Verify Files in Volume
```bash
# Check files in host directory
ls -lh ~/data/static-site/
# Expected: Shows index.html and any assets

# Check files from NGINX container
docker exec nginx ls -lh /var/www/static/
# Expected: Same files as host directory
```

### Browser Access
Visit: `https://localhost/static/`

**Expected Result:**
- Static HTML page displays
- Images load correctly
- No WordPress interface

### Test Static Assets
```bash
# If you have images/CSS in static site:
curl -k -I https://localhost/static/image.jpg
curl -k -I https://localhost/static/style.css
# Expected: 200 OK responses
```

### Verify NGINX Configuration
```bash
# Check NGINX config for static location
docker exec nginx cat /etc/nginx/nginx.conf | grep -A 10 "location /static"
# Expected: Shows static site configuration with correct alias
```

### Modify Static Site
```bash
# Edit static page
echo "<h1>Test Update</h1>" >> ~/data/static-site/index.html

# Refresh browser - should show update immediately (no restart needed)
curl -k https://localhost/static/ | grep "Test Update"
# Expected: Shows new content
```

### Cache Headers Verification
```bash
# Check cache headers for static assets
curl -k -I https://localhost/static/image.jpg | grep -i cache
# Expected: Shows cache control headers
```

---

## 5. cAdvisor Testing

### Basic Access
```bash
# Check cAdvisor HTTP response
curl -s -o /dev/null -w "%{http_code}" http://localhost:8081
# Expected: 200

# Check health endpoint
curl -s http://localhost:8081/healthz
# Expected: "ok"
```

### Browser Access
Visit: `http://localhost:8081`

**Expected Interface:**
- Dashboard showing all containers
- Real-time resource usage graphs
- Container list with statistics

### Container Monitoring

#### View All Containers
- Main page shows Docker host summary
- Click "Docker Containers" to see list
- Should show: mariadb, wordpress, nginx, redis, ftp, adminer, uptime-kuma, cadvisor

#### Resource Metrics to Check
For each container:
- **CPU Usage:** % of CPU used
- **Memory Usage:** Current memory consumption
- **Network I/O:** Bytes sent/received
- **Filesystem Usage:** Disk I/O operations

#### Detailed Container View
1. Click on any container name
2. View graphs for:
   - CPU usage over time
   - Memory usage over time
   - Network throughput
   - Filesystem I/O
3. Check process list inside container

### API Testing
```bash
# Get machine info
curl -s http://localhost:8081/api/v1.3/machine | jq .

# Get container list
curl -s http://localhost:8081/api/v1.3/docker | jq .

# Get specific container stats
curl -s http://localhost:8081/api/v1.3/containers/docker/nginx | jq .
```

### Compare with Docker Stats
```bash
# Run both simultaneously
docker stats --no-stream
# Then check cAdvisor web interface
# Values should be similar
```

### Performance Test
1. Load WordPress site heavily (refresh many times)
2. Watch cAdvisor graphs update in real-time
3. Observe CPU and memory spikes for wordpress and nginx containers

### Verify Privileged Access
```bash
# cAdvisor needs privileged mode to access host metrics
docker inspect cadvisor | grep -i "Privileged"
# Expected: "Privileged": true
```

---
---

## Complete Bonus Verification Script
Run this comprehensive test of all bonus services:

```bash
#!/bin/bash

echo "======================================="
echo "  BONUS SERVICES VERIFICATION"
echo "======================================="

echo -e "\n=== 1. Redis Cache ==="
echo "  Redis connection:"
docker exec redis redis-cli ping 2>/dev/null && echo "    ✓ Redis is UP" || echo "    ✗ Redis is DOWN"
echo "  Cache entries:"
docker exec redis redis-cli DBSIZE 2>/dev/null | sed 's/^/    /'
echo "  Memory usage:"
docker exec redis redis-cli INFO memory 2>/dev/null | grep used_memory_human | sed 's/^/    /'
echo "  WordPress integration:"
docker exec wordpress wp redis status --allow-root 2>/dev/null | sed 's/^/    /' || echo "    Check manually in WordPress admin"

echo -e "\n=== 2. FTP Server ==="
echo "  FTP service status:"
docker exec ftp pgrep vsftpd >/dev/null 2>&1 && echo "    ✓ FTP is running" || echo "    ✗ FTP is not running"
echo "  FTP user:"
docker exec ftp id ftpuser 2>/dev/null | sed 's/^/    /' || echo "    ✗ FTP user not found"
echo "  WordPress files access:"
docker exec ftp ls /var/www/html/wp-config.php >/dev/null 2>&1 && echo "    ✓ Can access WordPress files" || echo "    ✗ Cannot access files"
echo "  Connection: ftp localhost 21 (user: ftpuser)"

echo -e "\n=== 3. Adminer ==="
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
if [ "$HTTP_CODE" = "200" ]; then
    echo "    ✓ Adminer is accessible (HTTP $HTTP_CODE)"
else
    echo "    ✗ Adminer is not accessible (HTTP $HTTP_CODE)"
fi
echo "    URL: http://localhost:8080"
echo "    Login: mariadb | wpuser | (password from secrets)"

echo -e "\n=== 4. Static Website ==="
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://localhost/static/)
if [ "$HTTP_CODE" = "200" ]; then
    echo "    ✓ Static site is accessible (HTTP $HTTP_CODE)"
else
    echo "    ✗ Static site is not accessible (HTTP $HTTP_CODE)"
fi
echo "    Files in volume:"
ls -lh ~/data/static-site/ 2>/dev/null | tail -n +2 | sed 's/^/      /' || docker exec nginx ls -lh /var/www/static/ | tail -n +2 | sed 's/^/      /'
echo "    URL: https://localhost/static/"

echo -e "\n=== 5. cAdvisor ==="
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081)
if [ "$HTTP_CODE" = "200" ]; then
    echo "    ✓ cAdvisor is accessible (HTTP $HTTP_CODE)"
else
    echo "    ✗ cAdvisor is not accessible (HTTP $HTTP_CODE)"
fi
HEALTH=$(curl -s http://localhost:8081/healthz 2>/dev/null)
if [ "$HEALTH" = "ok" ]; then
    echo "    ✓ Health check passed"
else
    echo "    ✗ Health check failed"
fi
echo "    URL: http://localhost:8081"

echo -e "\n=== 6. Uptime Kuma ==="
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001)
if [ "$HTTP_CODE" = "200" ]; then
    echo "    ✓ Uptime Kuma is accessible (HTTP $HTTP_CODE)"
else
    echo "    ✗ Uptime Kuma is not accessible (HTTP $HTTP_CODE)"
fi
echo "    URL: http://localhost:3001"
echo "    Setup: Create admin account on first visit"

echo -e "\n======================================="
echo "  BONUS VERIFICATION COMPLETE"
echo "======================================="
echo -e "\nBrowser Access Required:"
echo "  • Adminer:     http://localhost:8080"
echo "  • cAdvisor:    http://localhost:8081"
echo "  • Uptime Kuma: http://localhost:3001"
echo "  • Static Site: https://localhost/static/"
echo "  • FTP Client:  ftp://localhost:21"
echo ""
```

Save this script and run it:
```bash
chmod +x bonus_test.sh
./bonus_test.sh
```

---

## Quick Reference

| Service | Type | Port | URL | Credentials |
|---------|------|------|-----|-------------|
| Redis | Cache | 6379 | - | None (internal) |
| FTP | File Transfer | 21 | `ftp://localhost:21` | ftpuser / (secret) |
| Adminer | Web UI | 8080 | `http://localhost:8080` | wpuser / (secret) |
| Static Site | Web | 443 | `https://localhost/static/` | None |
| cAdvisor | Web UI | 8081 | `http://localhost:8081` | None |

---

## Common Issues and Solutions

### Redis Issues
- **Problem:** WordPress not using cache
- **Solution:** Check plugin status: `docker exec wordpress wp redis status --allow-root`
- **Fix:** Enable cache: `docker exec wordpress wp redis enable --allow-root`

### FTP Issues
- **Problem:** Permission denied
- **Solution:** Check FTP user owns files: `docker exec ftp chown -R ftpuser:ftpuser /var/www/html`

### Adminer Issues
- **Problem:** Can't connect to MariaDB
- **Solution:** Verify server name is "mariadb" (not localhost)
- **Check:** Ensure MariaDB container is healthy

### Static Site Issues
- **Problem:** 404 Not Found
- **Solution:** Verify files exist: `ls ~/data/static-site/`
- **Fix:** Copy files: `cp -r srcs/requirements/bonus/static-site/www/* ~/data/static-site/`

### cAdvisor Issues
### cAdvisor Issues
- **Problem:** Missing metrics
- **Solution:** Ensure privileged mode in docker-compose.yml
- **Check:** Verify volume mounts for host system access

---

## Evaluation Points
Each bonus service adds **+1 point** to your grade:

- ✓ Redis Cache working → +1
- ✓ FTP Server accessible → +1
## Evaluation Points

Each bonus service adds **+1 point** to your grade:

- ✓ Redis Cache working → +1
- ✓ FTP Server accessible → +1
- ✓ Adminer functional → +1
- ✓ Static Website serving → +1
- ✓ cAdvisor monitoring → +1

**Maximum Bonus: 5 points**

Ensure all services are accessible and functional before evaluation!