# Guide de Déploiement - MCT Maintenance sur VPS OVH

## Prérequis

- VPS OVH avec Ubuntu 22.04 LTS
- Accès SSH root
- Nom de domaine configuré (DNS pointant vers l'IP du VPS)
- Base de données PostgreSQL (Supabase déjà configuré)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        VPS OVH                              │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                      Nginx                              ││
│  │   :80/:443 → api.domaine.com    → localhost:3000 (API)  ││
│  │   :80/:443 → dashboard.domaine.com → /var/www/.../build ││
│  └─────────────────────────────────────────────────────────┘│
│                            │                                │
│  ┌─────────────────────────┴───────────────────────────────┐│
│  │                    PM2 Cluster                          ││
│  │      ┌─────────┐ ┌─────────┐ ┌─────────┐               ││
│  │      │ API #0  │ │ API #1  │ │ API #2  │  ...          ││
│  │      └─────────┘ └─────────┘ └─────────┘               ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
              ┌─────────────────────────┐
              │   PostgreSQL (Supabase) │
              └─────────────────────────┘
```

## Étape 1: Configuration du VPS

### 1.1 Connexion SSH

```bash
ssh root@VOTRE_IP_OVH
```

### 1.2 Installation automatique

Copiez et exécutez le script d'installation:

```bash
# Télécharger le script
curl -fsSL https://raw.githubusercontent.com/bass1012/SMART-MAINTENANCE/main/deploy/install-server.sh -o install-server.sh

# Ou copiez-le manuellement puis:
chmod +x install-server.sh
./install-server.sh
```

### 1.3 Créer les dossiers de logs

```bash
sudo mkdir -p /var/log/mct
sudo chmod 755 /var/log/mct
```

## Étape 2: Configuration DNS

Chez votre registrar de domaine, créez ces enregistrements:

| Type | Nom | Valeur |
|------|-----|--------|
| A | api | VOTRE_IP_OVH |
| A | dashboard | VOTRE_IP_OVH |

## Étape 3: Déploiement de l'API

### 3.1 Depuis votre machine locale

```bash
# Option A: Avec le script de déploiement
cd /Users/bassoued/Documents/MAINTENANCE
chmod +x deploy/deploy.sh
# Modifier SERVER_IP dans deploy.sh
./deploy/deploy.sh api

# Option B: Manuellement avec rsync
rsync -avz --exclude='node_modules' --exclude='.env' --exclude='*.sqlite' \
    mct-maintenance-api/ root@VOTRE_IP:/var/www/mct-maintenance/mct-maintenance-api/
```

### 3.2 Sur le serveur

```bash
cd /var/www/mct-maintenance/mct-maintenance-api

# Copier et configurer l'environnement
cp /chemin/vers/.env.production .env
nano .env  # Modifier les valeurs

# Installer les dépendances
npm install --production

# Copier firebase-service-account.json si nécessaire
# scp firebase-service-account.json root@IP:/var/www/mct-maintenance/mct-maintenance-api/

# Démarrer avec PM2
pm2 start ecosystem.config.js
pm2 save

# Vérifier les logs
pm2 logs mct-api
```

## Étape 4: Déploiement du Dashboard

### 4.1 Build local

```bash
cd mct-maintenance-dashboard

# Configurer l'URL de l'API
echo "REACT_APP_API_URL=https://api.votredomaine.com" > .env.production

# Build
npm run build
```

### 4.2 Envoi vers le serveur

```bash
rsync -avz --delete build/ root@VOTRE_IP:/var/www/mct-maintenance/dashboard/
```

## Étape 5: Configuration Nginx

### 5.1 Copier la configuration

```bash
# Sur le serveur
sudo nano /etc/nginx/sites-available/mct-maintenance
# Coller le contenu de nginx-mct.conf
# Modifier les domaines

# Activer le site
sudo ln -s /etc/nginx/sites-available/mct-maintenance /etc/nginx/sites-enabled/

# Tester et recharger
sudo nginx -t
sudo systemctl reload nginx
```

### 5.2 Certificats SSL (Let's Encrypt)

```bash
sudo certbot --nginx -d api.votredomaine.com -d dashboard.votredomaine.com

# Renouvellement automatique
sudo certbot renew --dry-run
```

## Étape 6: Vérification

### 6.1 Tester l'API

```bash
curl https://api.votredomaine.com/health
```

Réponse attendue:
```json
{"status":"ok","timestamp":"2026-03-04T..."}
```

### 6.2 Tester le Dashboard

Ouvrez https://dashboard.votredomaine.com dans votre navigateur.

### 6.3 Vérifier PM2

```bash
pm2 status
pm2 logs mct-api --lines 50
```

## Commandes utiles

### PM2

```bash
pm2 status              # État des processus
pm2 logs mct-api        # Voir les logs
pm2 restart mct-api     # Redémarrer l'API
pm2 reload mct-api      # Reload gracieux (0 downtime)
pm2 monit               # Monitoring temps réel
```

### Nginx

```bash
sudo nginx -t                    # Tester la config
sudo systemctl reload nginx      # Recharger
sudo systemctl status nginx      # État
sudo tail -f /var/log/nginx/error.log  # Logs d'erreur
```

### Mise à jour

```bash
# Depuis votre machine locale
./deploy/deploy.sh all

# Ou manuellement
./deploy/deploy.sh api      # API uniquement
./deploy/deploy.sh dashboard # Dashboard uniquement
```

## Surveillance

### Logs

```bash
# API
pm2 logs mct-api
tail -f /var/log/mct/api-error.log

# Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Monitoring

```bash
pm2 monit   # CPU, mémoire temps réel
htop        # Ressources système
```

## Sécurité

### Firewall UFW

```bash
sudo ufw status
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
```

### Fail2ban (optionnel mais recommandé)

```bash
sudo apt install fail2ban
sudo systemctl enable fail2ban
```

## Troubleshooting

### L'API ne démarre pas

```bash
cd /var/www/mct-maintenance/mct-maintenance-api
pm2 logs mct-api --lines 100
# Vérifier .env et les variables d'environnement
```

### Erreur 502 Bad Gateway

```bash
# Vérifier que l'API tourne
pm2 status
# Vérifier les ports
sudo netstat -tlpn | grep 3000
```

### Erreur de connexion à la base de données

```bash
# Tester la connexion PostgreSQL
cd /var/www/mct-maintenance/mct-maintenance-api
node -e "require('dotenv').config(); const { sequelize } = require('./src/config/database'); sequelize.authenticate().then(() => console.log('OK')).catch(e => console.error(e.message))"
```
