#!/bin/bash
set -e

# dans le conteneur nginx
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html


CRT_PATH="/etc/ssl/inception/inception.crt"
KEY_PATH="/etc/ssl/inception/inception.key"
mkdir -p /etc/ssl/inception
# Vérifie si le certificat existe déjà
if [ ! -f "$CRT_PATH" ] || [ ! -f "$KEY_PATH" ]; then
    echo "🔐 Génération d'un nouveau certificat SSL..."
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "$KEY_PATH" \
        -out "$CRT_PATH" \
        -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=Inception/CN=localhost"
else
    echo "✅ Certificat SSL déjà présent."
fi

if openssl x509 -checkend 86400 -noout -in "$CRT_PATH" > /dev/null; then
    echo "🕒 Certificat encore valide."
else
    echo "⚠️  Certificat expiré — régénération..."
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "$KEY_PATH" \
        -out "$CRT_PATH" \
        -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=Inception/CN=localhost"
fi

echo "🚀 Démarrage de Nginx..."
exec nginx -g "daemon off;"

