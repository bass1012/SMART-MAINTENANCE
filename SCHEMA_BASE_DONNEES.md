# Schéma de Base de Données - MCT Maintenance API

## Vue d'ensemble

Ce document décrit le schéma complet de la base de données avec toutes les tables, colonnes et relations.

---

## 📊 Tables et Attributs

### 1. `users`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `email` | VARCHAR(255) | UNIQUE, NULL (si phone fourni) |
| `first_name` | VARCHAR(100) | NULL |
| `last_name` | VARCHAR(100) | NULL |
| `password_hash` | VARCHAR(255) | NOT NULL |
| `phone` | VARCHAR(20) | NULL |
| `role` | ENUM('admin', 'customer', 'technician', 'depannage', 'manager') | NOT NULL, DEFAULT 'customer' |
| `status` | ENUM('active', 'inactive', 'pending') | NOT NULL, DEFAULT 'pending' |
| `last_login` | DATE | NULL |
| `email_verified` | BOOLEAN | NOT NULL, DEFAULT false |
| `email_verification_token` | VARCHAR(255) | NULL |
| `email_verification_expires` | DATE | NULL |
| `phone_verified` | BOOLEAN | NOT NULL, DEFAULT false |
| `profile_image` | VARCHAR(255) | NULL |
| `fcm_token` | VARCHAR(255) | NULL |
| `created_by` | INTEGER | NULL |
| `preferences` | JSON | NULL, DEFAULT {} |
| `createdAt` | TIMESTAMP | AUTO |
| `updatedAt` | TIMESTAMP | AUTO |

---

### 2. `customer_profiles`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `user_id` | INTEGER | FK → users.id, UNIQUE, NOT NULL |
| `first_name` | VARCHAR(100) | NOT NULL |
| `last_name` | VARCHAR(100) | NOT NULL |
| `commune` | VARCHAR(100) | NULL |
| `latitude` | DECIMAL(10, 7) | NULL |
| `longitude` | DECIMAL(10, 7) | NULL |
| `country` | VARCHAR(50) | NOT NULL, DEFAULT "Côte d'Ivoire" |
| `city` | VARCHAR(100) | NULL |
| `company_name` | VARCHAR(255) | NULL |
| `company_type` | ENUM('household', 'healthcare', 'commerce', 'enterprise', 'administration') | NULL |
| `gender` | ENUM('male', 'female', 'other') | NULL |
| `preferences` | JSON | NULL, DEFAULT {...} |
| `createdAt` | TIMESTAMP | AUTO |
| `updatedAt` | TIMESTAMP | AUTO |

---

### 3. `technician_profiles`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `user_id` | INTEGER | FK → users.id, UNIQUE, NOT NULL |
| `first_name` | VARCHAR(100) | NOT NULL |
| `last_name` | VARCHAR(100) | NOT NULL |
| `phone` | VARCHAR(20) | NOT NULL |
| `address` | TEXT | NULL |
| `specialization` | VARCHAR(100) | NULL |
| `experience_years` | INTEGER | NULL (0-50) |
| `certification` | VARCHAR(255) | NULL |
| `certification_date` | DATE | NULL |
| `availability_status` | ENUM('available', 'busy', 'offline') | NOT NULL, DEFAULT 'offline' |
| `current_location_lat` | DECIMAL(10, 8) | NULL |
| `current_location_lng` | DECIMAL(11, 8) | NULL |
| `service_area` | JSON | NULL, DEFAULT [] |
| `skills` | JSON | NULL, DEFAULT [] |
| `hourly_rate` | DECIMAL(10, 2) | NULL |
| `rating` | DECIMAL(3, 2) | NULL, DEFAULT 0 |
| `total_reviews` | INTEGER | NOT NULL, DEFAULT 0 |
| `total_assignments` | INTEGER | NOT NULL, DEFAULT 0 |
| `completed_assignments` | INTEGER | NOT NULL, DEFAULT 0 |
| `is_verified` | BOOLEAN | NOT NULL, DEFAULT false |
| `verification_documents` | JSON | NULL, DEFAULT [] |
| `bio` | TEXT | NULL |
| `working_hours` | JSON | NULL, DEFAULT {...} |
| `emergency_contact_name` | VARCHAR(255) | NULL |
| `emergency_contact_phone` | VARCHAR(20) | NULL |
| `emergency_contact_relation` | VARCHAR(100) | NULL |
| `bank_account` | JSON | NULL, DEFAULT {} |
| `notes` | TEXT | NULL |
| `createdAt` | TIMESTAMP | AUTO |
| `updatedAt` | TIMESTAMP | AUTO |

