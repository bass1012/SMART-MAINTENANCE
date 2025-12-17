# 🚀 Commencer MAINTENANT avec iOS (sans payer)

## 📱 Ce que vous pouvez faire GRATUITEMENT

✅ Développer toute l'application  
✅ Tester sur vos iPhone/iPad  
✅ Notifications locales (quand l'app est ouverte)  
✅ Toutes les autres fonctionnalités  

❌ Publier sur l'App Store (nécessite 99$/an)  
❌ Push notifications fiables quand l'app est fermée  
❌ TestFlight beta testing  

## 🎯 5 étapes rapides

### 1. Ouvrir le projet dans Xcode

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile
open ios/Runner.xcworkspace
```

### 2. Ajouter votre Apple ID

**Dans Xcode :**

1. Menu **Xcode → Settings**
2. Onglet **Accounts**
3. Cliquer sur **+** (en bas à gauche)
4. Choisir **Apple ID**
5. Se connecter avec votre Apple ID (iCloud)
6. Fermer

### 3. Configurer le Signing

**Dans Xcode (même fenêtre) :**

1. À gauche, cliquer sur **Runner** (icône bleue en haut)
2. Sélectionner le target **Runner** (sous TARGETS)
3. Onglet **Signing & Capabilities**
4. Cocher **✅ Automatically manage signing**
5. **Team :** Sélectionner votre nom (compte personnel)
6. **Bundle Identifier :** Changer à `com.bassoued.mctMaintenanceMobile`
   
   ⚠️ **Pourquoi ?** Le Bundle ID original est peut-être déjà pris.
   Avec un compte gratuit, vous devez utiliser un ID unique.

### 4. Ajouter les Capabilities

**Toujours dans Signing & Capabilities :**

1. Cliquer sur **+ Capability** (en haut à gauche)
2. Chercher et ajouter **Push Notifications**
3. Cliquer à nouveau sur **+ Capability**
4. Chercher et ajouter **Background Modes**
5. Cocher **✅ Remote notifications**

### 5. Créer l'app Firebase (avec nouveau Bundle ID)

```
1. Aller sur : https://console.firebase.google.com
2. Sélectionner : mct-maintenance-10748
3. Cliquer sur ⚙️ (en haut à gauche) → Project Settings
4. Onglet "Your apps" → Cliquer sur iOS (icône Apple)
5. Bundle ID : com.bassoued.mctMaintenanceMobile
6. App nickname : MCT Maintenance Mobile
7. Cliquer sur "Register app"
8. Télécharger GoogleService-Info.plist
9. Cliquer sur "Next" → "Next" → "Continue to console"
```

### 6. Ajouter GoogleService-Info.plist

```bash
# Copier le fichier téléchargé
cp ~/Downloads/GoogleService-Info.plist ios/Runner/
```

**Dans Xcode :**

1. Clic droit sur le dossier **Runner** (à gauche, celui avec l'icône jaune)
2. Choisir **Add Files to "Runner"...**
3. Naviguer vers `ios/Runner/GoogleService-Info.plist`
4. Cocher **✅ Copy items if needed**
5. Cocher **✅ Create groups**
6. Target : **✅ Runner**
7. Cliquer sur **Add**

### 7. Installer les pods

```bash
cd ios
pod install
cd ..
```

### 8. Tester sur votre iPhone

```bash
# Connecter votre iPhone au Mac
# Le sélectionner en haut dans Xcode (à côté de Runner)
# Puis lancer :

flutter run
```

**OU dans Xcode : Cmd + R**

## ✅ Vérification

**Quand l'app se lance :**

1. Une popup demande : "Autoriser les notifications ?"
2. Cliquer sur **Autoriser**
3. Dans les logs Xcode/Terminal :
   ```
   ✅ Permission de notification accordée
   📱 FCM Token obtenu: ...
   ```

## 🎉 C'est tout !

**Votre app iOS fonctionne maintenant !**

### Ce qui marche :

✅ Toute l'application  
✅ Paiements  
✅ Commandes  
✅ Boutique  
✅ Chat  
✅ Notifications locales (quand app ouverte)  

### Ce qui ne marche pas (sans compte payant) :

❌ Push notifications quand app fermée  
❌ Publication App Store  

## 🔄 Workflow recommandé

### Pendant le développement (MAINTENANT)

1. **Focus sur Android pour les push notifications**
   - Android fonctionne normalement sans payer
   - Testez toute la logique backend

2. **iOS : développez tout le reste**
   - Toutes les features marchent
   - Notifications locales OK

3. **Testez régulièrement sur iPhone**
   - Le certificat expire tous les 7 jours
   - Relancez juste `flutter run`

### Avant la production (plus tard)

**Quand vous êtes prêt à publier :**

1. S'inscrire au Apple Developer Program (99$/an)
2. Configurer la clé APNs (voir `IOS_NOTIFICATIONS_SETUP.md`)
3. Tester avec TestFlight
4. Publier sur l'App Store

## 📊 Budget estimé

| Étape | Coût | Quand |
|-------|------|-------|
| **Développement** | 🆓 **GRATUIT** | Maintenant |
| **Tests locaux** | 🆓 **GRATUIT** | Maintenant |
| **Publication App Store** | 💰 99$/an | Plus tard |

## ❓ Questions fréquentes

**Q: Le certificat expire tous les 7 jours, c'est grave ?**  
R: Non ! Il suffit de rebuild l'app. Pendant le développement, ce n'est pas un problème.

**Q: Je peux tester sur combien d'appareils ?**  
R: Maximum 3 appareils avec un compte gratuit.

**Q: Les notifications push vont marcher ?**  
R: Les notifications locales (quand l'app est ouverte) : OUI. Les push (app fermée) : possiblement non ou pas fiable sans clé APNs.

**Q: Android marche normalement ?**  
R: Oui ! Android ne nécessite pas de compte payant. Les push fonctionnent parfaitement.

**Q: Je dois payer maintenant ?**  
R: **NON !** Payez seulement quand vous êtes prêt à publier sur l'App Store (dans plusieurs semaines/mois).

**Q: Et si je change le Bundle ID maintenant ?**  
R: Pas de problème ! C'est juste pour le développement. Vous pourrez utiliser le Bundle ID final quand vous aurez le compte payant.

## 🎯 Résumé

**AUJOURD'HUI (gratuit) :**
- Développez toute l'app iOS
- Testez sur vos iPhones
- Concentrez-vous sur Android pour les push

**PLUS TARD (99$/an) :**
- Quand tout est prêt
- Juste avant la publication
- Configurez les push iOS en production

## 📚 Guides complets

- **`IOS_NOTIFICATIONS_FREE_DEV.md`** - Guide détaillé développement gratuit
- **`IOS_NOTIFICATIONS_SETUP.md`** - Guide complet avec compte payant
- **`IOS_NOTIFICATIONS_QUICK_START.md`** - Quick start avec compte payant

---

**Vous êtes prêt ! Commencez à développer ! 🚀**
