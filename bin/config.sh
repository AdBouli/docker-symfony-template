#!/bin/bash

# @file config.sh
# @author Adrien Boulineau <adbouli@vivaldi.net>

# Nom des fichiers d'environnement
default_env_file=".env"
local_env_file=".env.local"

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

touch $local_env_file

echo -e "\nConfiguration du fichier $local_env_file.\n"
echo -e "Faites <entrer> pour garder la valeur entre crochet.\n"

{
    # Boucle pour chaque variable à configurer
    for ((i=0; i<${#variables[@]}; i+=2)); do
        var="${variables[$i]}"
        prompt="${variables[$((i+1))]}"

        # Si la variable existe déjà dans le fichier .env, on utilise sa valeur comme valeur par défaut
        if grep -q "^$var=" "$local_env_file"; then
            default=$(grep --only-matching --perl-regexp "^$var=\K.*" "$local_env_file")
            value=$(prompt_for_value "$prompt" "$default")

            # Puis on remplace sa valeur si elle a été changée
            if [[ "$value" != "$default" ]]; then
                sed --in-place "s/^$var=.*/$var=$value/g" "$local_env_file"
            fi

        # Sinon, on cherche la valeur par défaut dans le fichier de configuration par défaut
        else
            default=$(grep --only-matching --perl-regexp "^$var=\K.*" "$default_env_file")
            value=$(prompt_for_value "$prompt" "$default")
            # Puis on l'ajoute à la fin du fichier
            echo "$var=$value" >> "$local_env_file"
        fi
    done

} || {
    echo -e "\n\033[0;31mUne erreur est survenue pendant la configuration du fichier $local_env_file.\033[0m\n"
    exit 1
}

echo -e "\n\033[0;32mLe fichier $local_env_file a été configuré avec succès.\033[0m\n"
