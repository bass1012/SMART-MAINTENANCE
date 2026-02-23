# 📱 Intégration HSMS.ci pour l'envoi de SMS

## Vue d'ensemble

HSMS.ci est une plateforme ivoirienne d'envoi de SMS en masse qui permet d'envoyer des codes de vérification, des notifications et des alertes par SMS.

**Site officiel**: https://hsms.ci/  
**Contact**: support@hsms.ci | +225 05 84 20 80 80

---

## 🎯 Utilisation dans l'application

### Codes de vérification par SMS

Au lieu d'envoyer les codes de vérification par email, ils sont maintenant envoyés par **SMS** si :
1. L'utilisateur a un numéro de téléphone
2. La variable `USE_SMS_VERIFICATION=true` est configurée dans `.env`

**Cas d'usage** :
- ✅ Inscription : Code de vérification à 6 chiffres par SMS
- ✅ Réinitialisation de mot de passe : Code par SMS
- ⏸️ Fallback email : Si le SMS échoue, le système envoie un email automatiquement

---

## 🔑 Configuration initiale

### Étape 1 : Créer un compte HSMS.ci

1. Aller sur https://hsms.ci/inscription
2. Créer un compte avec :
   - Nom et prénom
   - Email
   - Numéro de téléphone (format: 2250170793131)
3. Se connecter au tableau de bord

### Étape 2 : Acheter un pack SMS

**Tarifs disponibles** :

| Pack | Prix | SMS inclus | Validité |
|------|------|------------|----------|
| Test | 500 FCFA | 30 SMS | 100 jours |
| Starter | 2 500 FCFA | 150 SMS | 365 jours |
| Argent | 12 000 FCFA | 750 SMS | 365 jours |
| Elephant Lite | 120 000 FCFA | 10 000 SMS | 365 jours |

**Recommandation** : Commencer avec le pack **Test** pour essayer.

### Étape 3 : Récupérer la clé API

