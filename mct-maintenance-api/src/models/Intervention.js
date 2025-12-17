const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Intervention = sequelize.define('Intervention', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  address: {
    type: DataTypes.STRING,
    allowNull: true
  },
  status: {
    type: DataTypes.ENUM('pending', 'assigned', 'accepted', 'on_the_way', 'arrived', 'in_progress', 'completed', 'cancelled'),
    allowNull: false,
    defaultValue: 'pending'
  },
  priority: {
    type: DataTypes.ENUM('low', 'normal', 'medium', 'high', 'urgent', 'critical'),
    allowNull: false
  },
  intervention_type: {
    type: DataTypes.STRING,
    allowNull: true
  },
  scheduled_date: {
    type: DataTypes.DATE,
    allowNull: false
  },
  completed_date: {
    type: DataTypes.DATE,
    allowNull: true
  },
  customer_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id'
    }
  },
  technician_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'users',
      key: 'id'
    }
  },
  product_id: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  contract_id: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  equipment_count: {
    type: DataTypes.INTEGER,
    allowNull: true,
    defaultValue: 1
  },
  // Workflow timestamps
  accepted_at: {
    type: DataTypes.DATE,
    allowNull: true
  },
  departed_at: {
    type: DataTypes.DATE,
    allowNull: true
  },
  arrived_at: {
    type: DataTypes.DATE,
    allowNull: true
  },
  started_at: {
    type: DataTypes.DATE,
    allowNull: true
  },
  completed_at: {
    type: DataTypes.DATE,
    allowNull: true
  },
  // Rapport d'intervention
  report_data: {
    type: DataTypes.TEXT, // JSON stocké en TEXT pour SQLite
    allowNull: true
  },
  report_submitted_at: {
    type: DataTypes.DATE,
    allowNull: true
  },
  // Gestion du diagnostic
  diagnostic_fee: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
    defaultValue: 0.00,
    comment: 'Coût du diagnostic (0 si gratuit, 4000 si payant)'
  },
  is_free_diagnosis: {
    type: DataTypes.BOOLEAN,
    allowNull: true,
    defaultValue: false,
    comment: 'true si le client a un contrat (diagnostic gratuit), false sinon (4000 FCFA)'
  },
  // Évaluation client
  rating: {
    type: DataTypes.INTEGER,
    allowNull: true,
    validate: {
      min: 1,
      max: 5
    },
    comment: 'Note du client (1-5 étoiles)'
  },
  review: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'Commentaire du client'
  }
}, {
  tableName: 'interventions',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  paranoid: false // Désactive le soft delete pour éviter l'erreur deleted_at
});

module.exports = Intervention;