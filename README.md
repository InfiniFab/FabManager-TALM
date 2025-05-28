# 🧰 FabManager-TALM

Un gestionnaire d'accès, de suivi et de traçabilité des machines pour un FabLab, conçu avec **Node-RED**, **MariaDB** et une interface utilisateur Web.

# Clone command :
git clone --single-branch --branch sauvegarde-flows4 https://github.com/InfiniFab/FabManager-TALM.git

---

## 🧩 Objectif du projet

Ce projet vise à :
- Suivre l’utilisation des machines par les utilisateurs
- Enregistrer les matériaux utilisés, les durées, les coûts
- Gérer les utilisateurs et les accès
- Disposer d’une interface simple et visuelle via le tableau de bord de Node-RED

---

## 📦 Prérequis

Avant d’installer ce projet, assurez-vous d’avoir les éléments suivants sur votre machine :

| Logiciel      | Version recommandée  |
|---------------|-----------------------|
| Node.js       | 16+                   |
| Node-RED      | dernière stable       |
| MariaDB       | 10+                   |
| Git           | n’importe             |
| npm           | inclus avec Node.js   |

---

## 🚀 Installation

### 1. Cloner le dépôt

```bash
git clone https://github.com/InfiniFab/FabManager-TALM.git
cd FabManager-TALM
```

### 2. Installer les dépendances Node.js
```bash
npm install
```
## 🛠️ Configuration
### 3. Base de données MariaDB
#### a. Créer la base de données

Connectez-vous à MariaDB :

sudo mariadb

Créez une base et un utilisateur :
```
CREATE DATABASE fabmanager;
CREATE USER 'fabuser'@'localhost' IDENTIFIED BY 'motdepasse';
GRANT ALL PRIVILEGES ON fabmanager.* TO 'fabuser'@'localhost';
FLUSH PRIVILEGES;
```

Vous pouvez adapter les noms (fabmanager, fabuser, motdepasse) selon vos besoins.

#### b. Configurer les connexions dans Node-RED

Ouvrez l’éditeur Node-RED : http://localhost:1880

Cliquez sur un nœud MariaDB

Renseignez :

    Host : localhost

    Database : fabmanager

    User : fabuser

    Password : motdepasse

## 🔐 Sécurisation de l’interface Node-RED
### 4. Activer l’authentification sur l’éditeur et le tableau de bord

Dans le fichier settings.js de Node-RED (~/.node-red/settings.js) :

#### a. Sécuriser l'éditeur

Ajoutez ou modifiez :
```
adminAuth: {
    type: "credentials",
    users: [
        {
            username: "admin",
            password: "<mot-de-passe-hashé>",
            permissions: "*"
        },
        {
            username: "user",
            password: "<mot-de-passe-hashé>",
            permissions: "read"
        }
    ]
},
```

Pour générer le mot de passe hashé :

`node-red-admin hash-pw`

Si node-red-admin ne fonctionne pas sur le Raspberry Pi, vous pouvez générer le hash sur une autre machine et le coller.

#### b. Sécuriser l’accès au tableau de bord (UI)

Toujours dans settings.js :

httpNodeAuth: { user: "admin", pass: "<mot-de-passe-hashé>" }

    Cela protègera aussi les URLs comme /ui.

## 📁 Arborescence simplifiée

    FabManager-TALM/
    ├── flows.json                 Flows Node-RED
    ├── package.json               Dépendances et scripts npm
    ├── settings.js                Configuration Node-RED
    ├── .config.users.json         Utilisateurs Node-RED (local)
    ├── projects/Fabmanager/       Contenu principal du projet
    ├── .gitignore                 Fichiers exclus de Git
    └── README.md                  Ce fichier

## 🔍 Git & confidentialité

Le .gitignore a été configuré pour exclure automatiquement :

    node_modules/

    Clés SSH : projects/.sshkeys/

    Fichiers sensibles : credentials.json, *.sql, *.log, .tmp, backups/, etc.

    Fichiers d’état comme .sessions.json

## 🧪 Démarrage
Lancer Node-RED

`node-red`

Accéder ensuite à :

    Éditeur : http://localhost:1880

    Interface UI : http://localhost:1880/ui

## 🛠️ Personnalisation

    Ajout de machines : Ajoutez des nœuds pour chaque machine dans Node-RED

    Suivi des utilisateurs : Adaptez les formulaires du tableau de bord

    Comptabilité / Paiement : Ajoutez des règles métier ou des exports CSV

## ❓ FAQ
##### Puis-je cloner ce projet ailleurs ?

##### Oui. Il suffit d’adapter :

    La connexion MariaDB

    Les mots de passe (si l’authentification est activée)

    Les fichiers settings.js et les credentials

##### Que dois-je faire après un git clone ?
```
cd FabManager-TALM
npm install
```
