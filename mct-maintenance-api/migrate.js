const { sequelize } = require('./src/config/database');

async function main() {
  try {
    await sequelize.query("ALTER TABLE users ALTER COLUMN profile_image TYPE TEXT;");
    console.log('✅ users.profile_image -> TEXT');
  } catch (e) {
    if (e.message.includes('already exists') || e.message.includes('cannot be cast')) {
      console.log('ℹ️  users.profile_image: déjà TEXT ou pas besoin');
    } else {
      throw e;
    }
  }

  try {
    await sequelize.query('ALTER TABLE equipments ADD COLUMN IF NOT EXISTS "imageUrl" TEXT;');
    console.log('✅ equipments.imageUrl ajouté');
  } catch (e) {
    if (e.message.includes('already exists')) {
      console.log('ℹ️  equipments.imageUrl: colonne déjà existante');
    } else {
      throw e;
    }
  }

  console.log('Migration SQL OK');
  process.exit(0);
}

main().catch(e => {
  console.error('Erreur migration:', e.message);
  process.exit(1);
});
