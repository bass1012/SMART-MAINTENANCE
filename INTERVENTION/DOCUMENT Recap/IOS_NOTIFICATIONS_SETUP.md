# Configuration des notifications push iOS - MCT Maintenance

## ✅ Modifications automatiques effectuées

### 1. Service FCM (fcm_service.dart) ✅
- ✅ Ajout de `DarwinInitializationSettings` pour iOS
- ✅ Ajout de `DarwinNotificationDetails` pour les notifications locales
- ✅ Support complet iOS + Android

### 2. AppDelegate.swift ✅
- ✅ Import Firebase et FirebaseMessaging
- ✅ Configuration Firebase au démarrage
- ✅ Enregistrement pour les notifications à distance (APNs)
- ✅ Délégué MessagingDelegate pour recevoir le token FCM
- ✅ Gestion du token APNs

### 3. Podfile ✅
- ✅ Plateforme iOS définie à `13.0` (minimum requis par Firebase)

## 🚀 Étapes manuelles requises

### Étape 1: Créer l'application iOS dans Firebase Console

**Vous devez faire ceci depuis la console Firebase :**

1. **Aller sur Firebase Console:**
   ```
   https://console.firebase.google.com
   ```

2. **Sélectionner votre projet:** `mct-maintenance-10748`

3. **Ajouter une app iOS:**
   - Cliquer sur l'icône iOS (⚙️ → Ajouter une app → iOS)
   
4. **Informations requises:**
   - **Bundle ID iOS:** `com.remples.mctMaintenanceMobile`
     ```bash
     # Vérifier le Bundle ID dans :
     # ios/Runner.xcodeproj/project.pbxproj
     # Chercher: PRODUCT_BUNDLE_IDENTIFIER
     ```
   
   - **Nom de l'app (optionnel):** `MCT Maintenance Mobile`
   
   - **App Store ID (optionnel):** Laisser vide pour le développement

5. **Télécharger GoogleService-Info.plist:**
   - Cliquer sur "Télécharger GoogleService-Info.plist"
   - ⚠️ **NE PAS fermer la page** avant d'avoir placé le fichier !

### Étape 2: Ajouter GoogleService-Info.plist au projet

**Placer le fichier téléchargé dans le projet :**

```bash
# Copier le fichier dans le dossier Runner
cp ~/Downloads/GoogleService-Info.plist ios/Runner/

# Vérifier qu'il est bien là
ls -la ios/Runner/GoogleService-Info.plist
```

**⚠️ IMPORTANT - Ajouter au projet Xcode :**

1. Ouvrir le projet dans Xcode :
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Dans Xcode, clic droit sur le dossier `Runner` (à gauche)
   
3. Sélectionner `Add Files to "Runner"...`
   
4. Naviguer vers `ios/Runner/GoogleService-Info.plist`
   
5. **Cocher:**
   - ✅ "Copy items if needed"
   - ✅ "Create groups"
   - ✅ Target: "Runner"
   
6. Cliquer sur "Add"

7. **Vérifier:** Le fichier doit apparaître dans le dossier Runner (bleu, pas jaune)

### Étape 3: Configurer APNs (Apple Push Notification service)

⚠️ **IMPORTANT:** Cette étape nécessite un **compte Apple Developer payant (99$/an)**

**Si vous n'avez PAS de compte payant :**  
👉 **Voir le guide alternatif : `IOS_NOTIFICATIONS_FREE_DEV.md`**  
Vous pouvez développer et tester SANS payer avec des limitations.

---

**Option A: Utiliser les clés APNs (RECOMMANDÉ pour développement) - NÉCESSITE COMPTE PAYANT**

1. **Aller sur Apple Developer:**
   ```
   https://developer.apple.com/account/resources/authkeys/list
   ```
   
   ⚠️ Si vous voyez "This resource is only for developers enrolled in a developer program"  
   → Vous n'avez pas de compte payant → Consultez `IOS_NOTIFICATIONS_FREE_DEV.md`

2. **Créer une nouvelle clé:**
   - Cliquer sur "+" (Create a key)
   - Nom: `MCT Maintenance APNs Key`
   - Cocher: **Apple Push Notifications service (APNs)**
   - Cliquer sur "Continue" puis "Register"
   
3. **Télécharger la clé:**
   - Télécharger le fichier `.p8`
   - **NOTER le Key ID** (ex: ABC123DEF4)
   - **NOTER le Team ID** (dans le coin en haut à droite)
   - ⚠️ **Cette clé ne peut être téléchargée qu'une seule fois !**

4. **Uploader dans Firebase Console:**
   - Retourner sur Firebase Console → Project Settings → Cloud Messaging
   - Section "iOS app configuration"
   - Cliquer sur "Upload" sous "APNs Authentication Key"
   - Uploader le fichier `.p8`
   - Entrer le **Key ID**
   - Entrer le **Team ID**
   - Cliquer sur "Upload"

**Option B: Utiliser les certificats APNs (pour production)**

1. Créer un certificat APNs dans Apple Developer
2. Exporter le certificat .p12
3. Uploader dans Firebase Console

