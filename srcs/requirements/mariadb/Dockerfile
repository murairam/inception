FROM alpine:3.21

RUN apk update && apk add --no-cache mariadb mariadb-client

RUN mkdir -p /var/lib/mysql /run/mysqld

RUN chown -R mysql:mysql /var/lib/mysql /run/mysqld

COPY conf/my.cnf /etc/my.cnf

COPY tools/docker-entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 3306

ENTRYPOINT [ "docker-entrypoint.sh" ]

CMD [ "mariadbd", "--user=mysql", "--bind-address=0.0.0.0", "--port=3306" ]
