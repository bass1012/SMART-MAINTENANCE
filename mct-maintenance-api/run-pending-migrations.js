const { sequelize } = require('./src/config/database');
const queryInterface = sequelize.getQueryInterface();
const Sequelize = require('sequelize');

const m1 = require('./migrations/20260801_create_outbox_events');
const m2 = require('./migrations/20260801_create_payment_webhook_events');
const m3 = require('./migrations/20260801_add_notification_idempotency');
const m4 = require('./migrations/20260801_expand_notification_types');
const m5 = require('./migrations/20260801_harden_payments_ledger');

async function run() {
  console.log('🔄 Démarrage de l\'application des migrations sur la base...');

  const migrations = [
    { name: '20260801_create_outbox_events', mod: m1 },
    { name: '20260801_create_payment_webhook_events', mod: m2 },
    { name: '20260801_add_notification_idempotency', mod: m3 },
    { name: '20260801_expand_notification_types', mod: m4 },
    { name: '20260801_harden_payments_ledger', mod: m5 }
  ];

  for (const m of migrations) {
    try {
      console.log(`➡️ Exécution de ${m.name}...`);
      await m.mod.up(queryInterface, Sequelize);
      console.log(`✅ ${m.name} appliquée avec succès.`);
    } catch (e) {
      if (
        e.message.includes('already exists') ||
        e.message.includes('déjà existante') ||
        e.message.includes('duplicate')
      ) {
        console.log(`ℹ️  ${m.name}: déjà appliquée ou ignorée (${e.message})`);
      } else {
        console.error(`❌ Erreur sur ${m.name}:`, e.message);
      }
    }
  }

  console.log('🎉 Migrations terminées avec succès.');
  process.exit(0);
}

run().catch(err => {
  console.error('❌ Erreur globale migration:', err);
  process.exit(1);
});
