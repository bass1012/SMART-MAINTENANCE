-- Migration: Add checkout_link_id column to subscriptions table
-- Date: 2026-03-02

ALTER TABLE subscriptions ADD COLUMN checkout_link_id VARCHAR(255) NULL;
