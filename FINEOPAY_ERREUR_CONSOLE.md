# 🔍 Erreur détectée dans la console navigateur - FineoPay

## Pour l'équipe technique FineoPay

---

## 📍 Contexte

Business Code: `smart_maintenance_by_mct`  
Environnement: Sandbox/Dev

---

## ✅ Ce qui fonctionne

Notre backend génère correctement le checkout link :

```bash
POST https://dev.fineopay.com/api/v1/business/dev/checkout-link
Headers:
  businessCode: smart_maintenance_by_mct
  apiKey: fpay_5feda0bf5d62257365c70b73f1aa0c6d098f80dbcf788ff8a4c48a661923

Réponse: ✅
{
  "success": true,
  "message": "Lien de paiement généré avec succès",
  "data": {
    "checkoutLink": "https://demo.fineopay.com/smart_maintenance_by_mct/xxx/checkout"
  }
}
```

---

## ❌ Le problème

Lorsqu'on ouvre le `checkoutLink` dans un navigateur, votre **page de checkout** affiche :

```
🔴 Erreur interne du serveur.
```

---

## 🐛 Erreur dans la console du navigateur (F12)

Votre page de checkout fait une **requête JavaScript interne** qui échoue :

### Requête détectée :

```
POST https://dev.fineopay.com/api/v1/business/checkout/payin
Status: 500 OK
```

### Erreur retournée :

```json
{
  "success": false,
  "message": "Erreur interne du serveur.",
  "error": "Internal Error"
}
```

### Headers de la requête (vus dans Network tab) :

```
Headers:
  normalizedNames: Map(0)
  lazyUpdate: null
  lazyInit: ƒ

Message: 
  "Http failure response for https://dev.fineopay.com/api/v1/business/checkout/payin: 500 OK"

Status: 500
StatusText: "OK"
URL: "https://dev.fineopay.com/api/v1/business/checkout/payin"
```

---

## 🧪 Test manuel de l'endpoint

Nous avons testé l'endpoint `/checkout/payin` manuellement :

```bash
curl -X POST https://dev.fineopay.com/api/v1/business/checkout/payin \
  -H "Content-Type: application/json" \
  -d '{
    "businessCode": "smart_maintenance_by_mct",
    "apiKey": "fpay_5feda0bf5d62257365c70b73f1aa0c6d098f80dbcf788ff8a4c48a661923",
    "canal": "WEB",
    "title": "Test",
    "amount": 1000,
    "callbackUrl": "http://192.168.1.139:3000/api/fineopay/callback",
    "syncRef": "TEST"
  }'
```

**Réponse :**
```json
{
  "success": false,
  "message": "clientAccount must be a string",
  "error": "Bad Request"
}
```

→ L'endpoint existe mais demande des champs supplémentaires (`clientAccount`, etc.)

---

## 📊 Analyse

### Ce qui est clair :

1. ✅ Notre backend génère correctement les liens via `/checkout-link`
2. ✅ L'API FineoPay accepte nos requêtes et retourne un `checkoutLink`
3. ❌ La **page de checkout FineoPay** (votre frontend) crashe
4. ❌ Votre page tente d'appeler `/checkout/payin` mais reçoit une erreur 500

### Hypothèses possibles :

1. **Bug dans votre page de checkout**
   - La requête à `/checkout/payin` est mal formée
   - Paramètres manquants ou incorrects

2. **Configuration de compte manquante**
   - Notre business code n'a pas accès à l'endpoint `/checkout/payin`
   - Champs obligatoires manquants dans notre profil

3. **Problème serveur**
   - L'endpoint `/checkout/payin` a un bug côté serveur
   - Erreur 500 = problème interne FineoPay

---

## ❓ Questions pour votre équipe

1. **L'endpoint `/checkout/payin` est-il fonctionnel ?**
   - Pouvez-vous vérifier vos logs serveur ?
   - Y a-t-il des erreurs dans vos logs pour notre businessCode ?

2. **Quels sont les champs requis pour `/checkout/payin` ?**
   - Documentation disponible ?
   - Format exact attendu ?

3. **Notre compte est-il correctement configuré ?**
   - Avons-nous accès à cet endpoint ?
   - Configuration manquante dans votre dashboard ?

4. **Votre page de checkout envoie-t-elle les bons paramètres ?**
   - Peut-être un bug dans le code JavaScript de votre page ?

---

## 🎯 Actions requises

Pour débloquer l'intégration, il faut :

1. **Corriger l'erreur 500** sur `/checkout/payin`
2. **OU** configurer notre compte différemment
3. **OU** utiliser un autre endpoint pour la page de checkout

---

## 📸 Captures d'écran

Vous pouvez reproduire l'erreur facilement :

1. Générer un checkout link avec votre API
2. Ouvrir le link dans Chrome/Firefox
3. Appuyer sur **F12** (DevTools)
4. Onglet **Network**
5. Voir la requête à `/checkout/payin` échouer avec 500

---

## 📞 Contact

**Projet:** Smart Maintenance by MCT  
**Business Code:** smart_maintenance_by_mct  
**Date:** 9 février 2026

Merci de vérifier vos logs serveur et de nous indiquer la cause de l'erreur 500 ! 🙏

---

**Note importante:**  
Cette erreur NE VIENT PAS de notre code. C'est votre page de checkout (JavaScript FineoPay) qui fait cette requête et qui reçoit l'erreur 500.
