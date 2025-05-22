#!/bin/bash
set -e

# =============================================================================
# Variables
# =============================================================================
REPO_URL="https://github.com/InfiniFab/FabManager-TALM.git"
INSTALL_DIR="$HOME/FabManager-TALM"

# =============================================================================
# 1) Mise à jour du système via APT
# =============================================================================
echo "→ Mise à jour des paquets APT..."
sudo apt-get update -y
sudo apt-get upgrade -y

# =============================================================================
# 2) Installation des paquets de base
# =============================================================================
echo "→ Installation de Git, Curl, build-essential et MariaDB..."
sudo apt-get install -y git curl build-essential mariadb-server

# =============================================================================
# 3) Installation de Node-RED (avec la bonne version de Node.js)
# =============================================================================
echo "→ Installation de Node-RED et Node.js adaptés à l'architecture..."
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered) --confirm-root

# =============================================================================
# 4) Clone ou mise à jour du dépôt FabManager-TALM
# =============================================================================
if [ -d "$INSTALL_DIR" ]; then
  echo "→ Le répertoire existe, mise à jour du dépôt..."
  cd "$INSTALL_DIR"
  git pull origin main
else
  echo "→ Clonage du dépôt FabManager-TALM dans $INSTALL_DIR..."
  git clone "$REPO_URL" "$INSTALL_DIR"
  cd "$INSTALL_DIR"
fi

# =============================================================================
# 5) Installation des dépendances npm du projet
# =============================================================================
echo "→ Installation des modules npm du projet..."
npm install

# =============================================================================
# 6) Résumé et fin
# =============================================================================
echo "======================================"
echo "Installation terminée !"
echo "- Lancez Node-RED avec : node-red"
echo "- Le projet est disponible dans : $INSTALL_DIR"
echo "======================================"
