const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const DiagnosticReport = sequelize.define('DiagnosticReport', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  intervention_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'interventions',
      key: 'id'
    },
    comment: 'Intervention concernée par ce diagnostic'
  },
  technician_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id'
    },
    comment: 'Technicien qui a effectué le diagnostic'
  },
  problem_description: {
    type: DataTypes.TEXT,
    allowNull: false,
    comment: 'Description détaillée du problème identifié'
  },
  recommended_solution: {
    type: DataTypes.TEXT,
    allowNull: false,
    comment: 'Solution recommandée par le technicien'
  },
  parts_needed: {
    type: DataTypes.JSON,
    allowNull: true,
    comment: 'Liste des pièces nécessaires avec quantités et prix: [{name, quantity, unit_price}]'
  },
  labor_cost: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
    defaultValue: 0,
    comment: 'Coût de la main d\'œuvre'
  },
  estimated_total: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
    comment: 'Montant total estimé (pièces + main d\'œuvre)'
  },
  urgency_level: {
    type: DataTypes.ENUM('low', 'medium', 'high', 'urgent'),
    allowNull: false,
    defaultValue: 'medium',
    comment: 'Niveau d\'urgence de la réparation'
  },
  estimated_duration: {
    type: DataTypes.STRING,
    allowNull: true,
    comment: 'Durée estimée des travaux (ex: "2 heures", "1 jour")'
  },
  photos: {
    type: DataTypes.JSON,
    allowNull: true,
    comment: 'URLs des photos prises lors du diagnostic'
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'Notes additionnelles du technicien'
  },
  status: {
    type: DataTypes.ENUM('submitted', 'reviewed', 'quote_sent', 'approved', 'rejected'),
    allowNull: false,
    defaultValue: 'submitted',
    comment: 'Statut du rapport: submitted → reviewed → quote_sent → approved/rejected'
  },
  submitted_at: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
    comment: 'Date de soumission du rapport'
  },
  reviewed_by: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'users',
      key: 'id'
    },
    comment: 'Admin qui a examiné le rapport'
  },
  reviewed_at: {
    type: DataTypes.DATE,
    allowNull: true,
    comment: 'Date de révision par l\'admin'
  }
}, {
  tableName: 'diagnostic_reports',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  paranoid: false
});

module.exports = DiagnosticReport;
