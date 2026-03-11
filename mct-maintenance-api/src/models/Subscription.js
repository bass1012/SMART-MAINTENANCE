const { Model, DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

class Subscription extends Model {}

Subscription.init({
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  customer_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    field: 'customer_id'
  },
  maintenance_offer_id: {
    type: DataTypes.INTEGER,
    allowNull: true, // Optionnel - au moins un des trois IDs doit être présent
    field: 'maintenance_offer_id'
  },
  installation_service_id: {
    type: DataTypes.INTEGER,
    allowNull: true, // Optionnel - au moins un des trois IDs doit être présent
    field: 'installation_service_id'
  },
  repair_service_id: {
    type: DataTypes.INTEGER,
    allowNull: true, // Optionnel - au moins un des trois IDs doit être présent
    field: 'repair_service_id'
  },
  split_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    field: 'split_id'
  },
  equipment_description: {
    type: DataTypes.STRING,
    allowNull: true,
    field: 'equipment_description',
    comment: 'Description de l\'équipement (ex: mural 1 cv)'
  },
  equipment_model: {
    type: DataTypes.STRING,
    allowNull: true,
    field: 'equipment_model',
    comment: 'Marque de l\'équipement (LG, Carrier, etc.)'
  },
  equipment_count: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1,
    field: 'equipment_count',
    comment: 'Nombre d\'équipements couverts par cette souscription'
  },
  equipment_used: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
    field: 'equipment_used',
    comment: 'Nombre d\'équipements déjà utilisés'
  },
  status: {
    type: DataTypes.ENUM('pending_payment', 'active', 'awaiting_second_payment', 'completed', 'used', 'expired', 'cancelled'),
    defaultValue: 'pending_payment'
  },
  start_date: {
    type: DataTypes.DATE,
    allowNull: false,
    field: 'start_date'
  },
  end_date: {
    type: DataTypes.DATE,
    allowNull: false,
    field: 'end_date'
  },
  price: {
    type: DataTypes.FLOAT,
    allowNull: false
  },
  original_price: {
    type: DataTypes.FLOAT,
    allowNull: true,
    field: 'original_price'
  },
  discount_amount: {
    type: DataTypes.FLOAT,
    allowNull: true,
    defaultValue: 0,
    field: 'discount_amount'
  },
  promo_code: {
    type: DataTypes.STRING(50),
    allowNull: true,
    field: 'promo_code'
  },
  payment_status: {
    type: DataTypes.ENUM('pending', 'paid', 'failed'),
    defaultValue: 'pending',
    field: 'payment_status'
  },
  intervention_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    field: 'intervention_id',
    comment: 'ID de l\'intervention qui a utilisé cette souscription'
  },
  used_at: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'used_at',
    comment: 'Date d\'utilisation de la souscription'
  },
  // Champs pour les contrats avec visites planifiées
  contract_type: {
    type: DataTypes.STRING(50),
    allowNull: false,
    defaultValue: 'on_demand',
    field: 'contract_type',
    comment: 'Type de contrat: on_demand (à la demande) ou scheduled (planifié avec visites)'
  },
  visits_total: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1,
    field: 'visits_total',
    comment: 'Nombre total de visites prévues dans le contrat'
  },
  visits_completed: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
    field: 'visits_completed',
    comment: 'Nombre de visites effectuées'
  },
  visit_interval_months: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 3,
    field: 'visit_interval_months',
    comment: 'Intervalle en mois entre chaque visite'
  },
  next_visit_date: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'next_visit_date',
    comment: 'Date de la prochaine visite planifiée'
  },
  first_intervention_date: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'first_intervention_date',
    comment: 'Date de la première intervention effectuée (point de départ de la planification)'
  },
  checkout_link_id: {
    type: DataTypes.STRING,
    allowNull: true,
    field: 'checkout_link_id',
    comment: 'ID du lien de paiement FineoPay pour le matching'
  },
  // Champs split payment (50/50)
  first_payment_amount: {
    type: DataTypes.FLOAT,
    allowNull: true,
    field: 'first_payment_amount',
    comment: 'Montant du premier paiement (50% à la validation)'
  },
  first_payment_status: {
    type: DataTypes.STRING(20),
    allowNull: false,
    defaultValue: 'pending',
    field: 'first_payment_status',
    comment: 'Statut du premier paiement: pending, paid'
  },
  second_payment_amount: {
    type: DataTypes.FLOAT,
    allowNull: true,
    field: 'second_payment_amount',
    comment: 'Montant du deuxième paiement (50% à la dernière visite)'
  },
  second_payment_status: {
    type: DataTypes.STRING(20),
    allowNull: false,
    defaultValue: 'pending',
    field: 'second_payment_status',
    comment: 'Statut du deuxième paiement: pending, paid'
  }
}, {
  sequelize,
  modelName: 'Subscription',
  tableName: 'subscriptions',
  timestamps: true,
  underscored: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  deletedAt: 'deleted_at',
  paranoid: true
});

module.exports = Subscription;