---

### 4. `equipments`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `customer_id` | INTEGER | FK → users.id, NOT NULL |
| `name` | VARCHAR(255) | NOT NULL |
| `type` | VARCHAR(100) | NOT NULL |
| `brand` | VARCHAR(100) | NULL |
| `model` | VARCHAR(100) | NULL |
| `serial_number` | VARCHAR(100) | UNIQUE, NULL |
| `installation_date` | DATE | NULL |
| `purchase_date` | DATE | NULL |
| `warranty_expiry` | DATE | NULL |
| `location` | VARCHAR(255) | NULL |
| `status` | ENUM('active', 'inactive', 'maintenance', 'retired') | NOT NULL, DEFAULT 'active' |
| `last_maintenance_date` | DATE | NULL |
| `next_maintenance_date` | DATE | NULL |
| `notes` | TEXT | NULL |
| `createdAt` | TIMESTAMP | AUTO |
| `updatedAt` | TIMESTAMP | AUTO |
| `deletedAt` | TIMESTAMP | NULL (soft delete) |

---

### 5. `interventions`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `title` | VARCHAR | NOT NULL |
| `description` | TEXT | NOT NULL |
| `address` | VARCHAR | NULL |
| `status` | ENUM('pending', 'assigned', 'accepted', 'on_the_way', 'arrived', 'in_progress', 'completed', 'cancelled') | NOT NULL, DEFAULT 'pending' |
| `priority` | ENUM('low', 'normal', 'medium', 'high', 'urgent', 'critical') | NOT NULL |
| `intervention_type` | VARCHAR | NULL |
| `climatiseur_type` | VARCHAR | NULL |
| `scheduled_date` | DATE | NOT NULL |
| `completed_date` | DATE | NULL |
| `customer_id` | INTEGER | FK → users.id, NOT NULL |
| `technician_id` | INTEGER | FK → users.id, NULL |
| `product_id` | INTEGER | NULL |
| `contract_id` | INTEGER | NULL |
| `equipment_count` | INTEGER | NULL, DEFAULT 1 |
| `maintenance_offer_id` | INTEGER | FK → maintenance_offers.id, NULL |
| `repair_service_id` | INTEGER | FK → repair_services.id, NULL |
| `installation_service_id` | INTEGER | FK → installation_services.id, NULL |
| `split_id` | INTEGER | FK → Splits.id, NULL |
| `accepted_at` | DATE | NULL |
| `departed_at` | DATE | NULL |
| `arrived_at` | DATE | NULL |
| `started_at` | DATE | NULL |
| `completed_at` | DATE | NULL |
| `report_data` | TEXT (JSON) | NULL |
| `report_submitted_at` | DATE | NULL |
| `diagnostic_fee` | DECIMAL(10, 2) | NULL, DEFAULT 0 |
| `is_free_diagnosis` | BOOLEAN | NULL, DEFAULT true |
| `diagnostic_paid` | BOOLEAN | NULL, DEFAULT false |
| `diagnostic_payment_date` | DATE | NULL |
| `customer_confirmed` | BOOLEAN | NULL, DEFAULT false |
| `customer_confirmed_at` | DATE | NULL |
| `customer_rejection_reason` | TEXT | NULL |
| `rating` | INTEGER | NULL (1-5) |
| `review` | TEXT | NULL |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |

---

### 6. `intervention_images`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `intervention_id` | INTEGER | FK → interventions.id, NOT NULL, ON DELETE CASCADE |
| `image_url` | VARCHAR | NOT NULL |
| `order` | INTEGER | NOT NULL, DEFAULT 0 |
| `image_type` | VARCHAR(50) | NULL, DEFAULT 'intervention' |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |

---

### 7. `contracts`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `reference` | VARCHAR | UNIQUE, NOT NULL |
| `title` | VARCHAR | NULL |
| `description` | TEXT | NULL |
| `customer_id` | INTEGER | FK → users.id, NOT NULL |
| `type` | ENUM('maintenance', 'support', 'warranty', 'service') | NOT NULL, DEFAULT 'maintenance' |
| `status` | ENUM('draft', 'active', 'expired', 'terminated', 'pending') | NOT NULL, DEFAULT 'draft' |
| `start_date` | DATE | NOT NULL |
| `end_date` | DATE | NOT NULL |
| `amount` | DECIMAL(10, 2) | NOT NULL, DEFAULT 0 |
| `payment_frequency` | ENUM('monthly', 'quarterly', 'yearly', 'one_time') | NOT NULL, DEFAULT 'yearly' |
| `terms_and_conditions` | TEXT | NULL |
| `notes` | TEXT | NULL |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |

