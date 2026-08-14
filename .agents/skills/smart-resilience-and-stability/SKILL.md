---
name: smart-resilience-and-stability
description: Guide de résilience, haute disponibilité et stabilité pour le backend Express Node.js, Socket.IO et la base de données PostgreSQL de SMART MAINTENANCE. À utiliser pour garantir le Graceful Shutdown, la gestion des promesses non capturées, la résilience aux pannes réseau et la reconnexion Socket.IO.
---

# Smart Resilience & Stability - Backend Node.js & Socket.IO

Ce skill fournit les directives pour garantir que le serveur `mct-maintenance-api` ne crashe jamais en production et gère proprement les pannes réseau et montées en charge.

## Checklists de Résilience Backend

### 1. Gestion Globale des Erreurs Inattendues
- [ ] **Uncaught Exceptions & Unhandled Rejections** : Enregistrer des écouteurs globaux dans `src/app.js` ou `src/server.js` pour intercepter `process.on('uncaughtException')` et `process.on('unhandledRejection')` avec log d'erreur détaillé et arrêt propre au lieu d'un crash brutal silencieux.
- [ ] **Middleware d'erreur Express** : S'assurer que tous les contrôleurs asynchrones utilisent `asyncHandler` ou des blocs `try/catch` transmettant les erreurs à `next(err)`.

### 2. Arrêt Propre (Graceful Shutdown)
- [ ] **Interception des Signaux** : Capturer `SIGTERM` et `SIGINT` (émis par PM2 ou Docker lors des déploiements).
- [ ] **Fermeture Ordonnée** :
  1. Refuser les nouvelles connexions HTTP incoming (`server.close()`).
  2. Fermer proprement les connexions WebSockets Socket.IO activement établies.
  3. Attendre la fin des tâches outbox en cours (`outboxWorker`).
  4. Fermer le pool de connexions PostgreSQL (`sequelize.close()`) et Redis (`redis.quit()`).

### 3. Résilience Socket.IO & Coupures Réseau Mobiles
- [ ] **Buffered Events & Offline Messages** : Permettre aux événements envoyés pendant une brève déconnexion mobile d'être rejoués proprement.
- [ ] **Heartbeat & Ping Timeouts** : Régler `pingTimeout: 20000` et `pingInterval: 25000` pour détecter rapidement les déconnexions sans déconnecter intempestivement les mobiles en 3G/4G.
