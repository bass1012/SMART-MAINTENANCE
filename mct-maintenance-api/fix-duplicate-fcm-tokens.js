const { sequelize } = require('./src/config/database');

async function fixDuplicateTokens() {
  try {
    console.log('🔍 Recherche des FCM tokens dupliqués...\n');

    // Trouver tous les tokens dupliqués
    const [duplicates] = await sequelize.query(`
      SELECT fcm_token, COUNT(*) as count, GROUP_CONCAT(id) as user_ids
      FROM users 
      WHERE fcm_token IS NOT NULL AND fcm_token != ''
      GROUP BY fcm_token
      HAVING count > 1
      ORDER BY count DESC
    `);

    if (duplicates.length === 0) {
      console.log('✅ Aucun FCM token dupliqué trouvé\n');
      await sequelize.close();
      return;
    }

    console.log(`⚠️  ${duplicates.length} FCM token(s) dupliqué(s) trouvé(s):\n`);
    
    for (const dup of duplicates) {
      console.log(`📱 Token: ${dup.fcm_token.substring(0, 50)}...`);
      console.log(`   👥 Utilisé par ${dup.count} user(s): ${dup.user_ids}`);
      
      // Garder seulement le dernier utilisateur connecté avec ce token
      const userIds = dup.user_ids.split(',').map(id => parseInt(id));
      
      const [users] = await sequelize.query(`
        SELECT id, email, role, last_login
        FROM users
        WHERE id IN (${userIds.join(',')})
        ORDER BY last_login DESC
      `);
      
      console.log('   📊 Détails des utilisateurs:');
      users.forEach((user, index) => {
        const status = index === 0 ? '✅ GARDER' : '❌ SUPPRIMER';
        console.log(`      ${status} - User ${user.id} (${user.role}) ${user.email} - Last login: ${user.last_login || 'Never'}`);
      });
      
      // Supprimer le token pour tous sauf le premier (dernier connecté)
      const usersToClean = users.slice(1).map(u => u.id);
      
      if (usersToClean.length > 0) {
        await sequelize.query(`
          UPDATE users
          SET fcm_token = NULL
          WHERE id IN (${usersToClean.join(',')})
        `);
        console.log(`   ✅ Token supprimé pour ${usersToClean.length} user(s)\n`);
      }
    }

    console.log('🎉 Nettoyage terminé !\n');
    
    // Vérification finale
    const [remaining] = await sequelize.query(`
      SELECT COUNT(DISTINCT fcm_token) as unique_tokens, COUNT(*) as total_users
      FROM users
      WHERE fcm_token IS NOT NULL AND fcm_token != ''
    `);
    
    console.log('📊 État final:');
    console.log(`   - ${remaining[0].unique_tokens} FCM token(s) unique(s)`);
    console.log(`   - ${remaining[0].total_users} utilisateur(s) avec token\n`);

    await sequelize.close();
    console.log('💡 Conseil: Demandez aux utilisateurs de se déconnecter puis reconnecter');
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

fixDuplicateTokens();