---

### 8. `products`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `nom` | VARCHAR | NOT NULL |
| `reference` | VARCHAR | UNIQUE, NOT NULL |
| `description` | TEXT | NOT NULL |
| `prix` | FLOAT | NOT NULL |
| `quantite_stock` | INTEGER | NOT NULL, DEFAULT 0 |
| `seuil_alerte` | INTEGER | NOT NULL, DEFAULT 0 |
| `marque_id` | INTEGER | FK → brands.id, NULL |
| `categorie_id` | INTEGER | FK → categories.id, NOT NULL |
| `actif` | BOOLEAN | NOT NULL, DEFAULT true |
| `images` | JSON | NOT NULL, DEFAULT [] |
| `specifications` | JSON | NOT NULL, DEFAULT {} |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |
| `deleted_at` | TIMESTAMP | NULL (soft delete) |

---

### 9. `categories`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `nom` | VARCHAR | UNIQUE, NOT NULL |
| `description` | TEXT | NULL |
| `icone` | VARCHAR | NULL |
| `actif` | BOOLEAN | NOT NULL, DEFAULT true |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |

---

### 10. `brands`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `nom` | VARCHAR | UNIQUE, NOT NULL |
| `description` | TEXT | NULL |
| `logo` | VARCHAR | NULL |
| `actif` | BOOLEAN | NOT NULL, DEFAULT true |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |

---

### 11. `quotes`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `reference` | VARCHAR | UNIQUE, NOT NULL |
| `customerId` | INTEGER | NOT NULL |
| `customerName` | VARCHAR | NULL |
| `issueDate` | DATE | NOT NULL |
| `expiryDate` | DATE | NOT NULL |
| `status` | ENUM('draft', 'sent', 'accepted', 'rejected', 'expired', 'converted') | DEFAULT 'draft' |
| `subtotal` | FLOAT | NOT NULL |
| `taxAmount` | FLOAT | NOT NULL |
| `discountAmount` | FLOAT | NOT NULL |
| `total` | FLOAT | NOT NULL |
| `notes` | TEXT | NULL |
| `termsAndConditions` | TEXT | NULL |
| `rejection_reason` | TEXT | NULL |
| `scheduled_date` | DATE | NULL |
| `second_contact` | VARCHAR | NULL |
| `execute_now` | BOOLEAN | NULL, DEFAULT false |
| `intervention_id` | INTEGER | FK → interventions.id, NULL |
| `diagnostic_report_id` | INTEGER | FK → diagnostic_reports.id, NULL |
| `line_items` | TEXT (JSON) | NULL |
| `sent_at` | DATE | NULL |
| `viewed_at` | DATE | NULL |
| `responded_at` | DATE | NULL |
| `payment_status` | VARCHAR | DEFAULT 'pending' |
| `paid_at` | DATE | NULL |
| `payment_method` | VARCHAR | NULL |
| `payment_transaction_id` | VARCHAR | NULL |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |

---

### 12. `quote_items`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `quoteId` | INTEGER | FK → quotes.id, NOT NULL |
| `productId` | INTEGER | NOT NULL |
| `productName` | VARCHAR | NULL |
| `quantity` | INTEGER | NOT NULL |
| `unitPrice` | FLOAT | NOT NULL |
| `discount` | FLOAT | DEFAULT 0 |
| `taxRate` | FLOAT | DEFAULT 20 |
| `is_custom` | BOOLEAN | DEFAULT false |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |

---

### 13. `orders`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `customer_id` | INTEGER | NOT NULL |
| `quote_id` | INTEGER | FK → quotes.id, NULL |
| `total_amount` | FLOAT | NOT NULL |
| `status` | ENUM('pending', 'processing', 'completed', 'cancelled') | DEFAULT 'pending' |
| `payment_status` | ENUM('pending', 'paid', 'failed', 'refunded') | DEFAULT 'pending' |
| `notes` | TEXT | NULL |
| `shipping_address` | VARCHAR | NULL |
| `payment_method` | VARCHAR | NULL |
| `reference` | VARCHAR | NULL |
| `tracking_url` | VARCHAR(500) | NULL |
| `promo_code` | VARCHAR | NULL |
| `promo_discount` | FLOAT | DEFAULT 0 |
| `promo_id` | INTEGER | NULL |
| `fineopay_checkout_id` | VARCHAR | NULL |
| `fineopay_reference` | VARCHAR | NULL |
| `payment_date` | DATE | NULL |
| `payment_processing` | BOOLEAN | DEFAULT false |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |
| `deleted_at` | TIMESTAMP | NULL (soft delete) |

