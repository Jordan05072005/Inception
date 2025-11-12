#!/bin/bash
set -euo pipefail

DATADIR="/var/lib/mysql"
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld
chown -R mysql:mysql "$DATADIR"

# Démarre temporairement MariaDB (mode par défaut)
mysqld_safe --datadir="$DATADIR" &
PID=$!

# Attendre que MariaDB réponde
for i in $(seq 1 60); do
  if mysqladmin ping --silent; then
    break
  fi
  sleep 1
done

if ! mysqladmin ping --silent; then
  echo "❌ MariaDB n'a pas démarré dans le délai imparti."
  tail -n 200 /var/log/mysql/error.log 2>/dev/null || true
  exit 1
fi

echo "✅ MariaDB démarré (temporaire)."

# Fonction pour exécuter un bloc SQL en essayant plusieurs méthodes d'authent
exec_sql() {
  local sql="$1"

  # 1) tenter sans mot de passe
  if mysql -u root -e "SELECT 1;" >/dev/null 2>&1; then
    mysql -u root <<EOSQL
$sql
EOSQL
    return 0
  fi

  # 2) tenter avec MYSQL_ROOT_PASSWORD (si présent)
  if [ -n "${MYSQL_ROOT_PASSWORD:-}" ] && mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;" >/dev/null 2>&1; then
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOSQL
$sql
EOSQL
    return 0
  fi

  # 3) échec : on log et on continue (ne pas planter)
  echo "⚠️  Impossible de s'authentifier en tant que root (on saute l'exécution SQL)."
  return 1
}

SQL_CMDS="
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
"

exec_sql "$SQL_CMDS" || true

# Arrêt propre du serveur temporaire
if [ -n "${MYSQL_ROOT_PASSWORD:-}" ] && mysqladmin -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown >/dev/null 2>&1; then
  echo "🛑 Serveur temporaire arrêté (auth with password)."
elif mysqladmin -uroot shutdown >/dev/null 2>&1; then
  echo "🛑 Serveur temporaire arrêté (no password)."
else
  echo "⚠️  Impossible d'arrêter proprement mysqladmin, on kill le PID $PID"
  kill "$PID" || true
  wait "$PID" || true
fi

# Lancement final
echo "🚀 Lancement final de MariaDB..."
exec mysqld --user=mysql --datadir="$DATADIR" --bind-address=0.0.0.0
