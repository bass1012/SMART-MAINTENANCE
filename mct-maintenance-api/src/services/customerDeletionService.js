/**
 * Service de suppression complète d'un client et toutes ses données associées
 * Utilisation : deleteCustomerCompletely(customerId, transaction)
 */

const { 
  User, 
  CustomerProfile, 
  Intervention, 
  Order, 
  Quote, 
  Complaint, 
  Contract,
  Notification,
  InterventionImage,
  OrderItem,
  QuoteItem
} = require('../models');

// Import DiagnosticReport model
let DiagnosticReport;
try {
  DiagnosticReport = require('../models/DiagnosticReport');
} catch (e) {
  console.log('⚠️ DiagnosticReport model not available');
}

/**
 * Supprimer un client et TOUTES ses données associées
 * @param {number} customerId - ID du client (User.id ou CustomerProfile.id)
 * @param {Transaction} transaction - Transaction Sequelize (optionnelle)
 * @returns {Promise<Object>} - Résultat de la suppression avec statistiques
 */
const deleteCustomerCompletely = async (customerId, transaction = null) => {
  const shouldCommit = !transaction;
  const t = transaction || await User.sequelize.transaction();
  
  try {
    console.log(`🗑️  Suppression complète du client ID: ${customerId}`);
    
    // Statistiques de suppression
    const stats = {
      customerId,
      deletedItems: {
        user: 0,
        customerProfile: 0,
        interventions: 0,
        interventionImages: 0,
        diagnosticReports: 0,
        orders: 0,
        orderItems: 0,
        quotes: 0,
        quoteItems: 0,
        complaints: 0,
        contracts: 0,
        notifications: 0
      },
      success: false,
      message: ''
    };

    // 1. Trouver le User et CustomerProfile
    // L'ID peut être un User.id ou un CustomerProfile.id
    let user = await User.findByPk(customerId, { transaction: t });
    let customerProfile;
    
    if (!user) {
      // Essayer de trouver par CustomerProfile.id
      customerProfile = await CustomerProfile.findByPk(customerId, { transaction: t });
      if (customerProfile) {
        user = await User.findByPk(customerProfile.user_id, { transaction: t });
      }
    }
    
    if (!user) {
      throw new Error(`Client non trouvé avec l'ID: ${customerId}`);
    }

    // Si on n'a pas encore le profile, le chercher
    if (!customerProfile) {
      customerProfile = await CustomerProfile.findOne({
        where: { user_id: user.id },
        transaction: t
      });
    }

    console.log(`👤 Client trouvé: ${user.email} (${user.first_name} ${user.last_name})`);

    // ID du profil client pour les relations (Intervention, Order)
    const profileId = customerProfile ? customerProfile.id : null;

    // 2. Supprimer les INTERVENTIONS et leurs données liées (rapports, devis, images)
    if (profileId) {
      const interventions = await Intervention.findAll({
        where: { customer_id: profileId },
        transaction: t
      });
      
      if (interventions.length > 0) {
        console.log(`📋 ${interventions.length} intervention(s) trouvée(s)`);
        
        const interventionIds = interventions.map(i => i.id);
        
        // 2a. Supprimer les devis liés aux interventions (par intervention_id)
        const quotesLinkedToInterventions = await Quote.findAll({
          where: { intervention_id: interventionIds },
          transaction: t
        });
        
        if (quotesLinkedToInterventions.length > 0) {
          // D'abord supprimer les items de ces devis
          const quoteIdsToDelete = quotesLinkedToInterventions.map(q => q.id);
          const quoteItemsCount = await QuoteItem.destroy({
            where: { quoteId: quoteIdsToDelete },
            transaction: t
          });
          if (quoteItemsCount > 0) {
            stats.deletedItems.quoteItems += quoteItemsCount;
          }
          
          // Puis supprimer les devis
          const quotesLinkedToInterventionsCount = await Quote.destroy({
            where: { intervention_id: interventionIds },
            transaction: t
          });
          console.log(`📄 ${quotesLinkedToInterventionsCount} devis lié(s) aux interventions supprimé(s)`);
          stats.deletedItems.quotes += quotesLinkedToInterventionsCount;
        }
        
        // 2b. Supprimer les rapports de diagnostic liés aux interventions
        if (DiagnosticReport) {
          const diagnosticReportsCount = await DiagnosticReport.destroy({
            where: { intervention_id: interventionIds },
            transaction: t
          });
          if (diagnosticReportsCount > 0) {
            console.log(`🔍 ${diagnosticReportsCount} rapport(s) de diagnostic supprimé(s)`);
            stats.deletedItems.diagnosticReports = diagnosticReportsCount;
          }
        }
        
        // 2c. Supprimer les images de chaque intervention
        for (const intervention of interventions) {
          const imagesCount = await InterventionImage.destroy({
            where: { intervention_id: intervention.id },
            transaction: t
          });
          stats.deletedItems.interventionImages += imagesCount;
        }
        
        // 2d. Supprimer toutes les interventions
        const interventionsCount = await Intervention.destroy({
          where: { customer_id: profileId },
          transaction: t
        });
        stats.deletedItems.interventions = interventionsCount;
      }
    }

    // 3. Supprimer les COMMANDES et leurs items
    if (profileId) {
      const orders = await Order.findAll({
        where: { customerId: profileId },
        transaction: t
      });
    
      if (orders.length > 0) {
        console.log(`🛒 ${orders.length} commande(s) trouvée(s)`);
        
        for (const order of orders) {
          // Supprimer les items de la commande
          const itemsCount = await OrderItem.destroy({
            where: { order_id: order.id },
            transaction: t
          });
          stats.deletedItems.orderItems += itemsCount;
        }
        
        // Supprimer toutes les commandes
        const ordersCount = await Order.destroy({
          where: { customerId: profileId },
          transaction: t
        });
        stats.deletedItems.orders = ordersCount;
      }
    }

    // 4. Supprimer les DEVIS et leurs items
    if (profileId) {
      const quotes = await Quote.findAll({
        where: { customerId: profileId },
        transaction: t
      });
      
      if (quotes.length > 0) {
        console.log(`📄 ${quotes.length} devis trouvé(s)`);
        
        for (const quote of quotes) {
          // Supprimer les items du devis
          const itemsCount = await QuoteItem.destroy({
            where: { quoteId: quote.id },
            transaction: t
          });
          stats.deletedItems.quoteItems += itemsCount;
        }
        
        // Supprimer tous les devis
        const quotesCount = await Quote.destroy({
          where: { customerId: profileId },
          transaction: t
        });
        stats.deletedItems.quotes = quotesCount;
      }
    }

    // 5. Supprimer les RÉCLAMATIONS
    if (profileId) {
      const complaintsCount = await Complaint.destroy({
        where: { customerId: profileId },
        transaction: t
      });
      stats.deletedItems.complaints = complaintsCount;
      if (complaintsCount > 0) {
        console.log(`📝 ${complaintsCount} réclamation(s) supprimée(s)`);
      }
    }

    // 6. Supprimer les CONTRATS
    if (profileId) {
      const contractsCount = await Contract.destroy({
        where: { customer_id: profileId },
        transaction: t
      });
      stats.deletedItems.contracts = contractsCount;
      if (contractsCount > 0) {
        console.log(`📋 ${contractsCount} contrat(s) supprimé(s)`);
      }
    }

    // 7. Supprimer les NOTIFICATIONS
    const notificationsCount = await Notification.destroy({
      where: { user_id: customerId },
      transaction: t
    });
    stats.deletedItems.notifications = notificationsCount;
    if (notificationsCount > 0) {
      console.log(`🔔 ${notificationsCount} notification(s) supprimée(s)`);
    }

    // 8. Supprimer le CUSTOMER PROFILE
    if (customerProfile) {
      await customerProfile.destroy({ transaction: t });
      stats.deletedItems.customerProfile = 1;
      console.log(`✅ CustomerProfile supprimé`);
    }

    // 9. Supprimer le USER (DERNIÈRE ÉTAPE)
    await user.destroy({ transaction: t });
    stats.deletedItems.user = 1;
    console.log(`✅ User supprimé`);

    // Commit de la transaction si elle a été créée ici
    if (shouldCommit) {
      await t.commit();
    }

    stats.success = true;
    stats.message = `Client ${user.email} supprimé avec succès avec toutes ses données`;

    // Afficher le récapitulatif
    console.log('\n📊 RÉCAPITULATIF DE LA SUPPRESSION:');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`👤 User: ${stats.deletedItems.user}`);
    console.log(`📝 CustomerProfile: ${stats.deletedItems.customerProfile}`);
    console.log(`🔧 Interventions: ${stats.deletedItems.interventions}`);
    console.log(`📸 Images interventions: ${stats.deletedItems.interventionImages}`);
    console.log(`🛒 Commandes: ${stats.deletedItems.orders}`);
    console.log(`📦 Items commandes: ${stats.deletedItems.orderItems}`);
    console.log(`📄 Devis: ${stats.deletedItems.quotes}`);
    console.log(`📋 Items devis: ${stats.deletedItems.quoteItems}`);
    console.log(`💬 Réclamations: ${stats.deletedItems.complaints}`);
    console.log(`📜 Contrats: ${stats.deletedItems.contracts}`);
    console.log(`🔔 Notifications: ${stats.deletedItems.notifications}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    const totalDeleted = Object.values(stats.deletedItems).reduce((sum, val) => sum + val, 0);
    console.log(`✅ TOTAL: ${totalDeleted} élément(s) supprimé(s)\n`);

    return stats;

  } catch (error) {
    // Rollback de la transaction en cas d'erreur
    if (shouldCommit) {
      await t.rollback();
    }
    
    console.error('❌ Erreur lors de la suppression du client:', error);
    throw error;
  }
};

/**
 * Supprimer un client de manière SOFT (désactivation)
 * @param {number} customerId - ID du client
 * @returns {Promise<Object>} - User mis à jour
 */
const softDeleteCustomer = async (customerId) => {
  try {
    const user = await User.findByPk(customerId);
    if (!user) {
      throw new Error(`Client non trouvé avec l'ID: ${customerId}`);
    }

    // Désactiver le compte au lieu de le supprimer
    await user.update({
      status: 'inactive',
      email: `deleted_${Date.now()}_${user.email}`, // Éviter les conflits email
      fcm_token: null // Supprimer le token FCM
    });

    console.log(`✅ Client ${user.email} désactivé (soft delete)`);
    
    return {
      success: true,
      message: 'Client désactivé avec succès',
      user
    };

  } catch (error) {
    console.error('❌ Erreur lors de la désactivation du client:', error);
    throw error;
  }
};

module.exports = {
  deleteCustomerCompletely,
  softDeleteCustomer
};