---

### 14. `order_items`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `order_id` | INTEGER | FK → orders.id, NOT NULL |
| `product_id` | INTEGER | FK → products.id, NULL |
| `product_name` | VARCHAR | NULL |
| `is_custom` | BOOLEAN | DEFAULT false |
| `quantity` | INTEGER | NOT NULL |
| `unit_price` | FLOAT | NOT NULL |
| `total` | FLOAT | NOT NULL |

---

### 15. `complaints`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `reference` | VARCHAR(50) | UNIQUE, NOT NULL |
| `customer_id` | INTEGER | NOT NULL |
| `order_id` | INTEGER | FK → orders.id, NULL |
| `product_id` | INTEGER | FK → products.id, NULL |
| `intervention_id` | INTEGER | NULL |
| `subject` | VARCHAR(255) | NOT NULL |
| `description` | TEXT | NOT NULL |
| `status` | VARCHAR | NOT NULL, DEFAULT 'open' |
| `priority` | VARCHAR | NOT NULL, DEFAULT 'medium' |
| `category` | VARCHAR(100) | NULL |
| `resolution` | TEXT | NULL |
| `resolved_at` | DATE | NULL |
| `assigned_to` | INTEGER | NULL |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |
| `deleted_at` | TIMESTAMP | NULL (soft delete) |

---

### 16. `complaint_notes`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `complaint_id` | INTEGER | FK → complaints.id, NOT NULL |
| `user_id` | INTEGER | FK → users.id, NOT NULL |
| `note` | TEXT | NOT NULL |
| `is_internal` | BOOLEAN | NOT NULL, DEFAULT false |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |
| `deleted_at` | TIMESTAMP | NULL (soft delete) |

---

### 17. `maintenance_offers`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `title` | VARCHAR(255) | NOT NULL |
| `description` | TEXT | NULL |
| `price` | DECIMAL(10, 2) | NOT NULL |
| `duration` | INTEGER | NULL, DEFAULT 1 |
| `features` | TEXT (JSON) | NULL |
| `is_active` | BOOLEAN | NOT NULL, DEFAULT true |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |
| `deleted_at` | TIMESTAMP | NULL (soft delete) |

---

### 18. `installation_services`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `title` | VARCHAR | NOT NULL |
| `model` | VARCHAR | NOT NULL |
| `price` | DECIMAL(10, 2) | NOT NULL |
| `description` | TEXT | NULL |
| `duration` | INTEGER | NULL |
| `is_active` | BOOLEAN | DEFAULT true |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |

---

### 19. `repair_services`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `title` | VARCHAR | NOT NULL |
| `model` | VARCHAR | NOT NULL |
| `price` | DECIMAL(10, 2) | NOT NULL |
| `description` | TEXT | NULL |
| `duration` | INTEGER | NULL |
| `is_active` | BOOLEAN | DEFAULT true |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |

---

### 20. `subscriptions`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `customer_id` | INTEGER | FK → users.id, NOT NULL |
| `maintenance_offer_id` | INTEGER | FK → maintenance_offers.id, NULL |
| `installation_service_id` | INTEGER | FK → installation_services.id, NULL |
| `repair_service_id` | INTEGER | FK → repair_services.id, NULL |
| `split_id` | INTEGER | FK → Splits.id, NULL |
| `equipment_count` | INTEGER | NOT NULL, DEFAULT 1 |
| `equipment_used` | INTEGER | NOT NULL, DEFAULT 0 |
| `status` | ENUM('active', 'used', 'expired', 'cancelled') | DEFAULT 'active' |
| `start_date` | DATE | NOT NULL |
| `end_date` | DATE | NOT NULL |
| `price` | FLOAT | NOT NULL |
| `original_price` | FLOAT | NULL |
| `discount_amount` | FLOAT | NULL, DEFAULT 0 |
| `promo_code` | VARCHAR(50) | NULL |
| `payment_status` | ENUM('pending', 'paid', 'failed') | DEFAULT 'pending' |
| `intervention_id` | INTEGER | NULL |
| `used_at` | DATE | NULL |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |
| `deleted_at` | TIMESTAMP | NULL (soft delete) |

