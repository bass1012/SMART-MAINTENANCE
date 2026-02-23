-- Fix foreign key constraint for interventions table
-- customer_id should reference customer_profiles(id), not users(id)

BEGIN TRANSACTION;

-- Créer une nouvelle table avec la bonne contrainte
CREATE TABLE interventions_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT,
  address TEXT,
  status TEXT DEFAULT 'pending',
  priority TEXT DEFAULT 'normal',
  intervention_type TEXT DEFAULT 'maintenance',
  scheduled_date DATETIME NOT NULL,
  customer_id INTEGER NOT NULL,
  technician_id INTEGER,
  equipment_count INTEGER DEFAULT 1,
  diagnostic_fee REAL DEFAULT 0,
  is_free_diagnosis INTEGER DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customer_profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (technician_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Copier les données existantes (s'il y en a)
INSERT INTO interventions_new SELECT * FROM interventions;

-- Supprimer l'ancienne table
DROP TABLE interventions;

-- Renommer la nouvelle table
ALTER TABLE interventions_new RENAME TO interventions;

COMMIT;

-- Vérifier la nouvelle contrainte
SELECT '=== Vérification des contraintes ===' AS info;
PRAGMA foreign_key_list(interventions);
