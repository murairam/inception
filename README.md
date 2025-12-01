inception

---

what is SSL/TLS?

SSL - secure sockets layer, encriptions based interner security protocol. it is the predecessor for TLS inscription that is used today.
A website that has SSL/TLS has "HTTPS" in url, instead of the HTTP
works by
* encrypting data that is transmitted
* checks that the two communicating devices are who they claim to be by initiating a handshake between them
* signs the data to make sure it is not tampered with before it reaches the recipient

in 1999 SSL was updated to TLS
short description. SSL encrypts all data that is between user and web server to ensure that all data is hidden for outsiders (for example credit card info)

TLS - transport layer security
thw two are closely related, name change was to signify the change in ownership

why tail -f and sleep infinity are prohibited?

tail -f - continuously reads the end of a file (never exits)
sleep infinity - sleeps forever (never exits)

What is PID 1?

every process in linux gets a process id - the first one is usually allocated to systemd or init, which manage all other processes
in my docker container - PID 1 will be for the main command, it will be the parent of everything in that container. so when PID1 stops, the container stops.


how the three containers in inception are connected
```
User (browser)
    ↓ HTTPS (port 443)
NGINX container
    ↓ port 9000 (internal network)
WordPress+PHP-FPM container
    ↓ port 3306 (internal network)
MariaDB container
```

What the volumes contain:
Volume 1 - MariaDB (~/data/mariadb):

Database files (actual MySQL/MariaDB data)
WordPress posts, pages, users, settings
All stored as database tables

Volume 2 - WordPress (~/data/wordpress):

WordPress PHP files
Themes
Plugins
Uploaded media (images, videos)
wp-config.php (WordPress configuration)

what goes in a dockerfile?
FROM - base image
RUN - execute commands during build
COPY - copy files into image
EXPOSE - document which ports container uses
CMD - what runs when container starts
ENTRYPOINT - alternative to CMD

ENTRYPOINT = "python"      (the program)
CMD = ["script.py"]        (what to run)
Together: python script.py

What is Alpine?
Alpine is a tiny Linux distribution designed for containers:

Only ~5MB in size (vs Debian's ~100MB)
Uses apk package manager (not apt)
Security-focused
Perfect for Docker because it's lightweight

mariadb
/var/lib/mysql - Database files
	This is where MariaDB stores:

	All database tables
	User data
	WordPress posts/pages
	Everything persistent

	Without it: MariaDB can't store any data!

/run/mysqld - Socket file
	This is where MariaDB creates:

	mysqld.sock - a special file for local connections
	Process ID file

	Think of it like a "mailbox" where programs talk to MariaDB locally.
	Without it: MariaDB can't create the socket → can't start!

NGINX

--no-cache tells apk to not sore package cache files after installation

ssl generation
req -x509 - Create a self-signed certificate
-nodes - No password for the private key
-days 365 - Valid for 1 year
-newkey rsa:2048 - Generate new 2048-bit RSA key
-keyout - Where to save the private key
-out - Where to save the certificate
-subj - Certificate details (Country, State, etc.)

nginx conf file explanation
nginxevents {
    worker_connections 1024;
}
events block:

Required by NGINX (config won't work without it)
worker_connections 1024 - How many simultaneous connections each NGINX worker can handle
For this small project, 1024 is more than enough


nginxhttp {
    include /etc/nginx/mime.types;
http block:

Contains all web server configuration
include /etc/nginx/mime.types - Tells NGINX what file types are what (e.g., .html is text/html, .jpg is image/jpeg)
This file comes with NGINX package


nginx    server {
        listen 443 ssl;
        listen [::]:443 ssl;
server block - Defines one virtual server

listen 443 ssl; - Listen on port 443 with SSL for IPv4
listen [::]:443 ssl; - Same for IPv6
The ssl keyword enables HTTPS


nginx        server_name mmiilpal.42.fr;
server_name:

What domain this server responds to
Change this to YOUR login! mmiilpal.42.fr


nginx        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;
        ssl_protocols TLSv1.2 TLSv1.3;
SSL configuration:

ssl_certificate - Path to your .crt file (public certificate)
ssl_certificate_key - Path to your .key file (private key)
ssl_protocols TLSv1.2 TLSv1.3; - ONLY these two protocols allowed ✓


nginx        root /var/www/html;
        index index.php;
Document root:

root /var/www/html - Where website files are located (this will be the WordPress volume mount point)
index index.php - Default file to serve (WordPress main file)


nginx        location / {
            try_files $uri $uri/ /index.php?$args;
        }
location / block - Handles all requests

try_files $uri $uri/ /index.php?$args; -

First, try to serve the file directly ($uri)
If not found, try as directory ($uri/)
If still not found, send to index.php (WordPress handles it)


This is how WordPress "pretty URLs" work (e.g., /about instead of /index.php?page=about)


nginx        location ~ \.php$ {
            fastcgi_pass wordpress:9000;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }
location ~ \.php$ block - Handles PHP files

~ means "regex match"
\.php$ matches any file ending in .php
fastcgi_pass wordpress:9000; - KEY LINE! Forward PHP requests to WordPress container on port 9000
fastcgi_index index.php - Default PHP file
include fastcgi_params; - Standard FastCGI parameters (comes with NGINX)
fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; - Tells PHP-FPM which file to execute
---
resources:
 - https://docs.docker.com/compose/
 - https://medium.com/@boutnaruthe-linux-process-journey-pid-1-init-60765a069f17
 - https://cloud.theodo.com/en/blog/docker-processes-container
 - https://www.youtube.com/watch?v=pg19Z8LL06w
 - https://nickjanetakis.com/blog/benchmarking-debian-vs-alpine-as-a-base-docker-image
 - https://www.youtube.com/watch?v=DQdB7wFEygo
 - https://tuto.grademe.fr/inception/#
 - https://docker-curriculum.com/?source=post_page-----cfda98d9f4ac--------------------------------#introduction
 - https://docs.docker.com/engine/storage/volumes/
 - https://www.youtube.com/watch?v=iInUBOVeBCc
 - https://medium.com/@afatir.ahmedfatir/unveiling-42-the-network-inception-a-dive-into-docker-and-docker-compose-cfda98d9f4ac
 - https://www.youtube.com/watch?v=sK5i-N34im8
 - https://medium.com/@weidagang/linux-beyond-the-basics-cgroups-f157d93bd755
 - https://nginx.org/en/docs/beginners_guide.html
 - https://www.cloudflare.com/en-gb/learning/ssl/what-is-ssl/
 - https://hoop.dev/blog/what-alpine-debian-actually-does-and-when-to-use-it/
 - https://www.youtube.com/watch?v=JKxlsvZXG7c
 - https://www.youtube.com/watch?v=4NB0NDtOwIQ





