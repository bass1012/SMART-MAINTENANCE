const notificationService = require('./notificationService');
const fcmService = require('./fcmService');
const { User } = require('../models');

/**
 * Helpers pour créer des notifications spécifiques
 * Envoient des notifications web (Socket.IO) ET mobiles (FCM)
 */

// Notification: Nouvelle demande d'intervention
const notifyNewIntervention = async (intervention, customer) => {
  return await notificationService.notifyAdmins({
    type: 'intervention_request',
    title: 'Nouvelle demande d\'intervention',
    message: `${customer.first_name} ${customer.last_name} a créé une demande d'intervention`,
    data: {
      interventionId: intervention.id,
      customerId: customer.id,
      customerName: `${customer.first_name} ${customer.last_name}`
    },
    priority: 'high',
    actionUrl: `/interventions` // Redirection vers la liste des interventions
  });
};

// Notification: Intervention assignée au technicien
const notifyInterventionAssigned = async (intervention, technician) => {
  return await notificationService.create({
    userId: technician.id,
    type: 'intervention_assigned',
    title: 'Nouvelle intervention assignée',
    message: `Une intervention vous a été assignée`,
    data: {
      interventionId: intervention.id
    },
    priority: 'high',
    actionUrl: `/interventions` // Liste des interventions
  });
};

// Notification: Technicien assigné à l'intervention (pour le client)
const notifyTechnicianAssignedToCustomer = async (intervention, customer, technician) => {
  return await notificationService.create({
    userId: customer.id,
    type: 'technician_assigned',
    title: 'Technicien assigné',
    message: `${technician.first_name} ${technician.last_name} a été assigné à votre intervention`,
    data: {
      interventionId: intervention.id,
      technicianId: technician.id,
      technicianName: `${technician.first_name} ${technician.last_name}`
    },
    priority: 'high',
    actionUrl: `/interventions` // Liste des interventions
  });
};

// Notification: Intervention terminée
const notifyInterventionCompleted = async (intervention, customer) => {
  return await notificationService.create({
    userId: customer.id,
    type: 'intervention_completed',
    title: 'Intervention terminée',
    message: `Votre intervention a été terminée avec succès`,
    data: {
      interventionId: intervention.id
    },
    priority: 'medium',
    actionUrl: `/interventions` // Liste des interventions
  });
};

// Notification: Intervention modifiée
const notifyInterventionUpdated = async (intervention, customer) => {
  return await notificationService.create({
    userId: customer.id,
    type: 'intervention_updated',
    title: 'Intervention modifiée',
    message: `Votre intervention a été mise à jour`,
    data: {
      interventionId: intervention.id
    },
    priority: 'high',
    actionUrl: `/interventions`
  });
};

// Notification: Nouvelle réclamation
const notifyNewComplaint = async (complaint, customer) => {
  return await notificationService.notifyAdmins({
    type: 'complaint_created',
    title: 'Nouvelle réclamation',
    message: `${customer.first_name} ${customer.last_name} a créé une réclamation`,
    data: {
      complaintId: complaint.id,
      customerId: customer.id,
      customerName: `${customer.first_name} ${customer.last_name}`,
      subject: complaint.subject,
      createdAt: complaint.createdAt || complaint.created_at // Ajout de la date de création
    },
    priority: 'high',
    actionUrl: `/reclamations/${complaint.id}` // Détails de la réclamation
  });
};

// Notification: Réponse à une réclamation
const notifyComplaintResponse = async (complaint, customer) => {
  return await notificationService.create({
    userId: customer.id,
    type: 'complaint_response',
    title: 'Mise à jour de votre réclamation',
    message: `Votre réclamation "${complaint.subject}" a été mise à jour`,
    data: {
      complaintId: complaint.id,
      reference: complaint.reference,
      createdAt: complaint.createdAt || complaint.created_at
    },
    priority: 'high',
    actionUrl: `/reclamations/${complaint.id}` // Détails de la réclamation
  });
};

