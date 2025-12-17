-- Migration: Ajout de la colonne subscription_id à la table payments
-- Date: 2025-10-31

-- Ajouter la colonne subscription_id
ALTER TABLE payments ADD COLUMN subscription_id INTEGER;

-- Créer un index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_payments_subscription_id ON payments(subscription_id);

-- Note: SQLite ne supporte pas l'ajout de contraintes de clé étrangère après création
-- La contrainte sera appliquée via Sequelize au niveau applicatif
