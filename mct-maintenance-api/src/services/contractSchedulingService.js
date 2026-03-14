/**
 * Service de planification des contrats de maintenance
 * 
 * Gère les contrats avec visites planifiées :
 * - Contrat 1 an = 4 visites (1 tous les 3 mois)
 * - Première intervention planifiée manuellement ou automatiquement
 * - Les suivantes sont générées automatiquement après chaque intervention terminée
 */

const { Subscription, Intervention, CustomerProfile, User, MaintenanceOffer } = require('../models');
const notificationService = require('./notificationService');
const { Op } = require('sequelize');

class ContractSchedulingService {
  
  /**
   * Créer un contrat de maintenance planifié
   * @param {Object} contractData - Données du contrat
   * @param {number} contractData.customer_id - ID du client (user_id)
   * @param {number} contractData.maintenance_offer_id - ID de l'offre de maintenance
   * @param {number} contractData.equipment_count - Nombre d'équipements
   * @param {Date} contractData.first_intervention_date - Date de la première intervention
   * @param {number} [contractData.visits_total=4] - Nombre total de visites
   * @param {number} [contractData.visit_interval_months=3] - Intervalle entre visites (mois)
   * @param {number} [contractData.duration_months=12] - Durée du contrat (mois)
   * @param {number} contractData.price - Prix total du contrat
   */
  async createScheduledContract(contractData) {
    const {
      customer_id,
      maintenance_offer_id = null,
      equipment_description = null,
      equipment_model = null,
      equipment_count = 1,
      first_intervention_date,
      visits_total = 4,
      visit_interval_months = 3,
      duration_months = 12,
      price = 0,
      split_id = null,
      address = null
    } = contractData;

    console.log(`📋 Création contrat planifié pour client #${customer_id}`);
    console.log(`   - ${visits_total} visites sur ${duration_months} mois`);
    console.log(`   - Intervalle: ${visit_interval_months} mois`);
    console.log(`   - Première intervention: ${first_intervention_date}`);
    console.log(`   - Équipement: ${equipment_description} (${equipment_model})`);

    // Récupérer les infos du client (customer_id peut être CustomerProfile.id ou user_id)
    let customerProfile = await CustomerProfile.findByPk(customer_id, {
      include: [{ model: User, as: 'user' }]
    });
    
    // Si pas trouvé par PK, chercher par user_id
    if (!customerProfile) {
      customerProfile = await CustomerProfile.findOne({
        where: { user_id: customer_id },
        include: [{ model: User, as: 'user' }]
      });
    }

    if (!customerProfile) {
      throw new Error(`CustomerProfile non trouvé pour id/user_id: ${customer_id}`);
    }

    // Subscription.customer_id doit être User.id (pas CustomerProfile.id)
    const userId = customerProfile.user_id;
    console.log(`   - CustomerProfile #${customerProfile.id} -> User #${userId}`);

    // Calculer les dates
    const startDate = new Date(first_intervention_date);
    const endDate = new Date(startDate);
    endDate.setMonth(endDate.getMonth() + duration_months);

    // Créer la souscription en attente de paiement
    const subscription = await Subscription.create({
      customer_id: userId, // Important: User.id, pas CustomerProfile.id
      maintenance_offer_id,
      equipment_description,
      equipment_model,
      split_id,
      equipment_count,
      equipment_used: 0,
      status: 'pending_payment', // En attente de paiement
      contract_type: 'scheduled',
      visits_total,
      visits_completed: 0,
      visit_interval_months,
      first_intervention_date: startDate,
      next_visit_date: startDate,
      start_date: startDate,
      end_date: endDate,
      price,
      payment_status: 'pending'
    });

    console.log(`✅ Souscription #${subscription.id} créée (en attente de paiement)`);

    // Récupérer l'offre de maintenance (optionnel)
    const maintenanceOffer = maintenance_offer_id 
      ? await MaintenanceOffer.findByPk(maintenance_offer_id)
      : null;

    // Ne PAS créer l'intervention maintenant - elle sera créée après le paiement

    // Notifier le client qu'un contrat est en attente de paiement
    const contractTitle = maintenanceOffer?.title || equipment_description || 'Maintenance planifiée';
    console.log(`📤 Envoi notification contract_pending_payment à user ${userId}...`);
    try {
      await notificationService.create({
        userId: userId,
        type: 'contract_created',
        title: 'Nouveau contrat de maintenance',
        message: `Votre contrat "${contractTitle}" est en attente de paiement. Montant: ${price.toLocaleString('fr-FR')} FCFA`,
        data: {
          subscriptionId: String(subscription.id),
          visitsTotal: String(visits_total),
          price: String(price),
          paymentStatus: 'pending'
        },
        priority: 'high',
        actionUrl: '/contracts'
      });
      console.log(`✅ Notification contract_created envoyée à user ${userId}`);
    } catch (notifError) {
      console.error(`⚠️ Erreur envoi notification contract_created:`, notifError.message);
    }

    return {
      subscription,
      firstIntervention: null, // Sera créée après paiement
      customerProfile
    };
  }

