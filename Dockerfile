# ============================================================================
#  Sundy.Host VPS — Dockerfile
# ============================================================================

FROM alpine:3.21

ENV PROOT_VERSION=5.4.0
ENV LANG=en_US.UTF-8

# Install packages
RUN apk update && \
    apk add --no-cache \
        bash \
        jq \
        curl \
        ca-certificates \
        iproute2 \
        xz \
        shadow \
        iptables \
        ip6tables \
        procps \
        coreutils

# Install PRoot
RUN ARCH=$(uname -m) && \
    mkdir -p /usr/local/bin && \
    proot_url="https://github.com/ysdragon/proot-static/releases/download/v${PROOT_VERSION}/proot-${ARCH}-static" && \
    curl -Ls "$proot_url" -o /usr/local/bin/proot && \
    chmod 755 /usr/local/bin/proot

# Create non-root user
RUN adduser -D -h /home/container -s /bin/sh container

USER container
ENV USER=container
ENV HOME=/home/container

WORKDIR /home/container

# Copy scripts
COPY --chown=container:container ./scripts/entrypoint.sh /entrypoint.sh
COPY --chown=container:container ./scripts/install.sh /install.sh
COPY --chown=container:container ./scripts/helper.sh /helper.sh
COPY --chown=container:container ./scripts/run.sh /run.sh
COPY --chown=container:container ./scripts/common.sh /common.sh
COPY --chown=container:container ./scripts/firewall.sh /firewall.sh

RUN chmod +x /entrypoint.sh /install.sh /helper.sh /run.sh /common.sh /firewall.sh

CMD ["/bin/sh", "/entrypoint.sh"]