---

### 21. `notifications`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `user_id` | INTEGER | FK → users.id, NOT NULL, ON DELETE CASCADE |
| `type` | ENUM(nombreux types...) | NOT NULL |
| `title` | VARCHAR | NOT NULL |
| `message` | TEXT | NOT NULL |
| `data` | JSON | NULL |
| `is_read` | BOOLEAN | DEFAULT false |
| `read_at` | DATE | NULL |
| `priority` | ENUM('low', 'medium', 'high', 'urgent') | DEFAULT 'medium' |
| `action_url` | VARCHAR | NULL |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |

---

### 22. `chat_messages`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `sender_id` | INTEGER | FK → users.id, NOT NULL |
| `sender_role` | ENUM('customer', 'admin', 'technician') | NOT NULL |
| `recipient_id` | INTEGER | FK → users.id, NULL |
| `message` | TEXT | NOT NULL |
| `is_read` | BOOLEAN | DEFAULT false |
| `attachment_url` | VARCHAR | NULL |
| `attachment_type` | ENUM('image', 'file', 'audio') | NULL |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |

---

### 23. `payments`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `order_id` | INTEGER | FK → orders.id, NULL |
| `subscription_id` | INTEGER | FK → subscriptions.id, NULL |
| `amount` | DECIMAL(10, 2) | NOT NULL |
| `currency` | VARCHAR(3) | DEFAULT 'XOF' |
| `provider` | ENUM('stripe', 'wave', 'orange_money', 'mtn_money', 'moov_money', 'cash') | NOT NULL |
| `payment_id` | VARCHAR | NULL |
| `status` | ENUM('pending', 'processing', 'succeeded', 'failed', 'refunded', 'cancelled') | DEFAULT 'pending' |
| `payment_method` | VARCHAR | NULL |
| `phone_number` | VARCHAR | NULL |
| `transaction_id` | VARCHAR | NULL |
| `checkout_url` | TEXT | NULL |
| `metadata` | JSON | NULL |
| `error_message` | TEXT | NULL |
| `paid_at` | DATE | NULL |
| `refunded_at` | DATE | NULL |
| `refund_amount` | DECIMAL(10, 2) | NULL |
| `refund_reason` | TEXT | NULL |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |

---

### 24. `payment_logs`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `order_id` | INTEGER | NULL |
| `event_type` | ENUM('checkout_created', 'webhook_received', 'status_check', 'payment_confirmed', 'payment_failed', 'signature_invalid', 'duplicate_blocked', 'manual_sync') | NOT NULL |
| `provider` | VARCHAR(50) | DEFAULT 'fineopay' |
| `fineopay_reference` | VARCHAR | NULL |
| `checkout_link_id` | VARCHAR | NULL |
| `amount` | FLOAT | NULL |
| `payment_status` | VARCHAR(50) | NULL |
| `source_ip` | VARCHAR(50) | NULL |
| `user_agent` | VARCHAR(500) | NULL |
| `raw_data` | TEXT (JSON) | NULL |
| `signature` | VARCHAR(500) | NULL |
| `signature_valid` | BOOLEAN | NULL |
| `error_message` | TEXT | NULL |
| `success` | BOOLEAN | DEFAULT true |
| `metadata` | TEXT (JSON) | NULL |
| `created_at` | TIMESTAMP | AUTO |

---

### 25. `Splits`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `split_code` | VARCHAR(50) | UNIQUE, NOT NULL |
| `qr_code_url` | VARCHAR(255) | NULL |
| `customer_id` | INTEGER | FK → Users.id, NOT NULL |
| `brand` | VARCHAR(100) | NULL |
| `model` | VARCHAR(100) | NULL |
| `serial_number` | VARCHAR(100) | NULL |
| `power` | VARCHAR(50) | NULL |
| `power_type` | ENUM('BTU', 'kW', 'CV') | DEFAULT 'BTU' |
| `location` | VARCHAR(100) | NULL |
| `floor` | VARCHAR(50) | NULL |
| `installation_date` | DATE | NULL |
| `warranty_end_date` | DATE | NULL |
| `last_maintenance_date` | DATE | NULL |
| `next_maintenance_date` | DATE | NULL |
| `status` | ENUM('active', 'inactive', 'out_of_service', 'pending_installation') | DEFAULT 'active' |
| `notes` | TEXT | NULL |
| `photo_url` | VARCHAR(255) | NULL |
| `intervention_count` | INTEGER | DEFAULT 0 |
| `installation_address` | VARCHAR(255) | NULL |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |

