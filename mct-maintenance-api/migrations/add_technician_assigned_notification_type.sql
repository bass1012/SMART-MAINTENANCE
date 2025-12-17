-- Migration: Ajouter le type de notification 'technician_assigned'
-- Date: 2025-10-30
-- Description: Ajoute le type 'technician_assigned' pour notifier les clients 
--              quand un technicien est assigné à leur intervention

-- Note: SQLite ne supporte pas ALTER TYPE pour les ENUMs
-- Il faut recréer la table avec les nouvelles valeurs

-- 1. Créer une table temporaire avec le nouveau type
CREATE TABLE notifications_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
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
    'payment_received',
    'report_submitted',
    'general'
  )),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data TEXT,
  is_read INTEGER DEFAULT 0,
  read_at DATETIME,
  priority TEXT DEFAULT 'medium' CHECK(priority IN ('low', 'medium', 'high')),
  action_url TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
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
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- Vérification
SELECT COUNT(*) as total_notifications FROM notifications;
