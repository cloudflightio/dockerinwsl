FROM docker:20.10.12-dind

ARG VPNKIT_VERSION=0.5.0-20211026
ARG NPIPERELAY_VERSION=0.1.0

RUN apk add --no-cache \ 
    docker-compose \
    socat \
    p7zip \
    wget \
    curl \
 && chmod +x /usr/local/bin/docker-*

RUN mkdir -p "/files/vpnkit" "/files/npiperelay"

# download VPNKit binaries
ADD https://github.com/sakai135/vpnkit/releases/download/v${VPNKIT_VERSION}/vpnkit-tap-vsockd /usr/local/sbin/vpnkit-tap-vsockd
RUN chmod +x /usr/local/sbin/vpnkit-tap-vsockd && chown root:root /usr/local/sbin/vpnkit-tap-vsockd

COPY wsl-vpnkit /usr/local/bin/wsl-vpnkit 
RUN chmod +x /usr/local/bin/wsl-vpnkit && chown root:root /usr/local/bin/wsl-vpnkit

ADD https://github.com/sakai135/vpnkit/releases/download/v${VPNKIT_VERSION}/vpnkit.exe /files/vpnkit/vpnkit.exe

# download npiperelay
RUN wget https://github.com/jstarks/npiperelay/releases/download/v${NPIPERELAY_VERSION}/npiperelay_windows_amd64.zip \
 && 7z e npiperelay_windows_amd64.zip npiperelay.exe \
 && rm npiperelay_windows_amd64.zip \
 && mv npiperelay.exe "/files/npiperelay/"

COPY defaults.conf /files/
