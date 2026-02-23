const { DataTypes } = require('sequelize');

module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('notifications', {
      id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
      },
      user_id: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id'
        },
        onDelete: 'CASCADE'
      },
      type: {
        type: DataTypes.ENUM(
          'intervention_request',
          'intervention_assigned',
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
        ),
        allowNull: false
      },
      title: {
        type: DataTypes.STRING,
        allowNull: false
      },
      message: {
        type: DataTypes.TEXT,
        allowNull: false
      },
      data: {
        type: DataTypes.JSON,
        allowNull: true
      },
      is_read: {
        type: DataTypes.BOOLEAN,
        defaultValue: false
      },
      read_at: {
        type: DataTypes.DATE,
        allowNull: true
      },
      priority: {
        type: DataTypes.ENUM('low', 'medium', 'high', 'urgent'),
        defaultValue: 'medium'
      },
      action_url: {
        type: DataTypes.STRING,
        allowNull: true
      },
      created_at: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      },
      updated_at: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      }
    });

    // Ajouter les index avec vérification d'existence
    try {
      await queryInterface.addIndex('notifications', ['user_id'], {
        name: 'notifications_user_id'
      });
    } catch (error) {
      if (!error.message.includes('already exists')) {
        throw error;
      }
      console.log('Index notifications_user_id already exists, skipping...');
    }

    try {
      await queryInterface.addIndex('notifications', ['is_read'], {
        name: 'notifications_is_read'
      });
    } catch (error) {
      if (!error.message.includes('already exists')) {
        throw error;
      }
      console.log('Index notifications_is_read already exists, skipping...');
    }

    try {
      await queryInterface.addIndex('notifications', ['type'], {
        name: 'notifications_type'
      });
    } catch (error) {
      if (!error.message.includes('already exists')) {
        throw error;
      }
      console.log('Index notifications_type already exists, skipping...');
    }

    try {
      await queryInterface.addIndex('notifications', ['created_at'], {
        name: 'notifications_created_at'
      });
    } catch (error) {
      if (!error.message.includes('already exists')) {
        throw error;
      }
      console.log('Index notifications_created_at already exists, skipping...');
    }
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.dropTable('notifications');
  }
};
