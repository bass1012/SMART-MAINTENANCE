'use strict';

const addColumnIfMissing = async (queryInterface, table, description, column, definition) => {
  if (!description[column]) {
    await queryInterface.addColumn(table, column, definition);
  }
};

/**
 * Cette migration remplace les mutations autrefois exécutées au démarrage de
 * l'API. Elle est volontairement versionnée, rejouable et doit être exécutée
 * pendant la procédure de déploiement, jamais par le processus HTTP.
 */
module.exports = {
  async up(queryInterface, Sequelize) {
    const interventions = await queryInterface.describeTable('interventions');
    await addColumnIfMissing(queryInterface, 'interventions', interventions, 'payment_option', {
      type: Sequelize.STRING,
      allowNull: true,
      defaultValue: 'full'
    });
    await addColumnIfMissing(queryInterface, 'interventions', interventions, 'total_price', {
      type: Sequelize.DECIMAL(10, 2),
      allowNull: true,
      defaultValue: 0
    });
    await addColumnIfMissing(queryInterface, 'interventions', interventions, 'second_payment_amount', {
      type: Sequelize.DECIMAL(10, 2),
      allowNull: true,
      defaultValue: 0
    });
    await addColumnIfMissing(queryInterface, 'interventions', interventions, 'second_payment_status', {
      type: Sequelize.STRING,
      allowNull: true,
      defaultValue: 'none'
    });

    const diagnosticReports = await queryInterface.describeTable('diagnostic_reports');
    await addColumnIfMissing(queryInterface, 'diagnostic_reports', diagnosticReports, 'equipments', {
      type: Sequelize.TEXT,
      allowNull: true
    });
    await addColumnIfMissing(queryInterface, 'diagnostic_reports', diagnosticReports, 'materials_needed', {
      type: Sequelize.TEXT,
      allowNull: true
    });

    // Corrections historiques explicites, contrôlées par la migration.
    await queryInterface.sequelize.query(`
      UPDATE subscriptions
      SET payment_status = 'paid', first_payment_status = 'paid',
          second_payment_status = 'paid', status = 'active'
      WHERE price = 0 AND payment_status = 'pending'
    `);
    const trueValue = queryInterface.sequelize.getDialect() === 'postgres' ? 'TRUE' : '1';
    await queryInterface.sequelize.query(`
      UPDATE interventions
      SET diagnostic_paid = ${trueValue}, is_free_diagnosis = ${trueValue}
      WHERE diagnostic_fee = 0 AND (diagnostic_paid = ${queryInterface.sequelize.getDialect() === 'postgres' ? 'FALSE' : '0'} OR diagnostic_paid IS NULL)
    `);
    await queryInterface.sequelize.query(`
      UPDATE interventions
      SET second_payment_status = 'pending'
      WHERE payment_option = 'split'
        AND second_payment_status = 'paid'
        AND status <> 'completed'
        AND (customer_confirmed IS NULL OR customer_confirmed <> ${trueValue})
    `);
  },

  async down(queryInterface) {
    // Les corrections de données sont intentionnellement irréversibles : les
    // annuler pourrait dégrader l'état financier réel. Les colonnes restent
    // également en place pour ne pas casser les enregistrements existants.
    return Promise.resolve(queryInterface);
  }
};
