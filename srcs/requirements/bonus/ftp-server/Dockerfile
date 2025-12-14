FROM alpine:3.21

RUN apk update && apk add --no-cache \
	vsftpd \
	bash

RUN mkdir -p /var/www/html /var/run/vsftpd/empty

COPY conf/vsftpd.conf /etc/vsftpd/vsftpd.conf

COPY tools/docker-entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 21 21000-21010

WORKDIR /var/www/html

ENTRYPOINT [ "docker-entrypoint.sh" ]

CMD [ "vsftpd", "/etc/vsftpd/vsftpd.conf" ]