// Notification: Note ajoutée à une réclamation
const notifyComplaintNoteAdded = async (complaint, customer, note, author) => {
  const authorName = author.role === 'admin' 
    ? 'Un administrateur' 
    : `${author.first_name || ''} ${author.last_name || ''}`.trim() || 'Un technicien';
  
  return await notificationService.create({
    userId: customer.id,
    type: 'complaint_response',
    title: 'Nouveau suivi sur votre réclamation',
    message: `${authorName} a ajouté un suivi à votre réclamation`,
    data: {
      complaintId: complaint.id,
      reference: complaint.reference,
      notePreview: note.substring(0, 100),
      createdAt: complaint.createdAt || complaint.created_at
    },
    priority: 'high',
    actionUrl: `/reclamations/${complaint.id}`
  });
};

// Notification: Changement de statut de réclamation
const notifyComplaintStatusChange = async (complaint, customer, status) => {
  // Messages personnalisés selon le statut
  const statusMessages = {
    open: {
      title: 'Réclamation enregistrée',
      message: 'Votre réclamation a été enregistrée et sera traitée prochainement',
      priority: 'medium'
    },
    in_progress: {
      title: 'Réclamation en cours de traitement',
      message: 'Votre réclamation est en cours de traitement par notre équipe',
      priority: 'high'
    },
    resolved: {
      title: 'Réclamation résolue',
      message: 'Votre réclamation a été résolue. Merci de votre patience !',
      priority: 'high'
    },
    rejected: {
      title: 'Réclamation rejetée',
      message: 'Votre réclamation a été examinée et rejetée. Consultez la résolution pour plus de détails',
      priority: 'high'
    },
    on_hold: {
      title: 'Réclamation en attente',
      message: 'Votre réclamation est temporairement en attente. Nous reviendrons vers vous prochainement',
      priority: 'medium'
    }
  };

  const statusConfig = statusMessages[status] || statusMessages.open;

  return await notificationService.create({
    userId: customer.id,
    type: 'complaint_status_change',
    title: statusConfig.title,
    message: statusConfig.message,
    data: {
      complaintId: complaint.id,
      status: status,
      reference: complaint.reference,
      createdAt: complaint.createdAt || complaint.created_at
    },
    priority: statusConfig.priority,
    actionUrl: `/reclamations/${complaint.id}`
  });
};

// Notification: Nouvelle souscription
const notifyNewSubscription = async (subscription, customer, offer) => {
  // Notifier les admins
  await notificationService.notifyAdmins({
    type: 'subscription_created',
    title: 'Nouvelle souscription',
    message: `${customer.first_name} ${customer.last_name} a souscrit à "${offer.title}"`,
    data: {
      subscriptionId: subscription.id,
      customerId: customer.id,
      customerName: `${customer.first_name} ${customer.last_name}`,
      offerName: offer.title
    },
    priority: 'medium',
    actionUrl: `/dashboard` // Pas de page subscriptions
  });

  // Confirmer au client
  return await notificationService.create({
    userId: customer.id,
    type: 'subscription_created',
    title: 'Paiement confirmé',
    message: `Votre paiement pour "${offer.title}" a été confirmé. Votre souscription est maintenant active !`,
    data: {
      subscriptionId: subscription.id,
      offerName: offer.title
    },
    priority: 'high',
    actionUrl: `/dashboard` // Pas de page subscriptions
  });
};

// Notification: Souscription bientôt expirée
const notifySubscriptionExpiring = async (subscription, customer, offer) => {
  return await notificationService.create({
    userId: customer.id,
    type: 'subscription_expiring',
    title: 'Souscription bientôt expirée',
    message: `Votre souscription "${offer.title}" expire bientôt`,
    data: {
      subscriptionId: subscription.id,
      offerName: offer.title,
      endDate: subscription.end_date
    },
    priority: 'high',
    actionUrl: `/dashboard`
  });
};

// Notification: Nouvelle commande
const notifyNewOrder = async (order, customer) => {
  // Notifier les admins
  await notificationService.notifyAdmins({
    type: 'order_created',
    title: 'Nouvelle commande',
    message: `${customer.first_name || customer.firstName} ${customer.last_name || customer.lastName} a passé une commande de ${order.totalAmount || order.total_amount} FCFA`,
    data: {
      orderId: order.id,
      customerId: customer.id,
      customerName: `${customer.first_name || customer.firstName} ${customer.last_name || customer.lastName}`,
      amount: order.totalAmount || order.total_amount
    },
    priority: 'high',
    actionUrl: `/commandes/${order.id}` // Détails de la commande
  });

  // Confirmer au client
  return await notificationService.create({
    userId: customer.id,
    type: 'order_created',
    title: 'Commande confirmée',
    message: `Votre commande #${order.reference} a été enregistrée avec succès`,
    data: {
      orderId: order.id,
      reference: order.reference,
      amount: order.totalAmount || order.total_amount
    },
    priority: 'medium',
    actionUrl: `/commandes/${order.id}` // Détails de la commande
  });
};

