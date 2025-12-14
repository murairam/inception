FROM alpine:3.21

RUN apk update && apk add --no-cache \
    php83 \
    php83-fpm \
    php83-mysqli \
    php83-session \
    nginx \
    wget \
    && rm -rf /var/cache/apk/*

RUN mkdir -p /var/www/html /run/php83 /run/nginx

RUN wget -O /var/www/html/adminer.php https://www.adminer.org/latest.php

RUN chown -R nginx:nginx /var/www/html

COPY conf/nginx.conf /etc/nginx/http.d/default.conf
COPY tools/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
