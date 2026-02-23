/**
 * Migration: Ajouter les champs de sécurité paiement FineoPay
 * 
 * - fineopay_checkout_id: ID du checkout link pour matching sécurisé
 * - fineopay_reference: Référence de la transaction FineoPay
 * - payment_date: Date du paiement
 * - payment_processing: Flag anti-doublon
 */

'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    
    try {
      // Ajouter les colonnes à la table orders
      await queryInterface.addColumn('orders', 'fineopay_checkout_id', {
        type: Sequelize.STRING,
        allowNull: true,
        comment: 'ID du checkout link FineoPay pour matching sécurisé'
      }, { transaction });

      await queryInterface.addColumn('orders', 'fineopay_reference', {
        type: Sequelize.STRING,
        allowNull: true,
        comment: 'Référence de la transaction FineoPay'
      }, { transaction });

      await queryInterface.addColumn('orders', 'payment_date', {
        type: Sequelize.DATE,
        allowNull: true,
        comment: 'Date du paiement'
      }, { transaction });

      await queryInterface.addColumn('orders', 'payment_processing', {
        type: Sequelize.BOOLEAN,
        defaultValue: false,
        comment: 'Flag anti-doublon de traitement'
      }, { transaction });

      // Créer la table payment_logs
      await queryInterface.createTable('payment_logs', {
        id: {
          type: Sequelize.INTEGER,
          primaryKey: true,
          autoIncrement: true
        },
        order_id: {
          type: Sequelize.INTEGER,
          allowNull: true,
          references: {
            model: 'orders',
            key: 'id'
          },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL'
        },
        event_type: {
          type: Sequelize.ENUM(
            'checkout_created',
            'webhook_received',
            'status_check',
            'payment_confirmed',
            'payment_failed',
            'signature_invalid',
            'duplicate_blocked',
            'manual_sync'
          ),
          allowNull: false
        },
        provider: {
          type: Sequelize.STRING(50),
          defaultValue: 'fineopay'
        },
        fineopay_reference: {
          type: Sequelize.STRING,
          allowNull: true
        },
        checkout_link_id: {
          type: Sequelize.STRING,
          allowNull: true
        },
        amount: {
          type: Sequelize.FLOAT,
          allowNull: true
        },
        payment_status: {
          type: Sequelize.STRING(50),
          allowNull: true
        },
        source_ip: {
          type: Sequelize.STRING(50),
          allowNull: true
        },
        user_agent: {
          type: Sequelize.STRING(500),
          allowNull: true
        },
        raw_data: {
          type: Sequelize.TEXT,
          allowNull: true
        },
        signature: {
          type: Sequelize.STRING(500),
          allowNull: true
        },
        signature_valid: {
          type: Sequelize.BOOLEAN,
          allowNull: true
        },
        error_message: {
          type: Sequelize.TEXT,
          allowNull: true
        },
        success: {
          type: Sequelize.BOOLEAN,
          defaultValue: true
        },
        metadata: {
          type: Sequelize.TEXT,
          allowNull: true
        },
        created_at: {
          type: Sequelize.DATE,
          allowNull: false,
          defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
        }
      }, { transaction });

      // Ajouter des index pour optimiser les recherches
      await queryInterface.addIndex('payment_logs', ['order_id'], { transaction });
      await queryInterface.addIndex('payment_logs', ['event_type'], { transaction });
      await queryInterface.addIndex('payment_logs', ['fineopay_reference'], { transaction });
      await queryInterface.addIndex('payment_logs', ['created_at'], { transaction });
      await queryInterface.addIndex('orders', ['fineopay_checkout_id'], { transaction });

      await transaction.commit();
      console.log('✅ Migration exécutée avec succès');
    } catch (error) {
      await transaction.rollback();
      console.error('❌ Erreur migration:', error);
      throw error;
    }
  },

  async down(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    
    try {
      // Supprimer les index
      await queryInterface.removeIndex('orders', ['fineopay_checkout_id'], { transaction });
      
      // Supprimer la table payment_logs
      await queryInterface.dropTable('payment_logs', { transaction });

      // Supprimer les colonnes de orders
      await queryInterface.removeColumn('orders', 'fineopay_checkout_id', { transaction });
      await queryInterface.removeColumn('orders', 'fineopay_reference', { transaction });
      await queryInterface.removeColumn('orders', 'payment_date', { transaction });
      await queryInterface.removeColumn('orders', 'payment_processing', { transaction });

      await transaction.commit();
      console.log('✅ Rollback exécuté avec succès');
    } catch (error) {
      await transaction.rollback();
      console.error('❌ Erreur rollback:', error);
      throw error;
    }
  }
};
