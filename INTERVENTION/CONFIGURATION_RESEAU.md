# 🏢🏠 Configuration Bureau / Maison

Ce projet supporte deux configurations réseau différentes : **Bureau** et **Maison**.

---

## 🚀 Méthode rapide (recommandée)

Exécutez le script automatique à la racine du projet :

```bash
./switch-location.sh
```

Le script configurera automatiquement :
- ✅ Dashboard web (fichier `.env`)
- ✅ Application mobile Flutter (`environment.dart`)

---

## ⚙️ Configuration manuelle

### 1️⃣ Trouver votre adresse IP

**Mac :**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**Windows :**
```cmd
ipconfig
```

---

### 2️⃣ Configurer l'IP de la maison

#### Dashboard Web
Éditez `mct-maintenance-dashboard/.env.home` :
```properties
REACT_APP_API_URL=http://VOTRE_IP:3000/api
REACT_APP_SOCKET_URL=http://VOTRE_IP:3000
```

#### Application Mobile
Éditez `mct_maintenance_mobile/lib/config/environment.dart` (ligne 20) :
```dart
static const Map<Location, String> _locationIPs = {
  Location.office: '192.168.1.139',
  Location.home: 'VOTRE_IP_MAISON',  // ⚠️ Remplacez ici
};
```

---

### 3️⃣ Basculer entre Bureau et Maison

#### Avec le script :
```bash
./switch-location.sh
# Puis choisir 1 (Bureau) ou 2 (Maison)
```

#### Manuellement :

**Dashboard :**
```bash
cd mct-maintenance-dashboard

# Bureau
cp .env.office .env

# Maison  
cp .env.home .env

npm start
```

**Mobile :**

Éditez `mct_maintenance_mobile/lib/config/environment.dart` (ligne 11) :

```dart
// Bureau
const Location currentLocation = Location.office;

// Maison
const Location currentLocation = Location.home;
```

Puis faites **Hot Restart (R)** dans Flutter.

---

## 📋 Configuration actuelle

Actuellement configuré pour : **BUREAU** (192.168.1.139)

Pour vérifier :
- Dashboard : `cat mct-maintenance-dashboard/.env`
- Mobile : `grep "currentLocation" mct_maintenance_mobile/lib/config/environment.dart`

---

## 🔍 Structure des fichiers

```
MAINTENANCE/
├── switch-location.sh          # Script de basculement automatique
├── mct-maintenance-dashboard/
│   ├── .env                     # Config active (générée)
│   ├── .env.office              # Config bureau
│   ├── .env.home                # Config maison
│   └── CHANGER_IP.md            # Documentation dashboard
└── mct_maintenance_mobile/
    ├── lib/config/environment.dart  # Config mobile
    └── CHANGER_IP.md            # Documentation mobile
```

---

## ✅ Checklist après changement

- [ ] Dashboard redémarré (`npm start`)
- [ ] Mobile redémarré (Hot Restart - R)
- [ ] Backend accessible sur la nouvelle IP
- [ ] Test de connexion OK

---

## 🆘 Dépannage

### "Le serveur ne répond pas"
1. Vérifier que le backend est démarré : `cd mct-maintenance-api && npm start`
2. Vérifier l'IP configurée correspond à celle de votre machine
3. Vérifier que le firewall n'est pas bloqué
4. Tester l'accès : `curl http://VOTRE_IP:3000/api/health`

### "Cannot connect to Socket.IO"
1. Vérifier que le backend Socket.IO est actif
2. L'IP du chat doit correspondre à `AppConfig.baseUrl`
3. Faire un Hot Restart de l'app mobile

---

## 📝 Notes

- Les fichiers `.env.office` et `.env.home` sont versionnés
- Le fichier `.env` est ignoré par Git (généré localement)
- Le changement est instantané pour le dashboard (rechargement auto)
- Le changement nécessite un Hot Restart pour le mobile
