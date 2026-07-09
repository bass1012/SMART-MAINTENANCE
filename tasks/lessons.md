R# Leçons Apprises

<!-- Format: [date] | ce qui a mal tourné | règle pour l'éviter -->

[2026-07-08] | Lors de l'appui sur un bouton "Déconnexion" situé dans un BottomSheet ou un Dialog, la méthode `navigator.pop()` était appelée **avant** `context.read<AuthRepository>()` pour fermer le menu. Cela rendait le contexte invalide (unmounted), ce qui levait une exception silencieuse lors de l'appel à `context.read` et provoquait l'annulation totale de la fonction `logout()`. L'utilisateur était redirigé vers l'écran de Login sans que les tokens ne soient supprimés ! | Toujours extraire les dépendances liées au contexte (ex: `final repo = context.read<Repo>();`) **avant** toute opération de navigation asynchrone ou de fermeture (`pop()`) qui risquerait de démonter le widget.
[2026-07-08] | Lors de la déconnexion, si la suppression du token via `FlutterSecureStorage` échouait silencieusement ou plantait (ex: bug lié au Keychain sur simulateur iOS/Mac qui survit aux hot restarts), le reste du processus de nettoyage (`SharedPreferences`, FCM) était interrompu, et l'utilisateur restait connecté au prochain redémarrage | Toujours isoler chaque étape critique du nettoyage (`logout` ou `clearAuthData`) dans son propre bloc `try...catch`. Surtout, implémenter un flag explicite (`has_logged_out`) dans `SharedPreferences` lors de la déconnexion, et vérifier ce flag en premier lieu dans `isLoggedIn()` pour ignorer toute valeur fantôme coincée dans la keychain de `FlutterSecureStorage`. Retirer le flag uniquement à la prochaine connexion réussie.

[2026-07-08] | Les formulaires d'inscription et de connexion supposaient un succès de l'opération même lorsque le backend renvoyait une erreur (ex: 409 Conflit ou 401 Unauthorized), ce qui provoquait des comportements inattendus ou des plantages avec des messages non explicites | Ne jamais présumer du succès d'une requête API simplement parce qu'aucune exception réseau (SocketException) n'est levée. Il faut toujours vérifier explicitement le statut de la réponse (ex: `response['success'] == true`) avant de parser les données, et extraire le champ `message` de l'API pour afficher la vraie erreur à l'utilisateur.

[2026-07-08] | La table SQLite locale n'avait pas la colonne `availability_info` dans `installation_services`, contrairement au modèle Sequelize, provoquant un plantage 500 silencieux bloquant l'affichage des requêtes | Toujours vérifier que la structure des tables de la base de données de développement correspond à la structure définie dans Sequelize, car les options comme `{ alter: true }` ne mettent pas toujours à jour proprement sur SQLite. Exécuter un `ALTER TABLE` si besoin.

[2026-07-08] | Lors de la création d'une nouvelle demande de maintenance, les utilisateurs devaient initialement payer l'acompte (50%) et le solde (50%) plus tard, mais préféraient payer la totalité en une seule fois | Toujours offrir plus de flexibilité dans les processus de paiement complexes. Si un système d'acompte 50/50 est implémenté, prévoir une option UX `Paiement intégral (100%)` pour les utilisateurs désirant s'acquitter de la somme dès la commande.

[2026-07-09] | Déploiement du Dashboard (React) : Les fichiers sources étaient sur le serveur mais non compilés, car `npm run build` échouait sans `package.json` | Un serveur web (comme Nginx) sert des fichiers statiques compilés, pas des sources React. Soit on build sur le serveur (nécessite `package.json`), soit on build en local et on utilise `scp -r build/* ...` pour transférer uniquement les fichiers statiques de production.
[2026-07-09] | Fausses erreurs CORS sur le Dashboard alors que la config CORS de l'API était correcte | Lorsqu'une API Node.js crashe complètement (ex: erreur de syntaxe), Nginx renvoie une erreur 502 Bad Gateway. Cette réponse 502 ne contient pas d'en-têtes CORS. Le navigateur intercepte la réponse et signale une erreur CORS ("No Access-Control-Allow-Origin"), masquant le crash serveur. Toujours lancer `node -c` pour vérifier la syntaxe avant d'investiguer une erreur CORS soudaine.
[2026-07-09] | Erreurs 404 sur des anciennes notifications après avoir corrigé les URLs dans l'API | Les corrections de routes générées par l'API (ex: passer de `/contracts` à `/contrats`) ne s'appliquent qu'aux *nouvelles* notifications. Les anciennes notifications stockées en base de données contiennent toujours l'URL obsolète. Il faut toujours ajouter une couche d'interception (fallback) côté frontend pour réécrire à la volée les anciennes URLs lors du clic.
[2026-07-09] | Validation stricte dans les formulaires Ant Design sur le Dashboard | Dans un `<Form.Item>` avec Ant Design (React), la règle `rules={[{ required: true }]}` bloque la soumission du formulaire et affiche l'astérisque rouge. Pour rendre un champ optionnel, il suffit de supprimer cette règle du `<Form.Item>`.

