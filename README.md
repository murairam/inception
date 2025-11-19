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