---

### 26. `diagnostic_reports`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `intervention_id` | INTEGER | FK → interventions.id, NOT NULL |
| `technician_id` | INTEGER | FK → users.id, NOT NULL |
| `problem_description` | TEXT | NOT NULL |
| `recommended_solution` | TEXT | NOT NULL |
| `parts_needed` | JSON | NULL |
| `labor_cost` | DECIMAL(10, 2) | NOT NULL, DEFAULT 0 |
| `estimated_total` | DECIMAL(10, 2) | NOT NULL |
| `urgency_level` | ENUM('low', 'medium', 'high', 'urgent') | NOT NULL, DEFAULT 'medium' |
| `estimated_duration` | VARCHAR | NULL |
| `photos` | JSON | NULL |
| `notes` | TEXT | NULL |
| `status` | ENUM('submitted', 'reviewed', 'quote_sent', 'approved', 'rejected') | NOT NULL, DEFAULT 'submitted' |
| `submitted_at` | DATE | NOT NULL, DEFAULT NOW |
| `reviewed_by` | INTEGER | FK → users.id, NULL |
| `reviewed_at` | DATE | NULL |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |

---

### 27. `maintenance_schedules`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `equipment_id` | INTEGER | FK → equipments.id, NOT NULL |
| `technician_id` | INTEGER | FK → users.id, NOT NULL |
| `scheduled_date` | DATE | NOT NULL |
| `type` | ENUM('preventive', 'corrective', 'inspection') | NOT NULL |
| `status` | ENUM('scheduled', 'in_progress', 'completed', 'cancelled') | NOT NULL, DEFAULT 'scheduled' |
| `notes` | TEXT | NULL |
| `createdAt` | TIMESTAMP | AUTO |
| `updatedAt` | TIMESTAMP | AUTO |

---

### 28. `system_configs`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `key` | VARCHAR(100) | UNIQUE, NOT NULL |
| `value` | TEXT | NULL |
| `type` | ENUM('string', 'number', 'boolean', 'json', 'array') | DEFAULT 'string' |
| `category` | VARCHAR(50) | NOT NULL, DEFAULT 'general' |
| `description` | TEXT | NULL |
| `is_public` | BOOLEAN | DEFAULT false |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |

---

### 29. `promotions`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `name` | VARCHAR | NOT NULL |
| `code` | VARCHAR | UNIQUE, NOT NULL |
| `type` | VARCHAR | NOT NULL ('percentage', 'fixed') |
| `value` | FLOAT | NOT NULL |
| `start_date` | DATE | NOT NULL |
| `end_date` | DATE | NOT NULL |
| `usage_limit` | INTEGER | NULL |
| `usage_count` | INTEGER | DEFAULT 0 |
| `target` | VARCHAR | NOT NULL, DEFAULT 'all' |
| `is_active` | BOOLEAN | DEFAULT true |
| `description` | TEXT | NULL |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |

---

### 30. `email_verification_codes`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `user_id` | INTEGER | FK → users.id, NOT NULL, ON DELETE CASCADE |
| `code` | VARCHAR(6) | NOT NULL |
| `expires_at` | DATE | NOT NULL |
| `used` | BOOLEAN | DEFAULT false |
| `created_at` | TIMESTAMP | AUTO |
| `updated_at` | TIMESTAMP | AUTO |

---

### 31. `password_reset_codes`
| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | INTEGER | PK, AUTO_INCREMENT |
| `user_id` | INTEGER | FK → users.id, NOT NULL, ON DELETE CASCADE |
| `code` | VARCHAR(6) | NOT NULL |
| `expires_at` | DATE | NOT NULL |
| `used` | BOOLEAN | NOT NULL, DEFAULT false |
| `created_at` | TIMESTAMP | AUTO |

---

## 🔗 Relations et Associations

### User (Centre du système)
```
User ─┬─ hasOne ────→ CustomerProfile (user_id)
      ├─ hasOne ────→ TechnicianProfile (user_id)
      ├─ hasMany ───→ Equipment (customer_id)
      ├─ hasMany ───→ Contract (customer_id)
      ├─ hasMany ───→ Intervention (technician_id) [as: technicianInterventions]
      ├─ hasMany ───→ Subscription (customer_id)
      ├─ hasMany ───→ Split (customer_id)
      ├─ hasMany ───→ Notification (user_id)
      ├─ hasMany ───→ ChatMessage (sender_id) [as: sentMessages]
      ├─ hasMany ───→ DiagnosticReport (technician_id) [as: submittedReports]
      ├─ hasMany ───→ DiagnosticReport (reviewed_by) [as: reviewedReports]
      ├─ hasMany ───→ PasswordResetCode (user_id)
      └─ hasMany ───→ EmailVerificationCode (user_id)
```

