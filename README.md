# MCT Maintenance - Application de Gestion de Maintenance

Application complète de gestion de maintenance et de climatisation comprenant :
- 📱 Application mobile Flutter (iOS/Android)
- 🖥️ Dashboard web admin (React/TypeScript)
- 🔧 API Backend (Node.js/Express)

---

## 📋 DOCUMENTATION CENTRALE

👉 **[PROJET_MCT_MAINTENANCE.md](./PROJET_MCT_MAINTENANCE.md)** - Document unique centralisé (Roadmap, Fonctionnalités)
👉 **[tasks/lessons.md](./tasks/lessons.md)** - Base de connaissances techniques (Résolutions de bugs, Bonnes pratiques)

Ce document contient :
- ✅ État d'avancement complet (96%)
- ✅ Liste de toutes les fonctionnalités (complétées et en cours)
- ✅ Roadmap et planning
- ✅ Métriques et KPIs
- ✅ Prochaines étapes
- ✅ Réalisations majeures
- ✅ Décisions techniques

---

## 🚀 Démarrage Rapide

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
- ✅ Architecture RESTful & Outbox Transactionnelle
- ✅ Machine d'état centralisée des interventions (`interventionStateMachineService.js`)
- ✅ Endpoints d'observabilité (`GET /live` Liveness, `GET /ready` Readiness DB)
- ✅ Traçabilité distribuée (`X-Correlation-ID`) & masquage PII dans les journaux
- ✅ Gestion des litiges et remboursements idempotents (`/api/refunds`)
- ✅ WebSocket (Socket.IO) pour le temps réel
- ✅ Authentification JWT & politiques d'accès étanches
- ✅ Notifications FCM & SMS (HSMS)
- ✅ Base de données SQLite (dev) / PostgreSQL (prod)
- ✅ Intégration Continue (GitHub Actions CI pour Node.js et Flutter)

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

## 🚀 Déploiement & Production

### Backend API (PM2)
En production (sur le VPS), le backend utilise **PM2** en mode cluster :
```bash
pm2 start ecosystem.config.js
```

### Application Mobile (Automatisation)
Un script de déploiement est fourni pour faciliter la génération des builds Android et l'incrémentation de version :
```bash
./deploy_mobile.sh
```
Pour iOS, l'intégration continue est gérée automatiquement via **Xcode Cloud** (compilation et déploiement TestFlight/App Store).

### Dashboard Web (Nginx)
Le tableau de bord React doit être compilé (`npm run build`) et les fichiers statiques servis par **Nginx**.

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
│   │   ├── config/                # Configuration et environnement
│   │   ├── core/                  # Code cœur et utilitaires partagés
│   │   ├── features/              # Architecture Feature-First (modules)
│   │   ├── models/                # Modèles de données globaux
│   │   ├── screens/               # Écrans historiques (en migration)
│   │   └── services/              # Services API et locaux
│   └── pubspec.yaml
│
└── INTERVENTION/                  # Documentation
```

## 🔧 Configuration

### Variables d'environnement Backend
```env
PORT=3000
JWT_SECRET=your_secret_key
# SQLite est utilisé en développement local. 
# En production, utilisez une URL PostgreSQL (ex: postgres://user:pass@host:5432/db)
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
- Flutter 3.x
- Provider (state management)
- Architecture hybride (vers Feature-First)
- Socket.IO Client
- Firebase Messaging (Push Notifications)
- Dio (HTTP client)
- Geolocator & Image Picker

### Backend
- Node.js / Express
- Sequelize ORM (PostgreSQL en prod / SQLite en dev)
- Socket.IO (Temps réel)
- PM2 (Cluster Management)
- JWT (Authentification)
- Firebase Messaging API v1
- FineoPay (Passerelle de paiement en ligne)

### Dashboard
- React 18 / TypeScript
- Material-UI
- Axios
- Socket.IO Client
- React Router v6

### CI/CD & Déploiement
- Script bash automatisé (Android APK/AAB)
- Xcode Cloud (CI iOS & TestFlight)
- Nginx (Reverse Proxy & Fichiers statiques)

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
