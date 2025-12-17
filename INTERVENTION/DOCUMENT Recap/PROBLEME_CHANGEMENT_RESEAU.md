# 🌐 PROBLÈME : Connexion Impossible Après Changement de Réseau

## 📋 Symptômes

Chaque fois que vous changez de réseau WiFi, l'application mobile Flutter affiche :

```
🔴 Le serveur ne répond pas dans le délai imparti. Vérifiez votre connexion Internet.
```

---

## 🔍 Cause du Problème

### **Pourquoi cela se produit ?**

Quand vous changez de réseau WiFi, votre **routeur attribue une nouvelle adresse IP** à votre Mac :

```
Réseau Maison    → 192.168.1.22    ✅ (actuellement configuré)
Réseau Bureau    → 10.0.0.45       ❌ (nouvelle adresse)
Café Public      → 192.168.100.12  ❌ (nouvelle adresse)
```

L'application Flutter a l'adresse **codée en dur** dans `/lib/config/environment.dart` :

```dart
Environment.development: 'http://192.168.1.22:3000'
```

Quand l'IP change, l'app continue d'essayer de se connecter à l'ancienne adresse qui **n'existe plus** sur le nouveau réseau.

---

## ✅ Solutions Permanentes

### **Solution 1 : IP Statique (RECOMMANDÉE)**

Configurez une **adresse IP fixe** pour votre Mac qui ne changera jamais.

#### **Sur macOS :**

1. **Préférences Système** → **Réseau**
2. Sélectionnez **Wi-Fi** (ou Ethernet)
3. Cliquez sur **Avancé...**
4. Onglet **TCP/IP**
5. Changez **Configurer IPv4** : `DHCP` → `Manuellement`
6. Entrez les paramètres :
   ```
   Adresse IPv4 : 192.168.1.100
   Masque de sous-réseau : 255.255.255.0
   Routeur : 192.168.1.1
   ```
7. **OK** → **Appliquer**

#### **Comment trouver l'adresse du routeur ?**

```bash
netstat -nr | grep default | awk '{print $2}' | head -1
```

#### **Choisir une bonne adresse IP statique :**

- Utilisez une adresse **en dehors de la plage DHCP** du routeur
- Généralement : `192.168.1.100` à `192.168.1.200` sont sûrs
- Évitez : `192.168.1.1` à `192.168.1.50` (souvent utilisés par DHCP)

#### **Mettre à jour l'app Flutter :**

Fichier : `/lib/config/environment.dart`

```dart
static const Map<Environment, String> _baseUrls = {
  Environment.development: 'http://192.168.1.100:3000', // IP STATIQUE
  // ...
};
```

**Avantages :**
- ✅ L'IP ne change jamais, même après redémarrage
- ✅ Fonctionne sur tous les réseaux où vous avez le contrôle
- ✅ Pas besoin de reconfigurer à chaque fois

**Inconvénients :**
- ❌ Ne fonctionne pas sur les réseaux publics (café, hôtel)
- ❌ Peut causer des conflits si une autre machine utilise la même IP

---

### **Solution 2 : Script de Mise à Jour Automatique**

Utilisez le script helper pour détecter et mettre à jour l'IP automatiquement.

#### **Utilisation :**

À chaque changement de réseau, exécutez :

```bash
cd /Users/bassoued/Documents/MAINTENANCE
./update_ip.sh
```

Le script va :
1. 🔍 Détecter automatiquement votre nouvelle IP
2. 📝 Mettre à jour le fichier de configuration Flutter
3. ✅ Créer une sauvegarde de l'ancien fichier

**Avantages :**
- ✅ Fonctionne sur tous les réseaux
- ✅ Mise à jour en 1 commande
- ✅ Sauvegarde automatique

**Inconvénients :**
- ❌ Vous devez exécuter le script manuellement à chaque changement de réseau
- ❌ Nécessite un hot restart de l'app Flutter

---

### **Solution 3 : Hostname au lieu d'IP (Avancé)**

Utilisez le **nom d'hôte** de votre Mac au lieu de l'IP.

#### **Trouver le nom d'hôte :**

```bash
hostname
# Résultat : MacBook-Pro-de-Bass.local
```

#### **Mettre à jour l'app Flutter :**

```dart
static const Map<Environment, String> _baseUrls = {
  Environment.development: 'http://MacBook-Pro-de-Bass.local:3000',
  // ...
};
```

**⚠️ Limitation :** Cela nécessite que votre téléphone et votre Mac soient sur le **même réseau local** et que le **mDNS/Bonjour** soit activé.

**Avantages :**
- ✅ Pas besoin de mettre à jour l'IP
- ✅ Fonctionne automatiquement sur n'importe quel réseau

