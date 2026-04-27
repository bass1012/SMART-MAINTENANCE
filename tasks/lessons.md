# Leçons Apprises

<!-- Format: [date] | ce qui a mal tourné | règle pour l'éviter -->

[2026-04-07] | Notifications dupliquées envoyées car pas de vérification si déjà envoyée aujourd'hui | Toujours implémenter une logique de déduplication pour les jobs cron qui envoient des notifications

[2026-04-07] | Push notifications ne fonctionnent pas car le serveur de prod utilise un ancien fichier Firebase (projet différent) | Après changement de projet Firebase: 1) Mettre à jour firebase-service-account.json sur TOUS les serveurs 2) Redémarrer les serveurs 3) Les utilisateurs doivent se reconnecter pour régénérer leur token FCM

[2026-04-08] | firebase-admin SDK v13+ ne fonctionne pas pour envoyer des FCM (erreur auth interne) | Utiliser google-auth-library + HTTP v1 API directement via https natif au lieu de firebase-admin pour les notifications FCM

[2026-04-08] | Clé APNs uploadée uniquement en slot "développement" dans Firebase Console → iOS notifications échouent avec THIRD_PARTY_AUTH_ERROR | Firebase a deux slots séparés pour les clés APNs (dev et production). Toujours uploader la clé .p8 dans LES DEUX slots, même si Apple ne distingue plus dev/prod

[2026-04-08] | Token FCM envoyé à un appareil iOS avec THIRD_PARTY_AUTH_ERROR mais Android fonctionne | Quand Android marche mais iOS non → c'est un problème de clé APNs dans Firebase, pas un problème OAuth

[2026-04-08] | PM2 processes corrompus ("Process 0 not found") → 502 Bad Gateway | Quand pm2 restart échoue, utiliser: pm2 kill && pm2 start ecosystem.config.js

[2026-04-20] | 8 notifications identiques envoyées simultanément pour un même rappel de paiement | En mode PM2 cluster, les cron jobs s'exécutent sur CHAQUE worker. Toujours limiter les cron jobs au worker 0 avec: if (!process.env.NODE_APP_INSTANCE || process.env.NODE_APP_INSTANCE === '0')

[2026-04-20] | Notifications de paiement échouent silencieusement car les types (payment_failed, payment_confirmed, etc.) ne sont pas dans l'ENUM PostgreSQL du modèle Notification | Toujours vérifier que les types utilisés dans notificationService.create() existent dans l'ENUM du modèle Notification.js ET dans la base PostgreSQL (ALTER TYPE ADD VALUE)

[2026-04-20] | Dashboard ne reçoit pas les notifications Socket.IO en temps réel — l'utilisateur doit rafraîchir la page | En PM2 cluster mode, chaque worker a sa propre instance Socket.IO avec ses propres rooms en mémoire. Un événement émis par le worker C n'atteint jamais les sockets connectés au worker A. Solution : installer @socket.io/redis-adapter pour propager les événements entre tous les workers via Redis pub/sub

[2026-04-20] | Badge chat affiche "0000" au lieu de 0 | PostgreSQL retourne `unread_count` comme string depuis un CASE/COUNT. La concaténation "0" + "0" donne "00". Toujours utiliser `parseInt(value, 10) || 0` sur les compteurs PostgreSQL

[2026-04-20] | Variable `message` du callback Socket.IO masque `message` d'Ant Design | Nommer les paramètres de callback Socket différemment des imports globaux. Ex: `msg` au lieu de `message`

[2026-04-20] | Déploiement dashboard ne prend pas effet | Nginx sert depuis `/build/` sous-dossier. La cible scp doit être `.../mct-maintenance-dashboard/build/` et non `.../mct-maintenance-dashboard/`

[2026-04-20] | Graphique "Répartition par Type" affiche tout en "Non spécifié" | Le backend retourne `intervention_type` mais le frontend lit `d.type`. Toujours vérifier le nom exact du champ retourné par l'API avant de le mapper côté frontend

