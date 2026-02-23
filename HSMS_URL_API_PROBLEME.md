# 🔍 Trouver l'URL de l'API HSMS.ci

## ❌ Problème actuel

Erreur : `ENOTFOUND api.hsms.ci` ou `ENOTFOUND app.hsms.ci`

**Cause** : L'URL de l'API HSMS.ci n'est pas la bonne.

---

## ✅ Comment trouver la bonne URL

### Étape 1 : Se connecter à HSMS.ci

1. Aller sur https://hsms.ci/connexion
2. Se connecter avec votre compte

### Étape 2 : Chercher la documentation API

Une fois connecté, cherchez :

- **Documentation API** dans le menu
- **Intégration** dans les paramètres
- **API** ou **Développeurs** dans le tableau de bord

### Étape 3 : Récupérer l'URL de l'API

La documentation devrait indiquer l'URL de base de l'API, qui peut être :

**Possibilités courantes** :
- `https://hsms.ci/api/v1`
- `https://www.hsms.ci/api/v1`
- `https://api.hsms.ci/v1`
- `https://sms.hsms.ci/api/v1`
- Un sous-domaine spécifique fourni dans votre compte

### Étape 4 : Tester l'URL

Une fois l'URL trouvée, testez-la avec curl :

```bash
# Remplacer <URL_API> par l'URL trouvée
curl -X POST <URL_API>/send \
  -H "Content-Type: application/json" \
  -d '{
    "token": "votre_token",
    "sender": "TEST",
    "recipient": "2250708205263",
    "message": "Test API",
    "type": "simple"
  }'
```

Si l'URL est correcte, vous devriez recevoir une réponse (même si elle indique une erreur d'authentification).

Si l'URL est incorrecte, vous aurez : `Could not resolve host`

---

## 🔧 Mettre à jour la configuration

Une fois l'URL correcte trouvée, mettez à jour le fichier `.env` :

```bash
# Éditer le fichier .env
nano /Users/bassoued/Documents/MAINTENANCE/mct-maintenance-api/.env

# Changer la ligne :
HSMS_API_URL=https://la_vraie_url_ici/api/v1
```

Puis testez à nouveau :

```bash
node Scripts-api/test-hsms-sms.js 2250708205263 verification
```

---

## 📞 Contacter le support HSMS.ci

Si vous ne trouvez pas l'URL dans la documentation :

**Email** : support@hsms.ci  
**Téléphone** : +225 05 84 20 80 80  
**WhatsApp** : +225 05 84 20 80 80

**Message type** :
```
Bonjour,

Je souhaite intégrer l'API HSMS.ci pour l'envoi de SMS dans mon application.
J'ai créé mon application et récupéré mon token, mais je ne trouve pas 
l'URL de base de l'API.

Pouvez-vous me communiquer :
- L'URL de base de l'API
- Les endpoints disponibles (envoi SMS, vérification solde)
- La documentation complète de l'API

Merci,
[Votre nom]
```

---

## 🧪 URLs à tester

En attendant la réponse du support, vous pouvez tester ces URLs :

```bash
# Test 1
curl https://hsms.ci/api/v1/send

# Test 2
curl https://www.hsms.ci/api/v1/send

# Test 3
curl https://api.hsms.ci/v1/send

# Test 4 (URL du site principal)
curl https://hsms.ci/api/send
```

**Si une URL répond** (même avec une erreur 401 ou 403), c'est la bonne !

**Exemple de bonne réponse** :
```json
{"error": "Unauthorized", "message": "Token invalide"}
```

**Exemple de mauvaise URL** :
```
curl: (6) Could not resolve host: api.hsms.ci
```

---

## ⚙️ Configuration alternative : Webhook uniquement

Si l'API d'envoi ne fonctionne pas, vous pouvez :

1. **Désactiver l'envoi automatique** dans `.env` :
   ```env
   USE_SMS_VERIFICATION=false
   ```

2. **Envoyer les SMS manuellement** depuis le dashboard HSMS.ci

3. **Garder les webhooks actifs** pour recevoir les statuts

Cette solution temporaire vous permet de continuer le développement en attendant la résolution du problème d'API.

---

## 📋 Checklist

- [ ] Se connecter sur https://hsms.ci/
- [ ] Chercher la documentation API
- [ ] Récupérer l'URL de l'API
- [ ] Tester l'URL avec curl
- [ ] Mettre à jour le .env avec la bonne URL
- [ ] Re-tester avec le script
- [ ] Si problème : Contacter le support HSMS.ci

---

**Status actuel** : ⏳ En attente de l'URL correcte de l'API HSMS.ci
