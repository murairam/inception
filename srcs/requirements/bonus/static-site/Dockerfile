FROM alpine:3.21

RUN apk add --no-cache nginx

# Create web directory
RUN mkdir -p /var/www/html

# Copy nginx config
COPY conf/nginx.conf /etc/nginx/http.d/default.conf

# Copy static website files
COPY www/ /var/www/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