### CustomerProfile
```
CustomerProfile ─┬─ belongsTo ──→ User (user_id)
                 ├─ hasMany ────→ Intervention (customer_id)
                 └─ (reçoit)───→ Order.belongsTo (customerId) [as: customer]
                 └─ (reçoit)───→ Complaint.belongsTo (customerId) [as: customer]
```

### TechnicianProfile
```
TechnicianProfile ──── belongsTo ──→ User (user_id)
```

### Intervention
```
Intervention ─┬─ belongsTo ──→ CustomerProfile (customer_id) [as: customer]
              ├─ belongsTo ──→ User (technician_id) [as: technician]
              ├─ belongsTo ──→ MaintenanceOffer (maintenance_offer_id)
              ├─ belongsTo ──→ RepairService (repair_service_id)
              ├─ belongsTo ──→ InstallationService (installation_service_id)
              ├─ belongsTo ──→ Split (split_id)
              ├─ hasMany ────→ InterventionImage (intervention_id) [as: images]
              ├─ hasMany ────→ DiagnosticReport (intervention_id) [as: diagnosticReports]
              └─ hasMany ────→ Quote (intervention_id) [as: quotes]
```

### InterventionImage
```
InterventionImage ──── belongsTo ──→ Intervention (intervention_id)
```

### Split (Équipement tracé par QR code)
```
Split ─┬─ belongsTo ──→ User (customer_id) [as: customer]
       ├─ hasMany ────→ Subscription (split_id)
       └─ hasMany ────→ Intervention (split_id)
```

### Services (Offres)
```
MaintenanceOffer ─┬─ hasMany ──→ Intervention (maintenance_offer_id)
                  └─ hasMany ──→ Subscription (maintenance_offer_id)

RepairService ─┬─ hasMany ──→ Intervention (repair_service_id)
               └─ hasMany ──→ Subscription (repair_service_id)

InstallationService ─┬─ hasMany ──→ Intervention (installation_service_id)
                     └─ hasMany ──→ Subscription (installation_service_id)
```

### Subscription
```
Subscription ─┬─ belongsTo ──→ User (customer_id)
              ├─ belongsTo ──→ MaintenanceOffer (maintenance_offer_id) [as: offer]
              ├─ belongsTo ──→ InstallationService (installation_service_id)
              ├─ belongsTo ──→ RepairService (repair_service_id)
              ├─ belongsTo ──→ Split (split_id)
              └─ hasMany ────→ Payment (subscription_id)
```

### Quote & QuoteItem
```
Quote ─┬─ hasMany ────→ QuoteItem (quoteId) [as: items]
       ├─ hasOne ─────→ Order (quoteId)
       ├─ belongsTo ──→ DiagnosticReport (diagnostic_report_id)
       └─ belongsTo ──→ Intervention (intervention_id)

QuoteItem ──── belongsTo ──→ Quote (quoteId)
```

### Order & OrderItem
```
Order ─┬─ belongsTo ──→ CustomerProfile (customerId) [as: customer]
       ├─ belongsTo ──→ Quote (quoteId)
       ├─ hasMany ────→ OrderItem (orderId) [as: items]
       └─ hasMany ────→ Payment (orderId)

OrderItem ─┬─ belongsTo ──→ Order (orderId)
           └─ belongsTo ──→ Product (productId)
```

### Product, Category, Brand
```
Product ─┬─ belongsTo ──→ Category (categorie_id) [as: categorie]
         └─ belongsTo ──→ Brand (marque_id) [as: marque]

Category ──── hasMany ──→ Product (categorie_id)
Brand ────── hasMany ──→ Product (marque_id)
```

### Complaint & ComplaintNote
```
Complaint ─┬─ belongsTo ──→ CustomerProfile (customerId) [as: customer]
           ├─ belongsTo ──→ Product (productId)
           ├─ belongsTo ──→ Order (orderId)
           └─ hasMany ────→ ComplaintNote (complaintId) [as: notes]

ComplaintNote ─┬─ belongsTo ──→ Complaint (complaintId)
               └─ belongsTo ──→ User (userId)
```

