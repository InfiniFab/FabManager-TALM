#!/bin/bash
set -e

# ================================
# Variables
# ================================
REPO_URL="https://github.com/InfiniFab/FabManager-TALM.git"
INSTALL_DIR="$HOME/FabManager-TALM"

# ================================
# 1) Mise à jour du système
# ================================
echo "→ Mise à jour des paquets APT..."
sudo apt-get update -y
sudo apt-get upgrade -y

# ================================
# 2) Installation des paquets de base
# ================================
echo "→ Installation de Git, Curl, build-essential et MariaDB..."
sudo apt-get install -y git curl build-essential mariadb-server

# ================================
# 3) Installation de Node.js v16 LTS
# ================================
echo "→ Installation de Node.js v16 LTS..."
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get install -y nodejs

# Vérification rapide
echo "→ Versions installées :"
node -v
npm -v

# ================================
# 4) Installation de Node-RED
# ================================
echo "→ Installation globale de Node-RED..."
sudo npm install -g --unsafe-perm node-red

# ================================
# 5) Clone ou mise à jour du dépôt
# ================================
if [ -d "$INSTALL_DIR" ]; then
  echo "→ Le répertoire existe, mise à jour du dépôt..."
  cd "$INSTALL_DIR"
  git pull origin main
else
  echo "→ Clonage du dépôt FabManager-TALM dans $INSTALL_DIR..."
  git clone "$REPO_URL" "$INSTALL_DIR"
  cd "$INSTALL_DIR"
fi

# ================================
# 6) Installation des dépendances du projet
# ================================
echo "→ Installation des modules npm du projet..."
npm install

# ================================
# 7) Résumé et fin
# ================================
echo "======================================"
echo "Installation terminée !"
echo "- Pour lancer Node-RED : node-red"
echo "- Le projet est dans : $INSTALL_DIR"
echo "======================================"
