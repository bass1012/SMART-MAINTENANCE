// Migration: Création de la table equipments
module.exports = {
  up: async (queryInterface, Sequelize) => {
  await queryInterface.createTable('equipments', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true,
        allowNull: false
      },
      customer_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'RESTRICT',
        comment: 'Référence vers users.id (client propriétaire de l\'équipement)'
      },
      name: {
        type: Sequelize.STRING(255),
        allowNull: false,
        comment: 'Nom de l\'équipement (ex: Climatiseur Samsung, Chauffe-eau LG)'
      },
      type: {
        type: Sequelize.STRING(100),
        allowNull: false,
        comment: 'Type d\'équipement (ex: climatiseur, chauffe-eau, pompe)'
      },
      brand: {
        type: Sequelize.STRING(100),
        allowNull: true,
        comment: 'Marque de l\'équipement'
      },
      model: {
        type: Sequelize.STRING(100),
        allowNull: true,
        comment: 'Modèle de l\'équipement'
      },
      serial_number: {
        type: Sequelize.STRING(100),
        allowNull: true,
        unique: true,
        comment: 'Numéro de série unique'
      },
      installation_date: {
        type: Sequelize.DATEONLY,
        allowNull: true,
        comment: 'Date d\'installation'
      },
      purchase_date: {
        type: Sequelize.DATEONLY,
        allowNull: true,
        comment: 'Date d\'achat'
      },
      warranty_expiry: {
        type: Sequelize.DATEONLY,
        allowNull: true,
        comment: 'Date d\'expiration de la garantie'
      },
      location: {
        type: Sequelize.STRING(255),
        allowNull: true,
        comment: 'Emplacement chez le client (ex: Salon, Chambre 1, Bureau)'
      },
      status: {
        type: Sequelize.ENUM('active', 'inactive', 'maintenance', 'retired'),
        allowNull: false,
        defaultValue: 'active',
        comment: 'Statut de l\'équipement'
      },
      last_maintenance_date: {
        type: Sequelize.DATE,
        allowNull: true,
        comment: 'Date de la dernière maintenance'
      },
      next_maintenance_date: {
        type: Sequelize.DATE,
        allowNull: true,
        comment: 'Date de la prochaine maintenance planifiée'
      },
      notes: {
        type: Sequelize.TEXT,
        allowNull: true,
        comment: 'Notes et observations sur l\'équipement'
      },
      createdAt: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      },
      updatedAt: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      },
      deletedAt: {
        type: Sequelize.DATE,
        allowNull: true,
        comment: 'Soft delete timestamp'
      }
    });

    // Créer des index pour améliorer les performances, mais ignorer si déjà existants
    const indexes = [
      { fields: ['customer_id'], name: 'idx_equipments_customer_id' },
      { fields: ['status'], name: 'idx_equipments_status' },
      { fields: ['type'], name: 'idx_equipments_type' }
    ];
    for (const idx of indexes) {
      try {
        await queryInterface.addIndex('equipments', idx.fields, { name: idx.name });
      } catch (err) {
        if (err && err.message && err.message.includes('already exists')) {
          console.warn(`Index ${idx.name} déjà existant, ignoré.`);
        } else {
          throw err;
        }
      }
    }
    console.log('✅ Table equipments créée avec succès');
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.dropTable('equipments');
    console.log('✅ Table equipments supprimée');
  }
};
