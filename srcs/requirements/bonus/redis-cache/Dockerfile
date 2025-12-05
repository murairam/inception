FROM alpine:3.21

RUN apk update && apk add --no cache



EXPOSE 6379

WORKDIR /data

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["redis-server"]
