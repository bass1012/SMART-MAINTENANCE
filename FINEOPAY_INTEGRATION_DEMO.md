# 🔧 Démonstration Technique - Intégration FineoPay
## Pour l'équipe technique FineoPay

---

## 📋 Informations du compte

```
Business Code: smart_maintenance_by_mct
API Key: fpay_5feda0bf5d62257365c70b73f1aa0c6d098f80dbcf788ff8a4c48a661923
Environment: Sandbox/Dev
```

---

## ✅ Ce qui fonctionne

### 1. Génération de lien de paiement (API)

**Endpoint utilisé:**
```
POST https://dev.fineopay.com/api/v1/business/dev/checkout-link
```

**Headers:**
```http
Content-Type: application/json
businessCode: smart_maintenance_by_mct
apiKey: fpay_5feda0bf5d62257365c70b73f1aa0c6d098f80dbcf788ff8a4c48a661923
```

**Body:**
```json
{
  "title": "Commande CMD-1770629322469",
  "amount": 1000,
  "callbackUrl": "http://192.168.1.139:3000/api/fineopay/callback",
  "syncRef": "ORDER_56"
}
```

**Réponse reçue:** ✅
```json
{
  "success": true,
  "message": "Lien de paiement généré avec succès",
  "data": {
    "checkoutLink": "https://demo.fineopay.com/smart_maintenance_by_mct/yqczmaypddiwnskpdvtxgyfzmqkywu/checkout"
  }
}
```

---

## ❌ Le problème

### 2. Ouverture du lien de paiement (Page web)

Lorsqu'on ouvre le `checkoutLink` dans un navigateur :

**URL ouverte:**
```
https://demo.fineopay.com/smart_maintenance_by_mct/yqczmaypddiwnskpdvtxgyfzmqkywu/checkout
```

**Résultat:**
```
🔴 Erreur interne du serveur.
```

### 3. Erreur détectée dans la console du navigateur

Lorsque la page FineoPay charge, elle fait une **requête interne** qui échoue :

**Requête interne FineoPay (visible dans console navigateur):**
```
POST https://dev.fineopay.com/api/v1/business/checkout/payin
Status: 500 Internal Server Error
```

**Erreur retournée:**
```json
{
  "success": false,
  "message": "Erreur interne du serveur.",
  "error": "Internal Error"
}
```

⚠️ **Important:** Cette requête est faite par le **code JavaScript de la page FineoPay**, pas par notre application.
C'est la page de checkout qui crashe en tentant de récupérer les informations de paiement.

### Liens testés (tous affichent la même erreur)

1. `https://demo.fineopay.com/smart_maintenance_by_mct/yqczmaypddiwnskpdvtxgyfzmqkywu/checkout`
2. `https://demo.fineopay.com/smart_maintenance_by_mct/tubnjzblnwnoxlisqlpuhmsfoeyonv/checkout`
3. `https://demo.fineopay.com/smart_maintenance_by_mct/anwihjzomioerbiarslksgmqbhhzdk/checkout`
4. `https://demo.fineopay.com/smart_maintenance_by_mct/abexfctwchchprvsqcxcsvfdbnmjavwm/checkout`

**Note:** Testé immédiatement après génération (< 10 secondes) ⏱️

---

## 🧪 Tests effectués

### Test 1: Montants différents
```bash
# Test avec 5 FCFA
curl -X POST https://dev.fineopay.com/api/v1/business/dev/checkout-link \
  -H "Content-Type: application/json" \
  -H "businessCode: smart_maintenance_by_mct" \
  -H "apiKey: fpay_5feda0bf5d62257365c70b73f1aa0c6d098f80dbcf788ff8a4c48a661923" \
  -d '{"title":"Test 5 FCFA","amount":5,"callbackUrl":"...","syncRef":"TEST_5"}'
# ✅ API OK → ❌ Page checkout erreur

# Test avec 500 FCFA
curl -X POST https://dev.fineopay.com/api/v1/business/dev/checkout-link \
  -H "Content-Type: application/json" \
  -H "businessCode: smart_maintenance_by_mct" \
  -H "apiKey: fpay_5feda0bf5d62257365c70b73f1aa0c6d098f80dbcf788ff8a4c48a661923" \
  -d '{"title":"Test 500 FCFA","amount":500,"callbackUrl":"...","syncRef":"TEST_500"}'
# ✅ API OK → ❌ Page checkout erreur

# Test avec 1000 FCFA
curl -X POST https://dev.fineopay.com/api/v1/business/dev/checkout-link \
  -H "Content-Type: application/json" \
  -H "businessCode: smart_maintenance_by_mct" \
  -H "apiKey: fpay_5feda0bf5d62257365c70b73f1aa0c6d098f80dbcf788ff8a4c48a661923" \
  -d '{"title":"Test 1000 FCFA","amount":1000,"callbackUrl":"...","syncRef":"TEST_1000"}'
# ✅ API OK → ❌ Page checkout erreur
```