[2026-07-08] | Lors de la demande de maintenance (abonnements d'entretien), les paiements s'effectuaient à 100% au lieu d'être fractionnés (50/50) comme pour les devis, car l'application mobile redirigeait vers SubscriptionPaymentScreen au lieu de ContractPaymentScreen, et le backend n'associait pas les statuts de paiement split à l'activation | Configurer les abonnements à visites planifiées (scheduled) pour utiliser le flux de paiement fractionné (acompte 50% à la validation, solde 50% à la dernière visite). Dans l'app Flutter, utiliser le ContractPaymentScreen adapté et mettre à jour le filtrage des souscriptions actives pour accepter le statut de paiement 'partial' afin que le client puisse utiliser son abonnement dès le premier acompte payé.

[2026-07-08] | Le second paiement d'un devis en 50/50 pouvait rester bloqué parce que l'ordre gardait un `paymentStatus` déjà à `paid` et un `paymentStep` obsolète, alors que le devis était encore en état `partial` | Pour les paiements split, ne jamais se fier uniquement au statut `paid` de la commande. Déduire l'étape réelle depuis les statuts du devis (`first_payment_status` / `second_payment_status`), persister cet état sur l'ordre et continuer à attendre le second versement tant que le devis reste partiellement payé.

[2026-07-08] | Lors de la récupération d'entités contenant des données de secours en colonne JSON (ex: devis avec line_items au lieu d'une relation d'items Sequelize), certaines APIs ou le générateur PDF n'affichaient pas les articles | Toujours isoler l'extraction des données dans un helper unifié (ex. getQuoteItemsHelper) partagé par toutes les routes API et le générateur de PDF pour s'assurer que le contenu est identique partout.

[2026-07-08] | L'application mobile levait type 'Null' is not a subtype of type 'String' in type cast car certaines méthodes d'initialisation de paiement de PaymentRepositoryImpl renvoyaient le JSON racine au lieu du sous-objet 'data' attendu par les écrans de paiement | Assurer une cohérence stricte des types de retour dans les dépôts (repositories). Si un service/repository extrait la clé 'data' pour une méthode, s'assurer que toutes ses variantes de méthodes fassent de même pour éviter des valeurs nulles inattendues.

[2026-07-08] | Le bouton de paiement d'un devis n'apparaissait pas si l'utilisateur y retournait après avoir quitté le tunnel de paiement, car la condition d'affichage filtrait strictement sur paymentStatus == 'deferred' au lieu de proposer le paiement pour tout état non réglé | Ne pas baser la visibilité d'un bouton d'action critique sur un seul statut d'attente (comme deferred). Préférer un filtre large excluant uniquement le statut final de complétion (ex. paymentStatus != 'paid').

[2026-07-08] | Divergence potentielle entre le montant textuel affiché sur un bouton de paiement et le montant réellement traité lors de l'action de clic | Centraliser et harmoniser la logique de calcul de montant (et ses fallbacks de secours) afin que le libellé du widget bouton et la fonction d'action (ex: _payNow) s'appuient exactement sur les mêmes variables et règles.

[2026-06-15] | La récupération des souscriptions client renvoyait une erreur 500 car les colonnes de split payment (`first_payment_amount`, `first_payment_status`, `second_payment_amount`, `second_payment_status`) étaient absentes de la table `subscriptions` en SQLite local | Exécuter des requêtes `ALTER TABLE subscriptions ADD COLUMN ...` pour ajouter manuellement les colonnes manquantes liées au paiement fractionné et s'aligner sur la définition du modèle Sequelize.

[2026-06-15] | La modification d'un utilisateur renvoyait une erreur 500 sur SQLite local car la colonne `address` était absente de la table `customer_profiles` (Sequelize `{ alter: true }` ne gère pas toujours de manière fiable l'ajout de nouvelles colonnes sur SQLite) | En cas d'erreur 500 lors de requêtes Sequelize en base SQLite locale, inspecter le schéma de la table via `PRAGMA table_info(table)` et exécuter manuellement une commande `ALTER TABLE table ADD COLUMN ...` pour synchroniser le schéma physique avec le modèle Sequelize.

