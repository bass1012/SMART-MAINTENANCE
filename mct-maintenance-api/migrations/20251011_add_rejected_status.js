// Migration pour ajouter le statut 'rejected' aux réclamations
'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    // SQLite ne supporte pas ALTER COLUMN pour modifier un ENUM
    // Il faut recréer la table avec le nouveau statut
    
    // 1. Créer une table temporaire avec la nouvelle structure
    await queryInterface.createTable('complaints_temp', {
      id: {
        type: Sequelize.INTEGER,
        autoIncrement: true,
        primaryKey: true
      },
      reference: { 
        type: Sequelize.STRING(50), 
        allowNull: false,
        unique: true 
      },
      customer_id: { 
        type: Sequelize.INTEGER, 
        allowNull: false
      },
      order_id: { 
        type: Sequelize.INTEGER, 
        allowNull: true
      },
      product_id: { 
        type: Sequelize.INTEGER, 
        allowNull: true
      },
      intervention_id: { 
        type: Sequelize.INTEGER, 
        allowNull: true
      },
      subject: { 
        type: Sequelize.STRING(255), 
        allowNull: false 
      },
      description: { 
        type: Sequelize.TEXT, 
        allowNull: false 
      },
      status: { 
        type: Sequelize.STRING, // Utiliser STRING au lieu d'ENUM pour SQLite
        allowNull: false,
        defaultValue: 'open'
      },
      priority: { 
        type: Sequelize.STRING, // Utiliser STRING au lieu d'ENUM pour SQLite
        allowNull: false,
        defaultValue: 'medium'
      },
      category: { 
        type: Sequelize.STRING(100), 
        allowNull: true 
      },
      resolution: { 
        type: Sequelize.TEXT, 
        allowNull: true 
      },
      resolved_at: { 
        type: Sequelize.DATE, 
        allowNull: true
      },
      assigned_to: { 
        type: Sequelize.INTEGER, 
        allowNull: true
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.NOW
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.NOW
      },
      deleted_at: {
        type: Sequelize.DATE,
        allowNull: true
      }
    });

    // 2. Copier les données existantes
    await queryInterface.sequelize.query(`
      INSERT INTO complaints_temp (
        id, reference, customer_id, order_id, product_id, intervention_id,
        subject, description, status, priority, category, resolution,
        resolved_at, assigned_to, created_at, updated_at, deleted_at
      )
      SELECT 
        id, reference, customer_id, order_id, product_id, intervention_id,
        subject, description, status, priority, category, resolution,
        resolved_at, assigned_to, created_at, updated_at, deleted_at
      FROM complaints
    `);

    // 3. Supprimer l'ancienne table
    await queryInterface.dropTable('complaints');

    // 4. Renommer la table temporaire
    await queryInterface.renameTable('complaints_temp', 'complaints');
  },

  down: async (queryInterface, Sequelize) => {
    // Revenir à l'ancienne structure sans 'rejected'
    // Cette migration est irréversible en pratique
    console.log('Migration down non implémentée - modification de structure complexe');
  }
};