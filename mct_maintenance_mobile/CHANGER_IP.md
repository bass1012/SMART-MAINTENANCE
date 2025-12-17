# 🔧 Comment changer l'adresse IP (Bureau ↔ Maison)

## Configuration rapide

### 1️⃣ Trouver votre adresse IP

**Sur Mac :**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**Sur Windows :**
```cmd
ipconfig
```

**Ou via les préférences système :**
- Mac: System Preferences > Network
- Windows: Paramètres > Réseau et Internet

---

### 2️⃣ Configurer l'IP de la maison

Ouvrir le fichier : **`lib/config/environment.dart`**

Ligne 16, remplacer `xxx` par votre IP :
```dart
static const Map<Location, String> _locationIPs = {
  Location.office: '192.168.1.139', // IP du bureau
  Location.home: '192.168.1.xxx',   // ⚠️ Remplacez xxx par votre IP maison
};
```

---

### 3️⃣ Changer de lieu (Bureau ↔ Maison)

Dans le même fichier **`lib/config/environment.dart`**, ligne 13 :

**Au bureau :**
```dart
const Location currentLocation = Location.office;
```

**À la maison :**
```dart
const Location currentLocation = Location.home;
```

---

### 4️⃣ Redémarrer l'application

Après le changement, faire un **Hot Restart (R)** ou relancer l'app complètement.

---

## ✅ C'est tout !

Maintenant vous n'avez qu'à changer **une seule ligne** pour basculer entre bureau et maison ! 🎉

---

## 📝 Notes

- Le changement s'applique automatiquement à :
  - ✅ API REST
  - ✅ Socket.IO (Chat)
  - ✅ Upload d'images
  - ✅ Tous les services

- **Astuce** : Vous pouvez créer un raccourci VSCode ou un alias Git pour changer rapidement :
  ```bash
  # Bureau
  sed -i '' 's/Location.home/Location.office/' lib/config/environment.dart
  
  # Maison
  sed -i '' 's/Location.office/Location.home/' lib/config/environment.dart
  ```
