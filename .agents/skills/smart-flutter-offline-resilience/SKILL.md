---
name: smart-flutter-offline-resilience
description: Guide de stabilité, gestion des erreurs globales et résilience hors-ligne pour l'application mobile Flutter SMART MAINTENANCE. À utiliser pour intercepter tous les crashs Flutter, éliminer les fuites de mémoire et sérialiser les accès SQLite hors-ligne.
---

# Smart Flutter Offline Resilience - Application Mobile Flutter

Ce skill garantit la stabilité maximale de l'application Flutter `mct_maintenance_mobile` sur les smartphones Android et iOS des techniciens et clients.

## Checklists de Stabilité Flutter

### 1. Interception Globale des Erreurs (Zero Red Screen / Zero Silent Crash)
- [ ] **FlutterError.onError** : Intercepter les erreurs de rendu UI pour afficher un widget d'erreur personnalisé et élégant en mode Release au lieu d'un écran rouge/gris.
- [ ] **PlatformDispatcher.instance.onError** : Attraper toutes les exceptions asynchrones non gérées (hors de la boucle UI) et les consigner dans les logs de diagnostic local.

### 2. Gestion de la Mémoire RAM & Cycle de Vie (`dispose`)
- [ ] **Timers & Periodics** : S'assurer que tous les `Timer.periodic` sont annulés dans `dispose()` avec guard `if (!mounted)`.
- [ ] **Controllers & Streams** : Libérer impérativement `ScrollController`, `TextEditingController`, `AnimationController` et `StreamSubscription` à la fermeture de chaque écran.

### 3. Synchronisation & Base de Données SQLite Hors-Ligne
- [ ] **Accès Singleton Concurrent** : Sérialiser les accès à SQLite via `Completer<Database>` dans `LocalCacheService` pour éviter les verrous de fichiers `DatabaseLocked`.
- [ ] **Vérifications E/S UI Non-Bloquantes** : Ne jamais exécuter `File.existsSync()` synchrone dans la boucle d'affichage de widgets `build()`.