  /**
   * Activer un contrat après paiement
   * Crée la première intervention et met à jour le statut
   */
  async activateContractAfterPayment(subscriptionId, paymentReference = null) {
    console.log(`💳 Activation contrat #${subscriptionId} après paiement...`);

    const subscription = await Subscription.findByPk(subscriptionId, {
      include: [{ model: MaintenanceOffer, as: 'offer' }]
    });

    if (!subscription) {
      throw new Error(`Subscription #${subscriptionId} non trouvée`);
    }

    if (subscription.status !== 'pending_payment') {
      console.log(`⚠️ Contrat #${subscriptionId} déjà activé (status: ${subscription.status})`);
      return { subscription, alreadyActive: true };
    }

    // Récupérer le profil client
    const customerProfile = await CustomerProfile.findOne({
      where: { user_id: subscription.customer_id },
      include: [{ model: User, as: 'user' }]
    });

    if (!customerProfile) {
      throw new Error(`CustomerProfile non trouvé pour user_id: ${subscription.customer_id}`);
    }

    // Vérifier si le client a une adresse
    const hasAddress = customerProfile.address && customerProfile.address.trim() !== '';

    // Créer la première intervention maintenant
    const firstIntervention = await this.createScheduledIntervention({
      subscription,
      customerProfile,
      maintenanceOffer: subscription.offer,
      scheduled_date: subscription.first_intervention_date,
      visit_number: 1,
      address: hasAddress ? customerProfile.address : 'Adresse à compléter'
    });

    // Mettre à jour le statut du contrat
    await subscription.update({
      status: 'active',
      payment_status: 'paid',
      payment_reference: paymentReference,
      payment_date: new Date()
    });

    console.log(`✅ Contrat #${subscriptionId} activé, intervention #${firstIntervention.id} créée`);

    // Notifier le client de l'activation
    const contractTitle = subscription.offer?.title || subscription.equipment_description || 'Maintenance planifiée';
    const paymentAmount = subscription.first_payment_amount || Math.ceil(subscription.price / 2);
    
    // 1. D'abord envoyer la notification de paiement confirmé
    try {
      await notificationService.create({
        userId: subscription.customer_id,
        type: 'payment_success',
        title: '✅ Paiement confirmé',
        message: `Votre paiement de ${paymentAmount} FCFA pour le contrat "${contractTitle}" a été confirmé.`,
        data: {
          subscriptionId: String(subscription.id),
          amount: String(paymentAmount),
          paymentType: 'subscription_first_payment',
          reference: paymentReference || ''
        },
        priority: 'high',
        actionUrl: '/contracts'
      });
      console.log(`✅ Notification paiement envoyée pour contrat #${subscriptionId}`);
    } catch (paymentNotifError) {
      console.error(`⚠️ Erreur envoi notification paiement:`, paymentNotifError.message);
    }
    
    // 2. Ensuite envoyer la notification d'activation du contrat
    try {
      await notificationService.create({
        userId: subscription.customer_id,
        type: 'contract_activated',
        title: '🎉 Contrat activé !',
        message: `Votre contrat "${contractTitle}" est maintenant actif. Première visite prévue le ${subscription.first_intervention_date.toLocaleDateString('fr-FR')}.`,
        data: {
          subscriptionId: String(subscription.id),
          interventionId: String(firstIntervention.id)
        },
        priority: 'high',
        actionUrl: '/contracts'
      });
    } catch (notifError) {
      console.error(`⚠️ Erreur envoi notification contract_activated:`, notifError.message);
    }
    
    // 3. Si le client n'a pas d'adresse, lui demander de la mettre à jour
    if (!hasAddress) {
      try {
        await notificationService.create({
          userId: subscription.customer_id,
          type: 'alert',
          title: '📍 Adresse requise',
          message: `Veuillez mettre à jour votre adresse dans votre profil pour que nous puissions planifier votre première visite de maintenance.`,
          data: {
            subscriptionId: String(subscription.id),
            interventionId: String(firstIntervention.id),
            action: 'update_address'
          },
          priority: 'urgent',
          actionUrl: '/profile'
        });
        console.log(`📍 Notification adresse manquante envoyée pour contrat #${subscriptionId}`);
      } catch (addressNotifError) {
        console.error(`⚠️ Erreur envoi notification adresse:`, addressNotifError.message);
      }
    }
    
    // Note: La notification admin est déjà envoyée par fineoPayController.js

    return {
      subscription,
      firstIntervention,
      alreadyActive: false
    };
  }

