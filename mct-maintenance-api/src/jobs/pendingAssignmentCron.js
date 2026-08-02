const { Op } = require('sequelize');
const { Intervention } = require('../models');
const schedulingService = require('../services/schedulingService');

/**
 * Tente d'assigner automatiquement les interventions en attente (pending ou execution_confirmed)
 * qui n'ont pas encore de technicien et qui sont prévues dans les 7 prochains jours.
 */
async function processPendingAssignments() {
  try {
    const today = new Date();
    const sevenDaysFromNow = new Date();
    sevenDaysFromNow.setDate(today.getDate() + 7);

    // Recherche des interventions prêtes à être assignées
    const interventionsToAssign = await Intervention.findAll({
      where: {
        technician_id: null,
        scheduled_date: {
          [Op.or]: [
            { [Op.lte]: sevenDaysFromNow },
            { [Op.is]: null } // Prendre aussi celles qui n'ont pas de date spécifique
          ]
        },
        [Op.or]: [
          { status: 'execution_confirmed' }, // Le paiement a été confirmé
          { 
            status: 'pending', 
            // Seulement les interventions gratuites ou abonnements peuvent être assignées au statut pending
            [Op.or]: [
              { is_free_diagnosis: true },
              { diagnostic_fee: 0 },
              { diagnostic_paid: true }, // Inclure les diagnostics payés
              { subscription_id: { [Op.not]: null } } // Abonnements
            ]
          }
        ]
      }
    });

    if (interventionsToAssign.length === 0) {
      console.log('ℹ️ [Cron Assignation] Aucune intervention en attente d\'assignation trouvée.');
      return { success: true, processed: 0, assigned: 0 };
    }

    console.log(`ℹ️ [Cron Assignation] ${interventionsToAssign.length} intervention(s) à tenter d'assigner...`);
    
    let assignedCount = 0;

    for (const intervention of interventionsToAssign) {
      try {
        await schedulingService.autoAssignIntervention(intervention.id);
        console.log(`✅ [Cron Assignation] Assignation réussie pour l'intervention #${intervention.id}`);
        assignedCount++;
      } catch (err) {
        console.log(`⚠️ [Cron Assignation] Assignation échouée pour l'intervention #${intervention.id}: ${err.message}`);
        // On ne spamme pas de notifications client ici, on réessaiera au prochain cron
      }
    }

    return { success: true, processed: interventionsToAssign.length, assigned: assignedCount };

  } catch (error) {
    console.error('❌ [Cron Assignation] Erreur globale:', error);
    return { success: false, error: error.message };
  }
}

module.exports = {
  processPendingAssignments
};