[2026-06-15] | Le formulaire de modification d'utilisateur (`UserForm.tsx` du dashboard) plantait avec une `TypeError` lors de l'appel de `email.trim()` car certains comptes (ex: les clients locaux sans adresse email renseignée en base) avaient la valeur `null` | Toujours initialiser les valeurs de formulaires provenant de l'API avec des valeurs de repli (ex. `|| ''`) et valider l'existence de la variable avant d'appeler des méthodes de chaîne de caractères comme `.trim()`.

[2026-06-15] | L'overlay d'erreur Webpack (Create React App) bloque l'écran de développement en local à cause d'une erreur d'extension Chrome injectée (ex: `Cannot read properties of undefined (reading 'addListener')` dans un Worker Blob de Loom ou Adobe) | Ajouter une règle CSS globale (`iframe#webpack-dev-server-client-overlay { display: none !important; }`) pour désactiver l'overlay client Webpack pour ces erreurs de scripts externes sans avoir à éjecter la configuration du projet.

[2026-06-15] | L'application plantait au démarrage local à cause de l'option SSL requise par PostgreSQL en production car `NODE_ENV` était défini sur `production` localement | S'assurer que `NODE_ENV` est défini sur `development` en local pour basculer sur la base SQLite locale ou configurer le serveur local sans contraintes SSL de production.

[2026-06-15] | L'application mobile appelait une route avec le mauvais préfixe (`/api/payments/fineopay/...` au lieu de `/api/fineopay/...`) entraînant un 404 car celle-ci était déclarée différemment dans le backend | Toujours s'assurer de la cohérence des préfixes de route entre le client mobile (ex. `BaseApiService`) et la déclaration des routeurs Express en vérifiant les fichiers de routing du backend.

[2026-06-15] | Les écrans de paiement utilisaient une vérification générique par référence textuelle locale (ex. `DIAG-xxx`, `SUB-xxx`) auprès de la passerelle de paiement tierce FineoPay, générant une erreur 500 car le tiers attendait des identifiants `TRX...` | Ne jamais envoyer de références textuelles locales à des endpoints de vérification directe de passerelles tierces. Utiliser des endpoints backend dédiés (comme `/verify-diagnostic-payment/:interventionId`) qui résolvent et font correspondre dynamiquement les transactions locales avec les transactions tierces.

[2026-05-08] | Singleton service (NotificationNavigationService, FCMService) crée son propre BaseApiService() → jamais de token → 401 silencieux sur toutes ses API calls | Tout singleton qui fait des appels API doit exposer un `setToken()` (ou `setAuthToken()`) et l'AuthRepository doit l'appeler partout où il met à jour le token : `isLoggedIn()`, `loadSavedToken()`, `_saveToken()`, `_clearAuthData()`

[2026-05-08] | Repository retournait le wrapper JSON entier `{success, data: {...}}` au lieu de `data` → le champ cherché était toujours null | Dans les repositories Flutter, toujours extraire `decoded['data']` après vérification de `decoded['success'] == true`. Ne jamais retourner le wrapper brut si l'appelant s'attend à des champs de données directement

[2026-05-08] | `POST /api/customer/update-fcm-token` et `POST /api/notifications/:id/mark-as-read` n'existent pas → 404/500 silencieux | Avant d'écrire un appel API Flutter, vérifier l'existence exacte de la route dans les fichiers de routes backend (méthode HTTP + chemin). Ne pas deviner les noms d'endpoints

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

