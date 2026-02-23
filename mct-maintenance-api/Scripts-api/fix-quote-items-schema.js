const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, 'database.sqlite');
const db = new sqlite3.Database(dbPath);

console.log('🚀 Début de la migration: Ajout is_custom à quote_items\n');

db.serialize(() => {
  // 1. Vérifier si la colonne existe déjà
  console.log('[1/8] Vérification de la structure actuelle...');
  db.all(`PRAGMA table_info(quote_items)`, (err, columns) => {
    if (err) {
      console.error('❌ Erreur vérification:', err.message);
      db.close();
      return;
    }

    const hasIsCustom = columns.some(col => col.name === 'is_custom' || col.name === 'isCustom');
    
    if (hasIsCustom) {
      console.log('✅ La colonne is_custom existe déjà\n');
      console.log('📊 Structure actuelle:');
      console.log('━'.repeat(60));
      columns.forEach(col => {
        console.log(`  ${col.name.padEnd(15)} ${col.type.padEnd(10)}`);
      });
      console.log('━'.repeat(60));
      db.close();
      return;
    }

    console.log('⚠️  La colonne is_custom n\'existe pas, migration nécessaire\n');

    // 2. Sauvegarder les données existantes
    console.log('[2/8] Sauvegarde des données existantes...');
    db.run(`CREATE TABLE quote_items_backup AS SELECT * FROM quote_items`, (err) => {
      if (err) {
        console.error('❌ Erreur sauvegarde:', err.message);
        db.close();
        return;
      }
      console.log('✅ Données sauvegardées\n');

      // 3. Supprimer l'ancienne table
      console.log('[3/8] Suppression de l\'ancienne table...');
      db.run(`DROP TABLE quote_items`, (err) => {
        if (err) {
          console.error('❌ Erreur suppression:', err.message);
          db.close();
          return;
        }
        console.log('✅ Table supprimée\n');

        // 4. Recréer la table avec le nouveau champ
        console.log('[4/8] Recréation de la table avec is_custom...');
        db.run(`
          CREATE TABLE quote_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            quoteId INTEGER NOT NULL,
            productId INTEGER NOT NULL,
            productName TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            unitPrice REAL NOT NULL,
            discount REAL DEFAULT 0,
            taxRate REAL DEFAULT 20,
            is_custom INTEGER DEFAULT 0,
            created_at TEXT,
            updated_at TEXT,
            FOREIGN KEY (quoteId) REFERENCES quotes(id) ON DELETE CASCADE
          )
        `, (err) => {
          if (err) {
            console.error('❌ Erreur création table:', err.message);
            db.close();
            return;
          }
          console.log('✅ Table recréée\n');

          // 5. Restaurer les données
          console.log('[5/8] Restauration des données...');
          db.run(`
            INSERT INTO quote_items (
              id, quoteId, productId, productName, quantity, 
              unitPrice, discount, taxRate, is_custom, created_at, updated_at
            )
            SELECT 
              id, quoteId, productId, productName, quantity,
              unitPrice, 
              COALESCE(discount, 0) as discount,
              COALESCE(taxRate, 20) as taxRate,
              0 as is_custom,
              created_at, 
              updated_at
            FROM quote_items_backup
          `, (err) => {
            if (err) {
              console.error('❌ Erreur restauration:', err.message);
              db.close();
              return;
            }
            console.log('✅ Données restaurées\n');

            // 6. Supprimer la sauvegarde
            console.log('[6/8] Nettoyage de la sauvegarde...');
            db.run(`DROP TABLE quote_items_backup`, (err) => {
              if (err) {
                console.error('❌ Erreur nettoyage:', err.message);
                db.close();
                return;
              }
              console.log('✅ Sauvegarde supprimée\n');

              // 7. Créer l'index
              console.log('[7/8] Création de l\'index...');
              db.run(`CREATE INDEX idx_quote_items_is_custom ON quote_items(is_custom)`, (err) => {
                if (err && !err.message.includes('already exists')) {
                  console.error('❌ Erreur index:', err.message);
                } else {
                  console.log('✅ Index créé\n');
                }

                // 8. Vérifier la structure finale
                console.log('[8/8] Vérification de la structure finale...');
                db.all(`PRAGMA table_info(quote_items)`, (err, rows) => {
                  if (err) {
                    console.error('❌ Erreur vérification:', err.message);
                  } else {
                    console.log('\n📊 Structure finale de quote_items:');
                    console.log('━'.repeat(60));
                    rows.forEach(row => {
                      const nullable = row.notnull ? 'NOT NULL' : 'NULL';
                      const defaultVal = row.dflt_value ? `DEFAULT ${row.dflt_value}` : '';
                      console.log(`  ${row.name.padEnd(15)} ${row.type.padEnd(10)} ${nullable.padEnd(10)} ${defaultVal}`);
                    });
                    console.log('━'.repeat(60));
                    console.log('\n✅ Migration terminée avec succès!\n');
                  }

                  db.close();
                });
              });
            });
          });
        });
      });
    });
  });
});
