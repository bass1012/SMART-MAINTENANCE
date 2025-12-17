# 🔴 Blocage iOS Push Notifications - Résolution

## ❌ PROBLÈME PRINCIPAL

**Les notifications push ne fonctionnent PAS sur les simulateurs iOS.**

### Logs Simulateur (iPhone 16e)
```
❌ [FCM] ERREUR lors de l'initialisation: [firebase_messaging/unknown]
```

### Cause
- Les simulateurs iOS **ne peuvent PAS obtenir de token FCM**
- Les simulateurs **n'ont PAS accès aux serveurs APNs** d'Apple
- C'est une **limitation iOS connue**, pas un bug de configuration

---

## ✅ SOLUTION : Utiliser un iPhone Physique

### Configuration Actuelle
- ✅ **Bundle ID** : `com.bassoued.mctMaintenanceMobile`
- ✅ **Firebase APNs Key** : Uploadée et valide
  - Key ID : `Q568Q9TBA5`
  - Team ID : `F2HA66M3YN`
- ✅ **GoogleService-Info.plist** : Re-téléchargé après upload de la clé APNs
- ✅ **Xcode Capabilities** :
  - Push Notifications activé
  - Background Modes → Remote notifications activé
- ✅ **Entitlements** : `aps-environment: development`

### Prérequis iPhone Physique

1. **Mode Développeur ACTIVÉ**
   - Réglages → Confidentialité et sécurité → Mode développeur → ON
   - Nécessite redémarrage de l'iPhone

2. **Faire confiance à l'ordinateur**
   - Popup "Faire confiance à cet ordinateur ?" → Faire confiance

3. **iPhone déverrouillé**
   - Pas de code PIN en attente

### Commande pour Lancer sur iPhone Physique

```bash
# Vérifier les devices disponibles
flutter devices

# Lancer sur l'iPhone physique
flutter run -d 00008130-000204563A90001C
```

---

## 📋 Checklist de Test sur iPhone Physique

### Étape 1 : Installation
- [ ] Mode développeur activé sur l'iPhone
- [ ] iPhone déverrouillé et connecté via USB
- [ ] `flutter run -d 00008130-000204563A90001C` réussi
- [ ] App installée sur l'iPhone

### Étape 2 : Permissions
- [ ] Popup "Autoriser les notifications" → AUTORISER
- [ ] Réglages iOS → MCT Maintenance → Notifications → TOUT activé

### Étape 3 : Connexion et Token FCM
- [ ] Se connecter avec `pkanta@gmail.com`
- [ ] Observer logs Flutter pour :
  ```
  🔔 [FCM] Début initialisation...
  ✅ [FCM] Permission de notification accordée
  📱 [FCM] Token obtenu: xxxxxxxxxx...
  ✅ [FCM->Backend] Token FCM enregistré dans le backend
  🎉 [FCM] Initialisation terminée avec succès
  ```

### Étape 4 : Vérification Backend
```bash
# Vérifier que le token FCM a été enregistré
sqlite3 database.sqlite "SELECT id, SUBSTR(fcm_token, 1, 50), updated_at FROM users WHERE id = 14;"
```

Résultat attendu : Token FCM présent (pas NULL) avec date récente

### Étape 5 : Test de Notification
1. Sur le dashboard web (http://localhost:3001)
2. Interventions → Créer une intervention
3. **Client** : Noel Pkanta (ID: 14)
4. **Technicien** : Hamed OUATTARA ou Edouard Cissoko
5. Enregistrer

### Logs Backend Attendus
```
📤 Envoi notification assignation au client user_id: 14
👤 Client: Noel Pkanta
✅ Notification FCM envoyée avec succès
   Token: xxxxxxxxxx...
   Titre: Technicien assigné
   Message ID: projects/mct-maintenance-10748/messages/...
```

### Résultat Final
- [ ] **Notification reçue sur l'iPhone** (popup, son, badge)
- [ ] Test réussi avec app en foreground
- [ ] Test réussi avec app en background
- [ ] Test réussi avec app fermée

---

## 🎯 État Actuel

- ✅ Backend : 100% fonctionnel
- ✅ Firebase Console : Correctement configuré
- ✅ Xcode : Capabilities activées
- ✅ GoogleService-Info.plist : À jour
- ⏳ **EN ATTENTE** : Test sur iPhone physique avec mode développeur activé

---

## 📚 Références

- **Firebase iOS Setup** : https://firebase.google.com/docs/ios/setup
- **APNs Certificates** : https://firebase.google.com/docs/cloud-messaging/ios/certs
- **Flutter Firebase Messaging** : https://firebase.flutter.dev/docs/messaging/overview/
- **iOS Developer Mode** : https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device

---

## 🔗 Fichiers Importants

- `/ios/Runner/GoogleService-Info.plist` - Configuration Firebase
- `/ios/Runner/Runner.entitlements` - APNs entitlements
- `/lib/services/fcm_service.dart` - Service de notifications
- `/src/services/fcmService.js` - Backend Firebase Admin
- `/src/controllers/intervention/interventionController.js` - Envoi notifications

---

**Date de création** : 3 novembre 2025  
**Statut** : En attente d'activation du mode développeur sur iPhone physique
