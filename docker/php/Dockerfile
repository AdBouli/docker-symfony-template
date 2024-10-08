# @file php/Dockerfile
# @author Adrien Boulineau <adbouli@vivaldi.net>

# Variables syntaxiques
# syntax=docker/dockerfile:1
# escape=\

# Version PHP
ARG PHP_VERSION=8.3.9

# Base
FROM php:${PHP_VERSION}-fpm-bookworm

# Variables de construction
ARG USERNAME=app
ARG WORK_DIR=/app

# Métadonnées
LABEL author="Adrien Boulineau <adbouli@vivaldi.net>"
LABEL version="0.1"

# Configuration du fuseau horaire
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Installation des paquets nécessaires au fonctionnement de Symfony
COPY --from=composer /usr/bin/composer /usr/bin/composer
RUN apt-get update && apt-get -y upgrade \
    && apt-get -y install libicu-dev apt-transport-https gnupg libzip-dev zip\
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl \
    && docker-php-ext-configure opcache \
    && docker-php-ext-install opcache \
    && docker-php-ext-configure zip \
    && docker-php-ext-install zip \
    && docker-php-ext-configure mysqli \
    && docker-php-ext-install mysqli \
    && docker-php-ext-configure pdo \
    && docker-php-ext-install pdo \
    && docker-php-ext-configure pdo_mysql \
    && docker-php-ext-install pdo_mysql \
    && pecl install apcu-5.1.23 \
    && docker-php-ext-enable apcu \
    && pecl install xdebug-3.3.2 \
    && docker-php-ext-enable xdebug \
    && echo 'xdebug.mode = debug' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo 'xdebug.client_host = host.docker.internal' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo 'short_open_tag = Off' > /usr/local/etc/php/conf.d/php-short-open-tag-off.ini \
    && curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash \
    && apt-get -y install symfony-cli \
    # && apt-get -y install nodejs npm \
    && apt-get clean

# Configuration utilisateur, groupe et répertoire
RUN adduser --disabled-login --comment ${USERNAME} --shell /bin/bash ${USERNAME} \
    && mkdir --parents ${WORK_DIR} \
    && chown -R ${USERNAME}:${USERNAME} ${WORK_DIR}

# Utilisateur par défaut
USER ${USERNAME}:${USERNAME}

# Répertoire de travail par défaut
WORKDIR ${WORK_DIR}
