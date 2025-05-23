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

# Création conditionnelle de la base de données et de l'utilisateur
DB_EXISTS=$(sudo mariadb -e "SHOW DATABASES LIKE 'fabmanager';" | grep fabmanager || true)
if [ -z "$DB_EXISTS" ]; then
  echo "🗄️Création de la base de données MariaDB..."
  sudo mariadb <<EOF
CREATE DATABASE fabmanager;
CREATE USER IF NOT EXISTS 'nodered'@'localhost' IDENTIFIED BY 'nodered';
GRANT ALL PRIVILEGES ON fabmanager.* TO 'nodered'@'localhost';
FLUSH PRIVILEGES;
EOF
else
  echo "La base de données 'fabmanager' existe déjà. Étape ignorée."
fi

# Clonage conditionnel du dépôt
cd ~
if [ ! -d "FabManager-TALM" ]; then
  echo "Clonage du dépôt FabManager-TALM..."
  git clone https://github.com/InfiniFab/FabManager-TALM.git
else
  echo "Le dépôt FabManager-TALM existe déjà. Étape ignorée."
fi

# Copie conditionnelle des fichiers (ne remplace pas les fichiers existants)
echo "Copie des fichiers du projet dans le répertoire Node-RED..."
rsync -av --ignore-existing FabManager-TALM/ ~/.node-red/

echo "Installation des dépendances Node.js du projet..."
cd ~/.node-red
npm install

echo "Redémarrage de Node-RED pour appliquer les modifications..."
node-red-stop
node-red-start

echo "Installation terminée avec succès !"
echo "Accédez à l'éditeur Node-RED via : http://<adresse_IP_du_Raspberry_Pi>:1880"
echo "Accédez au tableau de bord via : http://<adresse_IP_du_Raspberry_Pi>:1880/ui"
