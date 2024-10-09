#!/bin/bash

# @file config.sh
# @author Adrien Boulineau <adbouli@vivaldi.net>

# Nom du fichier d'environnement
env_file=".env"

# Fonction pour demander une valeur à l'utilisateur
function prompt_for_value {
    local prompt="$1"
    local default="$2"
    read -p "$prompt [$default]: " value
    [[ -z "$value" ]] && value="$default"
    echo "$value"
}

# Liste des variables à configurer avec leurs messages personnalisés
variables=(
    "PROJECT_NAME"          "Nom du projet"
    "PROJECT_USERNAME"      "Nom d'utilisateur"
    "LOCAL_APP_PORT_NUMBER" "Port local du serveur web applicatif"
    "LOCAL_ADM_PORT_NUMBER" "Port local du serveur web phpmyadmin"
    "DB_ROOT_PASSWD"        "Mot de passe root de la base de données"
    "DB_USER_PASSWD"        "Mot de passe utilisateur de la base de données"
)

echo -e "\nConfiguration du fichier d'environnement.\n"
echo -e "Faites <entrer> pour garder la valeur entre crochet.\n"

{
    # Boucle pour chaque variable à configurer
    for ((i=0; i<${#variables[@]}; i+=2)); do

        var="${variables[$i]}"
        prompt="${variables[$((i+1))]}"

        # On utilise sa valeur actuelle comme valeur par défaut
        default=$(grep --only-matching --perl-regexp "^$var=\K.*" "$env_file")
        value=$(prompt_for_value "$prompt" "$default")

        # Puis on remplace sa valeur si elle a été changée
        if [[ "$value" != "$default" ]]; then
            sed --in-place "s/^$var=.*/$var=$value/g" "$env_file"
        fi

    done

} || {
    echo -e "\n\033[0;31mUne erreur est survenue pendant la configuration du fichier d'environnement.\033[0m\n"
    exit 1
}

echo -e "\n\033[0;32mLe fichier d'environnement a été configuré avec succès.\033[0m\n"
