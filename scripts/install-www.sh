#!/bin/bash

#usage apiendp apiport domainnme
set -eux  # Arrête l'exécution en cas d'erreur et affiche chaque commande exécutée

# Récupération des paramètres CloudFormation (passés comme arguments supplémentaires)
STACK_NAME=${4:-""}
RESOURCE_NAME=${5:-""}
REGION=${6:-"us-east-1"}

# Mettre à jour les paquets du système
sudo yum update -y

# Installer les paquets nécessaires
sudo yum install -y nginx git aws-cfn-bootstrap

# Définir les variables
DOMAIN_NAME=$3
WEB_ROOT="/var/www/html"

# Supprimer l'ancienne version si elle existe
cd /home/ec2-user
rm -rf ind250-MenuGraphique

# Cloner le code source depuis GitHub
git clone https://github.com/mathieu55/ind250-MenuGraphique.git
if [ $? -ne 0 ]; then
    echo "Erreur : échec du clonage du dépôt GitHub"
    # Signaler l'échec à CloudFormation si les paramètres sont fournis
    if [ -n "$STACK_NAME" ] && [ -n "$RESOURCE_NAME" ]; then
        /opt/aws/bin/cfn-signal -e 1 --stack "$STACK_NAME" --resource "$RESOURCE_NAME" --region "$REGION"
    fi
    exit 1
fi

if [ ! -d "$WEB_ROOT" ]; then
    sudo mkdir -p $WEB_ROOT
    #sudo chown -R nginx:nginx /var/www/html
    #sudo chmod -R 755 /var/www/html
fi


# Copier le site web dans le dossier web de NGINX
sudo rm -rf $WEB_ROOT/*
sudo cp -r ind250-MenuGraphique/* $WEB_ROOT/
sudo chown -R nginx:nginx $WEB_ROOT
sudo chmod -R 755 $WEB_ROOT

# Modifier config.js pour pointer vers l'API de l'équipe
sudo sed -i "s|http://localhost:8080|http://$1:$2|g" $WEB_ROOT/js/config.js

# Écrire le fichier de configuration NGINX
sudo tee /etc/nginx/conf.d/menugraphique.conf > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    root $WEB_ROOT;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# Vérifier la configuration NGINX avant de redémarrer
sudo nginx -t
if [ $? -ne 0 ]; then
    echo "Erreur : configuration NGINX invalide"
    # Signaler l'échec à CloudFormation si les paramètres sont fournis
    if [ -n "$STACK_NAME" ] && [ -n "$RESOURCE_NAME" ]: then
        /opt/aws/bin/cfn-signal -e 1 --stack "$STACK_NAME" --resource "$RESOURCE_NAME" --region "$REGION"
    fi
    exit 1
fi

# Activer et démarrer NGINX
sudo systemctl enable nginx
sudo systemctl restart nginx

echo "Installation terminée avec succès"

# Signaler le succès à CloudFormation si les paramètres sont fournis
if [ -n "$STACK_NAME" ] && [ -n "$RESOURCE_NAME" ]; then
    /opt/aws/bin/cfn-signal -e 0 --stack "$STACK_NAME" --resource "$RESOURCE_NAME" --region "$REGION"
fi