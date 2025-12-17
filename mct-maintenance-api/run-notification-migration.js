const fs = require('fs');
const path = require('path');
const { sequelize } = require('./src/config/database');

async function runMigration() {
  try {
    console.log('🔄 Exécution de la migration pour ajouter le type "technician_assigned"...\n');

    // Lire le fichier SQL
    const migrationPath = path.join(__dirname, 'migrations', 'add_technician_assigned_notification_type.sql');
    const sql = fs.readFileSync(migrationPath, 'utf8');

    // Séparer les commandes SQL (ignorer les commentaires)
    const commands = sql
      .split(';')
      .map(cmd => cmd.trim())
      .filter(cmd => cmd.length > 0 && !cmd.startsWith('--'));

    // Exécuter chaque commande
    for (const command of commands) {
      if (command) {
        console.log('📝 Exécution:', command.substring(0, 50) + '...');
        await sequelize.query(command);
      }
    }

    console.log('\n✅ Migration réussie !');
    console.log('\n📊 Vérification de la table notifications...');
    
    const [results] = await sequelize.query(`
      SELECT type, COUNT(*) as count 
      FROM notifications 
      GROUP BY type
    `);
    
    console.log('\n📈 Types de notifications dans la base:');
    results.forEach(row => {
      console.log(`   - ${row.type}: ${row.count} notification(s)`);
    });

    await sequelize.close();
    console.log('\n🎉 Migration terminée avec succès !');
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur lors de la migration:', error);
    process.exit(1);
  }
}

runMigration();
