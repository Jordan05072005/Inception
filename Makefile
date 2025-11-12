DATA_DIR = /home/jguaglio/data
WP_DATA = $(DATA_DIR)/wordpress_volume
DB_DATA = $(DATA_DIR)/mariadb_volume
COMPOSE_FILE = ./srcs/docker-compose.yml

all: up

init:
	sudo systemctl start docker
setup:
	@echo "📁 Création des dossiers de volumes..."
	@sudo mkdir -p $(WP_DATA)
	@sudo mkdir -p $(DB_DATA)
	@sudo chown -R $(USER):$(USER) $(DATA_DIR)
	@echo "✅ Dossiers créés : $(DATA_DIR)"

up: setup
	echo "🚀 Démarrage des conteneurs..."
	docker compose -f $(COMPOSE_FILE) up $(if $(filter 1,$(D)),-d,)

down:
	docker compose -f $(COMPOSE_FILE) down

build: setup
	echo "🚀 Démarrage (ou rebuild) des conteneurs..."
	docker compose --env-file ./srcs/.env -f $(COMPOSE_FILE) up --build $(if $(filter 1,$(D)),-d,)

clean:
	@echo "🧹 Nettoyage complet..."
	@docker compose -f $(COMPOSE_FILE) down -v
	@sudo rm -rf $(DB_DATA)/*
	@sudo rm -rf $(WP_DATA)/*
	@docker system prune -af

re: init down up