  /**
   * Créer une intervention planifiée
   */
  async createScheduledIntervention({ subscription, customerProfile, maintenanceOffer, scheduled_date, visit_number, address }) {
    // Construire le titre avec les infos d'équipement
    const equipmentInfo = subscription.equipment_description 
      ? `${subscription.equipment_model || ''} ${subscription.equipment_description}`.trim()
      : '';
    
    let title;
    if (maintenanceOffer) {
      title = `${maintenanceOffer.title} - Visite ${visit_number}/${subscription.visits_total}`;
    } else if (equipmentInfo) {
      title = `Maintenance ${equipmentInfo} - Visite ${visit_number}/${subscription.visits_total}`;
    } else {
      title = `Maintenance planifiée - Visite ${visit_number}/${subscription.visits_total}`;
    }
    
    const description = equipmentInfo
      ? `Intervention de maintenance planifiée (visite ${visit_number} sur ${subscription.visits_total}) - Équipement: ${equipmentInfo}`
      : `Intervention de maintenance planifiée (visite ${visit_number} sur ${subscription.visits_total})`;
    
    const intervention = await Intervention.create({
      customer_id: customerProfile.id,
      subscription_id: subscription.id, // Lien vers la souscription
      maintenance_offer_id: maintenanceOffer?.id || null,
      split_id: subscription.split_id,
      title,
      description,
      intervention_type: 'maintenance',
      priority: 'normal',
      status: 'pending',
      scheduled_date: scheduled_date,
      address: address || customerProfile.address,
      diagnostic_fee: 0, // Inclus dans le contrat
      is_free_diagnosis: true,
      equipment_count: subscription.equipment_count
    });

    return intervention;
  }