### DiagnosticReport
```
DiagnosticReport ─┬─ belongsTo ──→ Intervention (intervention_id)
                  ├─ belongsTo ──→ User (technician_id) [as: technician]
                  ├─ belongsTo ──→ User (reviewed_by) [as: reviewer]
                  └─ hasMany ────→ Quote (diagnostic_report_id) [as: quotes]
```

### MaintenanceSchedule
```
MaintenanceSchedule ─┬─ belongsTo ──→ Equipment (equipment_id)
                     └─ belongsTo ──→ User (technician_id) [as: technician]
```

### Equipment
```
Equipment ──── belongsTo ──→ User (customer_id) [as: customer]
```

### Contract
```
Contract ──── belongsTo ──→ User (customer_id) [as: customer]
```

### Payment
```
Payment ─┬─ belongsTo ──→ Order (orderId)
         └─ belongsTo ──→ Subscription (subscriptionId)
```

### Notification & ChatMessage
```
Notification ──── belongsTo ──→ User (user_id)
ChatMessage ───── belongsTo ──→ User (sender_id) [as: sender]
```

---

## 📈 Diagramme ER simplifié

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                    USERS                                         │
│  (users, customer_profiles, technician_profiles)                                │
└─────────────────────────────────────────────────────────────────────────────────┘
       │                    │                    │                    │
       ▼                    ▼                    ▼                    ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  equipments  │    │   Splits     │    │  contracts   │    │subscriptions │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
       │                    │                                      │
       ▼                    ▼                                      │
┌──────────────┐    ┌──────────────────────────────────────────────┴───────────────┐
│ maintenance_ │    │                      INTERVENTIONS                           │
│  schedules   │    │  (interventions, intervention_images, diagnostic_reports)    │
└──────────────┘    └──────────────────────────────────────────────────────────────┘
                           │                    │
                           ▼                    ▼
                    ┌──────────────┐    ┌──────────────┐
                    │    quotes    │    │  complaints  │
                    │ quote_items  │    │complaint_notes│
                    └──────────────┘    └──────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │    orders    │
                    │ order_items  │
                    └──────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │   payments   │
                    │ payment_logs │
                    └──────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                              CATALOGUE PRODUITS                                  │
│        (products, categories, brands)                                           │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                              SERVICES / OFFRES                                   │
│  (maintenance_offers, installation_services, repair_services)                   │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                          SYSTÈME & COMMUNICATION                                 │
│  (notifications, chat_messages, system_configs, promotions)                     │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                              SÉCURITÉ / AUTH                                     │
│  (email_verification_codes, password_reset_codes)                               │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 📋 Résumé des Tables

| # | Table | Soft Delete | Description |
|---|-------|-------------|-------------|
| 1 | users | Non | Comptes utilisateurs (admin, client, technicien) |
| 2 | customer_profiles | Non | Profils clients |
| 3 | technician_profiles | Non | Profils techniciens |
| 4 | equipments | Oui | Équipements des clients |
| 5 | interventions | Non | Demandes d'intervention |
| 6 | intervention_images | Non | Images des interventions |
| 7 | contracts | Non | Contrats de maintenance |
| 8 | products | Oui | Catalogue produits |
| 9 | categories | Non | Catégories de produits |
| 10 | brands | Non | Marques de produits |
| 11 | quotes | Non | Devis |
| 12 | quote_items | Non | Lignes de devis |
| 13 | orders | Oui | Commandes |
| 14 | order_items | Non | Lignes de commandes |
| 15 | complaints | Oui | Réclamations clients |
| 16 | complaint_notes | Oui | Notes sur réclamations |
| 17 | maintenance_offers | Oui | Offres d'entretien |
| 18 | installation_services | Non | Services d'installation |
| 19 | repair_services | Non | Services de réparation |
| 20 | subscriptions | Oui | Souscriptions clients |
| 21 | notifications | Non | Notifications |
| 22 | chat_messages | Non | Messages de chat |
| 23 | payments | Non | Paiements |
| 24 | payment_logs | Non | Logs de paiement |
| 25 | Splits | Non | Équipements tracés (QR code) |
| 26 | diagnostic_reports | Non | Rapports de diagnostic |
| 27 | maintenance_schedules | Non | Planification maintenance |
| 28 | system_configs | Non | Configuration système |
| 29 | promotions | Non | Codes promo |
| 30 | email_verification_codes | Non | Codes vérification email |
| 31 | password_reset_codes | Non | Codes reset mot de passe |

---

*Généré le 1 mars 2026*
