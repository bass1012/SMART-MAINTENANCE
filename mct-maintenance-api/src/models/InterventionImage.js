/**
 * Modèle InterventionImage
 * Gère les images associées aux interventions
 */

const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const InterventionImage = sequelize.define('InterventionImage', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  intervention_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    field: 'intervention_id',
    references: {
      model: 'interventions',
      key: 'id'
    },
    onDelete: 'CASCADE',
    comment: 'ID de l\'intervention associée'
  },
  image_url: {
    type: DataTypes.STRING,
    allowNull: false,
    field: 'image_url',
    comment: 'URL relative de l\'image (/uploads/interventions/xxx.jpg)'
  },
  order: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    allowNull: false,
    comment: 'Ordre d\'affichage des images (0-4)'
  },
  image_type: {
    type: DataTypes.STRING(50),
    defaultValue: 'intervention',
    allowNull: true,
    field: 'image_type',
    comment: 'Type d\'image: "intervention" (client) ou "report" (technicien)'
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
    field: 'created_at'
  },
  updated_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
    field: 'updated_at'
  }
}, {
  tableName: 'intervention_images',
  timestamps: true,
  underscored: true,
  paranoid: false, // Pas de soft delete pour les images
  indexes: [
    {
      fields: ['intervention_id']
    }
  ]
});

module.exports = InterventionImage;
