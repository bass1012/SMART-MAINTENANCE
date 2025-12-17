-- Migration pour ajouter le type de notification contract_renewal_request
-- Date: 2025-11-03

-- SQLite ne supporte pas ALTER TYPE pour les ENUM
-- On doit recréer la colonne type avec le nouveau ENUM

PRAGMA foreign_keys=off;

BEGIN TRANSACTION;

-- Créer une table temporaire avec la nouvelle structure
CREATE TABLE notifications_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK(type IN (
    'intervention_request',
    'intervention_assigned',
    'technician_assigned',
    'intervention_completed',
    'complaint_created',
    'complaint_response',
    'subscription_created',
    'subscription_expiring',
    'order_created',
    'order_status_update',
    'quote_created',
    'quote_accepted',
    'quote_rejected',
    'contract_created',
    'contract_expiring',
    'contract_renewal_request',
    'payment_received',
    'report_submitted',
    'general'
  )),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data TEXT,
  priority TEXT NOT NULL DEFAULT 'medium' CHECK(priority IN ('low', 'medium', 'high', 'urgent')),
  action_url TEXT,
  is_read INTEGER NOT NULL DEFAULT 0,
  read_at DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Copier les données existantes avec conversion de priorité
INSERT INTO notifications_new 
SELECT 
  id, user_id, type, title, message, data,
  CASE 
    WHEN priority IN ('low', 'medium', 'high', 'urgent') THEN priority
    ELSE 'medium'
  END as priority,
  action_url, is_read, read_at, created_at, updated_at
FROM notifications;

-- Supprimer l'ancienne table
DROP TABLE notifications;

-- Renommer la nouvelle table
ALTER TABLE notifications_new RENAME TO notifications;

-- Recréer les index
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

COMMIT;

PRAGMA foreign_keys=on;
