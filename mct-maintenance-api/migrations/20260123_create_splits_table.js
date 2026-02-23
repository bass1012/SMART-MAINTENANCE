/**
 * Migration: Création de la table Splits et modifications pour traçabilité
 * 
 * Cette migration crée:
 * 1. La table Splits pour stocker les équipements individuels
 * 2. Ajoute split_id aux Subscriptions (l'offre est liée au split)
 * 3. Ajoute les colonnes de scan aux Interventions
 */

module.exports = {
  up: async (queryInterface, Sequelize) => {
    console.log('🚀 Démarrage de la migration: Création table Splits et traçabilité...\n');

    // ========================================
    // 1. Créer la table Splits
    // ========================================
    console.log('📦 Création de la table Splits...');
    
    await queryInterface.sequelize.query(`
      CREATE TABLE IF NOT EXISTS Splits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        split_code VARCHAR(50) NOT NULL UNIQUE,
        qr_code_url VARCHAR(255),
        customer_id INTEGER NOT NULL,
        brand VARCHAR(100),
        model VARCHAR(100),
        serial_number VARCHAR(100),
        power VARCHAR(50),
        power_type VARCHAR(10) DEFAULT 'BTU',
        location VARCHAR(100),
        floor VARCHAR(50),
        installation_date DATE,
        warranty_end_date DATE,
        last_maintenance_date DATE,
        next_maintenance_date DATE,
        status VARCHAR(30) DEFAULT 'active',
        notes TEXT,
        photo_url VARCHAR(255),
        intervention_count INTEGER DEFAULT 0,
        installation_address VARCHAR(255),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (customer_id) REFERENCES Users(id)
      )
    `);
    console.log('   ✅ Table Splits créée\n');

    // Créer index sur split_code pour recherche rapide
    await queryInterface.sequelize.query(`
      CREATE INDEX IF NOT EXISTS idx_splits_split_code ON Splits(split_code)
    `);
    console.log('   ✅ Index sur split_code créé\n');

    // Créer index sur customer_id pour recherche par client
    await queryInterface.sequelize.query(`
      CREATE INDEX IF NOT EXISTS idx_splits_customer_id ON Splits(customer_id)
    `);
    console.log('   ✅ Index sur customer_id créé\n');

    // ========================================
    // 2. Ajouter split_id à Subscriptions
    // ========================================
    console.log('📦 Modification de la table Subscriptions...');
    
    // Vérifier si la colonne existe déjà
    const subscriptionColumns = await queryInterface.describeTable('Subscriptions');
    
    if (!subscriptionColumns.split_id) {
      await queryInterface.addColumn('Subscriptions', 'split_id', {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: {
          model: 'Splits',
          key: 'id'
        }
      });
      console.log('   ✅ Colonne split_id ajoutée à Subscriptions\n');
    } else {
      console.log('   ℹ️ Colonne split_id existe déjà dans Subscriptions\n');
    }

    // ========================================
    // 3. Ajouter colonnes de scan à Interventions
    // ========================================
    console.log('📦 Modification de la table Interventions...');
    
    const interventionColumns = await queryInterface.describeTable('Interventions');
    
    const columnsToAdd = [
      { name: 'split_id', definition: { type: Sequelize.INTEGER, allowNull: true } },
      { name: 'split_scan_method', definition: { type: Sequelize.STRING(30), defaultValue: 'none', allowNull: true } },
      { name: 'split_scan_exception_reason', definition: { type: Sequelize.STRING(255), allowNull: true } },
      { name: 'split_scanned_at', definition: { type: Sequelize.DATE, allowNull: true } }
    ];
    
    for (const col of columnsToAdd) {
      if (!interventionColumns[col.name]) {
        await queryInterface.addColumn('Interventions', col.name, col.definition);
        console.log(`   ✅ Colonne ${col.name} ajoutée à Interventions`);
      } else {
        console.log(`   ℹ️ Colonne ${col.name} existe déjà dans Interventions`);
      }
    }
    
    console.log('');

    // ========================================
    // 4. Créer la table SplitHistory (historique des changements)
    // ========================================
    console.log('📦 Création de la table SplitHistory...');
    
    await queryInterface.sequelize.query(`
      CREATE TABLE IF NOT EXISTS SplitHistory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        split_id INTEGER NOT NULL,
        action VARCHAR(50) NOT NULL,
        field_changed VARCHAR(100),
        old_value TEXT,
        new_value TEXT,
        changed_by INTEGER,
        notes TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (split_id) REFERENCES Splits(id),
        FOREIGN KEY (changed_by) REFERENCES Users(id)
      )
    `);
    console.log('   ✅ Table SplitHistory créée\n');

    console.log('✅ Migration terminée avec succès !');
  },

  down: async (queryInterface, Sequelize) => {
    console.log('🔄 Rollback de la migration Splits...');
    
    // Supprimer les colonnes ajoutées aux tables existantes
    const interventionColumns = await queryInterface.describeTable('Interventions');
    if (interventionColumns.split_id) await queryInterface.removeColumn('Interventions', 'split_id');
    if (interventionColumns.split_scan_method) await queryInterface.removeColumn('Interventions', 'split_scan_method');
    if (interventionColumns.split_scan_exception_reason) await queryInterface.removeColumn('Interventions', 'split_scan_exception_reason');
    if (interventionColumns.split_scanned_at) await queryInterface.removeColumn('Interventions', 'split_scanned_at');
    
    const subscriptionColumns = await queryInterface.describeTable('Subscriptions');
    if (subscriptionColumns.split_id) await queryInterface.removeColumn('Subscriptions', 'split_id');
    
    // Supprimer les tables
    await queryInterface.dropTable('SplitHistory');
    await queryInterface.dropTable('Splits');
    
    console.log('✅ Rollback terminé');
  }
};
