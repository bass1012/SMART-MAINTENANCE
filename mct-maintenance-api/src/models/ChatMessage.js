const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const ChatMessage = sequelize.define('ChatMessage', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  sender_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id'
    }
  },
  sender_role: {
    type: DataTypes.ENUM('customer', 'admin', 'technician'),
    allowNull: false
  },
  recipient_id: {
    type: DataTypes.INTEGER,
    allowNull: true, // Peut être null pour les messages des clients (destinés à tous les admins)
    references: {
      model: 'users',
      key: 'id'
    }
  },
  message: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  is_read: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  attachment_url: {
    type: DataTypes.STRING,
    allowNull: true
  },
  attachment_type: {
    type: DataTypes.ENUM('image', 'file', 'audio'),
    allowNull: true
  }
}, {
  tableName: 'chat_messages',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

module.exports = ChatMessage;