[2026-04-20] | Endpoint `/analytics/technicians` crash avec 500 (Cannot read properties of null) | Des `TechnicianProfile` existent en base sans `User` associé (orphelins). Toujours filtrer `.filter(tech => tech.user)` avant d'accéder aux relations

[2026-04-20] | Endpoint `/analytics/technicians` crash avec `column tp.specialty does not exist` | Le modèle Sequelize référence `specialty` mais la colonne réelle est `specialization`. Toujours vérifier les noms de colonnes réels via `information_schema.columns` avant de mapper

[2026-04-20] | `process.env.DATABASE_URL` non défini quand on SSH avec commande inline | Les variables d'env PM2 (ecosystem.config.js) ne sont pas chargées dans un SSH inline. Utiliser l'URL directe ou `source` l'env avant

[2026-04-21] | Dashboard web avec menu, routes React et widgets rapides désalignés | Quand un onglet est ajouté ou restreint, vérifier systématiquement l'alignement complet menu sidebar + routes App.tsx + liens internes/widgets pour éviter collisions et bypass d'accès

[2026-04-21] | Filtre de dates Analytics corrigé seulement côté page mais ignoré par le service et le backend des graphiques | Pour tout filtre transverse, valider la chaîne complète UI → service frontend → endpoint backend avant de considérer le bug corrigé

[2026-04-21] | Les spies posés après import ne pilotent pas les hooks UI déjà capturés au chargement du module (`useBreakpoint` par exemple) | Pour tester un composant qui capture un hook à l'import, mocker le module au niveau `jest.mock(...)` avant l'import du composant plutôt que d'utiliser un spy runtime

[2026-04-21] | Pages dashboard créées rapidement avec `import axios from 'axios'` et URLs construites à la main (`process.env.REACT_APP_API_URL`) — cassées en prod si env manquante ou sur domaine séparé | Toujours importer l'instance `api` from `../services/api` qui a baseURL + intercepteur token configurés. Ne jamais construire des URLs API manuellement dans les pages.

[2026-04-21] | `Promise.allSettled` dans DashboardStats remplace chaque source tombée par 0 — zéros valides masquent les pannes partielles d'API | Quand on utilise Promise.allSettled, distinguer `null` (erreur) de `0` (vraie valeur) dans les résultats, et propager le flag error dans le state pour l'affichage

[2026-04-21] | Fonctionnalité commentée (`auto-assign`) laisse une modal sans aucun bouton d'action — cul-de-sac UX invisible à la review | Quand une feature est désactivée, soit la remplacer par quelque chose d'utile (comme des boutons Assigner par technicien), soit retirer le point d'entrée dans l'UI jusqu'à ce qu'elle soit prête

[2026-04-21] | API utilisait SQLite en production alors que PostgreSQL était installé et disponible — DATABASE_URL manquante dans le .env | Après tout déploiement, vérifier que DATABASE_URL est présent dans le .env de prod. La config `database.js` bascule silencieusement sur SQLite si DATABASE_URL est absent, sans aucune erreur au démarrage

[2026-04-21] | `!` dans un mot de passe provoque `zsh: event not found` dans les commandes SSH inline | Pour toute commande SSH contenant des caractères spéciaux (`!`, `$`, `@`), toujours passer par un script local envoyé via `scp` puis exécuté à distance, jamais inline

[2026-04-21] | Colonne mot de passe dans la table `users` s'appelle `password_hash` et non `password` — UPDATE échoue silencieusement ou avec erreur | Toujours vérifier les noms de colonnes réels via `information_schema.columns` avant tout UPDATE direct en base

[2026-04-21] | Script Node.js exécuté depuis `/tmp` ne trouve pas les `node_modules` de l'API | Toujours copier les scripts utilitaires dans le dossier racine de l'API (qui contient `node_modules`) avant de les exécuter

[2026-04-21] | Flutter : `badCertificateCallback = (cert, host, port) => true` laissé en dur désactive SSL en production | Conditionner toujours ce callback à `kDebugMode`. En release, ne jamais accepter de certificats invalides

