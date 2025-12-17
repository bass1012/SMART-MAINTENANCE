-- Migration: Rendre order_id nullable dans la table payments
-- Date: 2025-10-31
-- Raison: Un paiement peut être pour une commande OU une souscription

-- SQLite ne permet pas de modifier directement les contraintes
-- Il faut recréer la table

BEGIN TRANSACTION;

-- 1. Renommer l'ancienne table
ALTER TABLE payments RENAME TO payments_old;

-- 2. Créer la nouvelle table avec order_id nullable
CREATE TABLE payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER NULL,  -- Maintenant nullable
    subscription_id INTEGER NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'XOF',
    provider TEXT NOT NULL,
    payment_id VARCHAR(255),
    status TEXT DEFAULT 'pending',
    payment_method VARCHAR(255),
    phone_number VARCHAR(255),
    transaction_id VARCHAR(255),
    checkout_url TEXT,
    metadata JSON,
    error_message TEXT,
    paid_at DATETIME,
    refunded_at DATETIME,
    refund_amount DECIMAL(10,2),
    refund_reason TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. Copier les données
INSERT INTO payments 
SELECT * FROM payments_old;

-- 4. Recréer les index
CREATE INDEX IF NOT EXISTS payments_order_id ON payments(order_id);
CREATE INDEX IF NOT EXISTS payments_payment_id ON payments(payment_id);
CREATE INDEX IF NOT EXISTS payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS payments_provider ON payments(provider);
CREATE INDEX IF NOT EXISTS idx_payments_subscription_id ON payments(subscription_id);

-- 5. Supprimer l'ancienne table
DROP TABLE payments_old;

COMMIT;
