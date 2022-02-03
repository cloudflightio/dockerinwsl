FROM ubuntu:20.04

ARG VPNKIT_VERSION=0.5.0-20211026
ARG NPIPERELAY_VERSION=0.1.0

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \ 
    socat \
    iputils-ping \
    dnsutils \
    wget \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    iproute2 \
    supervisor \
 && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
 && echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-compose \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p "/usr/share/vpnkit"

# download VPNKit binaries
ADD https://github.com/sakai135/vpnkit/releases/download/v${VPNKIT_VERSION}/vpnkit-tap-vsockd /usr/local/sbin/vpnkit-tap-vsockd
RUN chmod +x /usr/local/sbin/vpnkit-tap-vsockd && chown root:root /usr/local/sbin/vpnkit-tap-vsockd

COPY wsl-vpnkit /usr/local/bin/wsl-vpnkit 
RUN chmod +x /usr/local/bin/wsl-vpnkit && chown root:root /usr/local/bin/wsl-vpnkit

COPY defaults.conf /usr/share/vpnkit/
COPY conf.d/* /etc/supervisor/conf.d/

VOLUME ["/var/lib/docker"]
