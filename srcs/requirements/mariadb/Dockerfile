# srcs/requirements/mariadb/Dockerfile
FROM debian:11.9

# Installer MariaDB
RUN apt update && apt install -y mariadb-server mariadb-client \
    && apt clean && rm -rf /var/lib/apt/lists/*

# Copier script d'initialisation
COPY ./tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3306

ENTRYPOINT ["/entrypoint.sh"]
