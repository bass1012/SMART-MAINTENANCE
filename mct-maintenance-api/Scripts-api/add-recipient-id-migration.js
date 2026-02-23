const { sequelize } = require('../src/config/database');

async function addRecipientIdColumn() {
  try {
    console.log('🔧 Ajout de la colonne recipient_id à chat_messages...');
    
    // Vérifier si la colonne existe déjà
    const [results] = await sequelize.query(`
      PRAGMA table_info(chat_messages);
    `);
    
    const columnExists = results.some(col => col.name === 'recipient_id');
    
    if (columnExists) {
      console.log('✅ La colonne recipient_id existe déjà');
      process.exit(0);
    }
    
    // Ajouter la colonne
    await sequelize.query(`
      ALTER TABLE chat_messages ADD COLUMN recipient_id INTEGER;
    `);
    
    console.log('✅ Colonne recipient_id ajoutée avec succès');
    
    // Pour les messages existants des admins, on peut essayer de déduire le recipient_id
    // en regardant les messages des clients dans la même période
    console.log('📝 Migration des données existantes...');
    
    // Pour chaque message d'admin, trouver le client qui a écrit juste avant
    await sequelize.query(`
      UPDATE chat_messages 
      SET recipient_id = (
        SELECT sender_id 
        FROM chat_messages c2 
        WHERE c2.sender_role = 'customer' 
        AND c2.created_at < chat_messages.created_at
        ORDER BY c2.created_at DESC 
        LIMIT 1
      )
      WHERE sender_role = 'admin' AND recipient_id IS NULL;
    `);
    
    console.log('✅ Migration des données terminée');
    console.log('🎉 Migration complète !');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur lors de la migration:', error);
    process.exit(1);
  }
}

addRecipientIdColumn();