### Étape 4: Installer les dépendances iOS

```bash
cd ios
pod install
cd ..
```

**Si vous rencontrez des erreurs:**

```bash
# Nettoyer et réinstaller
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod deintegrate
pod install
cd ..
```

### Étape 5: Configurer les Capabilities dans Xcode

1. **Ouvrir le projet:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Sélectionner le target "Runner"** (à gauche)

3. **Onglet "Signing & Capabilities":**
   
   **a) Push Notifications:**
   - Cliquer sur "+ Capability"
   - Chercher et ajouter "Push Notifications"
   - ✅ Vérifier que c'est activé

   **b) Background Modes:**
   - Cliquer sur "+ Capability"
   - Chercher et ajouter "Background Modes"
   - Cocher:
     - ✅ "Remote notifications"
     - ✅ "Background fetch" (optionnel)

4. **Sauvegarder** (Cmd + S)

### Étape 6: Tester sur un appareil réel iOS

**⚠️ Les notifications push ne fonctionnent PAS sur simulateur iOS !**

1. **Connecter un iPhone/iPad réel**

2. **Sélectionner l'appareil dans Xcode:**
   - En haut: Runner > [Votre appareil]

3. **Lancer l'app:**
   ```bash
   flutter run
   ```
   
   Ou depuis Xcode: Cmd + R

4. **Autoriser les notifications:**
   - L'app va demander la permission
   - Cliquer sur "Autoriser"

5. **Vérifier les logs:**
   ```
   ✅ Permission de notification accordée
   📱 FCM Token obtenu: ...
   📱 APNs token enregistré
   🔔 FCM Token iOS: ...
   ✅ Token FCM enregistré dans le backend
   ```

### Étape 7: Tester l'envoi de notification

**Méthode 1: Firebase Console (rapide)**

1. Aller sur Firebase Console → Cloud Messaging
2. Cliquer sur "Send your first message"
3. Titre: "Test iOS"
4. Message: "Notification test sur iPhone"
5. Cliquer sur "Send test message"
6. Coller le FCM Token (depuis les logs)
7. Cliquer sur "Test"

**Méthode 2: Depuis le backend (réel)**

```bash
# Depuis votre backend Node.js
# Le service de notification devrait envoyer automatiquement
# Exemple: Quand une nouvelle commande arrive
```

## 📋 Checklist complète

### Configuration Firebase Console
- [ ] App iOS créée dans Firebase Console
- [ ] Bundle ID correct: `com.remples.mctMaintenanceMobile`
- [ ] GoogleService-Info.plist téléchargé
- [ ] Clé APNs créée sur Apple Developer
- [ ] Clé APNs uploadée dans Firebase Console

### Fichiers du projet
- [ ] GoogleService-Info.plist dans `ios/Runner/`
- [ ] GoogleService-Info.plist ajouté au projet Xcode (bleu, pas jaune)
- [ ] AppDelegate.swift modifié ✅ (déjà fait)
- [ ] fcm_service.dart modifié ✅ (déjà fait)
- [ ] Podfile modifié ✅ (déjà fait)

### Configuration Xcode
- [ ] Projet ouvert dans Xcode
- [ ] Capability "Push Notifications" ajoutée
- [ ] Capability "Background Modes" ajoutée
- [ ] "Remote notifications" coché dans Background Modes
- [ ] Signing configuré (Team, Bundle ID)

### Installation & Test
- [ ] `pod install` exécuté sans erreur
- [ ] App lancée sur appareil réel (pas simulateur)
- [ ] Permission de notification accordée
- [ ] Token FCM reçu (dans les logs)
- [ ] Token APNs enregistré (dans les logs)
- [ ] Token envoyé au backend
- [ ] Notification test reçue

## 🐛 Dépannage

### Problème: "No such module 'Firebase'"

**Solution:**
```bash
cd ios
pod install
# Puis ouvrir OBLIGATOIREMENT le .xcworkspace (pas .xcodeproj)
open Runner.xcworkspace
```

### Problème: Token FCM null

**Causes possibles:**
1. GoogleService-Info.plist manquant ou mal placé
2. Clé APNs non uploadée dans Firebase
3. App lancée sur simulateur (notifications non supportées)
4. Permissions refusées

**Solution:**
```bash
# Vérifier le fichier
ls -la ios/Runner/GoogleService-Info.plist

# Nettoyer et relancer
flutter clean
cd ios && pod install && cd ..
flutter run
```

### Problème: "Failed to register for remote notifications"

**Causes:**
- Capability "Push Notifications" non ajoutée
- Signing incorrect
- Pas de connexion internet

**Solution:**
1. Vérifier les Capabilities dans Xcode
2. Vérifier le Signing
3. Essayer sur un autre réseau

### Problème: Notifications ne s'affichent pas en foreground

**Normal !** Sur iOS, les notifications ne s'affichent pas automatiquement quand l'app est active.

**Solution déjà implémentée:**
- Le service FCM affiche une notification locale
- Vérifier les logs: "🔔 Notification reçue (foreground)"

### Problème: "APNs device token not set"

**Cause:** Le token APNs n'a pas été reçu

