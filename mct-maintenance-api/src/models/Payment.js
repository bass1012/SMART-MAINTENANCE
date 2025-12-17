module.exports = (sequelize, DataTypes) => {
  const Payment = sequelize.define('Payment', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    orderId: {
      type: DataTypes.INTEGER,
      allowNull: true,
      field: 'order_id',
      references: {
        model: 'orders',
        key: 'id'
      }
    },
    subscriptionId: {
      type: DataTypes.INTEGER,
      allowNull: true,
      field: 'subscription_id',
      references: {
        model: 'subscriptions',
        key: 'id'
      }
    },
    amount: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
      comment: 'Montant du paiement'
    },
    currency: {
      type: DataTypes.STRING(3),
      defaultValue: 'XOF',
      comment: 'Devise (XOF pour Franc CFA)'
    },
    provider: {
      type: DataTypes.ENUM('stripe', 'wave', 'orange_money', 'mtn_money', 'moov_money', 'cash'),
      allowNull: false,
      comment: 'Provider de paiement utilisé'
    },
    paymentId: {
      type: DataTypes.STRING,
      field: 'payment_id',
      comment: 'ID du paiement chez le provider'
    },
    status: {
      type: DataTypes.ENUM('pending', 'processing', 'succeeded', 'failed', 'refunded', 'cancelled'),
      defaultValue: 'pending',
      comment: 'Statut du paiement'
    },
    paymentMethod: {
      type: DataTypes.STRING,
      field: 'payment_method',
      comment: 'Méthode de paiement (carte, mobile money, etc.)'
    },
    phoneNumber: {
      type: DataTypes.STRING,
      field: 'phone_number',
      comment: 'Numéro de téléphone pour mobile money'
    },
    transactionId: {
      type: DataTypes.STRING,
      field: 'transaction_id',
      comment: 'ID de transaction du provider'
    },
    checkoutUrl: {
      type: DataTypes.TEXT,
      field: 'checkout_url',
      comment: 'URL de paiement pour redirection'
    },
    metadata: {
      type: DataTypes.JSON,
      comment: 'Métadonnées additionnelles du paiement'
    },
    errorMessage: {
      type: DataTypes.TEXT,
      field: 'error_message',
      comment: 'Message d\'erreur en cas d\'échec'
    },
    paidAt: {
      type: DataTypes.DATE,
      field: 'paid_at',
      comment: 'Date et heure du paiement réussi'
    },
    refundedAt: {
      type: DataTypes.DATE,
      field: 'refunded_at',
      comment: 'Date et heure du remboursement'
    },
    refundAmount: {
      type: DataTypes.DECIMAL(10, 2),
      field: 'refund_amount',
      comment: 'Montant remboursé'
    },
    refundReason: {
      type: DataTypes.TEXT,
      field: 'refund_reason',
      comment: 'Raison du remboursement'
    }
  }, {
    tableName: 'payments',
    underscored: true,
    timestamps: true,
    paranoid: false,
    indexes: [
      {
        fields: ['order_id']
      },
      {
        fields: ['payment_id']
      },
      {
        fields: ['status']
      },
      {
        fields: ['provider']
      }
    ]
  });

  Payment.associate = (models) => {
    Payment.belongsTo(models.Order, {
      foreignKey: 'orderId',
      as: 'order'
    });
    
    Payment.belongsTo(models.Subscription, {
      foreignKey: 'subscriptionId',
      as: 'subscription'
    });
  };

  return Payment;
};
