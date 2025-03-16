#!/bin/bash


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
 
#changement de repertoire pour acceder au fichiers
cd /home/ec2-user/licence

#installer les dependance npm
sudo npm install

#demarrer le serveur de licence

nohup node index.js &