**Solution:**
```swift
// Déjà implémenté dans AppDelegate.swift
Messaging.messaging().apnsToken = deviceToken
```

Vérifier dans les logs:
```
📱 APNs token enregistré
```

## 📊 Architecture des notifications iOS

```
┌─────────────────────────────────────────────────────┐
│                  Apple Push Notification             │
│                     Service (APNs)                   │
└────────────────┬────────────────────────────────────┘
                 │
                 │ 1. Envoyer notification
                 ▼
┌─────────────────────────────────────────────────────┐
│              Firebase Cloud Messaging               │
│                     (FCM)                           │
└────────────────┬────────────────────────────────────┘
                 │
                 │ 2. Convertir en format iOS
                 ▼
┌─────────────────────────────────────────────────────┐
│                   iOS Device                        │
│  ┌──────────────────────────────────────────────┐  │
│  │            Votre App Flutter                 │  │
│  │  ┌────────────────────────────────────────┐ │  │
│  │  │      FCMService (fcm_service.dart)     │ │  │
│  │  │  - Reçoit les notifications            │ │  │
│  │  │  - Affiche en foreground (local)       │ │  │
│  │  │  - Gère les clics                      │ │  │
│  │  └────────────────────────────────────────┘ │  │
│  │                                              │  │
│  │  ┌────────────────────────────────────────┐ │  │
│  │  │    AppDelegate.swift (Native iOS)      │ │  │
│  │  │  - Configure Firebase                  │ │  │
│  │  │  - Enregistre APNs token              │ │  │
│  │  │  - Délégué MessagingDelegate          │ │  │
│  │  └────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

## 🎯 Flux complet d'une notification

```
1. Backend envoie notification
   ↓
2. Firebase Cloud Messaging reçoit
   ↓
3. FCM route vers APNs (Apple)
   ↓
4. APNs envoie vers l'appareil iOS
   ↓
5a. App en BACKGROUND/KILLED
    → Notification système iOS affichée
    → Clic → App s'ouvre → _handleNotificationTap()
    
5b. App en FOREGROUND
    → FirebaseMessaging.onMessage
    → _handleForegroundMessage()
    → _showLocalNotification()
    → Notification locale affichée
    → Clic → _handleLocalNotificationTap()
```

## 📱 Format du payload pour iOS

**Backend Node.js (paymentService.js, orderController.js, etc) :**

```javascript
const message = {
  notification: {
    title: 'Nouvelle commande',
    body: 'Commande #123 reçue'
  },
  data: {
    type: 'order',
    actionUrl: '/orders/123',
    orderId: '123'
  },
  token: userFcmToken, // Token iOS du client
  
  // Configuration spécifique iOS
  apns: {
    payload: {
      aps: {
        alert: {
          title: 'Nouvelle commande',
          body: 'Commande #123 reçue'
        },
        sound: 'default',
        badge: 1,
        'content-available': 1, // Pour background fetch
      }
    }
  }
};

await admin.messaging().send(message);
```

## ✅ Résultat final

**Après toutes ces étapes, votre app iOS pourra:**

- ✅ Recevoir des notifications push en background
- ✅ Recevoir des notifications push quand l'app est tuée
- ✅ Afficher des notifications locales en foreground
- ✅ Gérer les clics sur notifications
- ✅ Naviguer vers le bon écran selon le type
- ✅ Envoyer le token FCM au backend automatiquement
- ✅ Rafraîchir le token si nécessaire
- ✅ Synchroniser avec le backend (même service que Android)

## 🔐 Sécurité

**Clés APNs (.p8) :**
- ⚠️ **NE JAMAIS commit dans Git**
- Stocker en lieu sûr
- Ne peut être téléchargée qu'une fois
- Renouveler si perdue

**GoogleService-Info.plist :**
- ⚠️ **NE JAMAIS commit dans Git public**
- Ajouter au .gitignore
- Contient des informations sensibles du projet Firebase

## 📚 Ressources

**Documentation officielle:**
- [Firebase Cloud Messaging iOS](https://firebase.google.com/docs/cloud-messaging/ios/client)
- [APNs Apple](https://developer.apple.com/documentation/usernotifications)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)

**Tester les notifications:**
- [Firebase Console - Cloud Messaging](https://console.firebase.google.com)
- [Pusher - Online Push Tester](https://pusher.github.io/push-tester/)

## 🎉 Prochaines étapes

Une fois les notifications iOS fonctionnelles :

1. **Tester tous les types de notifications:**
   - Nouvelle commande
   - Changement de statut
   - Nouveau message chat
   - Promotion

2. **Implémenter la navigation:**
   - Dans `_handleNotificationTap()` et `_handleLocalNotificationTap()`
   - Router vers l'écran approprié selon `data.type`

3. **Gérer les badges:**
   - Compter les notifications non lues
   - Mettre à jour le badge de l'icône

4. **Analytics:**
   - Tracker les taux d'ouverture
   - Analyser les types de notifications les plus engageantes

5. **A/B Testing:**
   - Tester différents titres/messages
   - Optimiser les taux de clic
