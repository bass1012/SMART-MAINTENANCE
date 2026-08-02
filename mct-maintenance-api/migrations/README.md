# Migrations de base de données

Le seul moteur autorisé est `npm run migrate`. Il exécute les migrations JavaScript exportant obligatoirement `up` et `down`, puis les enregistre dans `migration_history`.

- `npm run migrate:status` liste les migrations en attente sans modifier le schéma.
- `npm run migrate` applique toutes les migrations JavaScript en attente.
- Les fichiers `.sql` présents dans ce dossier sont des archives historiques propres à d'anciens dialectes. Ils ne doivent pas être exécutés en production.
- Les scripts de `Scripts-api/` sont également historiques et ne font pas partie du processus de déploiement.

Toute nouvelle évolution doit être ajoutée sous forme d'une migration JavaScript idempotente compatible avec les dialectes supportés et testée avec SQLite en mémoire avant déploiement.