  /**
   * Planifier la prochaine intervention après complétion
   * Appelée automatiquement quand une intervention de contrat planifié est terminée
   * @param {number} interventionId - ID de l'intervention terminée
   */
  async scheduleNextVisit(interventionId) {
    console.log(`🔄 Planification prochaine visite après intervention #${interventionId}`);

    // Récupérer l'intervention
    const intervention = await Intervention.findByPk(interventionId, {
      include: [
        { model: CustomerProfile, as: 'customer', include: [{ model: User, as: 'user' }] },
        { model: MaintenanceOffer, as: 'maintenance_offer' }
      ]
    });

    if (!intervention) {
      console.log('⚠️ Intervention non trouvée');
      return null;
    }

    // Chercher la souscription - d'abord par subscription_id direct, sinon par maintenance_offer_id
    let subscription = null;

    if (intervention.subscription_id) {
      console.log(`🔍 Recherche souscription par subscription_id: ${intervention.subscription_id}`);
      subscription = await Subscription.findByPk(intervention.subscription_id);
    }

    if (!subscription && intervention.maintenance_offer_id) {
      console.log(`🔍 Recherche souscription par maintenance_offer_id: ${intervention.maintenance_offer_id}`);
      subscription = await Subscription.findOne({
        where: {
          customer_id: intervention.customer?.user_id || intervention.customer_id,
          maintenance_offer_id: intervention.maintenance_offer_id,
          contract_type: 'scheduled',
          status: 'active'
        }
      });
    }

    if (!subscription) {
      console.log('⚠️ Pas de souscription planifiée trouvée pour cette intervention');
      return null;
    }

    console.log(`✅ Souscription #${subscription.id} trouvée (type: ${subscription.contract_type})`);

    // Vérifier que c'est bien un contrat programmé
    if (subscription.contract_type !== 'scheduled') {
      console.log('⚠️ Ce n\'est pas un contrat programmé, pas de planification suivante');
      return null;
    }

    // Incrémenter le compteur de visites
    const newVisitsCompleted = subscription.visits_completed + 1;
    
    console.log(`📊 Visite ${newVisitsCompleted}/${subscription.visits_total} complétée`);

    // Vérifier si toutes les visites sont effectuées
    if (newVisitsCompleted >= subscription.visits_total) {
      // Dernière visite terminée - vérifier le second paiement
      const secondPaymentPending = subscription.second_payment_status === 'pending' || !subscription.second_payment_status;
      // Calculer le montant du second paiement (50% du prix si non défini)
      const price = parseFloat(subscription.price || 0);
      const secondPaymentAmount = subscription.second_payment_amount || Math.floor(price / 2);
      
      // Si le premier paiement a été fait et le second est encore pending, demander le second paiement
      const firstPaymentDone = subscription.first_payment_status === 'paid';
      
      console.log(`📋 Analyse paiement - first_status: ${subscription.first_payment_status}, second_status: ${subscription.second_payment_status}, price: ${price}, secondAmount: ${secondPaymentAmount}`);
      
      if (secondPaymentPending && price > 0) {
        // Second paiement requis - ne pas marquer comme terminé
        await subscription.update({
          visits_completed: newVisitsCompleted,
          next_visit_date: null,
          status: 'awaiting_second_payment',
          // Initialiser les montants de paiement s'ils ne sont pas définis
          first_payment_amount: subscription.first_payment_amount || Math.ceil(price / 2),
          second_payment_amount: secondPaymentAmount
        });

        console.log('💳 Dernière visite terminée - Second paiement (50%) requis');

        // Notifier le client pour le second paiement
        try {
          await notificationService.create({
            userId: subscription.customer_id,
            type: 'second_payment_required',
            title: 'Paiement final requis',
            message: `Votre dernière visite de maintenance est terminée. Le paiement final de ${secondPaymentAmount.toLocaleString('fr-FR')} FCFA (50%) est maintenant dû.`,
            data: {
              subscriptionId: subscription.id,
              amount: secondPaymentAmount,
              paymentPhase: 2
            },
            priority: 'high',
            actionUrl: '/contracts'
          });
          console.log('✅ Notification de second paiement envoyée');
        } catch (notifError) {
          console.error('⚠️ Erreur notification second paiement:', notifError.message);
        }

        return null;
      }
      
      // Second paiement déjà effectué ou non applicable - Contrat terminé
      await subscription.update({
        visits_completed: newVisitsCompleted,
        next_visit_date: null,
        status: 'completed'
      });

      console.log('✅ Contrat terminé - toutes les visites effectuées et paiement complet');

      // Notifier le client
      await notificationService.create({
        userId: subscription.customer_id,
        type: 'contract_completed',
        title: 'Contrat de maintenance terminé',
        message: `Votre contrat de maintenance est terminé. ${subscription.visits_total} visites ont été effectuées. Pensez à renouveler!`,
        data: {
          subscriptionId: subscription.id
        },
        priority: 'medium'
      });

      return null;
    }

    // Calculer la date de la prochaine visite
    // IMPORTANT: Basé sur scheduled_date de l'intervention précédente, pas completed_at
    // Cela garantit que les visites restent espacées régulièrement (ex: mars, juin, sept, déc)
    // même si plusieurs visites sont complétées le même jour
    const baseDate = intervention.scheduled_date || intervention.completed_at || new Date();
    const nextVisitDate = new Date(baseDate);
    nextVisitDate.setMonth(nextVisitDate.getMonth() + subscription.visit_interval_months);

    // Mettre à jour la souscription
    await subscription.update({
      visits_completed: newVisitsCompleted,
      next_visit_date: nextVisitDate
    });

    // Créer la prochaine intervention
    const nextIntervention = await this.createScheduledIntervention({
      subscription,
      customerProfile: intervention.customer,
      maintenanceOffer: intervention.maintenance_offer,
      scheduled_date: nextVisitDate,
      visit_number: newVisitsCompleted + 1,
      address: intervention.address
    });

    console.log(`✅ Prochaine visite #${nextIntervention.id} planifiée pour le ${nextVisitDate.toLocaleDateString('fr-FR')}`);

    // Notifier le client
    await notificationService.create({
      userId: subscription.customer_id,
      type: 'next_visit_scheduled',
      title: 'Prochaine visite planifiée',
      message: `Votre prochaine visite de maintenance est prévue le ${nextVisitDate.toLocaleDateString('fr-FR')}`,
      data: {
        subscriptionId: subscription.id,
        interventionId: nextIntervention.id,
        visitNumber: newVisitsCompleted + 1,
        visitsTotal: subscription.visits_total,
        scheduledDate: nextVisitDate
      },
      priority: 'low',
      actionUrl: `/interventions?id=${nextIntervention.id}`
    });

    return nextIntervention;
  }

