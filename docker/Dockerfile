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
    dnsmasq \
    chrony \
    jq \
 && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
 && echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    docker-ce \
    docker-ce-cli \
    containerd.io \
 && rm -rf /var/lib/apt/lists/* \
 && curl -SL https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose \
 && chmod +x /usr/local/bin/docker-compose

# download VPNKit binaries
ADD https://github.com/sakai135/vpnkit/releases/download/v${VPNKIT_VERSION}/vpnkit-tap-vsockd /usr/local/sbin/vpnkit-tap-vsockd
RUN chmod +x /usr/local/sbin/vpnkit-tap-vsockd && chown root:root /usr/local/sbin/vpnkit-tap-vsockd

COPY root/ /

RUN mkdir -p $HOME/.docker/cli-plugins/ \
 && ln -s /usr/local/bin/docker-compose $HOME/.docker/cli-plugins/docker-compose \
 && chmod +x /usr/local/bin/* \
 && chown root:root /usr/local/bin/*

RUN useradd -m -u 1000 -g docker -s /bin/bash docker
USER docker

VOLUME ["/var/lib/docker"]
