# MCT Maintenance - Application de Gestion de Maintenance

Application complète de gestion de maintenance et de climatisation comprenant :
- 📱 Application mobile Flutter (iOS/Android)
- 🖥️ Dashboard web admin (React/TypeScript)
- 🔧 API Backend (Node.js/Express)

## 🚀 Fonctionnalités Principales

### Application Mobile
- ✅ Authentification sécurisée (JWT)
- ✅ Gestion des interventions (création, suivi, évaluation)
- ✅ Chat support client en temps réel
- ✅ Boutique e-commerce avec panier
- ✅ Système de codes promo
- ✅ Notifications push (FCM)
- ✅ Géolocalisation
- ✅ Upload d'images
- ✅ Rapports d'intervention

### Dashboard Admin
- ✅ Gestion des utilisateurs (clients/techniciens)
- ✅ Gestion des interventions
- ✅ Chat support avec clients
- ✅ Gestion des commandes
- ✅ Gestion des produits
- ✅ Système de promotions
- ✅ Notifications en temps réel
- ✅ Statistiques et tableaux de bord

### Backend API
- ✅ Architecture RESTful
- ✅ WebSocket (Socket.IO) pour le temps réel
- ✅ Authentification JWT
- ✅ Upload de fichiers
- ✅ Notifications FCM
- ✅ Base de données SQLite (dev) / PostgreSQL (prod)

## 📋 Prérequis

### Mobile
- Flutter 3.38.4+
- Dart 3.10.3+
- Android Studio / Xcode

### Backend
- Node.js 18+
- npm ou yarn

### Dashboard
- Node.js 18+
- npm ou yarn

## 🛠️ Installation

### 1. Backend API
```bash
cd mct-maintenance-api
npm install
cp .env.example .env  # Configurer les variables d'environnement
npm start
```

### 2. Dashboard Web
```bash
cd mct-maintenance-dashboard
npm install
cp .env.example .env  # Configurer l'URL de l'API
npm start
```

### 3. Application Mobile
```bash
cd mct_maintenance_mobile
flutter pub get
flutter run
```

## 📁 Structure du Projet

```
MAINTENANCE/
├── mct-maintenance-api/          # Backend Node.js
│   ├── src/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── routes/
│   │   ├── services/
│   │   └── middleware/
│   └── package.json
│
├── mct-maintenance-dashboard/     # Dashboard React
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── services/
│   │   └── contexts/
│   └── package.json
│
├── mct_maintenance_mobile/        # App Flutter
│   ├── lib/
│   │   ├── screens/
│   │   ├── services/
│   │   ├── models/
│   │   └── widgets/
│   └── pubspec.yaml
│
└── INTERVENTION/                  # Documentation
```

## 🔧 Configuration

### Variables d'environnement Backend
```env
PORT=3000
JWT_SECRET=your_secret_key
DATABASE_URL=sqlite://database.sqlite
FIREBASE_SERVICE_ACCOUNT=path/to/firebase-key.json
```

### Variables d'environnement Dashboard
```env
REACT_APP_API_URL=http://localhost:3000/api
```

### Configuration Mobile
Modifier `lib/config/environment.dart` pour l'URL de l'API

## 📱 Technologies Utilisées

### Mobile
- Flutter 3.38.4
- Provider (state management)
- Socket.IO Client
- Firebase Messaging
- Dio (HTTP client)
- Geolocator
- Image Picker

### Backend
- Node.js / Express
- Sequelize ORM
- Socket.IO
- Firebase Admin SDK
- JWT
- Multer
- SQLite / PostgreSQL

### Dashboard
- React 18
- TypeScript
- Material-UI
- Axios
- Socket.IO Client
- React Router v6

## 🤝 Contribution

Ce projet est privé. Pour toute question, contactez l'équipe de développement.

## 📄 Licence

Propriétaire - © 2025 MCT Maintenance

## 📞 Support

- Email: contact@mct.ci
- Téléphone: +225 07 09 09 09 42
- Site web: https://www.mct.ci/

## 📝 Changelog

Voir [CHANGELOG_MODIFICATIONS.md](./CHANGELOG_MODIFICATIONS.md) pour l'historique détaillé des modifications.

## ✨ Dernières Mises à Jour

- ✅ Système de codes promo (15/12/2025)
- ✅ Tests E2E avec Flutter Integration Test (15/12/2025)
- ✅ Boutons d'actualisation sur les chats (17/12/2025)
- ✅ Système de notifications complet
- ✅ Migration SnackBar (194 instances)

---

**Développé avec ❤️ par l'équipe MCT**
# SMART-MAINTENANCE
