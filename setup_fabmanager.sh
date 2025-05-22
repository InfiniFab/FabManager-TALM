#!/bin/bash
set -e

# --------------------------------
# Variables
# --------------------------------
USER=pi
HOME_DIR="/home/$USER"
REPO_URL="https://github.com/InfiniFab/FabManager-TALM.git"
INSTALL_DIR="$HOME_DIR/FabManager-TALM"
NODERED_USERDIR="$HOME_DIR/.node-red"
FLOWFILE="flows_$(hostname).json"

# --------------------------------
# 1) Mise à jour du système
# --------------------------------
echo "→ Mise à jour des paquets APT..."
sudo apt-get update -y
sudo apt-get upgrade -y

# --------------------------------
# 2) Désinstallation de Node.js v12
# --------------------------------
echo "→ Suppression de Node.js/npm obsolètes..."
sudo apt-get remove -y nodejs npm || true
sudo apt-get autoremove -y

# --------------------------------
# 3) Installation des dépendances système
# --------------------------------
echo "→ Installation de Git, Curl, build-essential et MariaDB..."
sudo apt-get install -y git curl build-essential mariadb-server

# --------------------------------
# 4) Installation de Node-RED (+ Node.js ≥18)
# --------------------------------
echo "→ Installation de Node-RED et détection automatique de Node.js..."
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered) --confirm-root

# --------------------------------
# 5) Clonage ou mise à jour du dépôt
# --------------------------------
if [ -d "$INSTALL_DIR" ]; then
  echo "→ Mise à jour du dépôt existant..."
  cd "$INSTALL_DIR"
  git pull origin main
else
  echo "→ Clonage du dépôt dans $INSTALL_DIR..."
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

# --------------------------------
# 6) Propriétés et permissions
# --------------------------------
echo "→ Réglage des droits sur le projet à $USER..."
sudo chown -R $USER:$USER "$INSTALL_DIR"

# --------------------------------
# 7) Déploiement des flows dans Node-RED
# --------------------------------
echo "→ Copie des flows dans $NODERED_USERDIR/$FLOWFILE..."
mkdir -p "$NODERED_USERDIR"
cp "$INSTALL_DIR/flows.json" "$NODERED_USERDIR/$FLOWFILE"
sudo chown $USER:$USER "$NODERED_USERDIR/$FLOWFILE"

# --------------------------------
# 8) Installation des dépendances des flows (nodes)
# --------------------------------
# Si votre projet contient un package.json pour les nodes, on le copie et installe :
if [ -f "$INSTALL_DIR/package.json" ]; then
  echo "→ Installation des nodes supplémentaires pour Node-RED..."
  cp "$INSTALL_DIR/package.json" "$NODERED_USERDIR/"
  sudo chown $USER:$USER "$NODERED_USERDIR/package.json"
  # Installation en tant que pi pour éviter les permissions root
  sudo -u $USER bash -c "cd $NODERED_USERDIR && npm install --production"
fi

# --------------------------------
# 9) Installation des dépendances npm du projet (outil, scripts, etc.)
# --------------------------------
echo "→ Installation des modules npm du projet..."
cd "$INSTALL_DIR"
sudo -u $USER npm install --production

# --------------------------------
# 10) Création de l’alias nred
# --------------------------------
echo "→ Ajout de l’alias 'nred' pour $USER..."
# On utilise tee en tant que pi pour écrire dans son .bashrc
grep -qxF "alias nred='cd $INSTALL_DIR && node-red'" "$HOME_DIR/.bashrc" \
  || sudo -u $USER tee -a "$HOME_DIR/.bashrc" > /dev/null <<EOF
# Alias pour FabManager-TALM
alias nred='cd $INSTALL_DIR && node-red'
EOF

# --------------------------------
# 11) Résumé
# --------------------------------
cat << EOF

=====================================
✔ Installation terminée !

• Rechargez votre profil : 
    source ~/.bashrc

• Pour démarrer Node-RED et aller dans le projet :
    nred

• Vérifications :
    node -v           (doit être ≥ v18)
    node-red --version

• Emplacements :
    Projet : $INSTALL_DIR
    Flows   : $NODERED_USERDIR/$FLOWFILE

=====================================
EOF
