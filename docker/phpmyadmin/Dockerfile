# PHPmyAdmin Dockerfile

# Variables syntaxiques
# syntax=docker/dockerfile:1
# escape=\

# Version PhpMyAdmin
ARG PMA_VERSION=5.2.1

# Base
FROM phpmyadmin:${PMA_VERSION}-apache

# Métadonnées
LABEL author="Adrien Boulineau <adbouli@vivaldi.net>"
LABEL version="0.1"

# Configuration du fuseau horaire
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