### Test 2: Avec tous les champs optionnels
```bash
curl -X POST https://dev.fineopay.com/api/v1/business/dev/checkout-link \
  -H "Content-Type: application/json" \
  -H "businessCode: smart_maintenance_by_mct" \
  -H "apiKey: fpay_5feda0bf5d62257365c70b73f1aa0c6d098f80dbcf788ff8a4c48a661923" \
  -d '{
    "title": "Test Complet FineoPay",
    "amount": 1000,
    "currency": "XOF",
    "callbackUrl": "http://192.168.1.139:3000/api/fineopay/callback",
    "returnUrl": "http://192.168.1.139:3000/payment-success",
    "cancelUrl": "http://192.168.1.139:3000/payment-cancel",
    "syncRef": "TEST_FULL_001",
    "description": "Test de paiement avec tous les champs",
    "customerEmail": "test@example.com",
    "customerPhone": "+221771234567",
    "customerName": "Test Client"
  }'
# ✅ API OK → ❌ Page checkout erreur
```

---

## 🔍 Observations

### Incohérence d'environnements ?

- **API de génération:** `https://dev.fineopay.com/api/v1/business/dev/...`
- **URL checkout retournée:** `https://demo.fineopay.com/smart_maintenance_by_mct/...`

⚠️ Notez que l'API est sur `dev.fineopay.com` mais le checkout sur `demo.fineopay.com`

### Analyse de l'erreur côté FineoPay

**Requête qui échoue (visible dans console navigateur):**
```
POST https://dev.fineopay.com/api/v1/business/checkout/payin
→ 500 Internal Server Error
```

**Cette requête est faite par la page FineoPay elle-même**, pas par notre application.

**Test manuel de l'endpoint:**
```bash
curl -X POST https://dev.fineopay.com/api/v1/business/checkout/payin \
  -H "Content-Type: application/json" \
  -d '{
    "businessCode": "smart_maintenance_by_mct",
    "apiKey": "fpay_...",
    "canal": "WEB",
    "title": "Test",
    "amount": 1000
  }'

# Réponse: "clientAccount must be a string"
# → L'endpoint existe mais demande des champs supplémentaires
```

**Conclusion:** La page de checkout FineoPay tente d'appeler `/checkout/payin` mais :
1. Soit les paramètres envoyés sont incorrects
2. Soit l'endpoint a un bug côté serveur
3. Soit notre compte n'est pas configuré pour utiliser cet endpoint

### Comparaison des messages d'erreur

| Lien | Résultat |
|------|----------|
| Lien fraîchement généré (< 10 sec) | ❌ "Erreur interne du serveur" |
| Lien ancien (> 5 min) | ❌ "Lien de paiement inexistant" |
| Lien avec mauvais businessCode | ❌ "Lien de paiement inexistant" |

---

## 💻 Code Backend (Node.js/Express)

### Controller: fineoPayController.js

