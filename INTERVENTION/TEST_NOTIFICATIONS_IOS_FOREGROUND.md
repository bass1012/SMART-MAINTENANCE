# Test Notifications iOS en Foreground

## 🎯 Objectif
Vérifier que les notifications fonctionnent quand l'app iOS est ouverte.

## 📱 Procédure de Test

### Étape 1 : Préparer l'iPhone
1. Ouvrez l'app **MCT Maintenance** sur iPhone
2. Connectez-vous avec le compte client (Noel Pkanta)
3. **Restez sur l'écran principal** de l'app
4. **NE FERMEZ PAS** l'application

### Étape 2 : Déclencher une Notification
Sur votre ordinateur, faites l'une de ces actions :

**Option A - Assigner un technicien :**
```bash
# Via le dashboard web
1. Aller sur /interventions
2. Créer une nouvelle intervention
3. Assigner un technicien
```

**Option B - Créer un contrat :**
```bash
# Via le dashboard web
1. Aller sur /contrats
2. Créer un nouveau contrat pour Noel Pkanta (ID: 14)
```

### Étape 3 : Vérifier la Console Xcode
Si vous avez Xcode connecté à l'iPhone :

```bash
# Les logs devraient montrer :
🔔 Notification reçue (foreground)
   Titre: [Titre de la notification]
   Message: [Message]
```

### Étape 4 : Observer l'iPhone

**✅ Résultat Attendu :**
- Une **popup de notification** apparaît en haut de l'écran
- L'app vibre (si activé)
- Le son de notification se joue

**❌ Si Rien N'Apparaît :**
- Les permissions iOS ne sont pas accordées
- OU Firebase n'est pas configuré correctement pour iOS

---

## 🔧 Si le Test Échoue

### Vérifier les Permissions
1. Sur iPhone : **Réglages → MCT Maintenance → Notifications**
2. Vérifier que tout est activé :
   - ✅ Autoriser les notifications
   - ✅ Sons
   - ✅ Badges
   - ✅ Bannières

### Réinstaller l'App
```bash
# Dans le terminal
cd /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile
flutter clean
flutter run
```

Lors du premier lancement, accepter la demande de permissions notifications.

---

## ⚠️ Limitation Connue

**Notifications en Background/App Fermée :**
- ❌ Ne fonctionnent PAS sans compte Apple Developer payant
- Nécessite une clé APNs (impossible à obtenir avec compte gratuit)
- C'est une **limitation Apple**, pas un bug de votre code

**Solution :**
- Attendre d'avoir le compte payant (99$/an) pour tester les push complets
- Pour l'instant, concentrez-vous sur Android pour les push notifications