[2026-04-21] | Flutter : deux variables token (`_authToken` SharedPreferences et `_accessToken` mémoire) désynchronisées après redémarrage → toutes les requêtes authentifiées partent sans Bearer token | Un seul token suffit. Si deux références existent, les synchroniser dans `loadSavedToken()` ET dans `setAuthToken()` en même temps

[2026-04-21] | Flutter : `static const bool debugLogs = true` dans `ApiConfig` → logs activés en release | Utiliser `static bool get debugLogs => kDebugMode` pour que les logs ne soient actifs qu'en debug

[2026-04-21] | Flutter : `corsHeaders` définis côté client Flutter et ajoutés aux requêtes HTTP | Les headers CORS (`Access-Control-Allow-*`) sont des headers de réponse serveur — jamais des headers de requête client. Les supprimer complètement du client Flutter

[2026-04-21] | Flutter : token JWT stocké dans `SharedPreferences` (stockage non chiffré) | Stocker les secrets (tokens) dans `FlutterSecureStorage` avec `AndroidOptions(encryptedSharedPreferences: true)`. Garder les données non-sensibles (préférences UI) dans SharedPreferences

[2026-04-21] | Flutter : sur 401, l'app lève une exception sans vider le token → l'utilisateur reste bloqué dans un état authentifié invalide | Sur 401, toujours supprimer le token stocké (`setAuthToken(null)`) avant de lever l'exception, pour forcer une reconnexion propre

[2026-04-21] | Flutter : `api_service_new.dart` duplique `ApiService` avec une interface `http.Response` différente — utilisé seulement par `auth_service.dart` | Ne jamais créer une deuxième instance du service API. Ajouter les méthodes manquantes directement dans le service principal

[2026-04-21] | Flutter : `ErrorWidget.builder` non conditionné expose les stack traces internes en production | Entourer `ErrorWidget.builder` avec `if (kReleaseMode)` pour afficher un message générique en prod et le détail d'erreur seulement en debug

[2026-04-21] | Flutter : `NSBonjourServices/_dartobservatory._tcp` laissé dans `Info.plist` expose le service de debug Dart en build de production iOS | Ce bloc est ajouté automatiquement par les outils de debug Flutter — toujours le retirer de `Info.plist` avant publication App Store

[2026-04-22] | `getInvoices()` appelait `/api/orders` (boutique) et n'affichait que le premier acompte — les devis avec paiement fractionné n'avaient pas de solde visible | Quand plusieurs types de paiements coexistent (commandes boutique + acomptes devis), créer un endpoint d'agrégation dédié plutôt que de réutiliser les endpoints génériques d'orders

[2026-04-22] | Backend DELETE upload refusait les types pluriels ('products', 'equipments') avec 400 alors que le dashboard envoyait le pluriel | Normaliser le paramètre `type` avec `.replace(/s$/, '')` dans le contrôleur pour accepter indifféremment le singulier et le pluriel

[2026-04-22] | POST upload retournait 500 ENOENT car les sous-dossiers `uploads/` n'existaient pas sur le serveur après déploiement | Toujours créer les sous-dossiers d'upload sur le serveur lors de chaque déploiement : `mkdir -p uploads/{products,avatars,equipments,documents,interventions}`

[2026-04-22] | Prévisualisation image dashboard pointait vers le domaine du dashboard au lieu de l'API — chemin relatif `/uploads/products/xxx.jpg` résolu par le navigateur contre le mauvais domaine | Toujours wrapper les chemins d'upload stockés en base avec `getImageUrl()` (qui préfixe `API_BASE_URL`) lors du chargement depuis `initialValues` — ne jamais supposer qu'un chemin relatif est résolvable dans le contexte navigateur courant

[2026-04-22] | Route spécifique `/export-data` capturée par le catch-all `/:id` avec `authorize('admin')` → 403 | En Express, toujours déclarer les routes spécifiques AVANT les routes `/:param` génériques dans le même fichier

