# 📱 SMS avec HSMS.ci - Guide Rapide

## ✅ Ce qui a été fait

### Fichiers créés :
1. **`src/services/smsService.js`** - Service d'envoi de SMS via HSMS.ci
2. **`Scripts-api/test-hsms-sms.js`** - Script de test
3. **`INTEGRATION_HSMS_SMS.md`** - Documentation complète

### Fichiers modifiés :
1. **`src/controllers/auth/authController.js`** - Ajout de l'envoi par SMS
2. **`.env`** - Ajout des variables HSMS.ci

### Fonctionnalités :
- ✅ Envoi de codes de vérification par SMS (inscription)
- ✅ Envoi de codes de réinitialisation par SMS (mot de passe oublié)
- ✅ Fallback automatique vers email si SMS échoue
- ✅ Formatage automatique des numéros de téléphone
- ✅ Validation des numéros ivoiriens
- ✅ Vérification du solde SMS

---

## 🚀 Prochaines étapes

### Étape 1 : Créer un compte HSMS.ci (5 min)

1. Aller sur https://hsms.ci/inscription
2. Remplir le formulaire :
   - Nom, prénom
   - Email
   - Téléphone (format: 2250170793131)
3. Valider l'inscription

### Étape 2 : Acheter un pack SMS (5 min)

**Recommandation pour débuter** : Pack Test (500 FCFA, 30 SMS)

1. Se connecter sur https://hsms.ci/connexion
2. Cliquer sur **Acheter un Pack**
3. Choisir le **Pack Test**
4. Payer par Mobile Money ou carte bancaire

**Autres packs disponibles** :
- Starter : 2 500 FCFA → 150 SMS
- Argent : 12 000 FCFA → 750 SMS
- Elephant Lite : 120 000 FCFA → 10 000 SMS

### Étape 3 : Récupérer la clé API (2 min)

⚠️ **Important** : HSMS.ci demande de créer une **application** pour obtenir la clé API.

1. Sur le tableau de bord HSMS.ci
2. Aller dans **Applications** → **Créer une application**
3. Remplir les informations :

| Champ | Valeur à entrer |
|-------|-----------------|
| **Nom** | SMART MAINTENANCE |
| **Description** | Codes de vérification et notifications |
| **URL de notification** | `http://192.168.1.139:3000/api/sms/notification` |
| **URL de stop** | `http://192.168.1.139:3000/api/sms/stop` |