```javascript
const axios = require('axios');

// Configuration
const FINEOPAY_BASE_URL = process.env.FINEOPAY_ENV === 'production' 
  ? 'https://api.fineopay.com/v1/business/dev'
  : 'https://dev.fineopay.com/api/v1/business/dev';
const FINEOPAY_BUSINESS_CODE = 'smart_maintenance_by_mct';
const FINEOPAY_API_KEY = 'fpay_5feda0bf5d62257365c70b73f1aa0c6d098f80dbcf788ff8a4c48a661923';

// Créer un lien de paiement
async createPaymentLink(req, res) {
  try {
    const { orderId, amount, title } = req.body;
    const callbackUrl = `${process.env.API_BASE_URL}/api/fineopay/callback`;

    console.log('📤 Envoi requête à FineoPay:', {
      url: `${FINEOPAY_BASE_URL}/checkout-link`,
      businessCode: FINEOPAY_BUSINESS_CODE
    });

    const response = await axios.post(
      `${FINEOPAY_BASE_URL}/checkout-link`,
      {
        title,
        amount: parseFloat(amount),
        callbackUrl,
        syncRef: `ORDER_${orderId}`,
        inputs: [] // Champs personnalisés (vide pour l'instant)
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'businessCode': FINEOPAY_BUSINESS_CODE,
          'apiKey': FINEOPAY_API_KEY
        }
      }
    );

    console.log('📥 Réponse FineoPay:', response.data);

    if (response.data.success) {
      const checkoutLink = response.data.data.checkoutLink;
      console.log('✅ Lien créé:', checkoutLink);
      
      res.json({
        success: true,
        paymentUrl: checkoutLink,
        reference: `ORDER_${orderId}`
      });
    } else {
      throw new Error(response.data.message);
    }
  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      message: error.response?.data?.message || 'Erreur lors de la création du lien'
    });
  }
}

// Gérer le callback webhook
async handleCallback(req, res) {
  try {
    console.log('📨 Callback FineoPay reçu:', req.body);
    
    const { reference, status, amount } = req.body;
    
    // Répondre immédiatement à FineoPay
    res.status(200).json({ success: true });
    
    // Traiter le paiement en arrière-plan
    if (status === 'SUCCESS' || status === 'PAID') {
      // Mettre à jour la commande...
      console.log('✅ Paiement confirmé pour:', reference);
    }
  } catch (error) {
    console.error('❌ Erreur callback:', error);
    res.status(500).json({ success: false });
  }
}
```

### Routes: fineoPayRoutes.js

```javascript
const express = require('express');
const router = express.Router();
const fineoPayController = require('../controllers/payment/fineoPayController');

router.post('/create-payment', fineoPayController.createPaymentLink);
router.post('/callback', fineoPayController.handleCallback);
router.get('/order-status/:orderId', fineoPayController.checkOrderStatus);

module.exports = router;
```

---

## 📱 Code Mobile (Flutter)

### Service: payment_service.dart

```dart
import 'package:url_launcher/url_launcher.dart';

class PaymentService {
  static Future<Map<String, dynamic>> initializeOrderPayment(
    int orderId,
    double amount,
    String reference,
  ) async {
    try {
      final response = await ApiService.post(
        '/payments/fineopay/initialize',
        data: {
          'orderId': orderId,
          'amount': amount,
          'reference': reference,
          'title': 'Commande #$orderId',
        },
      );

      if (response['success'] == true) {
        final paymentUrl = response['data']['paymentUrl'];
        print('✅ Paiement initialisé avec FineoPay');
        print('🔗 URL: $paymentUrl');
        return response['data'];
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      print('❌ Erreur initialisation paiement: $e');
      rethrow;
    }
  }

  static Future<void> openPaymentUrl(String url) async {
    try {
      print('🔗 Tentative d\'ouverture: $url');
      
      final uri = Uri.parse(url);
      final canLaunch = await canLaunchUrl(uri);
      
      print('🔍 canLaunchUrl result: $canLaunch');
      
      if (canLaunch) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('✅ launchUrl result: $launched');
      } else {
        throw Exception('Impossible d\'ouvrir le lien de paiement');
      }
    } catch (e) {
      print('❌ Erreur ouverture URL: $e');
      rethrow;
    }
  }
}
```

---

## 💻 Code Dashboard (React/TypeScript)

### Service: fineoPayService.ts

```typescript
import api from './api';

export const generatePaymentLink = async (
  orderId: number,
  amount: number,
  title: string
): Promise<{ paymentUrl: string; reference: string }> => {
  try {
    const response = await api.post('/payments/fineopay/initialize', {
      orderId,
      amount,
      title,
      description: `Paiement pour commande #${orderId}`,
    });

    if (response.data.success) {
      return {
        paymentUrl: response.data.paymentUrl,
        reference: response.data.reference,
      };
    } else {
      throw new Error(response.data.message);
    }
  } catch (error: any) {
    throw new Error(error.response?.data?.message || 'Erreur génération lien');
  }
};
```

### Composant: PaymentLinkGeneratorAntd.tsx

```typescript
import React, { useState } from 'react';
import { Button, Input, Space, message } from 'antd';
import { DollarOutlined, CopyOutlined, ExportOutlined } from '@ant-design/icons';
import fineoPayService from '../../services/fineoPayService';

