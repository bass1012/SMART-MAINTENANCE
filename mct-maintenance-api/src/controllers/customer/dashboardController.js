const { 
  Intervention, 
  Quote, 
  Order, 
  Complaint, 
  Contract,
  CustomerProfile 
} = require('../../models');
const { Op } = require('sequelize');

/**
 * Récupérer les statistiques du tableau de bord client
 */
exports.getDashboardStats = async (req, res, next) => {
  try {
    const userId = req.user.id;
    
    console.log(`📊 Récupération des statistiques pour user_id: ${userId}`);
    
    // Récupérer le profil client
    const customerProfile = await CustomerProfile.findOne({ 
      where: { user_id: userId } 
    });
    
    if (!customerProfile) {
      return res.status(404).json({
        success: false,
        message: 'Profil client non trouvé',
      });
    }
    
    const customerId = customerProfile.id;
    console.log(`✅ Customer profile ID: ${customerId}`);
    
    // Compter les interventions
    const totalInterventions = await Intervention.count({
      where: { customer_id: customerId }
    });
    
    const pendingInterventions = await Intervention.count({
      where: { 
        customer_id: customerId,
        status: 'pending'
      }
    });
    
    const completedInterventions = await Intervention.count({
      where: { 
        customer_id: customerId,
        status: 'completed'
      }
    });
    
    // Compter les devis
    const totalQuotes = await Quote.count({
      where: { customerId: customerId }
    });
    
    const pendingQuotes = await Quote.count({
      where: { 
        customerId: customerId,
        status: 'pending'
      }
    });
    
    const acceptedQuotes = await Quote.count({
      where: { 
        customerId: customerId,
        status: 'accepted'
      }
    });
    
    // Compter les commandes
    const totalOrders = await Order.count({
      where: { customerId: customerId }
    });
    
    // Calculer le total dépensé (commandes payées)
    const ordersSum = await Order.sum('totalAmount', {
      where: { 
        customerId: customerId,
        status: 'paid'
      }
    });
    const totalSpent = ordersSum || 0;
    
    // Compter les réclamations
    const totalComplaints = await Complaint.count({
      where: { customerId: customerId }
    });
    
    const pendingComplaints = await Complaint.count({
      where: { 
        customerId: customerId,
        status: 'open'
      }
    });
    
    // Compter les contrats
    const totalContracts = await Contract.count({
      where: { customer_id: customerId }
    });
    
    const activeContracts = await Contract.count({
      where: { 
        customer_id: customerId,
        status: 'active'
      }
    });
    
    // Compter les maintenances à venir (dans les 30 prochains jours)
    // Note: La colonne next_maintenance_date n'existe pas encore dans le modèle Contract
    // TODO: Ajouter cette colonne au modèle si nécessaire
    const upcomingMaintenances = 0;
    
    const stats = {
      totalInterventions,
      pendingInterventions,
      completedInterventions,
      totalQuotes,
      pendingQuotes,
      acceptedQuotes,
      totalOrders,
      totalComplaints,
      pendingComplaints,
      totalContracts,
      activeContracts,
      totalSpent: parseFloat(totalSpent.toFixed(2)),
      upcomingMaintenances,
    };
    
    console.log('📊 Statistiques calculées:', stats);
    
    res.json({
      success: true,
      data: stats,
      message: 'Statistiques récupérées avec succès',
    });
  } catch (error) {
    console.error('❌ Error getting dashboard stats:', error);
    next(error);
  }
};
