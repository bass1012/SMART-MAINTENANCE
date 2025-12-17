-- Migration: Ajouter les types de notification manquants
-- Date: 2025-11-04

BEGIN TRANSACTION;

-- 1. Créer une table temporaire avec les nouveaux types
CREATE TABLE notifications_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  type TEXT CHECK(type IN (
    'intervention_request',
    'intervention_assigned',
    'technician_assigned',
    'intervention_completed',
    'complaint_created',
    'complaint_response',
    'complaint_status_change',
    'subscription_created',
    'subscription_expiring',
    'order_created',
    'order_status_update',
    'quote_created',
    'quote_sent',
    'quote_updated',
    'quote_accepted',
    'quote_rejected',
    'contract_created',
    'contract_expiring',
    'contract_renewal_request',
    'payment_received',
    'report_submitted',
    'general'
  )) NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data TEXT,
  is_read INTEGER DEFAULT 0,
  read_at DATETIME,
  priority TEXT CHECK(priority IN ('low', 'medium', 'high', 'urgent')) DEFAULT 'medium',
  action_url TEXT,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 2. Copier les données existantes
INSERT INTO notifications_new 
SELECT * FROM notifications;

-- 3. Supprimer l'ancienne table
DROP TABLE notifications;

-- 4. Renommer la nouvelle table
ALTER TABLE notifications_new RENAME TO notifications;

-- 5. Recréer les index
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
CREATE INDEX notifications_user_id ON notifications(user_id);
CREATE INDEX notifications_is_read ON notifications(is_read);
CREATE INDEX notifications_type ON notifications(type);
CREATE INDEX notifications_created_at ON notifications(created_at);

COMMIT;
