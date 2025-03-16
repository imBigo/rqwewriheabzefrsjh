#!/bin/bash
# usage install-api.sh webserverport cryptoserver cryptoserverport licence DBHost DBPort DBUser DBPass [stack_name resource_name region]

# Récupération des paramètres CloudFormation (passés comme arguments supplémentaires)
STACK_NAME=${9:-""}
RESOURCE_NAME=${10:-""}
REGION=${11:-"us-east-1"}

# 1. Mise à jour du système
sudo yum update -y

# 2. Installer Git, Java JDK 21, et aws-cfn-bootstrap
sudo yum install -y git java-21-amazon-corretto aws-cfn-bootstrap

# 3. Cloner le dépôt du service web
cd /home/ec2-user
rm -rf service-web
git clone https://github.com/mathieu55/ind250-Artifact service-web
if [ $? -ne 0 ]; then
    echo "Erreur : échec du clonage du dépôt GitHub"
    # Signaler l'échec à CloudFormation si les paramètres sont fournis
    if [ -n "$STACK_NAME" ] && [ -n "$RESOURCE_NAME" ]; then
        /opt/aws/bin/cfn-signal -e 1 --stack "$STACK_NAME" --resource "$RESOURCE_NAME" --region "$REGION"
    fi
    exit 1
fi

# 4. Déplacer les fichiers nécessaires
cd /home/ec2-user/service-web/WebServer

JAR_FILE=$(ls WebServer-*.jar 2>/dev/null | head -n 1)
if [ -z "$JAR_FILE" ]; then
    echo "Erreur : Aucun fichier JAR trouvé dans WebServer."
    # Signaler l'échec à CloudFormation si les paramètres sont fournis
    if [ -n "$STACK_NAME" ] && [ -n "$RESOURCE_NAME" ]; then
        /opt/aws/bin/cfn-signal -e 1 --stack "$STACK_NAME" --resource "$RESOURCE_NAME" --region "$REGION"
    fi
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

# Démarrer l'API en arrière-plan
nohup java -jar "$JAR_FILE" > /home/ec2-user/api.log 2>&1 &

# Vérifier que le service est bien démarré en attendant quelques secondes
sleep 10
if pgrep -f "$JAR_FILE" > /dev/null; then
    echo "Service API démarré avec succès"
    # Signaler le succès à CloudFormation si les paramètres sont fournis
    if [ -n "$STACK_NAME" ] && [ -n "$RESOURCE_NAME" ]; then
        /opt/aws/bin/cfn-signal -e 0 --stack "$STACK_NAME" --resource "$RESOURCE_NAME" --region "$REGION"
    fi
else
    echo "Erreur: Le service API n'a pas démarré correctement"
    # Signaler l'échec à CloudFormation si les paramètres sont fournis
    if [ -n "$STACK_NAME" ] && [ -n "$RESOURCE_NAME" ]; then
        /opt/aws/bin/cfn-signal -e 1 --stack "$STACK_NAME" --resource "$RESOURCE_NAME" --region "$REGION"
    fi
    exit 1
fi