1. Se connecter sur https://hsms.ci/connexion
2. Aller dans **Paramètres** → **API**
3. Copier votre **API Key** (clé d'authentification)

### Étape 4 : Configurer dans le projet

Éditer le fichier `.env` :

```env
# HSMS.ci Configuration
USE_SMS_VERIFICATION=true
HSMS_API_URL=https://api.hsms.ci/api/v1
HSMS_API_KEY=votre_cle_api_hsms_ici
HSMS_SENDER_NAME=MCT-MAINT
```

**Notes** :
- `USE_SMS_VERIFICATION=true` : Active l'envoi par SMS
- `USE_SMS_VERIFICATION=false` : Conserve l'envoi par email
- `HSMS_SENDER_NAME` : Nom qui apparaît comme expéditeur (max 11 caractères)

---

## 📡 Fichiers créés/modifiés

### 1. Service SMS (`src/services/smsService.js`)

Fonctions disponibles :
```javascript
// Envoyer un code de vérification
await sendVerificationCodeSMS(phoneNumber, code, firstName);

// Envoyer un code de réinitialisation
await sendPasswordResetCodeSMS(phoneNumber, code, firstName);

// Envoyer un SMS générique
await sendSMS(phoneNumber, message);

// Vérifier le solde
await checkSMSBalance();

// Formater un numéro
const formatted = formatPhoneNumber('0170793131'); // → 2250170793131

// Valider un numéro ivoirien
const isValid = isValidIvoryCoastPhone('0170793131'); // → true
```

### 2. Contrôleur d'authentification modifié

**Fichier** : `src/controllers/auth/authController.js`

**Modifications** :
- Import du service SMS
- Fonction `register()` : Envoie le code par SMS si disponible
- Fonction `requestResetCode()` : Envoie le code par SMS si disponible
- Fallback automatique vers email en cas d'échec SMS

### 3. Variables d'environnement

**Fichier** : `.env`

Nouvelles variables ajoutées :
```env
USE_SMS_VERIFICATION=true
HSMS_API_URL=https://api.hsms.ci/api/v1
HSMS_API_KEY=your_hsms_api_key_here
HSMS_SENDER_NAME=MCT-MAINT
```

### 4. Script de test

**Fichier** : `Scripts-api/test-hsms-sms.js`

**Usage** :
```bash
# Test d'envoi d'un code de vérification
node Scripts-api/test-hsms-sms.js 0170793131 verification

# Test d'envoi d'un code de réinitialisation
node Scripts-api/test-hsms-sms.js 0170793131 reset

# Vérifier le solde SMS
node Scripts-api/test-hsms-sms.js 0170793131 balance
```

---

## 🔄 Flux de fonctionnement

### Inscription avec SMS

```
1. Utilisateur s'inscrit avec email + téléphone
   ↓
2. Backend génère un code à 6 chiffres
   ↓
3. Backend vérifie :
   - USE_SMS_VERIFICATION=true ?
   - L'utilisateur a un téléphone ?
   ↓
4. SI OUI → Envoi SMS via HSMS.ci
   SI NON → Envoi email
   ↓
5. En cas d'échec SMS → Fallback email automatique
   ↓
6. Utilisateur reçoit le code
   ↓
7. Utilisateur entre le code dans l'app
   ↓
8. Backend vérifie le code
   ↓
9. Compte activé ✅
```

### Réinitialisation de mot de passe

```
1. Utilisateur demande réinitialisation
   ↓
2. Backend génère un code à 6 chiffres
   ↓
3. Backend vérifie le téléphone
   ↓
4. Envoi SMS (ou email en fallback)
   ↓
5. Utilisateur entre le code
   ↓
6. Mot de passe réinitialisé ✅
```

---

## 📱 Format des SMS

### Code de vérification

```
Bonjour Jean,

Votre code de verification SMART MAINTENANCE est :

654321

Ce code expire dans 15 minutes.

Ne partagez jamais ce code avec quelqu'un.
```

### Code de réinitialisation

```
Bonjour Jean,

Votre code de reinitialisation SMART MAINTENANCE :

123456

Ce code expire dans 15 minutes.

Si vous n'avez pas demande cette reinitialisation, ignorez ce message.
```

**Note** : Les accents sont supprimés pour la compatibilité SMS.

---

## 🧪 Tests

### 1. Tester l'envoi de SMS

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api

# Installer les dépendances (si besoin)
npm install axios

# Tester l'envoi d'un SMS
node Scripts-api/test-hsms-sms.js 0170793131 verification
```

**Résultat attendu** :
```
✅ SMS de vérification envoyé avec succès !
   Message ID: xxx
   Statut: sent
```

### 2. Vérifier le solde

```bash
node Scripts-api/test-hsms-sms.js 0170793131 balance
```

**Résultat attendu** :
```
✅ Solde récupéré avec succès:
   Crédits disponibles: 30 SMS
```

### 3. Tester dans l'application

**Inscription** :
1. Lancer le backend : `node src/server.js`
2. Lancer l'app Flutter
3. S'inscrire avec un numéro de téléphone valide
4. Vérifier que le SMS est reçu

**Réinitialisation** :
1. Demander réinitialisation de mot de passe
2. Vérifier que le SMS est reçu avec le code
3. Entrer le code
4. Changer le mot de passe

---

## ⚙️ API HSMS.ci

### Endpoint d'envoi

**URL** : `POST https://api.hsms.ci/api/v1/send`

**Headers** :
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Body** :
```json
{
  "api_key": "votre_cle_api",
  "sender": "MCT-MAINT",
  "recipient": "2250170793131",
  "message": "Votre code: 123456",
  "type": "simple"
}
```

**Réponse (succès)** :
```json
{
  "success": true,
  "message_id": "xxx",
  "status": "sent"
}
```

### Endpoint de vérification du solde

**URL** : `GET https://api.hsms.ci/api/v1/balance`

**Headers** :
```json
{
  "Authorization": "Bearer votre_cle_api",
  "Content-Type": "application/json"
}
```

**Réponse** :
```json
{
  "success": true,
  "balance": 30,
  "credits": 30
}
```

**Note** : L'API exacte peut varier. Consultez la documentation officielle HSMS.ci une fois connecté.

---

## 📞 Format des numéros de téléphone

### Format accepté par HSMS.ci

**Format requis** : `2250170793131` (indicatif pays + numéro sans espaces)

**Exemples de conversion** :
```
0170793131      → 2250170793131  ✅
+225 01 70 79 31 31 → 2250170793131  ✅
225 0170793131  → 2250170793131  ✅
01-70-79-31-31  → 2250170793131  ✅
```

Le service `formatPhoneNumber()` gère automatiquement ces conversions.

### Validation

Un numéro ivoirien valide doit :
- Commencer par **225** (indicatif Côte d'Ivoire)
- Suivi de **10 chiffres**
- Total : **13 chiffres**

**Exemples valides** :
- `2250170793131` ✅
- `2250570793131` ✅
- `2250770793131` ✅

**Exemples invalides** :
- `0170793131` (trop court, mais sera converti automatiquement)
- `33612345678` (indicatif France) ❌
- `225123` (trop court) ❌

---

## 💰 Gestion des crédits SMS

### Surveiller le solde

**Méthode 1** : Via le script
```bash
node Scripts-api/test-hsms-sms.js 0170793131 balance
```

**Méthode 2** : Via le tableau de bord HSMS.ci
- Se connecter sur https://hsms.ci/connexion
- Le solde est affiché en haut de la page

### Recharger les crédits

1. Se connecter sur https://hsms.ci/connexion
2. Cliquer sur **Acheter un Pack**
3. Choisir le pack souhaité
4. Payer par :
   - Mobile Money (Orange Money, MTN, Moov)
   - Carte bancaire

**Note** : Les crédits sont cumulables et valables 365 jours (sauf pack Test : 100 jours)

---

## 🔐 Sécurité

### Bonnes pratiques

1. **Ne jamais commiter la clé API** :
   - La clé est dans `.env` qui est dans `.gitignore`
   - Ne jamais partager la clé publiquement

2. **Limiter les envois** :
   - Maximum 1 SMS de vérification par utilisateur par minute
   - Maximum 3 tentatives de réinitialisation par heure

3. **Valider les numéros** :
   - Toujours utiliser `formatPhoneNumber()` avant envoi
   - Vérifier avec `isValidIvoryCoastPhone()` pour les numéros CI

4. **Logs** :
   - Ne pas logger les codes complets en production
   - Logger uniquement les 3 premiers chiffres : `123***`

---

## 🚨 Gestion des erreurs

### Erreurs courantes

| Erreur | Cause | Solution |
|--------|-------|----------|
| `HSMS_API_KEY non configurée` | Variable manquante | Ajouter dans `.env` |
| `Invalid phone number` | Format incorrect | Utiliser `formatPhoneNumber()` |
| `Insufficient credits` | Solde épuisé | Recharger les crédits |
| `API timeout` | Serveur HSMS.ci lent | Réessayer après 30s |
| `Invalid sender name` | Nom > 11 caractères | Réduire à 11 max |

### Fallback automatique

Si l'envoi SMS échoue, le système envoie automatiquement un **email** :

```javascript
// Dans authController.js
if (useSMS) {
  try {
    const smsResult = await sendVerificationCodeSMS(...);
    if (smsResult.success) {
      return res.json({ success: true, method: 'sms' });
    }
  } catch (error) {
    console.log('📧 Fallback: envoi par email...');
  }
}

// Continuer avec l'email
const mailResult = await sendEmail(...);
```

---

## 🎯 Prochaines améliorations

### 1. Notifications par SMS

Envoyer des notifications pour :
- ✅ Nouvelle intervention assignée
- ✅ Changement de statut d'intervention
- ✅ Rappel de rendez-vous
- ✅ Confirmation de paiement

### 2. SMS marketing

- Campagnes promotionnelles
- Offres spéciales
- Newsletter SMS

### 3. Support multi-opérateurs

HSMS.ci supporte déjà :
- Orange Money CI
- MTN Money CI
- Moov Money CI
- Wave CI

Possibilité d'expansion dans d'autres pays d'Afrique.

### 4. Reporting SMS

- Dashboard de statistiques d'envoi
- Taux de délivrabilité
- Coût par campagne

---

## 📊 Statistiques d'implémentation

- **Fichiers créés** : 2
  - `src/services/smsService.js`
  - `Scripts-api/test-hsms-sms.js`

- **Fichiers modifiés** : 2
  - `src/controllers/auth/authController.js`
  - `.env`

- **Lignes de code** : ~450 lignes
- **Fonctions ajoutées** : 7
- **Temps d'intégration** : ~2 heures

---

## 📞 Support

### Problèmes techniques

1. **Vérifier la configuration** :
   ```bash
   cat .env | grep HSMS
   ```

2. **Tester avec le script** :
   ```bash
   node Scripts-api/test-hsms-sms.js 0170793131 balance
   ```

3. **Consulter les logs** :
   ```bash
   # Dans le terminal du backend
   # Chercher les messages avec 📱 (SMS) ou 📧 (Email)
   ```

### Contact HSMS.ci

- **Email** : support@hsms.ci
- **Téléphone** : +225 05 84 20 80 80
- **WhatsApp** : +225 05 84 20 80 80
- **Adresse** : Angré 7ème tranche, Abidjan, Côte d'Ivoire

### Documentation officielle

Une fois connecté sur https://hsms.ci/, vous trouverez :
- Documentation API complète
- Exemples de code
- FAQ
- Tutoriels vidéo

---

## ✅ Checklist de mise en production

- [ ] Créer un compte HSMS.ci
- [ ] Acheter un pack SMS adapté (recommandation : Argent ou Elephant)
- [ ] Récupérer la clé API
- [ ] Configurer `.env` avec la vraie clé
- [ ] Tester l'envoi avec `test-hsms-sms.js`
- [ ] Vérifier que `USE_SMS_VERIFICATION=true`
- [ ] Tester inscription complète
- [ ] Tester réinitialisation de mot de passe
- [ ] Vérifier les logs d'envoi
- [ ] Configurer une alerte pour solde < 50 SMS
- [ ] Documenter le process pour l'équipe

---

**Date de mise en œuvre** : 21 janvier 2026  
**Statut** : ✅ Prêt pour les tests
