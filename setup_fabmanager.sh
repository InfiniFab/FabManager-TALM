#!/bin/bash
set -e

# =============================================================================
# Variables
# =============================================================================
USER=pi
HOME_DIR="/home/$USER"
REPO_URL="https://github.com/InfiniFab/FabManager-TALM.git"
INSTALL_DIR="$HOME_DIR/FabManager-TALM"
NODERED_USERDIR="$HOME_DIR/.node-red"
FLOWFILE="flows_$(hostname).json"

# =============================================================================
# 1) Mise à jour du système
# =============================================================================
echo "→ Mise à jour des paquets APT..."
sudo apt-get update -y
sudo apt-get upgrade -y

# =============================================================================
# 2) Désinstallation de Node.js v12 (le cas échéant)
# =============================================================================
echo "→ Suppression de Node.js/npm obsolètes..."
sudo apt-get remove -y nodejs npm || true
sudo apt-get autoremove -y

# =============================================================================
# 3) Installation des outils de base
# =============================================================================
echo "→ Installation de Git, Curl, build-essential et MariaDB..."
sudo apt-get install -y git curl build-essential mariadb-server

# =============================================================================
# 4) Installation de Node-RED (+ Node.js ≥18)
# =============================================================================
echo "→ Installation de Node-RED (et Node.js adapté)..."
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered) --confirm-root

# =============================================================================
# 5) Clone ou mise à jour du dépôt FabManager-TALM
# =============================================================================
if [ -d "$INSTALL_DIR" ]; then
  echo "→ Mise à jour du dépôt existant..."
  cd "$INSTALL_DIR"
  git pull origin main
else
  echo "→ Clonage du dépôt dans $INSTALL_DIR..."
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

# =============================================================================
# 6) Permissions du projet
# =============================================================================
echo "→ Attribution des droits au projet..."
sudo chown -R $USER:$USER "$INSTALL_DIR"

# =============================================================================
# 7) Déploiement des flows et dépendances Node-RED
# =============================================================================
echo "→ Préparation du répertoire Node-RED userDir..."
# Crée ~/.node-red si besoin
sudo -u $USER mkdir -p "$NODERED_USERDIR"

# Copie du flow principal
echo "→ Copie de flows.json → $FLOWFILE"
sudo -u $USER cp "$INSTALL_DIR/flows.json" "$NODERED_USERDIR/$FLOWFILE"

# Copie et installation du package.json des flows
if [ -f "$INSTALL_DIR/package.json" ]; then
  echo "→ Copie de package.json (et package-lock.json) pour les flows..."
  sudo -u $USER cp "$INSTALL_DIR/package.json" "$NODERED_USERDIR/"
  [ -f "$INSTALL_DIR/package-lock.json" ] && sudo -u $USER cp "$INSTALL_DIR/package-lock.json" "$NODERED_USERDIR/"
  # Installation complète (inclut devDependencies)
  echo "→ Installation des modules Node-RED (flows)..."
  sudo -u $USER bash -c "cd $NODERED_USERDIR && npm install"
fi

# =============================================================================
# 8) Installation des dépendances du projet (scripts/outils)
# =============================================================================
echo "→ Installation des modules npm du projet..."
cd "$INSTALL_DIR"
sudo -u $USER npm install

# =============================================================================
# 9) Création de l’alias 'nred'
# =============================================================================
echo "→ Ajout de l’alias 'nred' pour l’utilisateur $USER..."

# 9.1 Assurez-vous que .bash_aliases est chargé dans .bashrc
if ! grep -q "bash_aliases" "$HOME_DIR/.bashrc"; then
  sudo -u $USER tee -a "$HOME_DIR/.bashrc" > /dev/null <<'EOF'

# Charger les alias utilisateur
if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi
EOF
fi

# 9.2 Ajout de l’alias dans ~/.bash_aliases
sudo -u $USER touch "$HOME_DIR/.bash_aliases"
if ! grep -q "alias nred=" "$HOME_DIR/.bash_aliases"; then
  sudo -u $USER tee -a "$HOME_DIR/.bash_aliases" > /dev/null <<EOF
# Raccourci pour lancer Node-RED depuis FabManager-TALM
alias nred='cd $INSTALL_DIR && node-red'
EOF
fi

# =============================================================================
# 10) Résumé
# =============================================================================
cat << EOF

=====================================
✔ Installation terminée !

→ Rechargez votre profil pour activer l’alias :
    source ~/.bashrc

→ Pour démarrer Node-RED depuis votre projet :
    nred

→ Vérifications :
    node -v           (doit être ≥ v18)
    node-red --version

→ Emplacements :
    Projet : $INSTALL_DIR
    Flows   : $NODERED_USERDIR/$FLOWFILE
=====================================
EOF
