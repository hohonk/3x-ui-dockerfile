FROM golang:1.22-alpine AS builder
WORKDIR /app
ARG TARGETARCH

RUN apk --no-cache --update add \
  build-base \
  gcc \
  wget \
  unzip

COPY . .

ENV CGO_ENABLED=1
ENV CGO_CFLAGS="-D_LARGEFILE64_SOURCE"
RUN go build -o build/x-ui main.go

# Заменяем вызов скрипта DockerInit.sh на его содержимое
RUN case $TARGETARCH in \
    amd64) \
        ARCH="64" \
        FNAME="amd64" \
        ;; \
    i386) \
        ARCH="32" \
        FNAME="i386" \
        ;; \
    armv8 | arm64 | aarch64) \
        ARCH="arm64-v8a" \
        FNAME="arm64" \
        ;; \
    armv7 | arm | arm32) \
        ARCH="arm32-v7a" \
        FNAME="arm32" \
        ;; \
    armv6) \
        ARCH="arm32-v6" \
        FNAME="armv6" \
        ;; \
    *) \
        ARCH="64" \
        FNAME="amd64" \
        ;; \
    esac && \
    mkdir -p build/bin && \
    cd build/bin && \
    wget "https://github.com/XTLS/Xray-core/releases/download/v1.8.13/Xray-linux-${ARCH}.zip" && \
    unzip "Xray-linux-${ARCH}.zip" && \
    rm -f "Xray-linux-${ARCH}.zip" geoip.dat geosite.dat && \
    mv xray "xray-linux-${FNAME}" && \
    wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat && \
    wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat && \
    wget -O geoip_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geoip.dat && \
    wget -O geosite_IR.dat https://github.com/chocolate4u/Iran-v2ray-rules/releases/latest/download/geosite.dat && \
    wget -O geoip_VN.dat https://github.com/vuong2023/vn-v2ray-rules/releases/latest/download/geoip.dat && \
    wget -O geosite_VN.dat https://github.com/vuong2023/vn-v2ray-rules/releases/latest/download/geosite.dat && \
    cd ../../

# ========================================================
# Stage: Final Image of 3x-ui
# ========================================================
FROM alpine
ENV TZ=Asia/Tehran
WORKDIR /app

RUN apk add --no-cache --update \
  ca-certificates \
  tzdata \
  fail2ban \
  bash

COPY --from=builder /app/build/ /app/
COPY --from=builder /app/DockerEntrypoint.sh /app/
COPY --from=builder /app/x-ui.sh /usr/bin/x-ui

# Configure fail2ban
RUN rm -f /etc/fail2ban/jail.d/alpine-ssh.conf \
  && cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local \
  && sed -i "s/^\[ssh\]$/&\nenabled = false/" /etc/fail2ban/jail.local \
  && sed -i "s/^\[sshd\]$/&\nenabled = false/" /etc/fail2ban/jail.local \
  && sed -i "s/#allowipv6 = auto/allowipv6 = auto/g" /etc/fail2ban/fail2ban.conf

RUN chmod +x \
  /app/DockerEntrypoint.sh \
  /app/x-ui \
  /usr/bin/x-ui

VOLUME [ "/etc/x-ui" ]
CMD [ "./x-ui" ]
ENTRYPOINT [ "/app/DockerEntrypoint.sh" ]

EXPOSE 8080
