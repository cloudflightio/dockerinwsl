FROM docker.io/library/alpine:3.17.2 as gvisor-tap-vsock

ARG GVISOR_TAP_VSOCK_VERSION=0.6.1
ARG GVISOR_TAP_VSOCK_VM_HASH=685e03788fb095a5296ff1d76358fd37144e1beae5c00e868da66379de53e4c8
ARG GVISOR_TAP_VSOCK_GVPROXY_HASH=abc58745468c655d2ea6ddf0b2bb825dfcdd02f4163464d8517de025b2e2aa41

WORKDIR /app/bin
RUN wget -q https://github.com/containers/gvisor-tap-vsock/releases/download/v${GVISOR_TAP_VSOCK_VERSION}/gvproxy-windows.exe && \
    wget -q https://github.com/containers/gvisor-tap-vsock/releases/download/v${GVISOR_TAP_VSOCK_VERSION}/vm && \
    chmod +x ./gvproxy-windows.exe ./vm && \
    printf "%s  %s\n%s  %s\n" "${GVISOR_TAP_VSOCK_VM_HASH}" "./vm" "${GVISOR_TAP_VSOCK_GVPROXY_HASH}" "./gvproxy-windows.exe" > sum  && \
    sha256sum -c sum

FROM docker.io/library/ubuntu:22.04
LABEL maintainer="Cloudflight GmbH"

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
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /opt/driver/

COPY --from=gvisor-tap-vsock /app/bin/vm /usr/local/sbin/wsl-vm
COPY --from=gvisor-tap-vsock /app/bin/gvproxy-windows.exe /opt/driver/wsl-gvproxy.exe

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
      docker \
      startup \
      vpnkit \
      chrony \
      dnsmasq

USER docker

VOLUME ["/var/lib/docker"]
