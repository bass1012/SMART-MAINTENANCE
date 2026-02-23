# 🏦 Intégration CinetPay - Documentation

## Vue d'ensemble

CinetPay est un agrégateur de paiement qui permet d'accepter des paiements par **Mobile Money** (Orange Money, MTN Money, Moov Money, Wave) et **cartes bancaires** en Afrique de l'Ouest et Centrale.

---

## 🔑 Configuration initiale

### 1. Créer un compte CinetPay
1. Aller sur https://cinetpay.com
2. Créer un compte marchand
3. Récupérer vos identifiants dans le back-office :
   - **API Key** (apikey)
   - **Site ID** (site_id)

### 2. Configurer les variables d'environnement

Dans `/mct-maintenance-api/.env` :
```env
# Backend URL pour les webhooks CinetPay
BACKEND_URL=http://votre-domaine.com

# CinetPay Configuration
CINETPAY_API_KEY=votre_api_key_ici
CINETPAY_SITE_ID=votre_site_id_ici
```

⚠️ **Important** : 
- En développement : utilisez l'IP publique ou ngrok pour que CinetPay puisse envoyer les notifications
- En production : utilisez votre nom de domaine HTTPS

---

## 🔄 Flux de paiement

### Étape 1 : Initialisation du paiement
```
Mobile App → Backend → CinetPay API
```
- L'app mobile appelle `/api/payments/cinetpay/initialize`
- Le backend génère un `transaction_id` unique
- CinetPay retourne une `payment_url`

### Étape 2 : Paiement
```
Mobile App → Navigateur → Page CinetPay
```
- L'utilisateur est redirigé vers la page de paiement CinetPay
- Il choisit son mode de paiement (Mobile Money ou Carte)
- Il effectue le paiement

### Étape 3 : Notification (Webhook)
```
CinetPay → Backend (notify_url)
```
- CinetPay envoie une notification au backend
- Le backend vérifie le paiement avec l'API CinetPay
- Le statut de la commande est mis à jour

### Étape 4 : Retour à l'app
```
Page CinetPay → Mobile App (return_url)
```
- L'utilisateur est redirigé vers l'app
- L'app vérifie le statut du paiement
- L'utilisateur voit la confirmation

---

## 📡 Endpoints API

### 1. Initialiser un paiement
```http
POST /api/payments/cinetpay/initialize
Authorization: Bearer <token>
Content-Type: application/json

{
  "orderId": 123
}
```

**Réponse (succès) :**
```json
{
  "success": true,
  "message": "Paiement initialisé",
  "data": {
    "payment_url": "https://checkout.cinetpay.com/payment/...",
    "payment_token": "xxx",
    "transaction_id": "ORD-123-1234567890"
  }
}
```

### 2. Webhook de notification (appelé par CinetPay)
```http
POST /api/payments/cinetpay/notify
Content-Type: application/json

{
  "cpm_trans_id": "ORD-123-1234567890",
  "cpm_trans_status": "ACCEPTED",
  "cpm_custom": "{\"orderId\":123}"
}
```

### 3. Vérifier le statut d'un paiement
```http
GET /api/payments/cinetpay/status/:transactionId
Authorization: Bearer <token>
```

---

## 💳 Codes de statut CinetPay

| Code | Description |
|------|-------------|
| `00` | Paiement réussi |
| `01` | Paiement échoué |
| `02` | Paiement en attente |

---

## 🛠️ Utilisation dans Flutter

### Import du service
```dart
import 'package:mct_maintenance_mobile/services/payment_service.dart';
```

### Initialiser un paiement
```dart
final paymentService = PaymentService(_apiService);

try {
  final paymentData = await paymentService.initializeOrderPayment(orderId);
  final paymentUrl = paymentData['payment_url'];
  
  // Ouvrir le lien de paiement
  await paymentService.openPaymentUrl(paymentUrl);
} catch (e) {
  print('Erreur: $e');
}
```

