FROM alpine:3.21

RUN apk update && apk add --no-cache nginx openssl gettext netcat-openbsd

RUN mkdir -p /etc/nginx/ssl

COPY conf/nginx.conf.template /etc/nginx/nginx.conf.template
COPY tools/docker-entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 443

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
