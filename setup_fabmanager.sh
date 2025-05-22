#!/usr/bin/env bash
set -euo pipefail

### Paramètres d’appel ###
GIT_REPO="${1:-https://github.com/InfiniFab/FabManager-TALM.git}"
GIT_BRANCH="${2:-main}"
INSTALL_DIR="/opt/fabmanager"
NR_USER="nodered"

if [[ -z "$GIT_REPO" ]]; then
  echo "Usage: sudo $0 <url-depot-git> [branche]" >&2
  exit 1
fi

echo "==> 1. Mise à jour du système"
apt-get update && apt-get -y upgrade

echo "==> 2. Installation des dépendances"
apt-get install -y build-essential git curl python3 python3-dev

echo "==> 3. Installation de Node.js & Node-RED"
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered) \
     --confirm-install --confirm-pi --confirm-node-red-user --skip-prompt
## :contentReference[oaicite:1]{index=1} :contentReference[oaicite:2]{index=2}

echo "==> 4. Création de l’utilisateur système '$NR_USER'"
if ! id "$NR_USER" &>/dev/null; then
  adduser --system --group "$NR_USER"
fi

echo "==> 5. Clonage du dépôt FabManager-TALM"
mkdir -p "$INSTALL_DIR"
chown "$NR_USER":"$NR_USER" "$INSTALL_DIR"
sudo -u "$NR_USER" git clone "$GIT_REPO" "$INSTALL_DIR"
cd "$INSTALL_DIR"
sudo -u "$NR_USER" git checkout "$GIT_BRANCH"

echo "==> 6. Installation des modules NPM du projet"
if [[ -f package.json ]]; then
  sudo -u "$NR_USER" npm install --production
fi

echo "==> 7. Déploiement du flow dans ~/.node-red"
FLOW_SRC="$(find . -maxdepth 1 -name '*.json' -print -quit)"
NR_HOME="/home/$NR_USER/.node-red"
mkdir -p "$NR_HOME"
if [[ -n "$FLOW_SRC" ]]; then
  cp "$FLOW_SRC" "$NR_HOME/flows_$(hostname).json"
fi
chown -R "$NR_USER":"$NR_USER" "$NR_HOME"

echo "==> 8. Activation & démarrage du service Node-RED"
systemctl enable nodered.service
systemctl restart nodered.service

echo
echo "Installation terminée ! Accéder à Node-RED : http://$(hostname -I | awk '{print $1}'):1880"
