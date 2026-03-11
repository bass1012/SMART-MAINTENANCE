const { Model, DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

/**
 * PaymentLog - Table d'audit pour toutes les opérations de paiement
 * 
 * Permet de tracer :
 * - Création de liens de paiement
 * - Webhooks reçus
 * - Vérifications de statut
 * - Mises à jour de paiement
 */
class PaymentLog extends Model {}

PaymentLog.init({
  // Référence à la commande
  orderId: { 
    type: DataTypes.INTEGER, 
    allowNull: true,
    field: 'order_id'
  },
  
  // Type d'événement
  eventType: { 
    type: DataTypes.ENUM(
      'checkout_created',           // Lien de paiement créé
      'diagnostic_checkout_created', // Paiement diagnostic créé
      'webhook_received',           // Webhook reçu de FineoPay
      'status_check',               // Vérification active du statut
      'payment_confirmed',          // Paiement confirmé
      'payment_failed',             // Paiement échoué
      'signature_invalid',          // Signature webhook invalide
      'duplicate_blocked',          // Double traitement bloqué
      'manual_sync'                 // Synchronisation manuelle
    ),
    allowNull: false,
    field: 'event_type'
  },
  
  // Provider de paiement
  provider: { 
    type: DataTypes.STRING(50), 
    defaultValue: 'fineopay',
    field: 'provider'
  },
  
  // Référence FineoPay (transaction reference)
  fineopayReference: { 
    type: DataTypes.STRING, 
    allowNull: true,
    field: 'fineopay_reference'
  },
  
  // ID du checkout link FineoPay
  checkoutLinkId: { 
    type: DataTypes.STRING, 
    allowNull: true,
    field: 'checkout_link_id'
  },
  
  // Montant
  amount: { 
    type: DataTypes.FLOAT, 
    allowNull: true 
  },
  
  // Statut du paiement au moment de l'événement
  paymentStatus: { 
    type: DataTypes.STRING(50), 
    allowNull: true,
    field: 'payment_status'
  },
  
  // Adresse IP source (pour webhooks)
  sourceIp: { 
    type: DataTypes.STRING(50), 
    allowNull: true,
    field: 'source_ip'
  },
  
  // User-Agent (pour auditer la source)
  userAgent: { 
    type: DataTypes.STRING(500), 
    allowNull: true,
    field: 'user_agent'
  },
  
  // Données brutes de la requête (JSON)
  rawData: { 
    type: DataTypes.TEXT, 
    allowNull: true,
    field: 'raw_data',
    get() {
      const value = this.getDataValue('rawData');
      return value ? JSON.parse(value) : null;
    },
    set(value) {
      this.setDataValue('rawData', value ? JSON.stringify(value) : null);
    }
  },
  
  // Signature reçue (pour validation)
  signature: { 
    type: DataTypes.STRING(500), 
    allowNull: true 
  },
  
  // Signature valide ?
  signatureValid: { 
    type: DataTypes.BOOLEAN, 
    allowNull: true,
    field: 'signature_valid'
  },
  
  // Message d'erreur si échec
  errorMessage: { 
    type: DataTypes.TEXT, 
    allowNull: true,
    field: 'error_message'
  },
  
  // Succès de l'opération
  success: { 
    type: DataTypes.BOOLEAN, 
    defaultValue: true 
  },
  
  // Métadonnées additionnelles (JSON)
  metadata: { 
    type: DataTypes.TEXT, 
    allowNull: true,
    get() {
      const value = this.getDataValue('metadata');
      return value ? JSON.parse(value) : null;
    },
    set(value) {
      this.setDataValue('metadata', value ? JSON.stringify(value) : null);
    }
  }
}, {
  sequelize,
  modelName: 'PaymentLog',
  tableName: 'payment_logs',
  timestamps: true,
  updatedAt: false, // Les logs ne sont jamais modifiés
  underscored: true
});

module.exports = PaymentLog;
