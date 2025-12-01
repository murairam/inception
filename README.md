# Inception

A Docker infrastructure project setting up a small network with NGINX, WordPress, and MariaDB.

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

SSL encrypts all data between user and web server to ensure that all data is hidden from outsiders (for example, credit card information).

### Why are `tail -f` and `sleep infinity` prohibited?

- `tail -f` - Continuously reads the end of a file (never exits)
- `sleep infinity` - Sleeps forever (never exits)

These commands don't allow proper container shutdown and signal handling.

### What is PID 1?

Every process in Linux gets a process ID. The first one is usually allocated to `systemd` or `init`, which manage all other processes.

**In a Docker container:** PID 1 is the main command and the parent of everything in that container. When PID 1 stops, the container stops.


---

## Project Architecture

### How the three containers are connected

```
User (browser)
    ↓ HTTPS (port 443)
NGINX container
    ↓ port 9000 (internal network)
WordPress+PHP-FPM container
    ↓ port 3306 (internal network)
MariaDB container
```

### Volume Contents

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

### NGINX

**`--no-cache` flag:** Tells `apk` to not store package cache files after installation.

**SSL Certificate Generation:**
- `req -x509` - Create a self-signed certificate
- `-nodes` - No password for the private key
- `-days 365` - Valid for 1 year
- `-newkey rsa:2048` - Generate new 2048-bit RSA key
- `-keyout` - Where to save the private key
- `-out` - Where to save the certificate
- `-subj` - Certificate details (Country, State, etc.)

**NGINX Configuration File Explanation:**

**`events` block:**
```nginx
events {
    worker_connections 1024;
}
```
- Required by NGINX (config won't work without it)
- `worker_connections 1024` - How many simultaneous connections each NGINX worker can handle
- For this small project, 1024 is more than enough

**`http` block:**
```nginx
http {
    include /etc/nginx/mime.types;
```
- Contains all web server configuration
- `include /etc/nginx/mime.types` - Tells NGINX what file types are (e.g., `.html` is `text/html`, `.jpg` is `image/jpeg`)
- This file comes with the NGINX package

**`server` block - Defines one virtual server:**
```nginx
server {
    listen 443 ssl;
    listen [::]:443 ssl;
```
- `listen 443 ssl;` - Listen on port 443 with SSL for IPv4
- `listen [::]:443 ssl;` - Same for IPv6
- The `ssl` keyword enables HTTPS

**`server_name`:**
```nginx
server_name mmiilpal.42.fr;
```
- What domain this server responds to

**SSL configuration:**
```nginx
ssl_certificate /etc/nginx/ssl/nginx.crt;
ssl_certificate_key /etc/nginx/ssl/nginx.key;
ssl_protocols TLSv1.2 TLSv1.3;
```
- `ssl_certificate` - Path to your `.crt` file (public certificate)
- `ssl_certificate_key` - Path to your `.key` file (private key)
- `ssl_protocols TLSv1.2 TLSv1.3;` - ONLY these two protocols allowed ✓

**Document root:**
```nginx
root /var/www/html;
index index.php;
```
- `root /var/www/html` - Where website files are located (this will be the WordPress volume mount point)
- `index index.php` - Default file to serve (WordPress main file)

**`location /` block - Handles all requests:**
```nginx
location / {
    try_files $uri $uri/ /index.php?$args;
}
```
- `try_files $uri $uri/ /index.php?$args;`:
  1. First, try to serve the file directly (`$uri`)
  2. If not found, try as directory (`$uri/`)
  3. If still not found, send to `index.php` (WordPress handles it)

This is how WordPress "pretty URLs" work (e.g., `/about` instead of `/index.php?page=about`)

**`location ~ \.php$` block - Handles PHP files:**
```nginx
location ~ \.php$ {
    fastcgi_pass wordpress:9000;
    fastcgi_index index.php;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
}
```
- `~` means "regex match"
- `\.php$` matches any file ending in `.php`
- `fastcgi_pass wordpress:9000;` - **KEY LINE!** Forward PHP requests to WordPress container on port 9000
- `fastcgi_index index.php` - Default PHP file
- `include fastcgi_params;` - Standard FastCGI parameters (comes with NGINX)
- `fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;` - Tells PHP-FPM which file to execute
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
- [Docker Tutorial](https://www.youtube.com/watch?v=pg19Z8LL06w)
- [Docker Explained](https://www.youtube.com/watch?v=DQdB7wFEygo)
- [Docker Compose Tutorial](https://www.youtube.com/watch?v=iInUBOVeBCc)
- [Docker Networking](https://www.youtube.com/watch?v=sK5i-N34im8)
- [Docker Containers and Images](https://www.youtube.com/watch?v=JKxlsvZXG7c)
- [Docker Deep Dive](https://www.youtube.com/watch?v=4NB0NDtOwIQ)





