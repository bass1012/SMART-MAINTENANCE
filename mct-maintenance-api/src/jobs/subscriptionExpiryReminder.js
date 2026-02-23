/**
 * Job de rappel pour les abonnements qui vont expirer
 * Envoie des notifications push aux clients 7 jours et 1 jour avant l'expiration
 */

const { Subscription, CustomerProfile, User, MaintenanceOffer } = require('../models');
const { Op } = require('sequelize');
const notificationService = require('../services/notificationService');

/**
 * Envoyer des rappels pour les abonnements qui vont expirer
 * - 7 jours avant: premier rappel
 * - 1 jour avant: rappel urgent
 */
const sendSubscriptionExpiryReminders = async () => {
  console.log('\n📅 [SubscriptionExpiry] Vérification des abonnements expirants...');

  try {
    const now = new Date();
    const in7Days = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    const in1Day = new Date(now.getTime() + 1 * 24 * 60 * 60 * 1000);
    const in8Days = new Date(now.getTime() + 8 * 24 * 60 * 60 * 1000);
    const in2Days = new Date(now.getTime() + 2 * 24 * 60 * 60 * 1000);

    // Chercher les abonnements qui expirent dans 7 jours (±12h)
    const expiringIn7Days = await Subscription.findAll({
      where: {
        status: 'active',
        end_date: {
          [Op.between]: [in7Days, in8Days]
        }
      },
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'email', 'first_name', 'last_name', 'fcm_token'],
          include: [{
            model: CustomerProfile,
            as: 'customerProfile'
          }]
        },
        {
          model: MaintenanceOffer,
          as: 'offer',
          attributes: ['id', 'title', 'price']
        }
      ]
    });

    // Chercher les abonnements qui expirent dans 1 jour (±12h)
    const expiringIn1Day = await Subscription.findAll({
      where: {
        status: 'active',
        end_date: {
          [Op.between]: [in1Day, in2Days]
        }
      },
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'email', 'first_name', 'last_name', 'fcm_token'],
          include: [{
            model: CustomerProfile,
            as: 'customerProfile'
          }]
        },
        {
          model: MaintenanceOffer,
          as: 'offer',
          attributes: ['id', 'title', 'price']
        }
      ]
    });

    console.log(`📊 [SubscriptionExpiry] ${expiringIn7Days.length} expiration(s) dans 7 jours, ${expiringIn1Day.length} dans 1 jour`);

    let sentCount = 0;
    let errorCount = 0;

    // Rappels 7 jours
    for (const subscription of expiringIn7Days) {
      const user = subscription.customer;
      if (!user) continue;

      try {
        const offerName = subscription.offer?.title || 'abonnement';
        const endDate = new Date(subscription.end_date).toLocaleDateString('fr-FR', {
          day: 'numeric',
          month: 'long',
          year: 'numeric'
        });

        await notificationService.create({
          userId: user.id,
          type: 'subscription_expiring',
          title: '⚠️ Abonnement expire bientôt',
          message: `Votre abonnement "${offerName}" expire le ${endDate}. Pensez à le renouveler pour continuer à bénéficier de nos services !`,
          data: {
            subscription_id: subscription.id,
            offer_name: offerName,
            end_date: subscription.end_date,
            days_remaining: 7
          },
          priority: 'medium'
        });

        sentCount++;
        console.log(`   ✅ Rappel 7j envoyé à ${user.first_name} pour "${offerName}"`);

      } catch (error) {
        errorCount++;
        console.error(`   ❌ Erreur rappel 7j subscription #${subscription.id}:`, error.message);
      }
    }

    // Rappels 1 jour (urgent)
    for (const subscription of expiringIn1Day) {
      const user = subscription.customer;
      if (!user) continue;

      try {
        const offerName = subscription.offer?.title || 'abonnement';

        await notificationService.create({
          userId: user.id,
          type: 'subscription_expiring',
          title: '🚨 Abonnement expire DEMAIN !',
          message: `Votre abonnement "${offerName}" expire demain ! Renouvelez-le maintenant pour éviter toute interruption.`,
          data: {
            subscription_id: subscription.id,
            offer_name: offerName,
            end_date: subscription.end_date,
            days_remaining: 1,
            urgent: true
          },
          priority: 'high'
        });

        sentCount++;
        console.log(`   ✅ Rappel URGENT envoyé à ${user.first_name} pour "${offerName}"`);

      } catch (error) {
        errorCount++;
        console.error(`   ❌ Erreur rappel urgent subscription #${subscription.id}:`, error.message);
      }
    }

    // Notifier les admins si des abonnements expirent
    if (expiringIn1Day.length > 0) {
      await notificationService.notifyAdmins({
        type: 'subscriptions_expiring',
        title: '📅 Abonnements expirants',
        message: `${expiringIn1Day.length} abonnement(s) expire(nt) demain`,
        data: {
          count: expiringIn1Day.length,
          urgent: true
        },
        priority: 'medium',
        actionUrl: '/dashboard'
      });
    }

    return {
      success: true,
      checked7Days: expiringIn7Days.length,
      checked1Day: expiringIn1Day.length,
      sent: sentCount,
      errors: errorCount
    };

  } catch (error) {
    console.error('❌ [SubscriptionExpiry] Erreur:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

module.exports = {
  sendSubscriptionExpiryReminders
};
