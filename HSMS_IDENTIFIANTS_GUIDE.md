# 🔑 Identifiants HSMS.ci - Guide d'utilisation

## 📋 Les 3 identifiants fournis par HSMS.ci

Quand vous créez une application sur HSMS.ci, ils vous fournissent **3 identifiants** :

### 1. **Client ID** (Identifiant Client)
- **C'est quoi ?** Un identifiant public de votre application
- **Format** : Chaîne alphanumérique (ex: `client_abc123`)
- **Usage** : Utilisé avec le Client Secret pour l'authentification

### 2. **Client Secret** (Secret Client)
- **C'est quoi ?** Une clé secrète privée
- **Format** : Chaîne longue et complexe
- **⚠️ IMPORTANT** : Ne jamais partager publiquement
- **Usage** : Utilisé avec le Client ID pour générer un token

### 3. **Token** (Jeton d'accès)
- **C'est quoi ?** Un token d'authentification pré-généré
- **Format** : JWT ou chaîne longue
- **Usage** : Authentification directe sans besoin de Client ID/Secret

---

## ✅ Quelle méthode choisir ?

### Méthode 1 : TOKEN (✅ Recommandé)

**Utilisez le TOKEN si HSMS.ci vous en fournit un.**

**Avantages** :
- ✅ Plus simple (1 seule variable)
- ✅ Plus rapide (pas de génération de token)
- ✅ Plus sécurisé (token peut avoir une durée limitée)

**Configuration `.env`** :
```env
USE_SMS_VERIFICATION=true
HSMS_API_URL=https://api.hsms.ci/api/v1
HSMS_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
HSMS_SENDER_NAME=MCT-MAINT
```

**Ne pas configurer** :
```env
# HSMS_CLIENT_ID=...     # Laisser commenté
# HSMS_CLIENT_SECRET=... # Laisser commenté
```

---

### Méthode 2 : Client ID + Secret

**Utilisez cette méthode si HSMS.ci ne fournit PAS de token.**

**Avantages** :
- ✅ Génération dynamique de tokens
- ✅ Contrôle des permissions

**Configuration `.env`** :
```env
USE_SMS_VERIFICATION=true
HSMS_API_URL=https://api.hsms.ci/api/v1
HSMS_CLIENT_ID=votre_client_id_ici
HSMS_CLIENT_SECRET=votre_client_secret_ici
HSMS_SENDER_NAME=MCT-MAINT
```

**Ne pas configurer** :
```env
# HSMS_TOKEN=...  # Laisser commenté
```

---

## 📝 Configuration dans votre fichier .env

### Option 1 : Avec TOKEN (recommandé)

Ouvrez `/Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/.env` :

```env
# HSMS.ci Configuration (SMS)
USE_SMS_VERIFICATION=true
HSMS_API_URL=https://api.hsms.ci/api/v1
HSMS_SENDER_NAME=MCT-MAINT

# Utiliser le TOKEN directement
HSMS_TOKEN=copiez_votre_token_ici
```

### Option 2 : Avec Client ID + Secret

```env
# HSMS.ci Configuration (SMS)
USE_SMS_VERIFICATION=true
HSMS_API_URL=https://api.hsms.ci/api/v1
HSMS_SENDER_NAME=MCT-MAINT

# Utiliser Client ID + Secret
HSMS_CLIENT_ID=copiez_votre_client_id_ici
HSMS_CLIENT_SECRET=copiez_votre_client_secret_ici
```

---

## 🔍 Comment le code gère les deux méthodes

Le code a été mis à jour pour supporter **les deux méthodes automatiquement** :

```javascript
// Dans smsService.js
if (HSMS_TOKEN) {
  // ✅ Si TOKEN existe, on l'utilise (priorité)
  requestData.token = HSMS_TOKEN;
} else {
  // ✅ Sinon, on utilise Client ID + Secret
  requestData.client_id = HSMS_CLIENT_ID;
  requestData.client_secret = HSMS_CLIENT_SECRET;
}
```

**Priorité** : TOKEN > Client ID+Secret

---

## 🧪 Tester votre configuration

### Étape 1 : Vérifier que les identifiants sont chargés

