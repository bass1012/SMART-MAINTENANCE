# Déployer une migration sans interruption

Le processus HTTP ne modifie jamais le schéma ni les données métier au démarrage.

Avant la bascule PM2, suivre cet ordre :

1. Créer une sauvegarde vérifiée de la base de données.
2. Déployer le code et les fichiers de migration.
3. Exécuter `npm ci`, puis `npm run migrate` avec le compte de migration dédié.
4. Exécuter les tests et un smoke test des endpoints `/live` et `/ready`.
5. Démarrer ou recharger PM2 seulement si les quatre étapes précédentes ont réussi.
6. En cas d'échec, arrêter la bascule et restaurer la sauvegarde plutôt que d'exécuter manuellement une correction SQL en production.

En production, `REDIS_URL` est obligatoire. Le serveur refuse de démarrer si Redis n'est pas configuré ou indisponible, car la révocation JWT et les limites de requêtes doivent être partagées entre tous les workers PM2. Le cache mémoire est réservé au développement et aux tests.

`20260802_move_startup_repairs_to_versioned_migration.js` contient les anciennes réparations automatiques. Son `down` est volontairement sans effet : ces corrections portent sur des états de paiement et ne doivent pas être annulées automatiquement.
