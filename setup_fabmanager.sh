#!/bin/bash

# Script d'installation de FabManager-TALM sur Raspberry Pi OS (mode local sans Git remote, sans mode Projects)

set -e

# Variables utilisateur Node-RED
NODE_USER="pi"
USER_HOME="/home/${NODE_USER}"
NODE_RED_DIR="${USER_HOME}/.node-red"

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

# 6. Préparation du répertoire .node-red
echo "Préparation du répertoire .node-red..."
sudo -u ${NODE_USER} mkdir -p "${NODE_RED_DIR}"

# 7. Copie des fichiers depuis le répertoire courant vers .node-red
echo "Copie des fichiers locaux vers ${NODE_RED_DIR}..."
sudo -u ${NODE_USER} cp -r ./ "${NODE_RED_DIR}/"

# 8. Nettoyage éventuel de node_modules avant installation
echo "Nettoyage de l'environnement précédent (si présent)..."
sudo -u ${NODE_USER} rm -rf "${NODE_RED_DIR}/node_modules"

# 8bis. Désactivation du mode projets dans settings.js
echo "Désactivation du mode projets dans settings.js..."
SETTINGS_FILE="${NODE_RED_DIR}/settings.js"
if [ ! -f "${SETTINGS_FILE}" ] && [ -f "${SETTINGS_FILE}.example" ]; then
  sudo -u ${NODE_USER} cp "${SETTINGS_FILE}.example" "${SETTINGS_FILE}"
fi
sudo -u ${NODE_USER} sed -i "s/^.*projects.*enabled.*:.*true.*/    projects: { enabled: false },/" "${SETTINGS_FILE}"

# 9. Installation des dépendances Node.js du projet
if [ -f "${NODE_RED_DIR}/package-lock.json" ]; then
  echo "Installation via npm ci..."
  cd "${NODE_RED_DIR}"
  sudo -u ${NODE_USER} npm ci
else
  echo "Installation via npm install..."
  cd "${NODE_RED_DIR}"
  sudo -u ${NODE_USER} npm install
fi

# 10. Redémarrage de Node-RED
echo "Redémarrage de Node-RED..."
sudo systemctl restart nodered.service

# 11. Fin
echo "Installation et configuration terminées avec succès !"
echo "Ouvre l’éditeur Node-RED à l’adresse : http://$(hostname -I | awk '{print $1}'):1880"
