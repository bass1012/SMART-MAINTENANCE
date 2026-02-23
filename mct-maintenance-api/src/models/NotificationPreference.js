const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const NotificationPreference = sequelize.define('NotificationPreference', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    unique: true,
    references: {
      model: 'users',
      key: 'id'
    },
    onDelete: 'CASCADE'
  },
  
  // Préférences générales
  email_enabled: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true,
    comment: 'Activer/désactiver tous les emails'
  },
  push_enabled: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true,
    comment: 'Activer/désactiver toutes les notifications push'
  },
  sms_enabled: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
    comment: 'Activer/désactiver tous les SMS'
  },
  
  // Notifications par type (interventions)
  intervention_request_email: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  intervention_request_push: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  intervention_assigned_email: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  intervention_assigned_push: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  intervention_completed_email: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  intervention_completed_push: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  
  // Notifications par type (commandes)
  order_created_email: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  order_created_push: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  order_status_update_email: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  order_status_update_push: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  
  // Notifications par type (devis)
  quote_created_email: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  quote_created_push: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  quote_updated_email: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  quote_updated_push: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  
  // Notifications par type (réclamations)
  complaint_created_email: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  complaint_created_push: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  complaint_response_email: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  complaint_response_push: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  
  // Notifications par type (contrats)
  contract_expiring_email: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  contract_expiring_push: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  
  // Notifications marketing et promotions
  promotion_email: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  promotion_push: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  maintenance_tip_email: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  maintenance_tip_push: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  
  // Notifications générales
  general_email: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  general_push: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  
  // Préférences horaires
  quiet_hours_enabled: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
    comment: 'Activer heures de silence'
  },
  quiet_hours_start: {
    type: DataTypes.TIME,
    allowNull: true,
    comment: 'Heure de début (format: HH:MM:SS)'
  },
  quiet_hours_end: {
    type: DataTypes.TIME,
    allowNull: true,
    comment: 'Heure de fin (format: HH:MM:SS)'
  },
  
  // Digest/résumé
  daily_digest_enabled: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
    comment: 'Recevoir un résumé quotidien au lieu de notifications individuelles'
  },
  weekly_digest_enabled: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
    comment: 'Recevoir un résumé hebdomadaire'
  }
}, {
  tableName: 'notification_preferences',
  timestamps: true,
  underscored: true,
  paranoid: false, // Désactiver soft delete (pas de colonne deleted_at)
  indexes: [
    {
      fields: ['user_id']
    }
  ]
});

module.exports = NotificationPreference;
