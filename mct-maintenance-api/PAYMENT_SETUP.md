# 💳 Configuration du Système de Paiement

Ce guide explique comment configurer et utiliser le système de paiement intégré avec **Stripe**, **Wave**, **Orange Money** et la génération de PDF/Email.

## 📋 Table des matières

1. [Prérequis](#prérequis)
2. [Configuration des providers](#configuration-des-providers)
3. [Configuration Email](#configuration-email)
4. [API Endpoints](#api-endpoints)
5. [Utilisation Frontend](#utilisation-frontend)
6. [Tests](#tests)

---

## 🔧 Prérequis

### Packages installés
```bash
npm install stripe nodemailer puppeteer axios
```

### Variables d'environnement
Copiez `.env.example` vers `.env` et configurez les variables suivantes :

```bash
cp .env.example .env
```

---

## 💰 Configuration des Providers

### 1. Stripe

**Inscription :** https://dashboard.stripe.com/register

1. Créez un compte Stripe
2. Récupérez vos clés API dans Dashboard → Developers → API keys
3. Ajoutez dans `.env` :

```env
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

**Mode test :** Utilisez les clés de test pour le développement

---

### 2. Wave (Côte d'Ivoire)

**Documentation :** https://developer.wave.com/

1. Créez un compte Wave Business
2. Activez l'API dans les paramètres
3. Récupérez votre clé API
4. Ajoutez dans `.env` :

```env
WAVE_API_URL=https://api.wave.com/v1
WAVE_API_KEY=your_wave_api_key
```

**Mode développement :** Le système retourne une simulation si la clé n'est pas configurée

---

### 3. Orange Money

**Documentation :** https://developer.orange.com/apis/orange-money-webpay/

1. Inscrivez-vous sur le portail développeur Orange
2. Créez une application
3. Récupérez vos credentials OAuth
4. Ajoutez dans `.env` :

```env
ORANGE_API_URL=https://api.orange.com/orange-money-webpay
ORANGE_CLIENT_ID=your_client_id
ORANGE_CLIENT_SECRET=your_client_secret
ORANGE_MERCHANT_KEY=your_merchant_key
```

---

## 📧 Configuration Email

### Option 1 : Gmail (Recommandé pour le développement)

1. Activez l'authentification à 2 facteurs sur votre compte Gmail
2. Générez un mot de passe d'application :
   - Compte Google → Sécurité → Validation en deux étapes → Mots de passe des applications
3. Ajoutez dans `.env` :

```env
EMAIL_SERVICE=gmail
EMAIL_USER=votre-email@gmail.com
EMAIL_PASSWORD=votre-mot-de-passe-application
EMAIL_FROM=noreply@mct-maintenance.com
```

### Option 2 : SMTP personnalisé

```env
SMTP_HOST=smtp.votreserveur.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=votre-email
SMTP_PASSWORD=votre-mot-de-passe
```

### Tester la configuration email

```bash
node -e "require('./src/services/emailService').testEmailConfiguration()"
```

---

## 🚀 API Endpoints

### Initier un paiement

```http
POST /api/payments/initiate
Authorization: Bearer {token}
Content-Type: application/json

{
  "orderId": 123,
  "provider": "wave",
  "phoneNumber": "+221771234567"
}
```

**Providers disponibles :**
- `stripe`
- `wave`
- `orange_money`
- `mtn_money`
- `moov_money`

**Réponse :**
```json
{
  "success": true,
  "message": "Paiement initié avec succès",
  "data": {
    "paymentId": 1,
    "providerPaymentId": "wave_123456",
    "checkoutUrl": "https://checkout.wave.com/...",
    "clientSecret": "...",
    "status": "pending"
  }
}
```

---

### Confirmer un paiement

```http
POST /api/payments/:paymentId/confirm
Authorization: Bearer {token}
```

---

### Historique des paiements

```http
GET /api/payments/order/:orderId
Authorization: Bearer {token}
```

---

### Télécharger la facture PDF

```http
GET /api/payments/invoice/:orderId/download
Authorization: Bearer {token}
```

**Réponse :** Fichier PDF

---

### Envoyer la facture par email

```http
POST /api/payments/invoice/:orderId/email
Authorization: Bearer {token}
Content-Type: application/json

{
  "email": "client@example.com"
}
```

---

## 💻 Utilisation Frontend

### 1. Initier un paiement

```typescript
import api from './api';

const initiatePayment = async (orderId: number, provider: string) => {
  try {
    const response = await api.post('/payments/initiate', {
      orderId,
      provider,
      phoneNumber: '+2250701234567' // Pour mobile money (Côte d'Ivoire)
    });
    
    const { checkoutUrl, clientSecret } = response.data.data;
    
    if (provider === 'stripe') {
      // Utiliser Stripe Elements avec clientSecret
      // ...
    } else {
      // Rediriger vers checkoutUrl pour Wave/Orange Money
      window.location.href = checkoutUrl;
    }
  } catch (error) {
    console.error('Erreur de paiement:', error);
  }
};
```

### 2. Télécharger la facture

```typescript
const downloadInvoice = async (orderId: number) => {
  try {
    const response = await api.get(`/payments/invoice/${orderId}/download`, {
      responseType: 'blob'
    });
    
    const url = window.URL.createObjectURL(new Blob([response.data]));
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', `facture-${orderId}.pdf`);
    document.body.appendChild(link);
    link.click();
    link.remove();
  } catch (error) {
    console.error('Erreur de téléchargement:', error);
  }
};
```

### 3. Envoyer la facture par email

```typescript
const emailInvoice = async (orderId: number, email: string) => {
  try {
    await api.post(`/payments/invoice/${orderId}/email`, { email });
    alert('Facture envoyée avec succès !');
  } catch (error) {
    console.error('Erreur d\'envoi:', error);
  }
};
```

---

## 🧪 Tests

### Test en mode développement

Le système fonctionne en mode simulation si les clés API ne sont pas configurées :

```javascript
// Les paiements Wave et Orange Money retournent des URLs de simulation
{
  "simulation": true,
  "checkoutUrl": "http://localhost:3001/payment/wave-simulator"
}
```

### Tester avec Stripe

Utilisez les cartes de test Stripe :
- **Succès :** 4242 4242 4242 4242
- **Échec :** 4000 0000 0000 0002
- **3D Secure :** 4000 0027 6000 3184

### Tester l'envoi d'email

```bash
# Dans le terminal
node -e "
const { sendInvoiceEmail } = require('./src/services/emailService');
const order = {
  id: 1,
  reference: 'CMD-TEST',
  totalAmount: 50000,
  customer: { email: 'test@example.com', first_name: 'Test', last_name: 'User' },
  items: [{ product: { nom: 'Produit Test' }, quantity: 1, unit_price: 50000, total: 50000 }]
};
sendInvoiceEmail(order, 'test@example.com').then(console.log).catch(console.error);
"
```

---

## 📊 Modèle de données

### Table `payments`

| Champ | Type | Description |
|-------|------|-------------|
| id | INTEGER | ID unique |
| order_id | INTEGER | ID de la commande |
| amount | DECIMAL | Montant |
| currency | STRING | Devise (XOF) |
| provider | ENUM | stripe, wave, orange_money, etc. |
| payment_id | STRING | ID chez le provider |
| status | ENUM | pending, succeeded, failed, refunded |
| phone_number | STRING | Numéro pour mobile money |
| checkout_url | TEXT | URL de paiement |
| metadata | JSON | Données additionnelles |
| paid_at | DATE | Date de paiement |
| created_at | DATE | Date de création |
| updated_at | DATE | Date de mise à jour |

---

## 🔐 Sécurité

### Webhooks

Les webhooks doivent être sécurisés avec des signatures :

```javascript
// Exemple pour Stripe
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

app.post('/api/payments/webhook/stripe', express.raw({type: 'application/json'}), (req, res) => {
  const sig = req.headers['stripe-signature'];
  
  try {
    const event = stripe.webhooks.constructEvent(
      req.body,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET
    );
    
    // Traiter l'événement
    // ...
    
    res.json({received: true});
  } catch (err) {
    res.status(400).send(`Webhook Error: ${err.message}`);
  }
});
```

---

## 🆘 Dépannage

### Erreur : "Clé API non configurée"

→ Vérifiez que les variables d'environnement sont bien définies dans `.env`

### Erreur : "Erreur d'envoi d'email"

→ Vérifiez la configuration SMTP et testez avec `testEmailConfiguration()`

### Erreur : "Puppeteer ne démarre pas"

→ Installez les dépendances système :
```bash
# Ubuntu/Debian
sudo apt-get install -y libgbm-dev

# macOS
brew install chromium
```

### Le PDF ne se génère pas

→ Vérifiez que Puppeteer est bien installé :
```bash
npm install puppeteer --save
```

---

## 📚 Ressources

- [Documentation Stripe](https://stripe.com/docs/api)
- [Documentation Wave](https://developer.wave.com/)
- [Documentation Orange Money](https://developer.orange.com/apis/orange-money-webpay/)
- [Nodemailer](https://nodemailer.com/)
- [Puppeteer](https://pptr.dev/)

---

## ✅ Checklist de déploiement

- [ ] Configurer les clés API de production
- [ ] Activer les webhooks
- [ ] Configurer le serveur SMTP
- [ ] Tester les paiements en production
- [ ] Configurer les URLs de retour
- [ ] Activer les logs de paiement
- [ ] Mettre en place la surveillance des erreurs
- [ ] Configurer les sauvegardes de la base de données

---

**Support :** Pour toute question, contactez l'équipe de développement MCT Maintenance.
