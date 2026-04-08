/**
 * Job de rappel pour les paiements de diagnostic en attente
 * Envoie des notifications push aux clients qui n'ont pas finalisé le paiement
 */

const { Intervention, CustomerProfile, User, Notification } = require('../models');
const { Op } = require('sequelize');
const notificationService = require('../services/notificationService');

/**
 * Vérifier et envoyer des rappels pour les paiements de diagnostic en attente
 * Cible: interventions de type diagnostic/repair créées il y a plus de 1 heure
 * et où le diagnostic n'a pas été payé
 */
const sendPendingDiagnosticReminders = async () => {
  console.log('\n💳 [DiagnosticReminder] Vérification des paiements en attente...');

  try {
    // Chercher les interventions avec diagnostic non payé
    // créées il y a plus de 1 heure mais moins de 7 jours
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

    const pendingInterventions = await Intervention.findAll({
      where: {
        is_free_diagnosis: false,
        diagnostic_paid: false,
        status: { [Op.notIn]: ['cancelled', 'completed'] },
        created_at: {
          [Op.between]: [sevenDaysAgo, oneHourAgo]
        }
      },
      include: [
        {
          model: CustomerProfile,
          as: 'customer',
          include: [{
            model: User,
            as: 'user',
            attributes: ['id', 'email', 'first_name', 'last_name', 'phone', 'fcm_token']
          }]
        }
      ]
    });

    console.log(`📊 [DiagnosticReminder] ${pendingInterventions.length} intervention(s) avec paiement en attente`);

    let sentCount = 0;
    let errorCount = 0;

    for (const intervention of pendingInterventions) {
      const user = intervention.customer?.user;
      if (!user) continue;

      try {
        // Vérifier si on a déjà envoyé une notification aujourd'hui pour cette intervention
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const existingNotification = await Notification.findOne({
          where: {
            user_id: user.id,
            type: 'diagnostic_payment_reminder',
            created_at: { [Op.gte]: today },
            data: {
              [Op.or]: [
                { intervention_id: intervention.id },
                { intervention_id: String(intervention.id) }
              ]
            }
          }
        });

        if (existingNotification) {
          console.log(`   ⏭️  Notification déjà envoyée aujourd'hui pour intervention #${intervention.id}, ignoré`);
          continue;
        }

        // Créer la notification de rappel
        await notificationService.create({
          userId: user.id,
          type: 'diagnostic_payment_reminder',
          title: '💳 Paiement en attente',
          message: `Vous n'avez pas finalisé le paiement du diagnostic pour votre intervention #${intervention.id}. Complétez le paiement pour activer votre demande.`,
          data: {
            intervention_id: intervention.id,
            diagnostic_fee: intervention.diagnostic_fee,
            type: 'pending_payment_reminder'
          },
          priority: 'high'
        });

        sentCount++;
        console.log(`   ✅ Rappel envoyé à ${user.first_name} ${user.last_name} pour intervention #${intervention.id}`);

      } catch (error) {
        errorCount++;
        console.error(`   ❌ Erreur pour intervention #${intervention.id}:`, error.message);
      }
    }

    return {
      success: true,
      checked: pendingInterventions.length,
      sent: sentCount,
      errors: errorCount
    };

  } catch (error) {
    console.error('❌ [DiagnosticReminder] Erreur:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

module.exports = {
  sendPendingDiagnosticReminders
};
