## +----------------------------------------------+
## |                                              |
## |    ***    Makefile Docker Symfony    ***     |
## |                                              |
## +----------------------------------------------+
##
## * Adrien Boulineau <adbouli@vivaldi.net>
## 

# Généralités
.DEFAULT_GOAL = help
.PHONY        : install build full_build up down ls ps top log \
				app_sh app_exec db_sh db_exec db_log db_backup db_restore \
				sf_init sf_start sf_stop sf_logs sf_dump sf_to_dev sf_to_prod sf_db_cfg sf_db_migrate \
				sf_bs_sass_cfg sf_compile_assets sf_dbg_assets sf_dbg_router sf_controller sf_entity
ENV_FILES     = .env
-include $(ENV_FILES)

# Executables
DC        = docker-compose
APP_CONT  = $(DC) exec application_service
DB_CONT   = $(DC) exec database_service
SYMFONY   = $(APP_CONT) symfony
CONSOLE   = $(APP_CONT) php bin/console
COMPOSER  = $(APP_CONT) composer

help: ## Affiche ce message d'aide
	@grep -E '(^[a-zA-Z0-9\./_-]+:.*?##.*$$)|(^##)' $(filter-out $(ENV_FILES), $(MAKEFILE_LIST)) | \
	awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m## /[33m/'

##
## *** Général *** ------------------------------ *
##

install: build up sf_init sf_db_cfg sf_bs_sass_cfg ## Construit les images Docker, installe et configure Symfony avec Sass et Bootstrap

build:	## Construit les images des services [srv='...']
	@$(eval srv ?=)
	@$(DC) build $(srv)

full_build:	## Construit les images des services [srv='...'] (sans utiliser le cache)
	@$(eval srv ?=)
	@$(DC) build --pull --no-cache $(srv)

up: ## Lance les services [srv='...']
	@$(eval srv ?=)
	@$(DC) up --detach $(srv)

down: ## Arrête les services [srv='...']
	@$(eval srv ?=)
	@$(DC) down --remove-orphans $(srv)

ls: ## Affiche le nom des services
	@$(DC) ps --services

ps: ## Affiche le détail des services
	@$(DC) ps

top: ## Affiche les processus des services [srv='...']
	@$(eval srv ?=)
	@$(DC) top $(srv)

log: ## Affiche le flux des logs des services [srv='...']
	@$(eval srv ?=)
	@$(DC) logs --tail=0 --follow $(srv)

##
## *** Application *** -------------------------- *
##

app_sh: ## Lance un shell bash sur le serveur applicatif
	@$(APP_CONT) bash

app_exec: ## Execute la commande : cmd='...', sur le serveur applicatif
	@$(eval cmd ?= echo "commande manquante : cmd='une commande'")
	@$(APP_CONT) $(cmd)

##
## *** Base de données *** ---------------------- *
##

db_sh: ## Lance un shell bash sur le serveur de base de données
	@$(DB_CONT) bash

db_exec: ## Execute la commande : cmd='...', sur le serveur de base de données
	@$(eval cmd ?= echo "commande manquante : cmd='une commande'")
	@$(DB_CONT) $(cmd)

db_log: ## Affiche le flux des logs SQL de la base de données
	@$(DB_CONT) tail --follow /var/lib/mysql/$(DB_HOSTNAME).log

db_backup: ## Lance une sauvegarde de la base de données [tag='...']
	@$(eval tag ?= null)
	@$(eval backup_filename ?= $(PROJECT_NAME)-backup-$(shell date +"%Y%m%d-%H%M%S"))
	@$(DB_CONT) bash -c "mariadb-dump --user=$(DB_USERNAME) --password=$(DB_USER_PASSWD) \
	--add-drop-table $(DB_DATABASE_NAME) > $(DB_BACKUP_DIR)/$(backup_filename).sql"
	@if [ $(tag) != null ]; then \
		mv backup/$(backup_filename).sql backup/$(backup_filename)-$(tag).sql; \
	fi

db_restore: ## Lance une restauration de la base de données : backup=YYYYmmdd-HHMMSS
	@$(eval backup ?= "null")
	@if [ $(backup) = "null" ]; then \
		echo "\n\033[0;31mSélectionnez un backup (ex: backup=20200101-123000)\033[0m\n"; \
		echo "Backup disponibles :"; \
		$(DB_CONT) bash -c 'ls $(DB_BACKUP_DIR) | sed "s/.*backup-\(.*\).sql/ - \1/"'; \
		echo ; \
	else \
		$(eval backup_filename ?= $(PROJECT_NAME)-backup-$(backup)) \
		if [ -f backup/$(backup_filename).sql ]; then \
			$(DB_CONT) bash -c 'exec mariadb --user=$(DB_USERNAME) --password=$(DB_USER_PASSWD) \
			$(DB_DATABASE_NAME) < $(DB_BACKUP_DIR)/$(backup_filename).sql'; \
		else \
			echo "\n\033[0;31mLe backup $(backup) n'existe pas.\033[0m\n"; \
		fi \
	fi

