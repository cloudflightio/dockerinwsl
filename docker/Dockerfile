FROM docker.io/library/ubuntu:22.04
LABEL maintainer="Cloudflight GmbH"

ARG WSL_VPNKIT_VERSION=0.3.8

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \ 
    systemd \
    systemd-sysv \
    dbus \
    rsyslog \
    socat \
    iputils-ping \
    dnsutils \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    iproute2 \
    dnsmasq \
    chrony \
    jq \
    make \
    uuid-runtime \
    net-tools \
    isc-dhcp-client \
    udhcpc \
 && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
 && echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-compose-plugin \
    docker-buildx-plugin \
 && rm -rf /var/lib/apt/lists/*

# download VPNKit binaries
RUN curl -L "https://github.com/sakai135/wsl-vpnkit/releases/download/v${WSL_VPNKIT_VERSION}/wsl-vpnkit.tar.gz" --output wsl-vpnkit.tar.gz \
 && tar --strip-components=1 -xf wsl-vpnkit.tar.gz app/wsl-vpnkit files/wsl-gvproxy.exe files/wsl-vm \
 && rm wsl-vpnkit.tar.gz \
 && mv wsl-vm /usr/local/sbin/ \
 && chmod +x /usr/local/sbin/wsl-vm \
 && chown root:root /usr/local/sbin/wsl-vm \
 && mkdir -p /opt/driver/ \
 && mv wsl-gvproxy.exe /opt/driver/

COPY root/ /

RUN mkdir -p "$HOME/.docker/cli-plugins/" \
 && ln -s /usr/local/bin/docker-compose "$HOME/.docker/cli-plugins/docker-compose" \
 && chmod +x /usr/local/bin/* \
 && chown root:root /usr/local/bin/* \
 && update-alternatives --set iptables /usr/sbin/iptables-legacy \
 && update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy \
 && sed -i 's/RESOLV_CONF=.*/RESOLV_CONF="\/etc\/resolv.conf.udhcpc"/g' /etc/udhcpc/default.script \
 && useradd -m -u 1000 -g docker -s /bin/bash docker \
 && systemctl enable \
      docker-data-mount \
      docker \
      startup \
      vpnkit \
      chrony \
      dnsmasq

USER docker

VOLUME ["/var/lib/docker"]
