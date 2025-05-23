#!/bin/bash

# Script d'installation de FabManager-TALM sur Raspberry Pi OS (mode Projects Git)

set -e

echo "Mise à jour du système..."
sudo apt update && sudo apt upgrade -y

echo "Installation des dépendances nécessaires..."
sudo apt install -y build-essential git curl mariadb-server

echo "Installation de Node.js, npm et Node-RED..."
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered)

echo "Activation et démarrage de Node-RED au démarrage..."
sudo systemctl enable nodered.service
sudo systemctl start nodered.service

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

# Clonage conditionnel du projet Git dans le répertoire Projects de Node-RED
PROJECT_NAME="Fabmanager"
PROJECT_DIR="$HOME/.node-red/projects/$PROJECT_NAME"
REMOTE_URL="https://github.com/InfiniFab/FabManager-TALM.git"

mkdir -p "$HOME/.node-red/projects"
if [ ! -d "$PROJECT_DIR" ]; then
  echo "Clonage du projet '$PROJECT_NAME' dans Node-RED Projects..."
  git clone --depth 1 "$REMOTE_URL" "$PROJECT_DIR"
else
  echo "Le projet '$PROJECT_NAME' existe déjà. Pull des dernières modifications..."
  cd "$PROJECT_DIR"
  git pull
fi

# Copie des fichiers de configuration (settings.js, package.json) si présents
echo "Synchronisation des fichiers de configuration..."
cp -f "$PROJECT_DIR/settings.js" "$HOME/.node-red/" 2>/dev/null || true
cp -f "$PROJECT_DIR/package.json" "$HOME/.node-red/" 2>/dev/null || true

# Installation des dépendances Node.js du projet
echo "Installation des dépendances Node.js du projet..."
cd "$PROJECT_DIR"
if [ -f package-lock.json ]; then
  npm ci
else
  npm install
fi

# Redémarrage de Node-RED pour prendre en compte le projet Git
echo "Redémarrage de Node-RED pour appliquer les changements..."
sudo systemctl restart nodered.service

echo "Installation et configuration terminées avec succès !"
echo "Ouvre l’éditeur Node-RED et sélectionne le projet '$PROJECT_NAME' pour voir les flows."