##
## *** Symfony *** ------------------------------ *
##

sf_init: ## Initialise le projet Symfony
	@rm ./app/.gitkeep
	@$(SYMFONY) new $(PROJECT_NAME) --webapp --version="6.4.*" --php="${APP_PHP_VERSION}" --no-git --dir="."
	@touch ./app/.gitkeep

sf_start: ## Lance le serveur web local de Symfony
	@$(SYMFONY) server:start --daemon --no-tls --port="$(APP_PORT_NUMBER)"
	@echo "\n\033[1;3;35m-> Accessible localement via : \
	http://$$(hostname -I | cut -f1 -d ' '):$(LOCAL_APP_PORT_NUMBER)\033[0m\n"

sf_stop: ## Arrête le serveur web local de Symfony
	@$(SYMFONY) server:stop

sf_logs: ## Affiche le flux des logs du serveur web local de Symfony
	@$(SYMFONY) server:log

sf_dump: ## Affiche le flux de debug du serveur web local de Symfony
	@$(CONSOLE) server:dump

sf_to_dev: ## Configure Symfony en environnement de développement
	@rm -rf ./app/public/assets/
	@sed --in-place 's/^APP_ENV=prod/APP_ENV=dev/' ./app/.env

sf_to_prod: sf_compile_assets ## Configure Symfony en environnement de production
	@sed --in-place 's/^APP_ENV=dev/APP_ENV=prod/' ./app/.env

sf_db_cfg: ## Configure Symfony pour l'accès à la base de données de l'application
	@sed --in-place 's~^DATABASE_URL=.*~# &\
	DATABASE_URL=\"mysql://$(DB_USERNAME):$(DB_USER_PASSWD)@$(DB_HOSTNAME):$(DB_PORT_NUMBER)/$(DB_DATABASE_NAME)'\
	'?serverVersion=$(DB_MARIADB_VERSION)-MariaDB\&charset=$(DB_MARIADB_CHARSET)\"~' ./app/.env

sf_db_migrate: ## Créé et effectue une migration de la dase de données
	@$(CONSOLE) make:migration
	@$(CONSOLE) doctrine:migrations:migrate

sf_bs_sass_cfg: ## Installe et configure Sass avec Boostrap à l'application
	@$(SYMFONY) server:stop
	@$(CONSOLE) importmap:require bootstrap@^$(APP_BOOTSTRAP_VERSION)
	@sed --in-place "/app.css/a import\ 'bootstrap';" ./app/assets/app.js
	@$(COMPOSER) require symfonycasts/sass-bundle:^0.7 twbs/bootstrap:^$(APP_BOOTSTRAP_VERSION) \
	symfony/ux-icons symfony/ux-twig-component
	@$(CONSOLE) make:controller BootstrapTest
	@mv ./app/templates/base.html.twig ./app/templates/base.html.twig.old
	@cp --force ./resources/scss/* ./app/assets/styles/
	@cp --force ./resources/js/* ./app/assets/controllers/
	@cp --force ./resources/html/base.html.twig ./app/templates/base.html.twig
	@cp --force ./resources/html/index.html.twig ./app/templates/bootstrap_test/index.html.twig
	@cp --force ./resources/config/asset_mapper.yaml ./app/config/packages/asset_mapper.yaml
	@cp --force ./resources/config/.symfony.local.yaml ./app/
	@$(SYMFONY) server:start --daemon --no-tls --port="$(APP_PORT_NUMBER)"
	@echo "\n\033[1;3;35m-> Page de test accessible localement via : \
	http://$$(hostname -I | cut -f1 -d ' '):$(LOCAL_APP_PORT_NUMBER)/bootstrap/test\033[0m\n"

sf_compile_assets: ## Compile les assets pour la mise en production
	@$(CONSOLE) asset-map:compile

sf_dbg_assets: ## Affiche les assets de l'application
	@$(CONSOLE) debug:asset-map

sf_dbg_router: ## Affiche les routes de l'application
	@$(CONSOLE) debug:router --env=prod

sf_controller: ## Génère un nouveau contrôleur Symfony [name='...']
	@$(eval name ?= )
	@$(CONSOLE) make:controller $(name)

sf_entity: ## Créé ou modifie une entité Symfony [name='...']
	@$(eval name ?= )
	@$(CONSOLE) make:entity $(name)

## 