```bash
cd /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api

# Vérifier les variables
node -e "require('dotenv').config(); console.log('TOKEN:', process.env.HSMS_TOKEN ? '✅ Configuré' : '❌ Non configuré'); console.log('CLIENT_ID:', process.env.HSMS_CLIENT_ID ? '✅ Configuré' : '❌ Non configuré');"
```

**Résultat attendu (avec TOKEN)** :
```
TOKEN: ✅ Configuré
CLIENT_ID: ❌ Non configuré
```

**Résultat attendu (avec Client ID+Secret)** :
```
TOKEN: ❌ Non configuré
CLIENT_ID: ✅ Configuré
```

### Étape 2 : Tester l'envoi de SMS

```bash
# Remplacer 0170793131 par votre numéro
node Scripts-api/test-hsms-sms.js 0170793131 verification
```

**Si TOKEN est configuré** :
```
📱 Envoi SMS vers 2250170793131 via HSMS.ci...
✅ SMS envoyé avec succès: {...}
```

**Si Client ID+Secret sont configurés** :
```
📱 Envoi SMS vers 2250170793131 via HSMS.ci...
✅ SMS envoyé avec succès: {...}
```

**Si rien n'est configuré** :
```
❌ Erreur: HSMS: Configurez soit HSMS_TOKEN, soit HSMS_CLIENT_ID + HSMS_CLIENT_SECRET
```

---

## 📊 Comparaison des méthodes

| Critère | TOKEN | Client ID + Secret |
|---------|-------|-------------------|
| **Simplicité** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Sécurité** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Performance** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Flexibilité** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Recommandé ?** | ✅ OUI | ⚠️ Si pas de TOKEN |

---

## 🔐 Sécurité

### Ne jamais commiter les identifiants

Le fichier `.env` est dans `.gitignore`, mais soyez vigilant :

```bash
# Vérifier que .env est ignoré
git status | grep .env

# Si .env apparaît, ajoutez-le à .gitignore
echo ".env" >> .gitignore
```

### Régénérer les identifiants si compromis

Si vous avez accidentellement partagé vos identifiants :

1. Aller sur https://hsms.ci/connexion
2. Aller dans **Applications** → Votre application
3. Cliquer sur **Régénérer le token** ou **Régénérer les secrets**
4. Mettre à jour le `.env` avec les nouveaux identifiants

---

## 🆘 Dépannage

### Problème 1 : "HSMS: Configurez soit HSMS_TOKEN..."

**Cause** : Aucun identifiant n'est configuré

**Solution** : Ajouter soit `HSMS_TOKEN`, soit `HSMS_CLIENT_ID` + `HSMS_CLIENT_SECRET` dans `.env`

### Problème 2 : "Invalid token" ou "Unauthorized"

**Cause** : Token expiré ou invalide

**Solutions** :
1. Vérifier que le token est correct (pas de caractères manquants)
2. Vérifier qu'il n'y a pas d'espaces avant/après le token
3. Régénérer le token sur HSMS.ci

### Problème 3 : "Invalid client credentials"

**Cause** : Client ID ou Secret incorrect

**Solutions** :
1. Vérifier les identifiants sur https://hsms.ci/
2. S'assurer qu'ils sont copiés entièrement
3. Vérifier qu'il n'y a pas d'espaces parasites

---

## 📚 Résumé

### Pour démarrer rapidement :

1. **Récupérer les identifiants sur HSMS.ci**
2. **Choisir la méthode** :
   - TOKEN disponible ? → Utiliser le TOKEN ✅
   - Pas de TOKEN ? → Utiliser Client ID + Secret
3. **Configurer `.env`** avec les bons identifiants
4. **Tester** : `node Scripts-api/test-hsms-sms.js 0170793131 verification`

### Variables à configurer :

**Option TOKEN (recommandé)** :
```env
HSMS_TOKEN=votre_token
```

**Option Client ID + Secret** :
```env
HSMS_CLIENT_ID=votre_client_id
HSMS_CLIENT_SECRET=votre_secret
```

---

**Besoin d'aide ?** Consultez [INTEGRATION_HSMS_SMS.md](INTEGRATION_HSMS_SMS.md) pour plus de détails.
