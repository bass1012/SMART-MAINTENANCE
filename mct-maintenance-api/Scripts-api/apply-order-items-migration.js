const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');

// Chemin vers la base de données
const dbPath = path.join(__dirname, 'database.sqlite');

// Vérifier si la base de données existe
if (!fs.existsSync(dbPath)) {
  console.error('❌ Base de données non trouvée:', dbPath);
  process.exit(1);
}

// Ouvrir la connexion à la base de données
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('❌ Erreur lors de la connexion à la base de données:', err.message);
    process.exit(1);
  }
  console.log('✅ Connecté à la base de données SQLite');
});

// Lire le fichier de migration
const migrationPath = path.join(__dirname, 'migrations', 'add_custom_items_to_orders.sql');
const migrationSQL = fs.readFileSync(migrationPath, 'utf8');

// Séparer les commandes SQL (par point-virgule, en ignorant les commentaires)
const sqlCommands = migrationSQL
  .split(';')
  .map(cmd => cmd.trim())
  .filter(cmd => cmd.length > 0 && !cmd.startsWith('--'));

console.log(`📋 ${sqlCommands.length} commande(s) SQL à exécuter...\n`);
console.log('🚀 Début de la migration: Support des articles personnalisés dans les commandes');
console.log('='.repeat(60) + '\n');

// Exécuter chaque commande SQL séquentiellement
let completed = 0;
let errors = 0;

function executeNext(index) {
  if (index >= sqlCommands.length) {
    // Toutes les commandes ont été exécutées
    console.log('\n' + '='.repeat(60));
    console.log(`✅ Migration terminée: ${completed} commande(s) réussie(s)`);
    if (errors > 0) {
      console.log(`⚠️  ${errors} erreur(s) rencontrée(s)`);
    }
    console.log('='.repeat(60));
    
    // Fermer la connexion
    db.close((err) => {
      if (err) {
        console.error('❌ Erreur lors de la fermeture:', err.message);
      }
      process.exit(errors > 0 ? 1 : 0);
    });
    return;
  }

  const sql = sqlCommands[index];
  const commandType = sql.split(' ')[0].toUpperCase();
  
  console.log(`[${index + 1}/${sqlCommands.length}] Exécution: ${commandType}...`);
  
  db.run(sql, function(err) {
    if (err) {
      // Ignorer certaines erreurs
      if (err.message.includes('already exists') || err.message.includes('duplicate')) {
        console.log(`⚠️  Élément déjà existant, migration déjà appliquée`);
        completed++;
      } else {
        console.error(`❌ Erreur:`, err.message);
        errors++;
      }
    } else {
      console.log(`✅ ${commandType} réussi`);
      completed++;
    }
    
    // Exécuter la commande suivante
    executeNext(index + 1);
  });
}

// Démarrer l'exécution
executeNext(0);
