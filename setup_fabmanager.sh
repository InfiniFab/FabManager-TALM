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
  echo "Création de la base de données MariaDB..."
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
  git clone --depth 1 https://github.com/InfiniFab/FabManager-TALM.git
else
  echo "Le dépôt FabManager-TALM existe déjà. Étape ignorée."
fi

# Copie des fichiers du projet dans le répertoire Node-RED (remplace les fichiers existants)
echo "Copie des fichiers du projet dans le répertoire Node-RED..."
rsync -av FabManager-TALM/ ~/.node-red/

# Copie forcée des fichiers de flows Node-RED
cp -f FabManager-TALM/flows*.json ~/.node-red/

# Copie du fichier credentials s’il existe
if [ -f FabManager-TALM/flows_cred.json ]; then
  cp -f FabManager-TALM/flows_cred.json ~/.node-red/
fi

# Copie du fichier settings.js et package.json s’ils existent
cp -f FabManager-TALM/settings.js ~/.node-red/ 2>/dev/null || true
cp -f FabManager-TALM/package.json ~/.node-red/ 2>/dev/null || true

echo "Installation des dépendances Node.js du projet..."
cd ~/.node-red
# Utiliser npm ci si un package-lock.json est présent pour garantir la cohérence des versions
if [ -f package-lock.json ]; then
  echo "package-lock.json trouvé, exécution de 'npm ci' pour installer les dépendances verrouillées..."
  npm ci
else
  echo "package-lock.json non trouvé, exécution de 'npm install'..."
  npm install
fi

echo "Redémarrage de Node-RED pour appliquer les modifications..."
# Redémarrage via systemctl pour plus de fiabilité
sudo systemctl restart nodered.service

echo "Installation terminée avec succès !"
echo "Accédez à l'éditeur Node-RED via : http://<adresse_IP_du_Raspberry_Pi>:1880"
echo "Accédez au tableau de bord via : http://<adresse_IP_du_Raspberry_Pi>:1880/ui"
