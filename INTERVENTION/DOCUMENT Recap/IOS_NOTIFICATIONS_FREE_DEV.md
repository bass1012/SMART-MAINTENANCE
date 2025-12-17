# 🆓 Notifications iOS SANS compte Apple Developer payant

## 🎯 Solution pour développement et tests

### Méthode 1: Certificat de développement gratuit

**✅ Ce que vous POUVEZ faire gratuitement :**
- Tester sur vos propres appareils (max 3)
- Recevoir des notifications push en développement
- Développer et débugger l'app

**❌ Limitations :**
- Certificat expire tous les 7 jours
- 3 appareils maximum
- Impossible de publier sur l'App Store
- Pas de TestFlight

### Configuration Xcode avec compte gratuit

#### Étape 1: Ajouter votre Apple ID dans Xcode

```bash
open ios/Runner.xcworkspace
```

**Dans Xcode :**

1. **Menu Xcode → Settings (Préférences)**
   - Onglet "Accounts"
   - Cliquer sur "+" (en bas à gauche)
   - Sélectionner "Apple ID"
   - Se connecter avec votre Apple ID (gratuit)

2. **Vérifier le compte :**
   - Vous devriez voir : "User" (pas "Agent" ou "Admin")
   - Cela signifie : compte gratuit

#### Étape 2: Configurer le Signing

**Dans le projet Runner :**

1. Sélectionner "Runner" (target, à gauche)
2. Onglet "Signing & Capabilities"
3. **Signing (Debug) :**
   - ✅ Automatically manage signing
   - Team : Sélectionner votre Apple ID
   - Signing Certificate : "Apple Development"

4. **Modifier le Bundle Identifier** (IMPORTANT)
   ```
   Original : com.remples.mctMaintenanceMobile
   Nouveau  : com.votreNom.mctMaintenanceMobile
   
   Exemple : com.bassoued.mctMaintenanceMobile
   ```
   
   ⚠️ **Pourquoi ?** Le bundle ID doit être unique. Avec un compte gratuit,
   vous ne pouvez pas utiliser un bundle ID déjà pris.

#### Étape 3: Ajouter les Capabilities

**Même avec compte gratuit :**

1. **Push Notifications**
   - Cliquer sur "+ Capability"
   - Chercher "Push Notifications"
   - Ajouter
   - ✅ La capability sera ajoutée

2. **Background Modes**
   - Cliquer sur "+ Capability"
   - Chercher "Background Modes"
   - Ajouter
   - Cocher : "Remote notifications"

#### Étape 4: Créer l'app dans Firebase Console

```
1. Firebase Console : https://console.firebase.google.com
2. Projet : mct-maintenance-10748
3. ⚙️ → Ajouter une app → iOS
4. Bundle ID : com.bassoued.mctMaintenanceMobile (VOTRE nouveau bundle)
5. Télécharger GoogleService-Info.plist
6. Placer dans ios/Runner/
```

#### Étape 5: Test SANS clé APNs

**Firebase permet de tester en mode "development" :**

```bash
# Installer les pods
cd ios
pod install
cd ..

# Lancer sur appareil RÉEL (pas simulateur)
flutter run
```

**Logs attendus :**
```
✅ Permission de notification accordée
📱 FCM Token obtenu: fMCFyvVNT-C...
⚠️  APNs token: Peut ne pas fonctionner sans clé
```

### Méthode 2: Mode "Development" dans Firebase

**Firebase supporte 2 modes de notifications iOS :**

1. **Production** (nécessite clé APNs) - Pour l'App Store
2. **Development** (peut marcher sans clé) - Pour les tests

#### Configuration du payload "Development"

**Quand vous envoyez une notification depuis votre backend :**

```javascript
// Backend Node.js - Envoyer en mode Development
const message = {
  notification: {
    title: 'Test notification',
    body: 'Ceci est un test'
  },
  data: {
    type: 'test'
  },
  token: fcmToken, // Token iOS de l'appareil
  
  // Configuration iOS pour développement
  apns: {
    headers: {
      'apns-push-type': 'alert',
      'apns-priority': '10',
      // Mode développement (pas production)
      'apns-topic': 'com.bassoued.mctMaintenanceMobile'
    },
    payload: {
      aps: {
        alert: {
          title: 'Test notification',
          body: 'Ceci est un test'
        },
        sound: 'default',
        badge: 1,
        'content-available': 1
      }
    }
  }
};

await admin.messaging().send(message);
```

### Méthode 3: Notifications locales uniquement

**Si les push ne marchent pas du tout, utiliser les notifications locales :**

Votre app a déjà le service FCM qui gère les notifications locales !

**Comment ça marche :**

1. **Backend** → envoie une requête HTTP à l'app (WebSocket, polling)
2. **App** → reçoit les données
3. **App** → affiche une notification locale

**Modifier le service FCM :**

```dart
// Dans fcm_service.dart

/// Simuler une notification push avec une locale
Future<void> simulateNotification({
  required String title,
  required String body,
  Map<String, dynamic>? data,
}) async {
  // Créer un faux RemoteMessage
  await _showLocalNotification(
    RemoteMessage(
      notification: RemoteMessage.notification(
        title: title,
        body: body,
      ),
      data: data ?? {},
    ),
  );
}
```