// Notification: Changement de statut de commande
const notifyOrderStatusUpdate = async (order, customer, newStatus) => {
  const statusMessages = {
    'pending': 'en attente',
    'processing': 'en cours de traitement',
    'shipped': 'expédiée',
    'delivered': 'livrée',
    'cancelled': 'annulée'
  };

  return await notificationService.create({
    userId: customer.id,
    type: 'order_status_update',
    title: 'Mise à jour de commande',
    message: `Votre commande #${order.reference} est ${statusMessages[newStatus] || newStatus}`,
    data: {
      orderId: order.id,
      reference: order.reference,
      status: newStatus
    },
    priority: 'medium',
    actionUrl: `/commandes/${order.id}` // Détails de la commande
  });
};

// Notification: Nouveau devis créé
const notifyNewQuote = async (quote, customer) => {
  // customer peut être CustomerProfile ou User
  const userId = customer.user_id || customer.id;
  
  return await notificationService.create({
    userId: userId,
    type: 'quote_created',
    title: 'Nouveau devis disponible',
    message: `Un devis de ${quote.total} FCFA a été créé pour vous`,
    data: {
      quoteId: quote.id,
      amount: quote.total
    },
    priority: 'high',
    actionUrl: `/devis/${quote.id}`
  });
};

// Notification: Devis accepté
const notifyQuoteAccepted = async (quote, customer) => {
  const userId = customer.user_id || customer.id;
  const customerName = `${customer.first_name || ''} ${customer.last_name || ''}`.trim();
  
  return await notificationService.notifyAdmins({
    type: 'quote_accepted',
    title: 'Devis accepté',
    message: `${customerName} a accepté un devis de ${quote.total} FCFA`,
    data: {
      quoteId: quote.id,
      customerId: userId,
      customerName: customerName,
      amount: quote.total
    },
    priority: 'high',
    actionUrl: `/devis/${quote.id}`
  });
};

// Notification: Devis rejeté
const notifyQuoteRejected = async (quote, customer) => {
  const userId = customer.user_id || customer.id;
  const customerName = `${customer.first_name || ''} ${customer.last_name || ''}`.trim();
  
  return await notificationService.notifyAdmins({
    type: 'quote_rejected',
    title: 'Devis rejeté',
    message: `${customerName} a rejeté un devis`,
    data: {
      quoteId: quote.id,
      customerId: userId,
      customerName: customerName
    },
    priority: 'medium',
    actionUrl: `/devis/${quote.id}`
  });
};

// Notification: Devis envoyé au client
const notifyQuoteSent = async (quote, customer) => {
  // customer peut être CustomerProfile ou User
  const userId = customer.user_id || customer.id;
  
  return await notificationService.create({
    userId: userId,
    type: 'quote_sent',
    title: 'Nouveau devis reçu',
    message: `Vous avez reçu un devis de ${quote.total} FCFA. Consultez-le et répondez avant expiration.`,
    data: {
      quoteId: quote.id,
      reference: quote.reference,
      amount: quote.total,
      expiryDate: quote.expiryDate
    },
    priority: 'high',
    actionUrl: `/devis/${quote.id}`
  });
};

// Notification: Devis modifié
const notifyQuoteUpdated = async (quote, customer) => {
  // customer peut être CustomerProfile ou User
  const userId = customer.user_id || customer.id;
  
  return await notificationService.create({
    userId: userId,
    type: 'quote_updated',
    title: 'Devis modifié',
    message: `Votre devis de ${quote.total} FCFA a été mis à jour`,
    data: {
      quoteId: quote.id,
      amount: quote.total
    },
    priority: 'high',
    actionUrl: `/devis/${quote.id}`
  });
};

