FROM alpine:3.21

# Install Node.js and dependencies
RUN apk update && apk add --no-cache \
	nodejs \
	npm \
	git \
	python3 \
	make \
	g++ \
	curl \
	wget

# Create app directory
WORKDIR /app

# Clone Uptime Kuma
RUN git clone https://github.com/louislam/uptime-kuma.git . && \
	git checkout 1.23.13

# Install dependencies and build
RUN npm ci --production && \
	npm run download-dist

# Create data directory
RUN mkdir -p /app/data

EXPOSE 3001

# Health check
HEALTHCHECK --interval=60s --timeout=30s --start-period=180s --retries=5 \
	CMD wget --no-verbose --tries=1 --spider http://localhost:3001 || exit 1

CMD ["node", "server/server.js"]
