FROM alpine:3.21

RUN apk update && apk add --no-cache \
	php83 \
	php83-fpm \
	php83-mysqli \
	php83-json \
	php83-curl \
	php83-dom \
	php83-exif \
	php83-fileinfo \
	php83-mbstring \
	php83-openssl \
	php83-xml \
	php83-zip \
	php83-phar \
	php83-tokenizer \
	php83-redis \
	curl \
	bash \
	mariadb-client


RUN mkdir -p /var/www/html /run/php83

RUN curl -O https://wordpress.org/latest.tar.gz && \
	tar -xzf latest.tar.gz -C /var/www/html --strip-components=1 && \
	rm latest.tar.gz

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
	chmod +x wp-cli.phar && \
	mv wp-cli.phar /usr/local/bin/wp

RUN chown -R nobody:nobody /var/www/html

COPY conf/www.conf /etc/php83/php-fpm.d/www.conf

COPY tools/docker-entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 9000

WORKDIR /var/www/html

ENTRYPOINT [ "docker-entrypoint.sh" ]

CMD [ "php-fpm83", "-F" ]