const PaymentLinkGenerator: React.FC<{ order: Order }> = ({ order }) => {
  const [loading, setLoading] = useState(false);
  const [paymentUrl, setPaymentUrl] = useState('');

  const handleGenerate = async () => {
    try {
      setLoading(true);
      const result = await fineoPayService.generatePaymentLink(
        order.id,
        order.totalAmount,
        `Commande CMD-${order.id}`
      );
      setPaymentUrl(result.paymentUrl);
      message.success('Lien généré avec succès');
    } catch (error) {
      message.error('Erreur lors de la génération du lien');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Space direction="vertical" style={{ width: '100%' }}>
      <Button
        type="primary"
        icon={<DollarOutlined />}
        onClick={handleGenerate}
        loading={loading}
      >
        Générer un lien de paiement FineoPay
      </Button>

      {paymentUrl && (
        <Space.Compact style={{ width: '100%' }}>
          <Input value={paymentUrl} readOnly />
          <Button icon={<CopyOutlined />} onClick={() => navigator.clipboard.writeText(paymentUrl)} />
          <Button icon={<ExportOutlined />} onClick={() => window.open(paymentUrl, '_blank')} />
        </Space.Compact>
      )}
    </Space>
  );
};
```

---

## 🔄 Flux complet attendu

```
┌──────────────┐                 ┌──────────────┐                 ┌──────────────┐
│   Client     │                 │  Notre API   │                 │  FineoPay    │
│  (Browser)   │                 │  (Backend)   │                 │     API      │
└──────┬───────┘                 └──────┬───────┘                 └──────┬───────┘
       │                                │                                │
       │  1. Clic "Payer"               │                                │
       ├───────────────────────────────>│                                │
       │                                │                                │
       │                                │  2. POST /checkout-link        │
       │                                ├───────────────────────────────>│
       │                                │     Headers: businessCode,     │
       │                                │              apiKey            │
       │                                │                                │
       │                                │  3. 200 OK                     │
       │                                │     {checkoutLink: "..."}      │
       │                                │<───────────────────────────────┤
       │                                │                                │
       │  4. Retour {paymentUrl}        │                                │
       │<───────────────────────────────┤                                │
       │                                │                                │
       │  5. Ouverture checkoutLink     │                                │
       ├────────────────────────────────┼───────────────────────────────>│
       │                                │                                │
       │  6. ❌ ERREUR ICI              │                                │
       │     "Erreur interne serveur"   │                                │
       │<───────────────────────────────┼────────────────────────────────┤
       │                                │                                │
```

L'erreur se produit à **l'étape 6** : quand le client ouvre le checkoutLink dans son navigateur.

---

## ❓ Questions pour l'équipe FineoPay

1. **Configuration du compte**
   - Notre business "smart_maintenance_by_mct" est-il complètement configuré et activé ?
   - Y a-t-il des documents/informations manquantes dans notre profil ?
   - Le compte sandbox est-il opérationnel ?

2. **Environnements**
   - Pourquoi l'API `dev.fineopay.com` retourne des liens vers `demo.fineopay.com` ?
   - Est-ce normal ou y a-t-il une incohérence ?

3. **Endpoint /checkout/payin**
   - La page de checkout fait une requête à `/api/v1/business/checkout/payin` qui retourne une erreur 500
   - Cet endpoint est-il correctement configuré côté serveur ?
   - Quels sont les champs requis pour cet endpoint ?
   - Notre compte a-t-il accès à cet endpoint ?

4. **Whitelist / Sécurité**
   - Faut-il ajouter nos URLs de callback dans une whitelist ?
   - Y a-t-il des restrictions IP ou domaine ?

5. **Configuration manquante**
   - Quelle configuration nous manque-t-il pour que les pages checkout fonctionnent ?
   - Y a-t-il des webhooks ou endpoints à configurer dans le dashboard ?
   - Des champs obligatoires manquants dans notre profil business ?

6. **Logs côté FineoPay**
   - Pouvez-vous vérifier vos logs serveur pour ces checkoutLinks ?
   - Vérifier également les logs de l'endpoint `/checkout/payin` ?
   - Quelle est la cause exacte de l'erreur 500 ?

---

## 📞 Contact

**Projet:** Smart Maintenance by MCT  
**Business Code:** smart_maintenance_by_mct  
**Environment:** Sandbox/Dev  

Notre intégration côté code est complète et fonctionnelle. Nous attendons votre retour pour finaliser l'activation du compte.

Merci ! 🙏
