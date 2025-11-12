FROM debian:bookworm-slim

MAINTAINER kill3rbytezzz <kill3rbytezzz@gmail.com>

LABEL maintainer="peter@linuxcontainers.dev" \
    org.opencontainers.image.authors="Peter, peter@linuxcontainers.dev, https://www.linuxcontainers.dev/" \
    org.opencontainers.image.source="https://github.com/kill3rbytezzz/alpine-test" \
    org.opencontainers.image.title="alpine-test"

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV PIHOLE_SKIP_OS_CHECK=true \
    PIHOLE_SKIP_STARTUP=true \
    PIHOLE_DURING_DOCKER_BUILD=true

# Install Pi-hole dependencies
RUN apt-get update && apt-get install -y \
    curl bash dnsutils lsb-release sudo iproute2 git whiptail net-tools lighttpd \
    && rm -rf /var/lib/apt/lists/*

# Prepare setupVars.conf
RUN mkdir -p /etc/pihole && echo "PIHOLE_INTERFACE=eth0" > /etc/pihole/setupVars.conf \
    && echo "IPV4_ADDRESS=127.0.0.1" >> /etc/pihole/setupVars.conf \
    && echo "DNSMASQ_LISTENING=all" >> /etc/pihole/setupVars.conf \
    && echo "WEBPASSWORD=admin" >> /etc/pihole/setupVars.conf \
    && echo "BLOCKING_ENABLED=true" >> /etc/pihole/setupVars.conf \
    && echo "INSTALL_WEB_SERVER=true" >> /etc/pihole/setupVars.conf \
    && echo "INSTALL_WEB_INTERFACE=true" >> /etc/pihole/setupVars.conf \
    && echo "LIGHTTPD_ENABLED=true" >> /etc/pihole/setupVars.conf

# Install Pi-hole silently (skip service start)
RUN curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended --disable-install-webserver --disable-install-lighttpd || true

# Copy runtime start script
RUN echo '#!/bin/bash\n\
set -e\n\
echo "[INFO] Starting lighttpd..."\n\
service lighttpd start || true\n\
echo "[INFO] Starting Pi-hole FTL..."\n\
pihole-FTL no-daemon' > /start.sh && chmod +x /start.sh

# Expose DNS and Web ports
EXPOSE 53/tcp 53/udp 80/tcp

# Start Pi-hole services at runtime
CMD ["/bin/bash", "/start.sh"]
