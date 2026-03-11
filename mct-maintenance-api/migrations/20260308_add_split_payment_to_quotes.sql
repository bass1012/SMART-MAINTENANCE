-- Migration: Ajouter les champs pour le paiement en deux étapes (50/50) aux devis
-- Date: 2026-03-08

-- Type de paiement: 'full' (paiement intégral) ou 'split' (paiement en 2 fois)
ALTER TABLE quotes ADD COLUMN IF NOT EXISTS payment_type VARCHAR(20) DEFAULT 'split';

-- Premier paiement (50% à l'acceptation du devis)
ALTER TABLE quotes ADD COLUMN IF NOT EXISTS first_payment_amount FLOAT;
ALTER TABLE quotes ADD COLUMN IF NOT EXISTS first_payment_status VARCHAR(20) DEFAULT 'pending';
ALTER TABLE quotes ADD COLUMN IF NOT EXISTS first_payment_date TIMESTAMP;
ALTER TABLE quotes ADD COLUMN IF NOT EXISTS first_payment_transaction_id VARCHAR(255);

-- Second paiement (50% à la fin de l'intervention/émission du rapport)
ALTER TABLE quotes ADD COLUMN IF NOT EXISTS second_payment_amount FLOAT;
ALTER TABLE quotes ADD COLUMN IF NOT EXISTS second_payment_status VARCHAR(20) DEFAULT 'pending';
ALTER TABLE quotes ADD COLUMN IF NOT EXISTS second_payment_date TIMESTAMP;
ALTER TABLE quotes ADD COLUMN IF NOT EXISTS second_payment_transaction_id VARCHAR(255);

-- Commentaire explicatif
COMMENT ON COLUMN quotes.payment_type IS 'Type de paiement: full (intégral) ou split (50/50)';
COMMENT ON COLUMN quotes.first_payment_amount IS 'Montant du premier paiement (50% du total)';
COMMENT ON COLUMN quotes.first_payment_status IS 'Statut: pending, paid';
COMMENT ON COLUMN quotes.second_payment_amount IS 'Montant du second paiement (50% restant)';
COMMENT ON COLUMN quotes.second_payment_status IS 'Statut: pending, paid';
