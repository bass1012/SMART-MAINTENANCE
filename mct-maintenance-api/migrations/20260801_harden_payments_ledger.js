'use strict';

const UNIQUE_INDEX = 'payments_provider_payment_id_uq';

const widenStringColumns = async (queryInterface, Sequelize, dialect) => {
  if (dialect === 'postgres') {
    await queryInterface.sequelize.query(
      'ALTER TABLE "payments" ALTER COLUMN "provider" TYPE VARCHAR(32) USING "provider"::text'
    );
    await queryInterface.sequelize.query(
      'ALTER TABLE "payments" ALTER COLUMN "status" DROP DEFAULT'
    );
    await queryInterface.sequelize.query(
      'ALTER TABLE "payments" ALTER COLUMN "status" TYPE VARCHAR(32) USING "status"::text'
    );
    await queryInterface.sequelize.query(
      'ALTER TABLE "payments" ALTER COLUMN "status" SET DEFAULT \'pending\''
    );
    await queryInterface.sequelize.query(
      'ALTER TABLE "payment_logs" ALTER COLUMN "event_type" TYPE VARCHAR(64) USING "event_type"::text'
    );
    return;
  }

  if (dialect === 'mysql' || dialect === 'mariadb') {
    await queryInterface.changeColumn('payments', 'provider', {
      type: Sequelize.STRING(32),
      allowNull: false
    });
    await queryInterface.changeColumn('payments', 'status', {
      type: Sequelize.STRING(32),
      allowNull: false,
      defaultValue: 'pending'
    });
    await queryInterface.changeColumn('payment_logs', 'event_type', {
      type: Sequelize.STRING(64),
      allowNull: false
    });
  }
};

const addColumnIfMissing = async (queryInterface, table, description, column, definition) => {
  if (!description[column]) {
    await queryInterface.addColumn(table, column, definition);
  }
};

module.exports = {
  async up(queryInterface, Sequelize) {
    const paymentColumns = await queryInterface.describeTable('payments');
    const paymentLogColumns = await queryInterface.describeTable('payment_logs');

    const [duplicates] = await queryInterface.sequelize.query(`
      SELECT provider, payment_id, COUNT(*) AS duplicate_count
      FROM payments
      WHERE payment_id IS NOT NULL
      GROUP BY provider, payment_id
      HAVING COUNT(*) > 1
    `);

    if (duplicates.length > 0) {
      const sample = duplicates
        .slice(0, 10)
        .map((row) => `${row.provider}:${row.payment_id} (${row.duplicate_count})`)
        .join(', ');
      throw new Error(
        `Doublons financiers détectés avant création de l'index unique: ${sample}. `
        + 'Rapprochement manuel requis; aucune ligne ne sera supprimée automatiquement.'
      );
    }

    const dialect = queryInterface.sequelize.getDialect();
    if (paymentColumns.provider && paymentColumns.status && paymentLogColumns.event_type) {
      await widenStringColumns(queryInterface, Sequelize, dialect);
    }

    await addColumnIfMissing(queryInterface, 'payments', paymentColumns, 'intervention_id', {
      type: Sequelize.INTEGER,
      allowNull: true,
      references: { model: 'interventions', key: 'id' },
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL'
    });
    await addColumnIfMissing(queryInterface, 'payments', paymentColumns, 'payment_step', {
      type: Sequelize.SMALLINT,
      allowNull: true
    });
    await addColumnIfMissing(queryInterface, 'payments', paymentColumns, 'purpose', {
      type: Sequelize.STRING(32),
      allowNull: true
    });
    await addColumnIfMissing(queryInterface, 'payments', paymentColumns, 'sync_ref', {
      type: Sequelize.STRING(191),
      allowNull: true
    });
    await addColumnIfMissing(queryInterface, 'payments', paymentColumns, 'gateway_checkout_id', {
      type: Sequelize.STRING(191),
      allowNull: true
    });
    await addColumnIfMissing(queryInterface, 'payments', paymentColumns, 'verified_at', {
      type: Sequelize.DATE,
      allowNull: true
    });

    const indexes = await queryInterface.showIndex('payments');
    if (!indexes.some((index) => index.name === UNIQUE_INDEX)) {
      await queryInterface.addIndex('payments', ['provider', 'payment_id'], {
        name: UNIQUE_INDEX,
        unique: true
      });
    }
  },

  async down(queryInterface) {
    const indexes = await queryInterface.showIndex('payments');
    if (indexes.some((index) => index.name === UNIQUE_INDEX)) {
      await queryInterface.removeIndex('payments', UNIQUE_INDEX);
    }

    const columns = await queryInterface.describeTable('payments');
    for (const column of [
      'verified_at',
      'gateway_checkout_id',
      'sync_ref',
      'purpose',
      'payment_step',
      'intervention_id'
    ]) {
      if (columns[column]) await queryInterface.removeColumn('payments', column);
    }

    // Les colonnes STRING ne sont volontairement pas reconverties en ENUM :
    // un rollback après l'arrivée de paiements FineoPay serait destructif.
  }
};