[2026-04-27] | Clé service account Firebase révoquée dans Google Cloud Console → `invalid_grant: Invalid JWT Signature` sur toutes les notifications FCM | Quand FCM retourne `invalid_grant`, vérifier l'état de la clé dans GCP → IAM → Service Accounts → Keys. Générer une nouvelle clé, l'uploader sur tous les serveurs, restart PM2 (Node.js met `require()` en cache — le process doit redémarrer pour recharger le fichier)

[2026-04-27] | Avatar 404 car `CircleAvatar.backgroundImage` n'a pas de fallback sur `child` quand l'image échoue | Toujours utiliser `foregroundImage` (pas `backgroundImage`) dans CircleAvatar quand un child de fallback (initiales) est prévu — Flutter bascule sur `child` automatiquement si foregroundImage échoue

[2026-04-27] | `equipment.imageUrl = filename; equipment.save()` ne persistait rien en DB car le champ `imageUrl` n'était pas dans le modèle Sequelize Equipment | Avant tout `instance.someField = value`, vérifier que le champ est déclaré dans le modèle Sequelize. Sinon, Sequelize l'ignore silencieusement au moment du save()

[2026-04-27] | Images disparaissent après reboot/redeploy car stockées uniquement au filesystem sous `uploads/` dans le dossier app | Pour les images critiques (avatars, équipements), convertir en base64 après compression et stocker le data URL directement en DB (TEXT). Pas de dépendance au filesystem. Taille acceptable pour avatars 400×400@85% (~30-60KB → ~80KB base64)

[2026-04-22] | Prévisualisation image dashboard pointait vers le domaine du dashboard au lieu de l'API — chemin relatif `/uploads/products/xxx.jpg` résolu par le navigateur contre le mauvais domaine | Toujours wrapper les chemins d'upload stockés en base avec `getImageUrl()` (qui préfixe `API_BASE_URL`) lors du chargement depuis `initialValues` — ne jamais supposer qu'un chemin relatif est résolvable dans le contexte navigateur courant

[2026-04-22] | Route spécifique `/export-data` capturée par le catch-all `/:id` avec `authorize('admin')` → 403 | En Express, toujours déclarer les routes spécifiques AVANT les routes `/:param` génériques dans le même fichier

[2026-04-22] | Endpoint Sequelize avec `attributes: [...]` hardcodé → 500 répétés car noms de colonnes inventoriés sans vérification (`total_amount`, `reference`, `plan_name`) | Avant tout `findAll` avec `attributes` manuels, toujours vérifier les champs réels dans le modèle Sequelize correspondant — ne jamais deviner les noms de colonnes

[2026-04-27] | Flutter : export binaire PDF crashait avec `FormatException: Invalid UTF-8 byte` car `_request()` décodait le stream en UTF-8 | Pour télécharger du contenu binaire (PDF, ZIP…), ne jamais passer par `_request()` qui décode en string. Utiliser `_client.send()` directement + `streamed.stream.toBytes()` pour récupérer les octets bruts

[2026-04-27] | Flutter WebView : `_isPaymentSuccessUrl` utilisait `contains('success')` — toute URL avec ce mot déclenchait un faux paiement réussi | La détection d'URL de retour paiement doit toujours être restreinte aux domaines connus (fineopay.com, mct.ci) avec vérification du chemin ET de la query. Utiliser `Uri.tryParse()` et ne jamais faire de matching par mots-clés génériques

[2026-04-27] | Flutter : `int.parse(widget.invoiceId)` crashe si l'ID contient une lettre (ex: ID de démo ou mauvais format API) | Toujours utiliser `int.tryParse()` + guard explicite quand la valeur vient de l'extérieur (widget param, API response). `int.parse()` ne doit s'utiliser que sur des strings dont on contrôle le format

[2026-04-27] | Flutter : polling `Timer.periodic` dans les écrans de paiement sans compteur — tournait indéfiniment si le paiement n'était jamais confirmé | Tout `Timer.periodic` de vérification doit avoir un compteur max (ex: 60 × 5s = 5 min) et annuler la timer + informer l'utilisateur si ce plafond est atteint