**Inconvénients :**
- ❌ Ne fonctionne pas toujours (problèmes mDNS)
- ❌ Peut être bloqué sur certains réseaux d'entreprise

---

### **Solution 4 : Ngrok (Pour Tester sur Internet)**

Exposez votre serveur backend sur Internet avec **ngrok**.

#### **Installation :**

```bash
brew install ngrok
```

#### **Utilisation :**

```bash
# Lancer le serveur backend normalement
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
npm start

# Dans un autre terminal, exposer le port 3000
ngrok http 3000
```

Ngrok vous donnera une URL publique :
```
Forwarding https://abc123.ngrok.io -> http://localhost:3000
```

#### **Mettre à jour l'app Flutter :**

```dart
static const Map<Environment, String> _baseUrls = {
  Environment.development: 'https://abc123.ngrok.io',
  // ...
};
```

**Avantages :**
- ✅ Fonctionne depuis n'importe où (WiFi, 4G, 5G)
- ✅ Pas besoin d'être sur le même réseau
- ✅ Utile pour tester avec des webhooks

**Inconvénients :**
- ❌ L'URL change à chaque redémarrage de ngrok (version gratuite)
- ❌ Peut être lent (tunnel internet)
- ❌ Nécessite une connexion internet

---

## 🚀 Workflow Recommandé

### **Scénario 1 : Développement à la Maison/Bureau**

1. **Configurez une IP statique** : `192.168.1.100`
2. **Mettez à jour l'app une fois**
3. ✅ **Plus jamais de problème** !

### **Scénario 2 : Développement Mobile (Plusieurs Réseaux)**

À chaque changement de réseau :

```bash
# 1. Vérifier la nouvelle IP
ifconfig | grep "inet " | grep -v 127.0.0.1

# 2. Mettre à jour automatiquement
./update_ip.sh

# 3. Hot restart de l'app Flutter
# Appuyer sur 'R' dans le terminal Flutter
```

### **Scénario 3 : Test à Distance**

```bash
# Lancer ngrok
ngrok http 3000

# Copier l'URL ngrok dans environment.dart
# Relancer l'app Flutter
```

---

## 🔧 Dépannage Rapide

### **1. Vérifier l'IP actuelle de votre Mac**

```bash
ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
```

### **2. Vérifier l'IP configurée dans l'app**

```bash
grep "Environment.development:" /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile/lib/config/environment.dart
```

### **3. Tester la connectivité**

```bash
# Depuis votre Mac
curl http://localhost:3000/health

# Depuis votre téléphone (remplacez l'IP)
curl http://192.168.1.22:3000/health
```

### **4. Vérifier que le serveur écoute sur toutes les interfaces**

Dans `/mct-maintenance-api/src/app.js`, vérifiez :

```javascript
server.listen(PORT, '0.0.0.0', () => {
  // '0.0.0.0' = écouter sur toutes les interfaces
});
```

### **5. Vérifier le firewall macOS**

```bash
# Désactiver temporairement pour tester
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off

# Réactiver après le test
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
```

Ou autoriser Node.js dans :
**Préférences Système** → **Sécurité et confidentialité** → **Pare-feu** → **Options du pare-feu**

---

## 📊 Comparaison des Solutions

| Solution | Facilité | Fiabilité | Mobilité | Coût |
|----------|----------|-----------|----------|------|
| **IP Statique** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ | Gratuit |
| **Script Helper** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Gratuit |
| **Hostname** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | Gratuit |
| **Ngrok** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Gratuit/Payant |

---

## 💡 Recommandation Finale

**Pour le développement quotidien :**
- ✅ Utilisez **IP statique** à la maison/bureau
- ✅ Gardez le **script helper** pour les déplacements

**Pour le test en production :**
- ✅ Utilisez un **vrai serveur cloud** avec un nom de domaine
- ✅ Mettez à jour `Environment.production` dans `environment.dart`

---

## 📝 Checklist Rapide

Quand vous changez de réseau :

- [ ] Vérifier la nouvelle IP : `ifconfig | grep "inet "`
- [ ] Exécuter le script : `./update_ip.sh`
- [ ] Relancer l'app Flutter (hot restart avec `R`)
- [ ] Tester la connexion

---

**Fichiers Modifiés :**
- ✅ `/lib/config/environment.dart` - Configuration IP
- ✅ `/update_ip.sh` - Script helper

**Scripts Disponibles :**
```bash
./update_ip.sh         # Mettre à jour l'IP automatiquement
./test_technicien.sh   # Tester la connexion API
```

---

**Besoin d'aide ? Vérifiez que :**
1. Le serveur backend tourne : `npm start`
2. L'IP est correcte dans `environment.dart`
3. Votre téléphone est sur le **même réseau WiFi** que votre Mac
4. Le firewall n'est pas bloquant
