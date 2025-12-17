-- Migration pour rendre la colonne title nullable dans la table contracts
-- Date: 2025-11-03

-- SQLite ne supporte pas ALTER COLUMN directement
-- On doit recréer la table avec la nouvelle structure

PRAGMA foreign_keys=off;

BEGIN TRANSACTION;

-- Créer une table temporaire avec la nouvelle structure
CREATE TABLE contracts_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  reference VARCHAR(255) NOT NULL UNIQUE,
  title VARCHAR(255), -- Maintenant nullable
  description TEXT,
  customer_id INTEGER NOT NULL REFERENCES users(id),
  type VARCHAR(20) NOT NULL DEFAULT 'maintenance',
  status VARCHAR(20) NOT NULL DEFAULT 'draft',
  start_date DATETIME NOT NULL,
  end_date DATETIME NOT NULL,
  amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
  payment_frequency VARCHAR(20) NOT NULL DEFAULT 'yearly',
  terms_and_conditions TEXT,
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Copier les données existantes
INSERT INTO contracts_new 
SELECT * FROM contracts;

-- Supprimer l'ancienne table
DROP TABLE contracts;

-- Renommer la nouvelle table
ALTER TABLE contracts_new RENAME TO contracts;

COMMIT;

PRAGMA foreign_keys=on;