**Appeler depuis votre app :**

```dart
// Quand vous recevez des données du backend
FCMService().simulateNotification(
  title: 'Nouvelle commande',
  body: 'Commande #123 reçue',
  data: {'type': 'order', 'orderId': '123'},
);
```

## 🔄 Workflow recommandé

### Phase 1: Développement (MAINTENANT)

**Utiliser le compte gratuit :**

1. ✅ Modifier Bundle ID
2. ✅ Signing avec Apple ID gratuit
3. ✅ Tester notifications locales
4. ✅ Développer toutes les features
5. ✅ Tester sur 1-3 appareils

**Côté backend :**
- Garder la logique de notifications
- Tester avec Android (qui marche normalement)
- L'iOS utilisera les notifications locales

### Phase 2: Pré-production (plus tard)

**Quand vous êtes prêt pour l'App Store :**

1. S'inscrire au Apple Developer Program (99$/an)
2. Créer la clé APNs
3. Uploader dans Firebase
4. Publier sur TestFlight
5. Soumettre à l'App Store

## 📊 Comparaison des solutions

| Fonctionnalité | Compte gratuit | Apple Dev (99$/an) |
|----------------|----------------|---------------------|
| **Test local** | ✅ Oui | ✅ Oui |
| **Notifications locales** | ✅ Oui | ✅ Oui |
| **Push (dev)** | ⚠️ Limité | ✅ Oui |
| **Push (prod)** | ❌ Non | ✅ Oui |
| **Nombre d'appareils** | 3 max | Illimité |
| **Durée certificat** | 7 jours | 1 an |
| **TestFlight** | ❌ Non | ✅ Oui |
| **App Store** | ❌ Non | ✅ Oui |
| **Coût** | 🆓 Gratuit | 💰 99$/an |

## 🎯 Ce que je vous recommande

### Pour l'instant (développement)

**✅ À FAIRE :**

1. **Modifier le Bundle ID** dans Xcode
   ```
   com.bassoued.mctMaintenanceMobile
   ```

2. **Utiliser le compte Apple ID gratuit**
   - Signing automatique
   - Tester sur votre iPhone/iPad

3. **Concentrez-vous sur Android pour les push**
   - Android fonctionne normalement
   - Testez toute la logique côté backend

4. **Sur iOS : notifications locales**
   - Quand l'app est ouverte : fonctionne parfaitement
   - Quand l'app est fermée : pas de notifications (pour l'instant)

5. **Développer TOUTES les autres features**
   - Paiements
   - Commandes
   - Chat
   - Etc.

### Plus tard (avant production)

**Quand vous avez un budget :**

1. Apple Developer Program (99$/an)
2. Configuration complète APNs
3. TestFlight pour beta testing
4. Publication App Store

## 🛠️ Guide rapide - Compte gratuit

### 1. Modifier le projet

```bash
open ios/Runner.xcworkspace
```

**Dans Xcode :**
1. Runner (target) → Signing & Capabilities
2. Team : Votre Apple ID
3. Bundle Identifier : `com.votreNom.mctMaintenanceMobile`
4. Ajouter "Push Notifications" capability
5. Ajouter "Background Modes" capability

### 2. Modifier le Bundle ID dans Flutter

```yaml
# Dans ios/Runner/Info.plist
# Le Bundle ID sera automatiquement mis à jour par Xcode

# Vérifier aussi dans Flutter (si utilisé)
# android/app/build.gradle garde : com.remples.mctMaintenanceMobile
# ios reste différent : com.votreNom.mctMaintenanceMobile
```

### 3. Créer app Firebase avec nouveau Bundle ID

```
Firebase Console → Ajouter app iOS
Bundle ID : com.votreNom.mctMaintenanceMobile
Télécharger GoogleService-Info.plist
```

### 4. Installer et tester

```bash
cd ios && pod install && cd ..
flutter run
```

## ❓ FAQ

**Q: Les notifications push vont marcher ?**  
R: En développement, possiblement oui, mais pas fiable. Les notifications locales marcheront parfaitement.

**Q: Dois-je payer maintenant ?**  
R: Non ! Développez d'abord avec le compte gratuit. Payez seulement quand vous êtes prêt à publier.

**Q: Et Android ?**  
R: Android fonctionne normalement, pas besoin de compte payant.

**Q: Je peux tester TestFlight ?**  
R: Non, TestFlight nécessite le compte payant (99$/an).

**Q: Le certificat expire tous les 7 jours ?**  
R: Oui, mais il suffit de rebuild l'app dans Xcode.

**Q: Combien d'appareils ?**  
R: 3 maximum avec compte gratuit.

## 🎉 Conclusion

**Vous POUVEZ développer l'app iOS MAINTENANT sans payer :**

✅ Toutes les features marchent  
✅ Notifications locales OK  
✅ Tests sur vos appareils OK  
✅ Android push notifications OK  

**Vous devrez payer (99$/an) seulement pour :**

📱 Publier sur l'App Store  
📱 Utiliser TestFlight  
📱 Push notifications fiables en production  

**Mon conseil :** Finissez le développement avec compte gratuit, puis inscrivez-vous au programme Apple Developer juste avant la publication.
