const { Sequelize } = require('sequelize');
const path = require('path');

// Configurer Sequelize pour SQLite
const sequelize = new Sequelize({
  dialect: 'sqlite',
  storage: path.join(__dirname, 'database.sqlite'),
  logging: false
});

async function checkAvatars() {
  try {
    console.log('🔍 Vérification des avatars dans la base de données...\n');

    // Requête directe sur la table users
    const [users] = await sequelize.query(`
      SELECT id, email, first_name, last_name, role, profile_image 
      FROM users 
      WHERE deleted_at IS NULL 
      AND role = 'technician'
      ORDER BY id
    `);

    console.log(`✅ ${users.length} technicien(s) trouvé(s)\n`);

    users.forEach(user => {
      console.log(`👤 User ID: ${user.id}`);
      console.log(`   Email: ${user.email}`);
      console.log(`   Nom: ${user.first_name} ${user.last_name}`);
      console.log(`   Rôle: ${user.role}`);
      console.log(`   🖼️  profile_image: ${user.profile_image || 'NULL'}`);
      
      if (user.profile_image) {
        console.log(`   ✅ Avatar défini: ${user.profile_image}`);
      } else {
        console.log(`   ❌ Pas d'avatar`);
      }
      console.log('');
    });

    await sequelize.close();
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

checkAvatars();
