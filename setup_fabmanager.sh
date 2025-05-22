#!/usr/bin/env bash
set -euo pipefail

### Vérification des privilèges ###
if [[ $EUID -ne 0 ]]; then
  echo "Ce script doit être exécuté en tant que root !" >&2
  exit 1
fi

### Paramètres d’appel ###
GIT_REPO="${1:-https://github.com/InfiniFab/FabManager-TALM.git}"
GIT_BRANCH="${2:-main}"
INSTALL_DIR="/opt/fabmanager"
NR_USER="pi"
LOG_FILE="/var/log/fabmanager_install.log"

### Fonction de log ###
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') | $*" | tee -a "$LOG_FILE"
}

log "=== Début de l'installation de FabManager-TALM ==="

### 3. Installation des dépendances ###
log "1. Mise à jour du système et installation des paquets requis"
apt-get update \
  && apt-get -y upgrade \
  && apt-get install -y \
       build-essential git curl python3 python3-dev npm jq \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

### 6. Clonage idempotent et gestion des permissions ###
log "2. Préparation du répertoire d'installation ($INSTALL_DIR)"
if [[ -d "$INSTALL_DIR/.git" ]]; then
  log "   Le dépôt existe déjà, mise à jour via git pull"
  sudo -u "$NR_USER" git -C "$INSTALL_DIR" pull origin "$GIT_BRANCH"
else
  log "   Clonage du dépôt depuis $GIT_REPO (branche $GIT_BRANCH)"
  mkdir -p "$INSTALL_DIR"
  chown root:root "$INSTALL_DIR"
  chmod 750 "$INSTALL_DIR"
  sudo -u "$NR_USER" git clone --branch "$GIT_BRANCH" "$GIT_REPO" "$INSTALL_DIR"
fi

log "   Installation des modules NPM en production"
cd "$INSTALL_DIR"
if [[ -f package.json ]]; then
  sudo -u "$NR_USER" npm install --production
else
  log "   Aucun package.json trouvé, passage de l'installation NPM"
fi

### 9. Journalisation et vérification finale ###
log "3. Déploiement du flow Node-RED"
FLOW_SRC="$(find . -maxdepth 1 -name '*.json' -print -quit || true)"
NR_HOME="/home/$NR_USER/.node-red"
mkdir -p "$NR_HOME"
if [[ -n "$FLOW_SRC" ]]; then
  if jq empty "$FLOW_SRC" >/dev/null 2>&1; then
    cp "$FLOW_SRC" "$NR_HOME/flows_$(hostname).json"
    log "   Flow $(basename "$FLOW_SRC") validé et copié"
  else
    log "   ERREUR : Flow JSON invalide, copie ignorée" >&2
  fi
else
  log "   Aucun flow JSON trouvé, copie ignorée"
fi
chown -R "$NR_USER":"$NR_USER" "$NR_HOME"

log "4. Activation & démarrage du service Node-RED"
if systemctl daemon-reload && systemctl enable nodered.service && systemctl restart nodered.service; then
  log "   Service Node-RED actif : $(systemctl is-active nodered.service)"
else
  log "   ERREUR lors du démarrage de Node-RED" >&2
  exit 1
fi

log "Installation terminée ! Accéder à Node-RED : http://$(hostname -I | awk '{print $1}'):1880"
