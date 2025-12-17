'use strict'; // Migration pour créer les tables quotes et quote_items

module.exports = {
  up: async (queryInterface, Sequelize) => {
  await queryInterface.createTable('quotes', {
      id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
      reference: { type: Sequelize.STRING, allowNull: false, unique: true },
      customerId: { type: Sequelize.INTEGER, allowNull: false },
      customerName: { type: Sequelize.STRING },
      issueDate: { type: Sequelize.DATEONLY, allowNull: false },
      expiryDate: { type: Sequelize.DATEONLY, allowNull: false },
      status: { type: Sequelize.STRING, allowNull: false, defaultValue: 'draft' },
      subtotal: { type: Sequelize.FLOAT, allowNull: false },
      taxAmount: { type: Sequelize.FLOAT, allowNull: false },
      discountAmount: { type: Sequelize.FLOAT, allowNull: false },
      total: { type: Sequelize.FLOAT, allowNull: false },
      notes: { type: Sequelize.TEXT },
      termsAndConditions: { type: Sequelize.TEXT },
      created_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.NOW },
      updated_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.NOW }
    });
  await queryInterface.createTable('quote_items', {
      id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
      quoteId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'quotes', key: 'id' }, onDelete: 'CASCADE' },
      productId: { type: Sequelize.INTEGER, allowNull: false },
      productName: { type: Sequelize.STRING },
      quantity: { type: Sequelize.INTEGER, allowNull: false },
      unitPrice: { type: Sequelize.FLOAT, allowNull: false },
      discount: { type: Sequelize.FLOAT, defaultValue: 0 },
      taxRate: { type: Sequelize.FLOAT, defaultValue: 20 },
      created_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.NOW },
      updated_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.NOW }
    });
  },
  down: async (queryInterface, Sequelize) => {
    await queryInterface.dropTable('quote_items');
    await queryInterface.dropTable('quotes');
  }
};
