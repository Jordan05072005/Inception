#!/bin/bash
set -euo pipefail

DATADIR="/var/lib/mysql"
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld
chown -R mysql:mysql "$DATADIR"


NEED_INIT=0

# Si la base n’existe pas, on initialise MariaDB
if [ ! -d "$DATADIR/mysql" ]; then
  echo "⚡ Initialisation de MariaDB..."
  mysqld --initialize-insecure --user=mysql --datadir="$DATADIR"
  NEED_INIT=1
fi

# Démarre temporairement MariaDB pour l'initialisation
mysqld_safe --datadir="$DATADIR" &
PID=$!

# Attendre que MariaDB réponde
until mysqladmin ping --silent; do
  sleep 1
done

echo "✅ MariaDB démarré, configuration des droits..."
if [ "$NEED_INIT" -eq 1 ]; then
	mysql -u root <<-EOSQL
	ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
	CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
	CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
	GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
	FLUSH PRIVILEGES;
EOSQL
fi
mysqladmin -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown
wait $PID

echo "🚀 Lancement final de MariaDB..."
exec mysqld --user=mysql --datadir="$DATADIR" --bind-address=0.0.0.0
