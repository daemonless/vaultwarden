ARG BASE_VERSION=15
FROM ghcr.io/daemonless/nginx-base:${BASE_VERSION}

ARG FREEBSD_ARCH=amd64
ARG PACKAGES="vaultwarden vaultwarden_web-vault"

LABEL org.opencontainers.image.title="Vaultwarden" \
    org.opencontainers.image.description="Vaultwarden (Bitwarden compatible backend) on FreeBSD" \
    org.opencontainers.image.source="https://github.com/daemonless/vaultwarden" \
    org.opencontainers.image.licenses="GPL-3.0-only" \
    org.opencontainers.image.vendor="daemonless" \
    org.opencontainers.image.authors="daemonless" \
    io.daemonless.port="80" \
    io.daemonless.arch="${FREEBSD_ARCH}" \
    io.daemonless.pkg-source="containerfile" \
    io.daemonless.base="nginx" \
    io.daemonless.category="Utilities" \
    io.daemonless.packages="${PACKAGES}"

# Install Vaultwarden and Web Vault from packages
RUN pkg update && \
    pkg install -y \
    ${PACKAGES} && \
    mkdir -p /app && pkg info vaultwarden | sed -n 's/.*Version.*: *//p' > /app/version && \
    pkg clean -ay && \
    rm -rf /var/cache/pkg/* /var/db/pkg/repos/*

# Create config directory and set permissions
RUN mkdir -p /config && \
    chown -R bsd:bsd /config

# Symlink web-vault to the expected location if needed, 
# though standard FreeBSD path is /usr/local/www/vaultwarden/web-vault
RUN ln -sf /usr/local/www/vaultwarden/web-vault /web-vault

# Environment defaults
ENV DATA_FOLDER=/config \
    WEB_VAULT_FOLDER=/usr/local/www/vaultwarden/web-vault \
    WEB_VAULT_ENABLED=true \
    ROCKET_ADDRESS=127.0.0.1 \
    ROCKET_PORT=8080

# Copy service definition and nginx config
COPY root/ /

# Make scripts executable
RUN chmod +x /etc/services.d/vaultwarden/run /etc/cont-init.d/* 2>/dev/null || true

EXPOSE 80
VOLUME /config
