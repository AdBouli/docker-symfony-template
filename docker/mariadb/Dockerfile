# MariaDB Dockerfile

# Variables syntaxiques
# syntax=docker/dockerfile:1
# escape=\

# Version MariaDB
ARG MARIADB_VERSION=11.4.2

# Base
FROM mariadb:${MARIADB_VERSION}-noble

# Variables de construction
ARG BACKUP_DIR=/backup

# Métadonnées
LABEL author="Adrien Boulineau <adbouli@vivaldi.net>"
LABEL version="0.1"

# Configuration du fuseau horaire
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Construction du répertoire de sauvegarde des données
RUN mkdir --parents ${BACKUP_DIR}

# Activation des logs MariaDB
RUN echo "[mysqld]\ngeneral_log=1" > /etc/mysql/conf.d/general_log.cnf
