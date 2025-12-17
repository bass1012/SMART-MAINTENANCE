const { sequelize } = require('./src/config/database');

async function cleanOldNotifications() {
  try {
    console.log('🧹 Nettoyage des anciennes notifications incorrectes...\n');

    // 1. Identifier les notifications problématiques
    console.log('1️⃣ Recherche des notifications "intervention_assigned" envoyées aux clients...');
    
    const [problematicNotifs] = await sequelize.query(`
      SELECT n.id, n.user_id, u.role, n.type, n.title, n.created_at
      FROM notifications n
      JOIN users u ON n.user_id = u.id
      WHERE n.type = 'intervention_assigned'
        AND u.role = 'customer'
      ORDER BY n.created_at DESC
    `);

    if (problematicNotifs.length === 0) {
      console.log('✅ Aucune notification incorrecte trouvée\n');
      await sequelize.close();
      return;
    }

    console.log(`⚠️  ${problematicNotifs.length} notification(s) incorrecte(s) trouvée(s):\n`);
    problematicNotifs.forEach(notif => {
      console.log(`   ID ${notif.id} → User ${notif.user_id} (${notif.role}) - ${notif.created_at}`);
    });

    // 2. Supprimer ces notifications
    console.log('\n2️⃣ Suppression des notifications incorrectes...');
    
    await sequelize.query(`
      DELETE FROM notifications
      WHERE type = 'intervention_assigned'
        AND user_id IN (
          SELECT id FROM users WHERE role = 'customer'
        )
    `);

    console.log('✅ Notifications incorrectes supprimées\n');

    // 3. Vérification
    console.log('3️⃣ Vérification des notifications restantes...');
    
    const [remainingNotifs] = await sequelize.query(`
      SELECT type, COUNT(*) as count 
      FROM notifications 
      GROUP BY type
      ORDER BY type
    `);

    console.log('\n📊 Types de notifications dans la base:');
    remainingNotifs.forEach(row => {
      console.log(`   - ${row.type}: ${row.count} notification(s)`);
    });

    await sequelize.close();
    console.log('\n🎉 Nettoyage terminé avec succès !');
    console.log('\n💡 Conseil: Synchronisez l\'application mobile pour rafraîchir les notifications');
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

cleanOldNotifications();
