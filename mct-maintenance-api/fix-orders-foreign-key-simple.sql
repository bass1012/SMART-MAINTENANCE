-- Fix foreign key constraint for orders table - Version simple
-- customer_id should reference customer_profiles(id), not users(id)

BEGIN TRANSACTION;

-- Supprimer l'ancienne table
DROP TABLE IF EXISTS orders;

-- Créer la nouvelle table avec la bonne contrainte
CREATE TABLE orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customer_id INTEGER NOT NULL,
  total_amount REAL NOT NULL,
  status TEXT DEFAULT 'pending',
  payment_status TEXT DEFAULT 'pending',
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customer_profiles(id) ON DELETE CASCADE
);

COMMIT;

-- Vérifier la nouvelle contrainte
SELECT '=== Vérification des contraintes orders ===' AS info;
PRAGMA foreign_key_list(orders);
