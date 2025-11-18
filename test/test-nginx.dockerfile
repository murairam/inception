FROM alpine:3.21

RUN apk update && apk add nginx

# Create directory and add HTML
RUN mkdir -p /usr/share/nginx/html && \
    echo '<h1>Hello from NGINX in Docker!</h1>' > /usr/share/nginx/html/index.html

# Replace the default config with a working one
RUN echo 'server { \
    listen 80; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ =404; \
    } \
}' > /etc/nginx/http.d/default.conf

RUN mkdir -p /run/nginx

CMD ["nginx", "-g", "daemon off;"]