4. Valider la création
5. Copier votre **API Key** (clé d'authentification)

**Explications des URLs** :
- **URL de notification** : Reçoit les statuts des SMS (livré, échoué)
- **URL de stop** : Gère les désabonnements (quand un utilisateur répond "STOP")

📝 **Note** : Utilisez votre vraie IP locale (pas `localhost`). Pour la trouver :
```bash
ipconfig getifaddr en0    # macOS
# ou
ipconfig                   # Windows
```

💡 **Voir le guide complet** : [HSMS_URLS_CONFIGURATION.md](HSMS_URLS_CONFIGURATION.md)

### Étape 4 : Configurer le projet (1 min)

Éditer `/Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/.env` :

```env
# HSMS.ci Configuration
USE_SMS_VERIFICATION=true
HSMS_API_URL=https://api.hsms.ci/api/v1
HSMS_API_KEY=votre_cle_api_ici
HSMS_SENDER_NAME=MCT-MAINT
```

⚠️ **Important** : Remplacer `votre_cle_api_ici` par votre vraie clé API

### Étape 5 : Tester (2 min)

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api

# Vérifier le solde
node Scripts-api/test-hsms-sms.js 0170793131 balance

# Tester l'envoi d'un SMS
node Scripts-api/test-hsms-sms.js 0170793131 verification
```

**Note** : Remplacer `0170793131` par votre vrai numéro de téléphone

**Résultat attendu** :
```
✅ SMS de vérification envoyé avec succès !
   Message ID: xxx
   Statut: sent
```

### Étape 6 : Lancer le backend (1 min)

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api
node src/server.js
```

Vérifier dans les logs :
```
✅ Configuration HSMS.ci chargée
```

### Étape 7 : Tester dans l'app (5 min)

1. Lancer l'app Flutter :
   ```bash
   cd /Users/bassoued/Documents/MAINTENANCE/mct_maintenance_mobile
   flutter run
   ```

2. S'inscrire avec un numéro de téléphone valide

3. Vérifier que vous recevez le SMS avec le code

4. Entrer le code pour activer le compte

---

## 🎯 Comment ça marche ?

### Avant (Email uniquement)

```
Inscription → Code par EMAIL → Vérification
```

### Maintenant (SMS avec fallback)

```
Inscription → Code par SMS → Vérification
                ↓ (si échec)
            Code par EMAIL
```

**Avantages** :
- ✅ Réception instantanée (SMS)
- ✅ Pas besoin de connexion Internet (pour recevoir)
- ✅ Taux d'ouverture 98% (vs 20% pour email)
- ✅ Fallback automatique si problème

---

## 📱 Format des SMS envoyés

### Code de vérification (inscription)

```
Bonjour Jean,

Votre code de verification SMART MAINTENANCE est :

654321

Ce code expire dans 15 minutes.

Ne partagez jamais ce code avec quelqu'un.
```

### Code de réinitialisation (mot de passe)

```
Bonjour Jean,

Votre code de reinitialisation SMART MAINTENANCE :

123456

Ce code expire dans 15 minutes.

Si vous n'avez pas demande cette reinitialisation, ignorez ce message.
```

---

## 🔧 Activer/Désactiver les SMS

### Activer les SMS
```env
USE_SMS_VERIFICATION=true
```

### Désactiver les SMS (retour à l'email)
```env
USE_SMS_VERIFICATION=false
```

Pas besoin de redémarrer le serveur, le changement est automatique.

---

## 💰 Coûts

### Tarifs HSMS.ci

- Pack Test : **500 FCFA** = 30 SMS (≈ 17 FCFA/SMS)
- Pack Starter : **2 500 FCFA** = 150 SMS (≈ 17 FCFA/SMS)
- Pack Argent : **12 000 FCFA** = 750 SMS (≈ 16 FCFA/SMS)
- Pack Elephant : **120 000 FCFA** = 10 000 SMS (≈ 12 FCFA/SMS)

### Estimation mensuelle

**Scénario 1** : 100 nouveaux utilisateurs/mois
- 100 SMS de vérification
- 20 SMS de réinitialisation
- **Total** : 120 SMS/mois = **2 040 FCFA/mois** (Pack Argent)

**Scénario 2** : 500 nouveaux utilisateurs/mois
- 500 SMS de vérification
- 100 SMS de réinitialisation
- **Total** : 600 SMS/mois = **10 200 FCFA/mois** (Pack Argent)

---

## 🚨 Dépannage

### Problème 1 : "HSMS_API_KEY non configurée"

**Solution** :
```bash
# Vérifier le fichier .env
cat /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/.env | grep HSMS

# Si vide, ajouter :
echo "HSMS_API_KEY=votre_cle_api" >> .env
```

### Problème 2 : "Invalid phone number"

**Cause** : Format de numéro incorrect

**Solution** : Les numéros sont automatiquement formatés. Assurez-vous que l'utilisateur entre un numéro ivoirien valide (10 chiffres commençant par 0).

### Problème 3 : "Insufficient credits"

**Solution** : Recharger les crédits sur https://hsms.ci/

### Problème 4 : SMS non reçu

**Vérifications** :
1. Le numéro est-il correct ?
2. Le téléphone a-t-il du réseau ?
3. Vérifier les logs du backend (📱 emoji)
4. Vérifier le solde SMS : `node Scripts-api/test-hsms-sms.js 0170793131 balance`

---

## 📞 Contact

### Support HSMS.ci
- **Email** : support@hsms.ci
- **Téléphone** : +225 05 84 20 80 80
- **Site** : https://hsms.ci/

### Documentation complète
Voir [INTEGRATION_HSMS_SMS.md](INTEGRATION_HSMS_SMS.md) pour tous les détails techniques.

---

## ✅ Checklist rapide

- [ ] Compte HSMS.ci créé
- [ ] Pack SMS acheté
- [ ] Clé API récupérée
- [ ] `.env` configuré avec la clé
- [ ] `USE_SMS_VERIFICATION=true`
- [ ] Test du script : `node Scripts-api/test-hsms-sms.js`
- [ ] Backend démarré
- [ ] Test d'inscription avec SMS reçu

**Temps total** : ~20 minutes

---

**Bonne chance avec l'intégration ! 📱✨**