[2026-04-27] | Flutter : fallback `_getDemoInvoices()` dans le catch — affichait 4 fausses factures hardcodées en cas d'erreur API | Ne jamais utiliser de données fictives comme fallback d'erreur dans une app de production. Afficher un état d'erreur explicite avec un bouton "Réessayer"

[2026-04-30] | DATABASE_URL sur le serveur pointait vers Supabase alors que la vraie DB est locale (PostgreSQL OVH) — API en crash loop silencieux avec ENOTFOUND | Après tout redéploiement, vérifier immédiatement `pm2 logs --lines 10` — si ENOTFOUND sur DATABASE_URL, l'URL pointe vers un host DNS inexistant. Utiliser `psql "$DATABASE_URL" -c "SELECT 1"` pour tester avant de relancer PM2

[2026-04-30] | `ApiService` importé dans 8 fichiers sans jamais être utilisé — import orphelin impossible à détecter sans grep | Avant de supprimer un fichier, toujours grep `import.*fichier.dart` dans tout le projet et vérifier que chaque import utilise effectivement le fichier (pas juste importé par habitude)

[2026-04-30] | `flutter pub upgrade` ne touche pas les breaking changes — `flutter pub upgrade --major-versions` met à jour les contraintes pubspec automatiquement | Pour une mise à jour complète des packages Flutter, lancer les deux commandes dans l'ordre : 1) `flutter pub upgrade` (mineures/patch) 2) `flutter pub upgrade --major-versions` (majeures) puis valider avec `flutter analyze`

[2026-04-27] | Flutter : `_currentPaymentPhase` retournait 1 même si les deux paiements étaient déjà `paid` — le bouton restait actif et permettait un troisième paiement | Toujours vérifier l'état complet (tous les jalons payés) avant d'activer un bouton de paiement. Ajouter une phase "0 = tout payé" avec affichage explicite et bouton désactivé

[2026-04-27] | Flutter : `subscription_payment_screen.dart` retournait un faux succès (dialog + `return true`) quand `checkoutUrl` était null | Quand un paramètre critique est absent (URL de paiement, ID transaction…), toujours lever une exception — jamais simuler un succès silencieux

[2026-04-27] | Flutter : URL ngrok et IPs LAN hardcodées dans `environment.dart` committées dans le dépôt Git | Les fichiers de configuration locale (IPs, ngrok, secrets) doivent être dans `.gitignore` dès le premier commit. Vider les valeurs par défaut (chaîne vide) pour forcer la configuration locale explicite

[2026-04-27] | Flutter : `_saveCart()` appelée sans `await` ni `unawaited()` dans CartService — intent ambigu, lint warning | Quand un appel async est volontairement fire-and-forget, wrapper avec `unawaited()` de `dart:async` pour déclarer l'intent explicitement et supprimer le warning

[2026-04-27] | Flutter : `Color.from(alpha:1, red:0.933, green:0.741, blue:0.106)` utilisé à la place de `Color(0xFFEEBD1B)` — notation non standard dans un projet qui utilise partout `0xFFxxxxxx` | Toujours utiliser la notation `Color(0xFFRRGGBB)` dans Flutter pour la cohérence. `Color.from()` avec flottants linéaires n'est utile que pour les espaces de couleur non-sRGB

[2026-04-28] | Refactoring massif d'une God Class (`ApiService`) casse l'application entière si supprimée d'un coup | Découper la classe en sous-repositories (`AuthRepository`, `InterventionRepository`), mais conserver l'ancienne classe et migrer les appels de manière incrémentale. Ne supprimer la God Class qu'à la toute fin.

[2026-04-28] | Déplacement de dizaines de fichiers dans une nouvelle architecture Feature-First brise tous les imports relatifs dans un projet Flutter | Utiliser un script d'automatisation (Python/Bash) ou un outil de refactoring de masse pour rechercher et remplacer les anciens chemins par les nouveaux dans tout le dossier `lib/` afin d'éviter des heures de travail manuel sujet aux erreurs.

[2026-04-28] | `if (!mounted) return;` inséré par erreur à l'intérieur des listes d'arguments de widgets (ex: `onPressed: () { if (!mounted) return; ... }`) → casse la syntaxe | Toujours vérifier le contexte d'insertion des guards `mounted`. Ils doivent être la première instruction d'un bloc `{}` après un `await`, jamais au milieu d'une expression.

