#!/bin/bash
# Usage: install-licence.sh port

#Configurer les variables d'environnement
export IND250_SECURE_SERVER_PORT=$1

# Mettre à jour le système
sudo yum update -y

# Installer Git
sudo yum install -y git

# Installer Node.js et npm
sudo yum install -y nodejs

# cloner le repertoire
sudo git clone https://github.com/mathieu55/ind250-SecureServer.git /home/ec2-user/licence
if [ $? -ne 0 ]; then
    echo "Erreur : échec du clonage du dépôt GitHub"
    exit 1
fi

#changement de repertoire pour acceder aux fichiers
cd /home/ec2-user/licence

#installer les dependances npm
sudo npm install
if [ $? -ne 0 ]; then
    echo "Erreur : échec de l'installation des dépendances npm"
    exit 1
fi

#demarrer le serveur de licence
nohup node index.js > /home/ec2-user/licence.log 2>&1 &

# Vérifier que le service est bien démarré en attendant quelques secondes
sleep 10
if pgrep -f "node index.js" > /dev/null; then
    echo "Service de licence démarré avec succès"
else
    echo "Erreur: Le service de licence n'a pas démarré correctement"
    exit 1
fi