  /**
   * Récupérer les prochaines visites planifiées
   * @param {number} customerId - ID du client (optionnel)
   */
  async getUpcomingVisits(customerId = null) {
    const where = {
      contract_type: 'scheduled',
      status: 'active',
      next_visit_date: {
        [Op.not]: null,
        [Op.gte]: new Date()
      }
    };

    if (customerId) {
      where.customer_id = customerId;
    }

    const subscriptions = await Subscription.findAll({
      where,
      include: [
        { model: User, as: 'customer' },
        { model: MaintenanceOffer, as: 'offer' }
      ],
      order: [['next_visit_date', 'ASC']]
    });

    return subscriptions.map(sub => ({
      subscriptionId: sub.id,
      customerId: sub.customer_id,
      customerName: sub.customer ? `${sub.customer.first_name} ${sub.customer.last_name}` : 'N/A',
      offerTitle: sub.offer?.title || 'N/A',
      nextVisitDate: sub.next_visit_date,
      visitNumber: sub.visits_completed + 1,
      visitsTotal: sub.visits_total,
      visitsRemaining: sub.visits_total - sub.visits_completed
    }));
  }

  /**
   * Récupérer les contrats planifiés d'un client
   */
  async getCustomerScheduledContracts(customerId) {
    const subscriptions = await Subscription.findAll({
      where: {
        customer_id: customerId,
        contract_type: 'scheduled'
      },
      include: [
        { model: MaintenanceOffer, as: 'offer' }
      ],
      order: [['created_at', 'DESC']]
    });

    return subscriptions.map(sub => ({
      id: sub.id,
      offerTitle: sub.offer?.title || 'N/A',
      status: sub.status,
      startDate: sub.start_date,
      endDate: sub.end_date,
      visitsTotal: sub.visits_total,
      visitsCompleted: sub.visits_completed,
      visitsRemaining: sub.visits_total - sub.visits_completed,
      nextVisitDate: sub.next_visit_date,
      visitIntervalMonths: sub.visit_interval_months,
      price: sub.price,
      paymentStatus: sub.payment_status,
      equipmentCount: sub.equipment_count
    }));
  }
}

module.exports = new ContractSchedulingService();
