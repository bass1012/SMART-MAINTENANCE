/**
 * Job CRON pour envoyer des rappels d'expiration de contrats
 * À exécuter quotidiennement (tous les jours à 9h00 par exemple)
 * 
 * Envoie des emails aux clients dont les contrats arrivent à expiration :
 * - 30 jours avant l'expiration
 * - 15 jours avant l'expiration
 * - 7 jours avant l'expiration
 */

const { Contract, User } = require('../models');
const { Op } = require('sequelize');
const { sendContractExpiringEmail } = require('../services/emailHelper');

/**
 * Vérifier et envoyer les rappels d'expiration de contrats
 */
async function checkExpiringContracts() {
  try {
    console.log('🔍 Vérification des contrats arrivant à expiration...');
    
    const today = new Date();
    today.setHours(0, 0, 0, 0); // Début de la journée
    
    // Dates cibles : 30, 15 et 7 jours avant expiration
    const targetDates = [30, 15, 7].map(days => {
      const date = new Date(today);
      date.setDate(date.getDate() + days);
      date.setHours(23, 59, 59, 999); // Fin de la journée
      return date;
    });
    
    console.log('📅 Dates cibles:', targetDates.map(d => d.toLocaleDateString('fr-FR')));
    
    // Chercher les contrats actifs expirant à ces dates
    const expiringContracts = await Contract.findAll({
      where: {
        status: 'active',
        end_date: {
          [Op.in]: targetDates
        }
      },
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'first_name', 'last_name', 'email']
        }
      ]
    });
    
    if (expiringContracts.length === 0) {
      console.log('✅ Aucun contrat arrivant à expiration aujourd\'hui');
      return { success: true, sent: 0 };
    }
    
    console.log(`📧 ${expiringContracts.length} contrat(s) arrivant à expiration trouvé(s)`);
    
    let sentCount = 0;
    let errorCount = 0;
    
    // Envoyer un email pour chaque contrat
    for (const contract of expiringContracts) {
      try {
        if (!contract.customer) {
          console.warn(`⚠️ Contrat ${contract.reference} : pas de client associé`);
          errorCount++;
          continue;
        }
        
        // Calculer le nombre de jours restants
        const daysRemaining = Math.ceil((new Date(contract.end_date) - today) / (1000 * 60 * 60 * 24));
        
        console.log(`📤 Envoi rappel expiration pour contrat ${contract.reference} (${daysRemaining} jours restants) → ${contract.customer.email}`);
        
        const result = await sendContractExpiringEmail(
          contract.get({ plain: true }),
          contract.customer.get({ plain: true })
        );
        
        if (result.success) {
          sentCount++;
          console.log(`✅ Email envoyé : ${contract.reference} → ${contract.customer.email}`);
        } else {
          errorCount++;
          console.error(`❌ Échec envoi email : ${contract.reference}`, result.error);
        }
        
      } catch (emailError) {
        errorCount++;
        console.error(`❌ Erreur envoi email contrat ${contract.reference}:`, emailError.message);
      }
    }
    
    console.log(`✅ Job terminé : ${sentCount} email(s) envoyé(s), ${errorCount} erreur(s)`);
    
    return {
      success: true,
      sent: sentCount,
      errors: errorCount,
      total: expiringContracts.length
    };
    
  } catch (error) {
    console.error('❌ Erreur lors de la vérification des contrats:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * Fonction à exporter pour être appelée par le scheduler
 */
module.exports = {
  checkExpiringContracts,
  
  /**
   * Configurer le job avec node-cron
   * @param {object} cron - Instance de node-cron
   * @returns {object} - Instance du job cron
   */
  setupCronJob: (cron) => {
    // Exécuter tous les jours à 9h00 (fuseau horaire local)
    const job = cron.schedule('0 9 * * *', async () => {
      console.log('⏰ [CRON] Démarrage job: vérification expiration contrats');
      const result = await checkExpiringContracts();
      console.log('⏰ [CRON] Job terminé:', result);
    }, {
      scheduled: true,
      timezone: "Africa/Dakar" // Ajuster selon votre fuseau horaire
    });
    
    console.log('✅ Job CRON configuré : vérification expiration contrats (tous les jours à 9h00)');
    return job;
  }
};