// Notification: Nouveau contrat
const notifyNewContract = async (contract, customer) => {
  return await notificationService.create({
    userId: customer.id,
    type: 'contract_created',
    title: 'Nouveau contrat de maintenance',
    message: `Un contrat de maintenance a été créé pour vous`,
    data: {
      contractId: contract.id
    },
    priority: 'high',
    actionUrl: `/contrats`
  });
};

// Notification: Contrat bientôt expiré
const notifyContractExpiring = async (contract, customer) => {
  return await notificationService.create({
    userId: customer.id,
    type: 'contract_expiring',
    title: 'Contrat bientôt expiré',
    message: `Votre contrat de maintenance expire bientôt`,
    data: {
      contractId: contract.id,
      endDate: contract.end_date
    },
    priority: 'medium',
    actionUrl: `/contrats`
  });
};

// Notification: Paiement reçu
const notifyPaymentReceived = async (payment, customer) => {
  return await notificationService.create({
    userId: customer.id,
    type: 'payment_received',
    title: 'Paiement confirmé',
    message: `Votre paiement de ${payment.amount} FCFA a été reçu`,
    data: {
      paymentId: payment.id,
      amount: payment.amount
    },
    priority: 'medium',
    actionUrl: `/commandes`
  });
};

// Notification: Rapport d'intervention soumis
const notifyReportSubmitted = async (report, customer) => {
  return await notificationService.create({
    userId: customer.id,
    type: 'report_submitted',
    title: 'Rapport d\'intervention disponible',
    message: `Le rapport de votre intervention est disponible`,
    data: {
      reportId: report.id,
      interventionId: report.intervention_id
    },
    priority: 'medium',
    actionUrl: `/rapports-interventions`
  });
};

// Notification: Intervention annulée
const notifyInterventionCancelled = async (intervention, customer, technician = null, cancelledBy = 'customer') => {
  const notifications = [];
  
  // Notifier le client si annulé par admin/technicien
  if (cancelledBy !== 'customer' && customer) {
    notifications.push(
      notificationService.create({
        userId: customer.user_id || customer.id,
        type: 'intervention_cancelled',
        title: 'Intervention annulée',
        message: `Votre intervention #${intervention.id} a été annulée`,
        data: {
          interventionId: intervention.id,
          cancelledBy
        },
        priority: 'high',
        actionUrl: `/interventions`
      })
    );
  }
  
  // Notifier le technicien si assigné
  if (technician && cancelledBy !== 'technician') {
    const customerName = customer ? 
      `${customer.first_name || ''} ${customer.last_name || ''}`.trim() : 'Le client';
    notifications.push(
      notificationService.create({
        userId: technician.id,
        type: 'intervention_cancelled',
        title: 'Intervention annulée',
        message: `${customerName} a annulé l'intervention #${intervention.id}`,
        data: {
          interventionId: intervention.id,
          cancelledBy
        },
        priority: 'high',
        actionUrl: `/interventions`
      })
    );
  }
  
  // Notifier les admins
  const customerName = customer ? 
    `${customer.first_name || ''} ${customer.last_name || ''}`.trim() : 'Un client';
  notifications.push(
    notificationService.notifyAdmins({
      type: 'intervention_cancelled',
      title: 'Intervention annulée',
      message: `L'intervention #${intervention.id} de ${customerName} a été annulée`,
      data: {
        interventionId: intervention.id,
        cancelledBy
      },
      priority: 'medium',
      actionUrl: `/interventions`
    })
  );
  
  return Promise.all(notifications);
};

// Notification: Intervention reprogrammée
const notifyInterventionRescheduled = async (intervention, customer, technician, newDate) => {
  const notifications = [];
  const formattedDate = new Date(newDate).toLocaleDateString('fr-FR', {
    weekday: 'long', day: 'numeric', month: 'long', hour: '2-digit', minute: '2-digit'
  });
  
  // Notifier le client
  if (customer) {
    notifications.push(
      notificationService.create({
        userId: customer.user_id || customer.id,
        type: 'intervention_rescheduled',
        title: 'Date modifiée',
        message: `Votre intervention a été reprogrammée au ${formattedDate}`,
        data: {
          interventionId: intervention.id,
          newDate
        },
        priority: 'high',
        actionUrl: `/interventions`
      })
    );
  }
  
  // Notifier le technicien
  if (technician) {
    notifications.push(
      notificationService.create({
        userId: technician.id,
        type: 'intervention_rescheduled',
        title: 'Intervention reprogrammée',
        message: `L'intervention #${intervention.id} a été déplacée au ${formattedDate}`,
        data: {
          interventionId: intervention.id,
          newDate
        },
        priority: 'high',
        actionUrl: `/interventions`
      })
    );
  }
  
  return Promise.all(notifications);
};

