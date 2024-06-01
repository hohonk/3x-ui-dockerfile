# Используйте официальный образ Docker
FROM ghcr.io/mhsanaei/3x-ui:latest

# Установите рабочую директорию в /app
WORKDIR /app

# Копируйте текущий каталог в рабочую директорию /app внутри контейнера
COPY . .

# Установите переменные среды
ENV XRAY_VMESS_AEAD_FORCED=false

# Смонтируйте папки
VOLUME [ "/etc/x-ui/", "/root/cert/" ]

# Запустите приложение при запуске контейнера
CMD ["docker", "run", "-itd", "--network=host", "--restart=unless-stopped", "--name", "3x-ui"]

EXPOSE 3478
