# Этап сборки: используйте образ Golang для компиляции приложения
FROM golang:1.22-alpine AS builder
WORKDIR /app
ARG TARGETARCH

# Установите необходимые пакеты
RUN apk --no-cache --update add build-base gcc wget unzip

# Копируйте исходный код приложения
COPY . .

# Установите переменные среды для сборки
ENV CGO_ENABLED=1
ENV CGO_CFLAGS="-D_LARGEFILE64_SOURCE"

# Соберите приложение
RUN go build -o build/x-ui main.go
RUN ./DockerInit.sh "$TARGETARCH"

# Финальный этап: создайте легкий образ с Alpine
FROM alpine
ENV TZ=Asia/Tehran
WORKDIR /app

# Установите необходимые пакеты
RUN apk add --no-cache --update ca-certificates tzdata fail2ban bash

# Скопируйте собранные файлы из этапа сборки
COPY --from=builder /app/build/ /app/
COPY --from=builder /app/DockerEntrypoint.sh /app/
COPY --from=builder /app/x-ui.sh /usr/bin/x-ui

# Настройте fail2ban
RUN rm -f /etc/fail2ban/jail.d/alpine-ssh.conf \
  && cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local \
  && sed -i "s/^\[ssh\]$/&\nenabled = false/" /etc/fail2ban/jail.local \
  && sed -i "s/^\[sshd\]$/&\nenabled = false/" /etc/fail2ban/jail.local \
  && sed -i "s/#allowipv6 = auto/allowipv6 = auto/g" /etc/fail2ban/fail2ban.conf

# Дайте права на выполнение скриптам
RUN chmod +x /app/DockerEntrypoint.sh /app/x-ui /usr/bin/x-ui

# Определите тома для конфигурации
VOLUME [ "/etc/x-ui" ]

# Установите точку входа и команду запуска
ENTRYPOINT [ "/app/DockerEntrypoint.sh" ]
CMD [ "./x-ui" ]

EXPOSE 2053
