#!/bin/bash

# Script d'installation de FabManager-TALM sur Raspberry Pi OS

set -e

echo "Mise à jour du système..."
sudo apt update && sudo apt upgrade -y

echo "Installation des dépendances nécessaires..."
sudo apt install -y build-essential git curl mariadb-server

echo "Installation de Node.js, npm et Node-RED..."
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered)

echo "Activation de Node-RED au démarrage..."
sudo systemctl enable nodered.service

echo "Configuration de la base de données MariaDB..."
sudo mariadb <<EOF
CREATE DATABASE fabmanager;
CREATE USER 'nodered'@'localhost' IDENTIFIED BY 'nodered';
GRANT ALL PRIVILEGES ON fabmanager.* TO 'nodered'@'localhost';
FLUSH PRIVILEGES;
EXIT
EOF

echo "Clonage du dépôt FabManager-TALM..."
cd ~
git clone https://github.com/InfiniFab/FabManager-TALM.git

echo "Copie des fichiers du projet dans le répertoire Node-RED..."
cp -r FabManager-TALM/* ~/.node-red/

echo "Installation des dépendances Node.js du projet..."
cd ~/.node-red
npm install

echo "Redémarrage de Node-RED pour appliquer les modifications..."
node-red-stop
node-red-start

echo "Installation terminée avec succès !"
echo "Accédez à l'éditeur Node-RED via : http://<adresse_IP_du_Raspberry_Pi>:1880"
echo "Accédez au tableau de bord via : http://<adresse_IP_du_Raspberry_Pi>:1880/ui"