[2026-04-28] | `activeThumbColor` utilisé sur `Radio` ou `CheckboxListTile` provoque une erreur `undefined_named_parameter` | `activeThumbColor` est spécifique à `Switch`. Pour `Radio` et `Checkbox`, utiliser `activeColor` (ou `fillColor` avec `WidgetStateProperty`).

[2026-04-28] | Widget tests échouent car ils référencent `MyApp` (nom par défaut) alors que l'application s'appelle `App` | Toujours vérifier le nom exact de la classe racine dans `main.dart` avant de configurer les tests.

[2026-04-28] | Script d'automatisation des accolades (`{}`) insère des accolades au milieu de structures complexes (collection-if Flutter) → casse la syntaxe (6000+ erreurs) | Ne jamais utiliser de simple script regex pour insérer des accolades dans du code Flutter riche en Widgets. Utiliser `dart format` ou des outils de refactoring officiels pour les lints de style, ou faire des passes manuelles ciblées.

[2026-04-28] | Migration Feature-First : imports de modèles/services partagés oubliés dans le script de migration global | Pour un refactoring d'architecture, construire une liste exhaustive des fichiers "partagés" (services, modèles, providers) et s'assurer que le script de remplacement d'imports couvre tous les fichiers déplacés, pas seulement les écrans.

[2026-04-28] | `context.mounted` versus `mounted` | Dans les builders ou dialogues, `mounted` (de l'état State) peut être vrai alors que le `context` local est déjà invalidé. Utiliser `if (context.mounted)` pour plus de précision.

[2026-04-28] | Script d'ajout d'imports `foundation.dart` échoue si un import partiel existe déjà (ex: `show kReleaseMode`) | Vérifier non seulement la présence du package mais aussi s'il est restreint. Si `show` est présent, il vaut mieux passer à un import complet pour supporter `kDebugMode` et `debugPrint`.

[2026-04-29] | `Geolocator.getCurrentPosition` utilisant `desiredAccuracy` (déprécié) | Utiliser `locationSettings` (LocationSettings) avec le paramètre `accuracy` pour se conformer aux versions récentes de Geolocator.

[2026-04-29] | Migration vers le pattern Repository : Oubli d'ajouter les méthodes dans l'interface/implémentation du Repository après les avoir utilisées dans l'UI | Toujours mettre à jour l'interface `abstract class` et son `Impl` AVANT ou EN MÊME TEMPS que la migration de l'écran UI. Lancer un build de test après chaque écran migré.

[2026-04-29] | Récursion infinie dans `SyncProvider` due au retry automatique de 10s sur échec | Ne jamais planifier de retry automatique à court terme indéfini à l'intérieur d'une méthode de sync globale. Préférer les timers périodiques longs (ex: 5 min) ou les déclencheurs d'événements (connectivité) pour éviter les boucles infinies en cas d'erreur persistante.

[2026-04-29] | Singletons créant des abonnements multiples à chaque `initialize()` | Toujours vérifier si un abonnement existe déjà (`_subscription != null`) avant de s'abonner à un stream dans une méthode d'initialisation répétable.

[2026-04-29] | Backend forçant le stockage Base64 au lieu des fichiers | Dans `uploadController.js`, l'utilisation systématique de `fileToBase64DataUrl` supprimait les fichiers physiques après upload. Toujours préférer le stockage de fichiers physiques pour les avatars et équipements afin de préserver la performance de la base de données et du réseau.

[2026-07-09] | API et App : Ajout de champs de mesure technique (pression, puissance, etc.) | Au lieu d'utiliser un champ générique "technical_data", définir des colonnes de mesure spécifiques et cohérentes (Pression, Puissance, Intensité, Tension) entre les modèles Flutter et les modèles Sequelize pour éviter les conversions de données difficiles.

[2026-07-09] | API et App : Ajout du Fréon | Ajout de la mesure de Fréon dans le rapport de diagnostic et le rapport de maintenance.

[2026-07-09] | Xcode Cloud & Flutter | Ajout du script ci_post_clone.sh pour forcer Xcode Cloud à installer Flutter et exécuter 'pod install' avant de tenter la compilation iOS, car par défaut Xcode Cloud ne gère pas nativement Flutter.
