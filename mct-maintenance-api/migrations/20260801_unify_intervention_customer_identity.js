'use strict';

const normalizeTableName = (value) => String(value || '').replace(/["'`]/g, '').toLowerCase();

const buildBackfillPlan = ({ interventionCustomerIds, profiles, users, referencedTable }) => {
  const profileById = new Map(profiles.map((profile) => [Number(profile.id), profile]));
  const profileByUserId = new Map(profiles.map((profile) => [Number(profile.user_id), profile]));
  const userIds = new Set(users.map((user) => Number(user.id)));
  const source = normalizeTableName(referencedTable);
  const updates = [];
  const errors = [];

  for (const rawId of interventionCustomerIds) {
    const id = Number(rawId);
    const asProfile = profileById.get(id);
    const asUserProfile = profileByUserId.get(id);
    const isUser = userIds.has(id);

    if (source === 'customer_profiles') {
      if (asProfile) continue;
      errors.push({ customerId: id, reason: 'PROFILE_FOREIGN_KEY_ORPHAN' });
      continue;
    }

    if (source === 'users') {
      if (!isUser || !asUserProfile) {
        errors.push({ customerId: id, reason: 'USER_WITHOUT_CUSTOMER_PROFILE' });
      } else {
        updates.push({ from: id, to: Number(asUserProfile.id) });
      }
      continue;
    }

    if (asProfile && !isUser) continue;
    if (!asProfile && isUser && asUserProfile) {
      updates.push({ from: id, to: Number(asUserProfile.id) });
      continue;
    }
    if (asProfile && isUser && asUserProfile && Number(asProfile.id) === Number(asUserProfile.id)) {
      continue;
    }
    errors.push({
      customerId: id,
      reason: asProfile && isUser ? 'AMBIGUOUS_USER_PROFILE_COLLISION' : 'ORPHAN_CUSTOMER_ID'
    });
  }
  return { updates, errors };
};

module.exports = {
  buildBackfillPlan,

  async up(queryInterface, Sequelize) {
    const references = await queryInterface.getForeignKeyReferencesForTable('interventions');
    const currentReference = references.find((reference) => (
      reference.columnName === 'customer_id' || reference.column_name === 'customer_id'
    ));
    const referencedTable = currentReference?.referencedTableName
      || currentReference?.referenced_table_name
      || null;

    const [interventions] = await queryInterface.sequelize.query(
      'SELECT DISTINCT customer_id FROM interventions WHERE customer_id IS NOT NULL'
    );
    const [profiles] = await queryInterface.sequelize.query(
      'SELECT id, user_id FROM customer_profiles'
    );
    const [users] = await queryInterface.sequelize.query('SELECT id FROM users');
    const plan = buildBackfillPlan({
      interventionCustomerIds: interventions.map((row) => row.customer_id),
      profiles,
      users,
      referencedTable
    });

    if (plan.errors.length > 0) {
      const sample = JSON.stringify(plan.errors.slice(0, 20));
      throw new Error(`Migration identité client refusée; rapprochement manuel requis: ${sample}`);
    }

    await queryInterface.sequelize.transaction(async (transaction) => {
      if (currentReference && normalizeTableName(referencedTable) !== 'customer_profiles') {
        const constraintName = currentReference.constraintName || currentReference.constraint_name;
        if (!constraintName) throw new Error('Nom de contrainte customer_id introuvable');
        await queryInterface.removeConstraint('interventions', constraintName, { transaction });
      }

      for (const update of plan.updates) {
        await queryInterface.bulkUpdate(
          'interventions',
          { customer_id: update.to },
          { customer_id: update.from },
          { transaction }
        );
      }

      if (normalizeTableName(referencedTable) !== 'customer_profiles') {
        await queryInterface.addConstraint('interventions', {
          fields: ['customer_id'],
          type: 'foreign key',
          name: 'interventions_customer_id_customer_profiles_fk',
          references: { table: 'customer_profiles', field: 'id' },
          onUpdate: 'CASCADE',
          onDelete: 'CASCADE',
          transaction
        });
      }
    });
  },

  async down() {
    throw new Error(
      'Migration non réversible automatiquement : les anciens User.id ne peuvent pas être reconstruits sans ambiguïté'
    );
  }
};
