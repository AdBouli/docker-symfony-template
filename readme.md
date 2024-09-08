# Modèle d'application Symfony avec Docker

## Configuration
Modifier le fichier *.env* à la racine du répertoire.

## Installation
```sh
# Constructiuon des images Docker
make build
# Initialisation des conteneurs
make up
# Initialisation du projet Symfony
make sf_init
# Configuration de Symfony à la base de données
make sf_db_cfg
# Configuration de Bootstrrap CSS et Sass dans Symfony (optionnel)
make sf_bs_sass_cfg
```

## Utilisation
```sh
# Lancement du serveur web de Symfony
make sf_start
# Création d'une page de test (optionnel)
make sf_test
```

## TODO
* db backup & restoration (physique)
* module xdebug
* prod container apache-phpfpm

## Auteurs
* Adrien Boulineau <adbouli@vivaldi.net>
  