// Notification: Technicien en route
const notifyTechnicianOnTheWay = async (intervention, customer, technician) => {
  if (!customer) return null;
  
  const techName = technician ? 
    `${technician.first_name || ''} ${technician.last_name || ''}`.trim() : 'Le technicien';
  
  return notificationService.create({
    userId: customer.user_id || customer.id,
    type: 'technician_on_the_way',
    title: '🚗 Technicien en route',
    message: `${techName} est en route vers votre adresse`,
    data: {
      interventionId: intervention.id,
      technicianId: technician?.id
    },
    priority: 'high',
    actionUrl: `/interventions`
  });
};

// Notification: Technicien arrivé
const notifyTechnicianArrived = async (intervention, customer, technician) => {
  if (!customer) return null;
  
  const techName = technician ? 
    `${technician.first_name || ''} ${technician.last_name || ''}`.trim() : 'Le technicien';
  
  return notificationService.create({
    userId: customer.user_id || customer.id,
    type: 'technician_arrived',
    title: '📍 Technicien arrivé',
    message: `${techName} est arrivé sur les lieux`,
    data: {
      interventionId: intervention.id,
      technicianId: technician?.id
    },
    priority: 'high',
    actionUrl: `/interventions`
  });
};

// Notification: Intervention en cours
const notifyInterventionInProgress = async (intervention, customer, technician) => {
  if (!customer) return null;
  
  const techName = technician ? 
    `${technician.first_name || ''} ${technician.last_name || ''}`.trim() : 'Le technicien';
  
  return notificationService.create({
    userId: customer.user_id || customer.id,
    type: 'intervention_in_progress',
    title: '🔧 Intervention en cours',
    message: `${techName} a démarré l'intervention`,
    data: {
      interventionId: intervention.id,
      technicianId: technician?.id
    },
    priority: 'high',
    actionUrl: `/interventions`
  });
};

// Notification: Paiement reçu (pour admins)
const notifyPaymentReceivedToAdmin = async (payment, customer, paymentType = 'order') => {
  const customerName = customer ? 
    `${customer.first_name || ''} ${customer.last_name || ''}`.trim() : 'Un client';
  
  const typeLabels = {
    'order': 'commande',
    'diagnostic': 'diagnostic',
    'subscription': 'abonnement',
    'quote': 'devis'
  };
  
  return notificationService.notifyAdmins({
    type: 'payment_received',
    title: '💰 Paiement reçu',
    message: `Paiement de ${payment.amount} FCFA reçu de ${customerName} (${typeLabels[paymentType] || paymentType})`,
    data: {
      paymentId: payment.id,
      amount: payment.amount,
      paymentType,
      customerId: customer?.id
    },
    priority: 'medium',
    actionUrl: `/dashboard`
  });
};

module.exports = {
  notifyNewIntervention,
  notifyInterventionAssigned,
  notifyTechnicianAssignedToCustomer,
  notifyInterventionCompleted,
  notifyInterventionUpdated,
  notifyInterventionCancelled,
  notifyInterventionRescheduled,
  notifyTechnicianOnTheWay,
  notifyTechnicianArrived,
  notifyInterventionInProgress,
  notifyNewComplaint,
  notifyComplaintResponse,
  notifyComplaintStatusChange,
  notifyComplaintNoteAdded,
  notifyNewSubscription,
  notifySubscriptionExpiring,
  notifyNewOrder,
  notifyOrderStatusUpdate,
  notifyNewQuote,
  notifyQuoteSent,
  notifyQuoteAccepted,
  notifyQuoteRejected,
  notifyQuoteUpdated,
  notifyNewContract,
  notifyContractExpiring,
  notifyPaymentReceived,
  notifyPaymentReceivedToAdmin,
  notifyReportSubmitted
};
