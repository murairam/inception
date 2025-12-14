FROM alpine:3.21

RUN apk update && apk add --no-cache \
	ca-certificates \
	curl \
	tar \
	device-mapper \
	findutils \
	zfs \
	libc6-compat \
	wget

# Download and install cAdvisor with architecture detection
RUN ARCH=$(uname -m) && \
	if [ "$ARCH" = "x86_64" ]; then \
		CADVISOR_ARCH="amd64"; \
	elif [ "$ARCH" = "aarch64" ]; then \
		CADVISOR_ARCH="arm64"; \
	else \
		echo "Unsupported architecture: $ARCH" && exit 1; \
	fi && \
	echo "Downloading cAdvisor for $CADVISOR_ARCH..." && \
	curl -L https://github.com/google/cadvisor/releases/download/v0.47.0/cadvisor-v0.47.0-linux-${CADVISOR_ARCH} -o /usr/local/bin/cadvisor && \
	chmod +x /usr/local/bin/cadvisor

EXPOSE 8080

CMD ["cadvisor", "-logtostderr"]
