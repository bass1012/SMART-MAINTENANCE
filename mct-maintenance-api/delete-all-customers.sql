-- Script pour supprimer TOUS les clients et leurs données
-- Usage: sqlite3 database.sqlite < delete-all-customers.sql

BEGIN TRANSACTION;

-- 1. Images d'interventions
DELETE FROM intervention_images 
WHERE intervention_id IN (
  SELECT id FROM interventions 
  WHERE customer_id IN (SELECT id FROM customer_profiles)
);

-- 2. Interventions
DELETE FROM interventions 
WHERE customer_id IN (SELECT id FROM customer_profiles);

-- 3. Items de commandes
DELETE FROM order_items 
WHERE order_id IN (
  SELECT id FROM orders 
  WHERE customerId IN (SELECT id FROM customer_profiles)
);

-- 4. Paiements
DELETE FROM payments 
WHERE order_id IN (
  SELECT id FROM orders 
  WHERE customerId IN (SELECT id FROM customer_profiles)
);

-- 5. Commandes
DELETE FROM orders 
WHERE customerId IN (SELECT id FROM customer_profiles);

-- 6. Items de devis
DELETE FROM quote_items 
WHERE quoteId IN (
  SELECT id FROM quotes 
  WHERE customerId IN (SELECT id FROM customer_profiles)
);

-- 7. Devis
DELETE FROM quotes 
WHERE customerId IN (SELECT id FROM customer_profiles);

-- 8. Réclamations
DELETE FROM complaints 
WHERE customerId IN (SELECT id FROM customer_profiles);

-- 9. Contrats
DELETE FROM contracts 
WHERE customer_id IN (SELECT id FROM customer_profiles);

-- 10. Notifications
DELETE FROM notifications 
WHERE user_id IN (SELECT user_id FROM customer_profiles);

-- 11. Messages de chat
DELETE FROM chat_messages 
WHERE sender_id IN (SELECT user_id FROM customer_profiles) 
   OR recipient_id IN (SELECT user_id FROM customer_profiles);

-- 12. Profils clients
DELETE FROM customer_profiles;

-- 13. Users customers
DELETE FROM users WHERE role='customer';

COMMIT;

-- Afficher le résultat
SELECT 'Suppression terminée!' as result;
SELECT COUNT(*) as remaining_customers FROM users WHERE role='customer';
