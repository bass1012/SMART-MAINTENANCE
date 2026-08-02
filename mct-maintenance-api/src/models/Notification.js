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
      type: DataTypes.STRING(64),
      allowNull: false,
      validate: { notEmpty: true, len: [1, 64] }
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
    },
    dedupe_key: {
      type: DataTypes.STRING(191),
      allowNull: true,
      comment: 'Clé stable empêchant la création et l’envoi répétés d’une même notification'
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
      },
      {
        name: 'notifications_user_dedupe_key_uq',
        unique: true,
        fields: ['user_id', 'dedupe_key']
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
