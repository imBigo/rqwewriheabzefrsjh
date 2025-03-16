#!/bin/bash
# Usage: install-licence.sh port [stack_name resource_name region]

# Récupération des paramètres CloudFormation (passés comme arguments supplémentaires)
STACK_NAME=${2:-""}
RESOURCE_NAME=${3:-""}
REGION=${4:-"us-east-1"}

#Configurer les variables d'environnement
export IND250_SECURE_SERVER_PORT=$1

# Mettre à jour le système
sudo yum update -y

# Installer Git et aws-cfn-bootstrap
sudo yum install -y git aws-cfn-bootstrap

# Installer Node.js et npm
sudo yum install -y nodejs

# cloner le repertoire
sudo git clone https://github.com/mathieu55/ind250-SecureServer.git /home/ec2-user/licence
if [ $? -ne 0 ]; then
    echo "Erreur : échec du clonage du dépôt GitHub"
    # Signaler l'échec à CloudFormation si les paramètres sont fournis
    if [ -n "$STACK_NAME" ] && [ -n "$RESOURCE_NAME" ]; then
        /opt/aws/bin/cfn-signal -e 1 --stack "$STACK_NAME" --resource "$RESOURCE_NAME" --region "$REGION"
    fi
    exit 1
fi

#changement de repertoire pour acceder aux fichiers
cd /home/ec2-user/licence

#installer les dependances npm
sudo npm install
if [ $? -ne 0 ]; then
    echo "Erreur : échec de l'installation des dépendances npm"
    # Signaler l'échec à CloudFormation si les paramètres sont fournis
    if [ -n "$STACK_NAME" ] && [ -n "$RESOURCE_NAME" ]; then
        /opt/aws/bin/cfn-signal -e 1 --stack "$STACK_NAME" --resource "$RESOURCE_NAME" --region "$REGION"
    fi
    exit 1
fi

#demarrer le serveur de licence
nohup node index.js > /home/ec2-user/licence.log 2>&1 &

# Vérifier que le service est bien démarré en attendant quelques secondes
sleep 10
if pgrep -f "node index.js" > /dev/null; then
    echo "Service de licence démarré avec succès"
    # Signaler le succès à CloudFormation si les paramètres sont fournis
    if [ -n "$STACK_NAME" ] && [ -n "$RESOURCE_NAME" ]; then
        /opt/aws/bin/cfn-signal -e 0 --stack "$STACK_NAME" --resource "$RESOURCE_NAME" --region "$REGION"
    fi
else
    echo "Erreur: Le service de licence n'a pas démarré correctement"
    # Signaler l'échec à CloudFormation si les paramètres sont fournis
    if [ -n "$STACK_NAME" ] && [ -n "$RESOURCE_NAME" ]; then
        /opt/aws/bin/cfn-signal -e 1 --stack "$STACK_NAME" --resource "$RESOURCE_NAME" --region "$REGION"
    fi
    exit 1
fi