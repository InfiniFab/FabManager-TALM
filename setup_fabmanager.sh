#!/bin/bash
set -e

# --------------------------------
# Variables
# --------------------------------
USER=pi
HOME=/home/$USER
REPO_URL="https://github.com/InfiniFab/FabManager-TALM.git"
INSTALL_DIR="$HOME/FabManager-TALM"
NODERED_USERDIR="$HOME/.node-red"
FLOWFILE="flows_$(hostname).json"

# --------------------------------
# 1) Mise à jour du système
# --------------------------------
echo "→ Mise à jour des paquets APT..."
sudo apt-get update -y
sudo apt-get upgrade -y

# --------------------------------
# 2) Désinstallation d'anciennes versions de Node.js
# --------------------------------
echo "→ Suppression de Node.js/npm obsolètes (si présents)..."
sudo apt-get remove -y nodejs npm || true
sudo apt-get autoremove -y

# --------------------------------
# 3) Installation des dépendances système
# --------------------------------
echo "→ Installation de Git, Curl, build-essential et MariaDB..."
sudo apt-get install -y git curl build-essential mariadb-server

# --------------------------------
# 4) Installation de Node-RED (et Node.js ≥ v18)
# --------------------------------
echo "→ Installation de Node-RED (avec Node.js adapté)..."
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered) --confirm-root

# --------------------------------
# 5) Clone ou mise à jour du dépôt dans /home/pi
# --------------------------------
if [ -d "$INSTALL_DIR" ]; then
  echo "→ Mise à jour du dépôt existant ($INSTALL_DIR)..."
  cd "$INSTALL_DIR"
  git pull origin main
else
  echo "→ Clonage du dépôt dans $INSTALL_DIR..."
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

# --------------------------------
# 6) Fix des permissions
# --------------------------------
echo "→ Attribution des droits sur $INSTALL_DIR à l’utilisateur $USER..."
sudo chown -R $USER:$USER "$INSTALL_DIR"

# --------------------------------
# 7) Installation des dépendances npm du projet
# --------------------------------
echo "→ Installation des modules npm du projet..."
cd "$INSTALL_DIR"
npm install

# --------------------------------
# 8) Déploiement des flows dans Node-RED
# --------------------------------
echo "→ Déploiement des flows dans $NODERED_USERDIR/$FLOWFILE..."
# Crée le dossier userDir s’il n’existe pas
mkdir -p "$NODERED_USERDIR"
# Copie le flows.json du projet (à adapter si le fichier porte un autre nom dans votre repo)
cp "$INSTALL_DIR/flows.json" "$NODERED_USERDIR/$FLOWFILE"
# S’assure que pi possède bien ces fichiers
sudo chown $USER:$USER "$NODERED_USERDIR/$FLOWFILE"

# --------------------------------
# 9) Création d’un alias 'nred'
# --------------------------------
echo "→ Ajout de l’alias 'nred' dans le .bashrc de $USER..."
grep -qxF "alias nred='cd $INSTALL_DIR && node-red'" "$HOME/.bashrc" || \
  echo "alias nred='cd $INSTALL_DIR && node-red'" >> "$HOME/.bashrc"

# --------------------------------
# 10) Résumé et instructions finales
# --------------------------------
cat << EOF

=====================================
✔ Installation terminée !
  
• Pour entrer dans le dossier & lancer Node-RED :  
  $ nred
  
• Votre dépôt est dans : $INSTALL_DIR  
• Vos flows sont copiés dans : $NODERED_USERDIR/$FLOWFILE  
• Pour voir la version de Node.js : node -v       (doit être ≥ v18)  
• Pour voir la version de Node-RED : node-red --version

Redémarrez votre session (ou faites `source ~/.bashrc`) pour prendre en compte l’alias.
=====================================
EOF
