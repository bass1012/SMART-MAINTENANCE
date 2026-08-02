// Compatibilité avec l'ancienne commande : toutes les migrations passent
// désormais par le moteur unique et sa table migration_history.
const runMigrations = require('./scripts/migrate');

runMigrations().catch((error) => {
  console.error(`❌ Échec des migrations: ${error.message}`);
  process.exitCode = 1;
});
