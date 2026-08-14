---
name: smart-observability-and-monitoring
description: Guide d'observabilité, de diagnostic de requêtes et d'optimisation des performances pour SMART MAINTENANCE (API Express, Nginx, PostgreSQL, Redis). À utiliser pour monitorer les temps de réponse, détecter les requêtes lentes et surveiller les pools de connexions.
---

# Smart Observability & Monitoring - Performance & Diagnostic

Ce skill fournit les outils et configurations pour monitorer la santé du système SMART MAINTENANCE en production et prévenir les ralentissements.

## Checklists de Performance & Monitoring

### 1. Pool de Connexions & Optimisation Base de Données
- [ ] **Pool Sequelize PostgreSQL** : Configurer un pool adapté aux montées en charge (`max: 20`, `min: 5`, `idle: 10000`, `acquire: 30000`) dans `src/config/database.js`.
- [ ] **Indexation SQL** : S'assurer que les colonnes fréquemment filtrées (`customerId`, `technicianId`, `status`, `reference`) disposent d'index SQL dédiés.

### 2. Monitoring HTTP & Nginx
- [ ] **Erreurs HTTP 5xx & Slow Requests** : Suivre les requêtes dont la réponse dépasse 2000 ms via les logs Express/Morgan.
- [ ] **Cache Redis** : Utiliser Redis pour mettre en cache les requêtes fréquemment lues (catalogues produits, grilles tarifaires, configurations).

### 3. Santé de la File de Tâches Outbox & Workers
- [ ] **Worker Queue Outbox** : Monitorer l'exécution des travaux d'arrière-plan (envoi d'emails, notifications push FCM, webhooks) pour s'assurer qu'aucune tâche ne reste bloquée indéfiniment.
