const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, 'database.sqlite');
const db = new sqlite3.Database(dbPath);

console.log('🚀 Début de la migration: Support des articles personnalisés\n');

db.serialize(() => {
  // 1. Sauvegarder les données existantes
  console.log('[1/7] Sauvegarde des données existantes...');
  db.run(`CREATE TABLE order_items_backup AS SELECT * FROM order_items`, (err) => {
    if (err) {
      console.error('❌ Erreur sauvegarde:', err.message);
      return;
    }
    console.log('✅ Données sauvegardées\n');

    // 2. Supprimer l'ancienne table
    console.log('[2/7] Suppression de l\'ancienne table...');
    db.run(`DROP TABLE order_items`, (err) => {
      if (err) {
        console.error('❌ Erreur suppression:', err.message);
        return;
      }
      console.log('✅ Table supprimée\n');

      // 3. Recréer la table avec les nouveaux champs
      console.log('[3/7] Recréation de la table avec support articles personnalisés...');
      db.run(`
        CREATE TABLE order_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_id INTEGER NOT NULL,
          product_id INTEGER,
          product_name TEXT,
          is_custom INTEGER DEFAULT 0,
          quantity INTEGER NOT NULL,
          unit_price REAL NOT NULL,
          total REAL NOT NULL,
          FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
          FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
        )
      `, (err) => {
        if (err) {
          console.error('❌ Erreur création table:', err.message);
          return;
        }
        console.log('✅ Table recréée\n');

        // 4. Restaurer les données
        console.log('[4/7] Restauration des données...');
        db.run(`
          INSERT INTO order_items (id, order_id, product_id, product_name, is_custom, quantity, unit_price, total)
          SELECT 
            id, 
            order_id, 
            product_id,
            NULL as product_name,
            0 as is_custom,
            quantity, 
            unit_price, 
            total
          FROM order_items_backup
        `, (err) => {
          if (err) {
            console.error('❌ Erreur restauration:', err.message);
            return;
          }
          console.log('✅ Données restaurées\n');

          // 5. Supprimer la sauvegarde
          console.log('[5/7] Nettoyage de la sauvegarde...');
          db.run(`DROP TABLE order_items_backup`, (err) => {
            if (err) {
              console.error('❌ Erreur nettoyage:', err.message);
              return;
            }
            console.log('✅ Sauvegarde supprimée\n');

            // 6. Créer les index
            console.log('[6/7] Création des index...');
            db.run(`CREATE INDEX idx_order_items_order_id ON order_items(order_id)`, (err) => {
              if (err && !err.message.includes('already exists')) {
                console.error('❌ Erreur index order_id:', err.message);
              } else {
                console.log('✅ Index order_id créé');
              }

              db.run(`CREATE INDEX idx_order_items_product_id ON order_items(product_id)`, (err) => {
                if (err && !err.message.includes('already exists')) {
                  console.error('❌ Erreur index product_id:', err.message);
                } else {
                  console.log('✅ Index product_id créé');
                }

                db.run(`CREATE INDEX idx_order_items_is_custom ON order_items(is_custom)`, (err) => {
                  if (err && !err.message.includes('already exists')) {
                    console.error('❌ Erreur index is_custom:', err.message);
                  } else {
                    console.log('✅ Index is_custom créé\n');
                  }

                  // 7. Vérifier la structure finale
                  console.log('[7/7] Vérification de la structure finale...');
                  db.all(`PRAGMA table_info(order_items)`, (err, rows) => {
                    if (err) {
                      console.error('❌ Erreur vérification:', err.message);
                    } else {
                      console.log('\n📊 Structure finale de order_items:');
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
});
