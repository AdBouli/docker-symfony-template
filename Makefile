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
.PHONY        : build fast_build up down ls ps top log \
				app_sh app_root_sh app_exec db_sh db_exec db_log db_backup db_restore \
				sf_init sf_start sf_stop sf_logs sf_dump sf_to_dev sf_to_prod sf_db_cfg sf_db_migrate sf_bs_sass_cfg sf_test \
				sf_sass_build sf_sass_watch sf_dbg_router sf_controller sf_entity sf_compile_assets sf_dbg_assets
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

build:	## Construit les images des services [srv='...']
	@$(eval srv ?=)
	@$(DC) build --pull --no-cache $(srv)

fast_build:	## Construit les images des services [srv='...'] (rapidement) 
	@$(eval srv ?=)
	@$(DC) build $(srv)

up: ## Lance les services [srv='...']
	@$(eval srv ?=)
	@$(DC) up --detach  $(srv)

down: ## Arrête les services [srv='...']
	@$(eval srv ?=)
	@$(DC) down --remove-orphans  $(srv)

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
	@$(SYMFONY) new $(PROJECT_NAME) --webapp --version="6.4.*" --php="${APP_PHP_VERSION}" --no-git --dir="."

sf_start: ## Lance le serveur web local de Symfony
	@$(SYMFONY) server:start --daemon --no-tls --port="$(APP_PORT_NUMBER)" \
	&& echo "\n\033[1;3;35m-> Accessible localement via : \
	http://$$(hostname -I | cut -f1 -d ' '):$(LOCAL_APP_PORT_NUMBER)\033[0m\n"

sf_stop: ## Arrête le serveur web local de Symfony
	@$(SYMFONY) server:stop

sf_logs: ## Affiche le flux des logs du serveur web local de Symfony
	@$(SYMFONY) server:log

sf_dump: ## Affiche le flux de debug du serveur web local de Symfony
	@$(CONSOLE) server:dump

sf_to_dev: ## Configure Symfony en environnement de développement
	@$(APP_CONT) sed --in-place 's/^APP_ENV=prod/APP_ENV=dev/' .env

sf_to_prod: ## Configure Symfony en environnement de production
	@$(APP_CONT) sed --in-place 's/^APP_ENV=dev/APP_ENV=prod/' .env

sf_db_cfg: ## Configure Symfony pour l'accès à la base de données de l'application
	@$(APP_CONT) sed --in-place 's~^DATABASE_URL=.*~# &\
	DATABASE_URL=\"mysql://$(DB_USERNAME):$(DB_USER_PASSWD)@$(DB_HOSTNAME):$(DB_PORT_NUMBER)/$(DB_DATABASE_NAME)'\
	'?serverVersion=$(DB_MARIADB_VERSION)-MariaDB\&charset=$(DB_MARIADB_CHARSET)\"~' .env

sf_db_migrate: ## Créer et effectue une migration de la dase de données
	@$(CONSOLE) make:migration
	@$(CONSOLE) doctrine:migrations:migrate

sf_bs_sass_cfg: ## Installe et configure Sass avec Boostrap CSS à l'application
	@$(COMPOSER) require symfonycasts/sass-bundle:^0.7 twbs/bootstrap:^5.3 symfony/ux-icons symfony/ux-twig-component
	@$(APP_CONT) bash -c "echo '@import \"bootstrap-custom\";' > assets/styles/app.scss"
	@cp ./res/scss/* ./app/assets/styles/
	@$(APP_CONT) sed --in-place '/block stylesheets/a \ \ \ \ \ \ \ \ \ \ \ \ '\
	'<link rel="stylesheet" href="{{ asset('"'"'styles/app.scss'"'"') }}">' templates/base.html.twig
	@$(CONSOLE) sass:build

sf_test: ## Créer une page de test [ctrl='nom']
	@$(eval ctrl ?= test)
	@$(CONSOLE) make:controller $(ctrl)
	@cp --force ./res/scss/* ./app/assets/styles/
	@cp --force ./res/html/base.html.twig ./app/templates/base.html.twig
	@cp --force ./res/html/index.html.twig ./app/templates/$(ctrl)/index.html.twig
	@$(CONSOLE) sass:build
	@echo "\n\033[1;3;35m-> Accessible localement via : \
	http://$$(hostname -I | cut -f1 -d ' '):$(LOCAL_APP_PORT_NUMBER)/$(ctrl)\033[0m\n"

sf_sass_build: ## Construit les assets Sass
	@$(CONSOLE) sass:build

sf_sass_watch: ## Construit automatiquement les assets Sass à chaque changement
	@$(CONSOLE) sass:build --watch --verbose

sf_dbg_router: ## Affiche les routes de l'application
	@$(CONSOLE) debug:router --env=prod

sf_controller: ## Génère un nouveau contrôleur Symfony [ctrl='...']
	@$(eval ctrl ?= )
	@$(CONSOLE) make:controller $(ctrl)

sf_entity: ## Créer ou modifie une entité Symfony [ent='...']
	@$(eval ent ?= )
	@$(CONSOLE) make:entity $(ent)

sf_compile_assets: ## Compile les assets pour la mise en production
	@$(CONSOLE) sass:build
	@$(CONSOLE) asset-map:compile

sf_dbg_assets: ## Affiche les assets de l'application
	@$(CONSOLE) debug:asset-map

## 
