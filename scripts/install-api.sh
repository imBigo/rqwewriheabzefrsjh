#!/bin/bash
# usage install-api.sh webserverport cryptoserver cryptoserverport licence DBHost DBPort DBUser DBPass
# 1. Mise à jour du système
sudo yum update -y

# 2. Installer Git, Java JDK 21
sudo yum install -y git java-21-amazon-corretto

# 3. Cloner le dépôt du service web
cd /home/ec2-user
rm -rf service-web
git clone https://github.com/mathieu55/ind250-Artifact service-web

# 4. Déplacer les fichiers nécessaires
cd /home/ec2-user/service-web/WebServer

JAR_FILE=$(ls WebServer-*.jar 2>/dev/null | head -n 1)
if [ -z "$JAR_FILE" ]; then
    echo "Erreur : Aucun fichier JAR trouvé dans WebServer."
    exit 1
fi

# 5. Configurer les variables d'environnement et exécuter l'application
export WEBSERVER_PORT=$1
export WEBSERVER_CRYPTOPROTOCOL=http
export WEBSERVER_CRYPTOSERVER=$2
export WEBSERVER_CRYPTOSERVERPORT=$3
export WEBSERVER_CRYPTOLICENCE=$4

export WEBSERVER_DBHOST=$5
export WEBSERVER_DBPORT=$6
export WEBSERVER_DBUSER=$7
export WEBSERVER_DBPASS=$8  # Remplace par le bon mot de passe


nohup java -jar "$JAR_FILE" &