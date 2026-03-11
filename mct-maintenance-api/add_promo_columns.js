const { sequelize } = require('./src/config/database');

async function addPromoColumns() {
  try {
    await sequelize.query('ALTER TABLE subscriptions ADD COLUMN original_price REAL');
    console.log('✅ Colonne original_price ajoutée');
  } catch (e) {
    if (e.message.includes('duplicate column') || e.message.includes('already exists')) {
      console.log('⚠️ original_price existe déjà');
    } else {
      console.error('❌', e.message);
    }
  }
  
  try {
    await sequelize.query('ALTER TABLE subscriptions ADD COLUMN discount_amount REAL DEFAULT 0');
    console.log('✅ Colonne discount_amount ajoutée');
  } catch (e) {
    if (e.message.includes('duplicate column') || e.message.includes('already exists')) {
      console.log('⚠️ discount_amount existe déjà');
    } else {
      console.error('❌', e.message);
    }
  }
  
  try {
    await sequelize.query('ALTER TABLE subscriptions ADD COLUMN promo_code VARCHAR(50)');
    console.log('✅ Colonne promo_code ajoutée');
  } catch (e) {
    if (e.message.includes('duplicate column') || e.message.includes('already exists')) {
      console.log('⚠️ promo_code existe déjà');
    } else {
      console.error('❌', e.message);
    }
  }
  
  await sequelize.close();
  console.log('✅ Migration terminée');
}

addPromoColumns();
