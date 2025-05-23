#!/bin/bash

# Script d'installation de FabManager-TALM sur Raspberry Pi OS (mode Projects Git)

set -e

# Variables utilisateur Node-RED
NODE_USER="pi"
USER_HOME="/home/${NODE_USER}"
NODE_RED_DIR="${USER_HOME}/.node-red"
PROJECT_NAME="Fabmanager"
PROJECT_DIR="${NODE_RED_DIR}/projects/${PROJECT_NAME}"
REMOTE_URL="https://github.com/InfiniFab/FabManager-TALM.git"

# 1. Mise à jour du système
echo "Mise à jour du système..."
sudo apt update && sudo apt upgrade -y

# 2. Installation des dépendances
echo "Installation des dépendances nécessaires..."
sudo apt install -y build-essential git curl mariadb-server

# 3. Installation de Node.js et Node-RED
echo "Installation de Node.js, npm et Node-RED..."
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered)

# 4. Activation et démarrage automatique de Node-RED
echo "Activation et démarrage de Node-RED..."
sudo systemctl enable nodered.service
sudo systemctl start nodered.service

# 5. Configuration de MariaDB
echo "Configuration de MariaDB..."
DB_EXISTS=$(sudo mariadb -e "SHOW DATABASES LIKE 'fabmanager';" | grep fabmanager || true)
if [ -z "$DB_EXISTS" ]; then
  sudo mariadb <<EOF
CREATE DATABASE fabmanager;
CREATE USER IF NOT EXISTS 'nodered'@'localhost' IDENTIFIED BY 'nodered';
GRANT ALL PRIVILEGES ON fabmanager.* TO 'nodered'@'localhost';
FLUSH PRIVILEGES;
EOF
  echo "Base de données créée."
else
  echo "Base de données 'fabmanager' déjà existante, aucune action."
fi

# 6. Préparation du répertoire Projects de Node-RED
echo "Préparation du répertoire Projects de Node-RED..."
sudo -u ${NODE_USER} mkdir -p "${PROJECT_DIR}"

# Nettoyage de toute ancienne configuration Git à la racine userDir
echo "Nettoyage du userDir Node-RED..."
sudo -u ${NODE_USER} find "${NODE_RED_DIR}" -maxdepth 1 \( -name '*.json' -o -name 'settings.js' -o -name 'package.json' \) -exec rm -f {} +
sudo -u ${NODE_USER} rm -rf "${NODE_RED_DIR}/lib" "${NODE_RED_DIR}/node_modules"

# 7. Clonage ou mise à jour du projet Git
if [ ! -d "${PROJECT_DIR}/.git" ]; then
  echo "Clonage du projet Git dans ${PROJECT_DIR}..."
  sudo -u ${NODE_USER} git clone --depth 1 "${REMOTE_URL}" "${PROJECT_DIR}"
else
  echo "Mise à jour du projet Git..."
  cd "${PROJECT_DIR}"
  sudo -u ${NODE_USER} git pull --ff-only
fi

# 8. Synchronisation des fichiers de configuration Essentiels
echo "Synchronisation des fichiers settings.js et package.json..."
sudo -u ${NODE_USER} cp -f "${PROJECT_DIR}/settings.js" "${NODE_RED_DIR}/" 2>/dev/null || true
sudo -u ${NODE_USER} cp -f "${PROJECT_DIR}/package.json" "${NODE_RED_DIR}/" 2>/dev/null || true

# 9. Installation des dépendances Node.js du projet Git
echo "Installation des dépendances Node.js du projet..."
cd "${PROJECT_DIR}"
if [ -f package-lock.json ]; then
  sudo -u ${NODE_USER} npm ci
else
  sudo -u ${NODE_USER} npm install
fi

# 10. Redémarrage de Node-RED
echo "Redémarrage de Node-RED..."
sudo systemctl restart nodered.service

# 11. Fin
echo "Installation et configuration terminées avec succès !"
echo "Ouvre l’éditeur Node-RED (http://<IP> :1880) et sélectionne le projet '${PROJECT_NAME}' pour voir tes flows."