### Vérifier le statut après retour
```dart
final status = await paymentService.checkPaymentStatus(transactionId);

if (status['code'] == '00') {
  // Paiement réussi
  print('✅ Paiement confirmé');
} else {
  // Paiement échoué ou en attente
  print('❌ Paiement échoué');
}
```

---

## 🧪 Tests

### 1. Tester avec CinetPay Sandbox (environnement de test)

CinetPay fournit un environnement de test avec des identifiants sandbox.
Consultez la documentation : https://docs.cinetpay.com

### 2. Tester le webhook localement avec ngrok

```bash
# Installer ngrok
brew install ngrok  # macOS
# ou télécharger depuis https://ngrok.com

# Exposer le backend local
ngrok http 3000

# Utiliser l'URL ngrok dans .env
BACKEND_URL=https://xxxx.ngrok.io
```

Puis configurer cette URL dans le back-office CinetPay pour les notifications.

### 3. Script de test du webhook
```bash
curl -X POST http://localhost:3000/api/payments/cinetpay/notify \
  -H "Content-Type: application/json" \
  -d '{
    "cpm_trans_id": "ORD-123-1234567890",
    "cpm_trans_status": "ACCEPTED",
    "cpm_custom": "{\"orderId\":123}"
  }'
```

---

## 🔐 Sécurité

### 1. Vérification des paiements
- **Toujours** vérifier le paiement avec l'API CinetPay (`/v2/payment/check`)
- Ne **jamais** se fier uniquement aux paramètres de retour

### 2. Variables d'environnement
- Ne **jamais** commiter les API keys
- Utiliser des identifiants différents en dev et prod

### 3. HTTPS obligatoire en production
- CinetPay requiert HTTPS pour les webhooks en production

---

## 💰 Devises et montants

### Devises supportées
- **XOF** : Franc CFA (Afrique de l'Ouest)
- **XAF** : Franc CFA (Afrique Centrale)
- **CDF** : Franc Congolais
- **GNF** : Franc Guinéen
- **USD** : Dollar américain

### Règles de montant
- Les montants doivent être des **multiples de 5** (sauf USD)
- Exemple : 1000, 1005, 1010 (OK) | 1001, 1003 (KO)

---

## 📱 Modes de paiement disponibles

### Channels
- `ALL` : Tous les moyens de paiement
- `MOBILE_MONEY` : Seulement Mobile Money
- `CREDIT_CARD` : Seulement cartes bancaires
- `WALLET` : Seulement portefeuilles électroniques

### Opérateurs Mobile Money supportés
- Orange Money
- MTN Money
- Moov Money
- Wave
- Flooz

---

## 🚀 Prochaines améliorations

### 1. SDK CinetPay Flutter
CinetPay propose un SDK Flutter pour une intégration sans redirection :
https://docs.cinetpay.com/sdk/flutter

**Avantages** :
- Interface de paiement intégrée dans l'app
- Pas de redirection vers le navigateur
- Meilleure UX

### 2. Paiements récurrents pour les abonnements
- Mettre en place des paiements automatiques mensuels
- Utiliser l'API de tokenisation CinetPay

### 3. Paiements pour les devis acceptés
- Ajouter un bouton de paiement sur la page de détail du devis
- Créer une commande automatiquement après paiement

---

## 📞 Support

### Documentation CinetPay
- API : https://docs.cinetpay.com/api/1.0-fr/
- SDK : https://docs.cinetpay.com/sdk/

### Contact CinetPay
- Email : support@cinetpay.com
- WhatsApp : +225 XX XX XX XX XX

---

## ✅ Checklist de mise en production

- [ ] Créer un compte marchand CinetPay
- [ ] Récupérer les identifiants de production (API Key + Site ID)
- [ ] Configurer les variables d'environnement
- [ ] Configurer le webhook URL dans le back-office CinetPay
- [ ] Activer HTTPS sur le backend
- [ ] Tester un paiement réel avec un petit montant
- [ ] Vérifier que les notifications arrivent bien
- [ ] Vérifier que les commandes sont mises à jour
- [ ] Configurer les alertes email pour les paiements
