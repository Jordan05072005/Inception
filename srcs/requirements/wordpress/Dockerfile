FROM debian:11.9

RUN apt update && apt install -y \
    php7.4-fpm php7.4-mysql php7.4-cli php7.4-curl php7.4-xml php7.4-mbstring \
    wget unzip mariadb-client \
    && apt install -y curl less mariadb-client \
    && apt clean && rm -rf /var/lib/apt/lists/*

# Installer wp-cli (outil de gestion WordPress en ligne de commande)
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp

# Créer dossier et utilisateur www-data
RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html

WORKDIR /var/www/html

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp

# Copier le script d’entrée
COPY ./tools/entrypoint.sh /entrypoint.sh
COPY ./tools/www.conf /etc/php/7.4/fpm/pool.d/www.conf
RUN chmod +x /entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]
