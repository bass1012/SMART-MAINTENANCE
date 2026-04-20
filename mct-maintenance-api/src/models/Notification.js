const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Notification = sequelize.define('Notification', {
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
        'technician_assigned',
        'intervention_completed',
        'complaint_created',
        'complaint_response',
        'complaint_status_change',
        'subscription_created',
        'subscription_expiring',
        'order_created',
        'order_status_update',
        'order_tracking',
        'quote_created',
        'quote_sent',
        'quote_updated',
        'quote_accepted',
        'quote_rejected',
        'contract_created',
        'contract_activated',
        'contract_completed',
        'contract_expiring',
        'contract_renewal_request',
        'second_payment_required',
        'next_visit_scheduled',
        'payment_received',
        'payment_confirmed',
        'payment_success',
        'payment_failed',
        'diagnostic_payment_confirmed',
        'diagnostic_payment_received',
        'diagnostic_payment_failed',
        'diagnostic_payment_reminder',
        'report_submitted',
        'maintenance_offer_created',
        'maintenance_offer_activated',
        'promotion',
        'maintenance_tip',
        'maintenance_reminder',
        'announcement',
        'alert',
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
      allowNull: true,
      comment: 'Données additionnelles (ID de la ressource, etc.)'
    },
    is_read: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    read: {
      type: DataTypes.VIRTUAL,
      get() {
        return this.getDataValue('is_read');
      },
      set(value) {
        this.setDataValue('is_read', value);
      }
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
      allowNull: true,
      comment: 'URL pour rediriger l\'utilisateur'
    }
  }, {
    tableName: 'notifications',
    timestamps: true,
    underscored: true,
    paranoid: false, // Pas de soft delete pour les notifications
    indexes: [
      {
        fields: ['user_id']
      },
      {
        fields: ['is_read']
      },
      {
        fields: ['type']
      },
      {
        fields: ['created_at']
      }
    ]
  });

// Ajouter une méthode toJSON pour inclure le champ virtuel 'read'
Notification.prototype.toJSON = function () {
  const values = Object.assign({}, this.get());
  // Ajouter explicitement le champ 'read' basé sur 'is_read'
  values.read = this.getDataValue('is_read');
  return values;
};

module.exports = Notification;