[2026-04-22] | Endpoint Sequelize avec `attributes: [...]` hardcodé → 500 répétés car noms de colonnes inventoriés sans vérification (`total_amount`, `reference`, `plan_name`) | Avant tout `findAll` avec `attributes` manuels, toujours vérifier les champs réels dans le modèle Sequelize correspondant — ne jamais deviner les noms de colonnes

[2026-04-27] | Flutter : export binaire PDF crashait avec `FormatException: Invalid UTF-8 byte` car `_request()` décodait le stream en UTF-8 | Pour télécharger du contenu binaire (PDF, ZIP…), ne jamais passer par `_request()` qui décode en string. Utiliser `_client.send()` directement + `streamed.stream.toBytes()` pour récupérer les octets bruts

[2026-04-27] | Flutter WebView : `_isPaymentSuccessUrl` utilisait `contains('success')` — toute URL avec ce mot déclenchait un faux paiement réussi | La détection d'URL de retour paiement doit toujours être restreinte aux domaines connus (fineopay.com, mct.ci) avec vérification du chemin ET de la query. Utiliser `Uri.tryParse()` et ne jamais faire de matching par mots-clés génériques

[2026-04-27] | Flutter : `int.parse(widget.invoiceId)` crashe si l'ID contient une lettre (ex: ID de démo ou mauvais format API) | Toujours utiliser `int.tryParse()` + guard explicite quand la valeur vient de l'extérieur (widget param, API response). `int.parse()` ne doit s'utiliser que sur des strings dont on contrôle le format

[2026-04-27] | Flutter : polling `Timer.periodic` dans les écrans de paiement sans compteur — tournait indéfiniment si le paiement n'était jamais confirmé | Tout `Timer.periodic` de vérification doit avoir un compteur max (ex: 60 × 5s = 5 min) et annuler la timer + informer l'utilisateur si ce plafond est atteint

[2026-04-27] | Flutter : fallback `_getDemoInvoices()` dans le catch — affichait 4 fausses factures hardcodées en cas d'erreur API | Ne jamais utiliser de données fictives comme fallback d'erreur dans une app de production. Afficher un état d'erreur explicite avec un bouton "Réessayer"

[2026-04-27] | Flutter : `_currentPaymentPhase` retournait 1 même si les deux paiements étaient déjà `paid` — le bouton restait actif et permettait un troisième paiement | Toujours vérifier l'état complet (tous les jalons payés) avant d'activer un bouton de paiement. Ajouter une phase "0 = tout payé" avec affichage explicite et bouton désactivé

[2026-04-27] | Flutter : `subscription_payment_screen.dart` retournait un faux succès (dialog + `return true`) quand `checkoutUrl` était null | Quand un paramètre critique est absent (URL de paiement, ID transaction…), toujours lever une exception — jamais simuler un succès silencieux

[2026-04-27] | Flutter : URL ngrok et IPs LAN hardcodées dans `environment.dart` committées dans le dépôt Git | Les fichiers de configuration locale (IPs, ngrok, secrets) doivent être dans `.gitignore` dès le premier commit. Vider les valeurs par défaut (chaîne vide) pour forcer la configuration locale explicite

[2026-04-27] | Flutter : `_saveCart()` appelée sans `await` ni `unawaited()` dans CartService — intent ambigu, lint warning | Quand un appel async est volontairement fire-and-forget, wrapper avec `unawaited()` de `dart:async` pour déclarer l'intent explicitement et supprimer le warning

[2026-04-27] | Flutter : `Color.from(alpha:1, red:0.933, green:0.741, blue:0.106)` utilisé à la place de `Color(0xFFEEBD1B)` — notation non standard dans un projet qui utilise partout `0xFFxxxxxx` | Toujours utiliser la notation `Color(0xFFRRGGBB)` dans Flutter pour la cohérence. `Color.from()` avec flottants linéaires n'est utile que pour les espaces de couleur non-sRGB


