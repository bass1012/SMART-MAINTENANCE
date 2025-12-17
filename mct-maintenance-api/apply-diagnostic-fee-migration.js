const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, 'database.sqlite');
const db = new sqlite3.Database(dbPath);

console.log('🔧 Application de la migration: diagnostic_fee pour interventions');

db.serialize(() => {
  // Vérifier si les colonnes existent déjà
  db.all("PRAGMA table_info(interventions)", [], (err, columns) => {
    if (err) {
      console.error('❌ Erreur lors de la vérification de la table:', err);
      return;
    }

    const haseDiagnosticFee = columns.some(col => col.name === 'diagnostic_fee');
    const hasFreeDiagnosis = columns.some(col => col.name === 'is_free_diagnosis');

    if (haseDiagnosticFee && hasFreeDiagnosis) {
      console.log('✅ Les colonnes existent déjà');
      db.close();
      return;
    }

    console.log('📝 Ajout des colonnes diagnostic_fee et is_free_diagnosis...');

    db.run(`
      ALTER TABLE interventions 
      ADD COLUMN diagnostic_fee REAL DEFAULT 0.00
    `, (err) => {
      if (err && !err.message.includes('duplicate column')) {
        console.error('❌ Erreur lors de l\'ajout de diagnostic_fee:', err);
      } else {
        console.log('✅ Colonne diagnostic_fee ajoutée');
      }
    });

    db.run(`
      ALTER TABLE interventions 
      ADD COLUMN is_free_diagnosis INTEGER DEFAULT 0
    `, (err) => {
      if (err && !err.message.includes('duplicate column')) {
        console.error('❌ Erreur lors de l\'ajout de is_free_diagnosis:', err);
      } else {
        console.log('✅ Colonne is_free_diagnosis ajoutée');
      }

      // Mettre à jour les interventions existantes avec contrat
      console.log('🔄 Mise à jour des interventions existantes avec contrat...');
      db.run(`
        UPDATE interventions 
        SET is_free_diagnosis = 1, diagnostic_fee = 0.00 
        WHERE contract_id IS NOT NULL
      `, (err) => {
        if (err) {
          console.error('❌ Erreur lors de la mise à jour des interventions avec contrat:', err);
        } else {
          console.log('✅ Interventions avec contrat mises à jour (diagnostic gratuit)');
        }
      });

      // Mettre à jour les interventions sans contrat
      console.log('🔄 Mise à jour des interventions sans contrat...');
      db.run(`
        UPDATE interventions 
        SET is_free_diagnosis = 0, diagnostic_fee = 4000.00 
        WHERE contract_id IS NULL
      `, (err) => {
        if (err) {
          console.error('❌ Erreur lors de la mise à jour des interventions sans contrat:', err);
        } else {
          console.log('✅ Interventions sans contrat mises à jour (diagnostic 4000 FCFA)');
        }

        // Afficher un résumé
        db.get(`
          SELECT 
            COUNT(*) as total,
            SUM(CASE WHEN is_free_diagnosis = 1 THEN 1 ELSE 0 END) as gratuit,
            SUM(CASE WHEN is_free_diagnosis = 0 THEN 1 ELSE 0 END) as payant
          FROM interventions
        `, [], (err, row) => {
          if (err) {
            console.error('❌ Erreur lors du résumé:', err);
          } else {
            console.log('\n📊 Résumé:');
            console.log(`   Total interventions: ${row.total}`);
            console.log(`   Diagnostics gratuits: ${row.gratuit}`);
            console.log(`   Diagnostics payants: ${row.payant}`);
          }

          console.log('\n✅ Migration terminée avec succès!');
          db.close();
        });
      });
    });
  });
});
