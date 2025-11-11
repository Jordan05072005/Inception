#!/bin/bash
set -euo pipefail

WP_PATH="/var/www/html"

# Variables depuis .env
DB_HOST=${WORDPRESS_DB_HOST}
DB_NAME=${WORDPRESS_DB_NAME}
DB_USER=${WORDPRESS_DB_USER}
DB_PASSWORD=${WORDPRESS_DB_PASSWORD}

ADMIN_USER=${WORDPRESS_ADMIN_USER}
ADMIN_PASS=${WORDPRESS_ADMIN_PASSWORD}
ADMIN_EMAIL=${WORDPRESS_ADMIN_EMAIL}
WP_TITLE=${WORDPRESS_TITLE}

SECOND_USER=${WORDPRESS_USER}
SECOND_USER_PASS=${WORDPRESS_PASSWORD}
SECOND_USER_EMAIL=${WORDPRESS_EMAIL}
SECOND_USER_ROLE=${WORDPRESS_ROLE}

if echo "$ADMIN_USER" | grep -iqE 'admin|administrator|Admin'; then
    echo "❌ Nom d'administrateur interdit : '$ADMIN_USER'. Le script s'arrête."
    exit 1
fi

# Crée le dossier php-fpm runtime
mkdir -p /run/php
chown -R www-data:www-data /run/php

# Attente que la base soit disponible
until mysqladmin ping -h "$DB_HOST" -u"$DB_USER" -p"$DB_PASSWORD" --silent; do
    echo "⏳ Waiting for database..."
    sleep 2
done

echo "⚡ Base prête !"

# Vérifie si WordPress est déjà installé
if ! wp core is-installed --allow-root --path="$WP_PATH"; then
    echo "🪄 Installation de WordPress..."

    wp core download --allow-root --path="$WP_PATH"

    wp config create --allow-root \
        --dbname="$DB_NAME" \
        --dbuser="$DB_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost="$DB_HOST" \
        --path="$WP_PATH"

    wp core install --allow-root \
        --url="https://localhost" \
        --title="$WP_TITLE" \
        --admin_user="$ADMIN_USER" \
        --admin_password="$ADMIN_PASS" \
        --admin_email="$ADMIN_EMAIL" \
        --path="$WP_PATH"

    # Crée un deuxième utilisateur si défini
    if [ -n "$SECOND_USER" ] && [ -n "$SECOND_USER_PASS" ]; then
        wp user create --allow-root \
            "$SECOND_USER" "$SECOND_USER_EMAIL" \
            --role="$SECOND_USER_ROLE" \
            --user_pass="$SECOND_USER_PASS" \
            --path="$WP_PATH"
    fi

    echo "🎉 WordPress installé !"
else
    echo "✅ WordPress déjà installé, rien à faire."
fi

chown -R www-data:www-data "$WP_PATH"
find "$WP_PATH" -type d -exec chmod 755 {} \;
find "$WP_PATH" -type f -exec chmod 644 {} \;

# Lancer php-fpm
echo "🚀 Lancement de PHP-FPM..."
exec php-fpm7.4 -F -R
