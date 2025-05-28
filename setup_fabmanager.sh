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

# 5. Configuration de MariaDB avec import du dump initial
echo "Configuration de MariaDB et import des tables..."
DB_EXISTS=$(sudo mariadb -e "SHOW DATABASES LIKE 'fabmanager';" | grep fabmanager || true)
if [ -z "$DB_EXISTS" ]; then
  sudo mariadb <<EOF
CREATE DATABASE fabmanager;
CREATE USER IF NOT EXISTS 'nodered'@'localhost' IDENTIFIED BY 'nodered';
GRANT ALL PRIVILEGES ON fabmanager.* TO 'nodered'@'localhost';
FLUSH PRIVILEGES;
USE fabmanager;

-- Désactivation temporaire des contraintes de clef étrangère
SET FOREIGN_KEY_CHECKS=0;

DROP TABLE IF EXISTS \`type\`;
CREATE TABLE \`type\` (
  \`id\` int(11) NOT NULL AUTO_INCREMENT,
  \`nom\` varchar(255) NOT NULL,
  PRIMARY KEY (\`id\`),
  UNIQUE KEY \`nom\` (\`nom\`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

DROP TABLE IF EXISTS \`materiaux\`;
CREATE TABLE \`materiaux\` (
  \`id\` int(11) NOT NULL AUTO_INCREMENT,
  \`nom\` varchar(255) NOT NULL,
  \`prix\` float NOT NULL,
  \`type_id\` int(11) NOT NULL,
  PRIMARY KEY (\`id\`),
  UNIQUE KEY \`nom\` (\`nom\`),
  KEY \`fk_materiaux_type\` (\`type_id\`),
  CONSTRAINT \`fk_materiaux_type\` FOREIGN KEY (\`type_id\`) REFERENCES \`type\` (\`id\`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

DROP TABLE IF EXISTS \`usage_lab\`;
CREATE TABLE \`usage_lab\` (
  \`no\` int(11) NOT NULL AUTO_INCREMENT,
  \`date\` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  \`classe\` varchar(80) DEFAULT NULL,
  \`nom\` varchar(80) DEFAULT NULL,
  \`fabrication\` varchar(80) DEFAULT NULL,
  \`prix\` varchar(80) DEFAULT NULL,
  \`reglement\` tinyint(1) DEFAULT NULL,
  \`CAO\` tinyint(1) DEFAULT NULL,
  \`date_entr\` varchar(100) DEFAULT NULL,
  \`remarques\` varchar(100) DEFAULT NULL,
  KEY \`no\` (\`no\`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- Réactivation des contraintes
SET FOREIGN_KEY_CHECKS=1;
EOF
  echo "Import SQL initial terminé."
else
  echo "Base de données 'fabmanager' déjà existante, import SQL ignoré."
fi

# 6. Préparation du répertoire .node-red Préparation du répertoire .node-red
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
echo "Installation via npm install..."
cd "${NODE_RED_DIR}"
sudo -u ${NODE_USER} npm install


# 10. Redémarrage de Node-RED
echo "Redémarrage de Node-RED..."
sudo systemctl restart nodered.service

# 11. Fin
echo "Installation et configuration terminées avec succès !"
echo "Ouvre l’éditeur Node-RED à l’adresse : http://$(hostname -I | awk '{print $1}'):1880"
