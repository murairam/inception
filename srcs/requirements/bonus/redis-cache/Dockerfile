FROM alpine:3.21

RUN apk update && apk add --no-cache redis

RUN mkdir -p /data /etc/redis && \
    chown redis:redis /data

COPY conf/redis.conf /etc/redis/redis.conf

EXPOSE 6379

WORKDIR /data

USER redis

CMD ["redis-server", "/etc/redis/redis.conf"]
