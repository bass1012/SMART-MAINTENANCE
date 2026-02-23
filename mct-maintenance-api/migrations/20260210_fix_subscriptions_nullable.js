'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    console.log('🔄 Reconstruction de la table subscriptions pour rendre maintenance_offer_id nullable...\n');

    try {
      // Désactiver les contraintes FK temporairement
      await queryInterface.sequelize.query('PRAGMA foreign_keys = OFF');
      console.log('✅ Contraintes FK désactivées');

      // Nettoyer toute tentative précédente
      await queryInterface.sequelize.query('DROP TABLE IF EXISTS subscriptions_new');
      console.log('✅ Nettoyage effectué');

      // Créer une nouvelle table avec maintenance_offer_id nullable
      await queryInterface.sequelize.query(`
        CREATE TABLE subscriptions_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_id INTEGER NOT NULL,
          maintenance_offer_id INTEGER NULL,
          installation_service_id INTEGER NULL,
          repair_service_id INTEGER NULL,
          split_id INTEGER NULL,
          status TEXT NOT NULL DEFAULT 'active',
          start_date DATETIME NOT NULL,
          end_date DATETIME,
          price DECIMAL(10,2) NOT NULL,
          payment_status TEXT NOT NULL DEFAULT 'pending',
          created_at DATETIME NOT NULL,
          updated_at DATETIME NOT NULL,
          deleted_at DATETIME NULL,
          FOREIGN KEY (customer_id) REFERENCES users(id),
          FOREIGN KEY (maintenance_offer_id) REFERENCES maintenance_offers(id),
          FOREIGN KEY (installation_service_id) REFERENCES installation_services(id),
          FOREIGN KEY (repair_service_id) REFERENCES repair_services(id),
          FOREIGN KEY (split_id) REFERENCES splits(id)
        );
      `);
      console.log('✅ Table subscriptions_new créée');

      // Copier les données existantes (colonnes explicites)
      await queryInterface.sequelize.query(`
        INSERT INTO subscriptions_new 
        (id, customer_id, maintenance_offer_id, status, start_date, end_date, 
         price, payment_status, created_at, updated_at, deleted_at)
        SELECT 
          id, customer_id, maintenance_offer_id, status, start_date, end_date, 
          price, payment_status, created_at, updated_at, deleted_at
        FROM subscriptions;
      `);
      console.log('✅ Données copiées');

      // Supprimer l'ancienne table
      await queryInterface.sequelize.query('DROP TABLE subscriptions;');
      console.log('✅ Ancienne table supprimée');

      // Renommer la nouvelle table
      await queryInterface.sequelize.query(`
        ALTER TABLE subscriptions_new RENAME TO subscriptions;
      `);
      console.log('✅ Table renommée');

      // Recréer les index
      await queryInterface.sequelize.query(`
        CREATE INDEX IF NOT EXISTS idx_subscriptions_customer 
        ON subscriptions(customer_id);
      `);
      await queryInterface.sequelize.query(`
        CREATE INDEX IF NOT EXISTS idx_subscriptions_offer 
        ON subscriptions(maintenance_offer_id);
      `);
      await queryInterface.sequelize.query(`
        CREATE INDEX IF NOT EXISTS idx_subscriptions_installation 
        ON subscriptions(installation_service_id);
      `);
      await queryInterface.sequelize.query(`
        CREATE INDEX IF NOT EXISTS idx_subscriptions_repair 
        ON subscriptions(repair_service_id);
      `);
      console.log('✅ Index recréés');

      // Réactiver les contraintes FK
      await queryInterface.sequelize.query('PRAGMA foreign_keys = ON');
      console.log('✅ Contraintes FK réactivées');

      console.log('\n✅ Migration terminée avec succès!');
      console.log('📝 maintenance_offer_id est maintenant nullable\n');
      
    } catch (error) {
      console.error('❌ Erreur lors de la migration:', error.message);
      console.error('   Détails:', error);
      // Réactiver les contraintes FK en cas d'erreur
      try {
        await queryInterface.sequelize.query('PRAGMA foreign_keys = ON');
      } catch (e) {
        // Ignorer les erreurs de réactivation
      }
      throw error;
    }
  },

  down: async (queryInterface, Sequelize) => {
    console.log('⚠️  Cette migration ne peut pas être annulée facilement.');
    console.log('   Une sauvegarde de la base de données est recommandée avant de procéder.\n');
  }
};
