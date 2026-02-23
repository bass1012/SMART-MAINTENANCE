/**
 * Helper pour l'envoi d'emails transactionnels
 * Simplifie l'envoi en gérant les templates et destinataires automatiquement
 */

const { sendCustomEmail } = require('./emailService');
const {
  interventionCreatedTemplate,
  interventionAssignedTemplate,
  interventionStartedTemplate,
  interventionCompletedTemplate,
  interventionReportTemplate,
  interventionRatingTemplate,
  orderCreatedTemplate,
  orderConfirmedTemplate,
  orderShippedTemplate,
  orderDeliveredTemplate,
  quoteCreatedTemplate,
  quoteAcceptedTemplate,
  quoteRejectedTemplate,
  complaintCreatedTemplate,
  complaintResponseTemplate,
  complaintResolvedTemplate,
  contractSubscribedTemplate,
  contractExpiringTemplate
} = require('./emailTemplates');

/**
 * Configuration des emails administrateurs
 */
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'admin@mct-maintenance.com';

/**
 * Vérifier si les emails sont activés
 */
const isEmailEnabled = () => {
  return process.env.EMAIL_ENABLED !== 'false';
};

/**
 * Envoyer un email avec gestion d'erreur silencieuse
 */
const sendEmailSafely = async (to, subject, html) => {
  if (!isEmailEnabled()) {
    console.log('📧 Email désactivé - destinataire:', to);
    return { success: false, reason: 'disabled' };
  }

  try {
    const result = await sendCustomEmail(to, subject, html);
    return { success: true, ...result };
  } catch (error) {
    console.error(`❌ Erreur email: ${to} -`, error.message);
    return { success: false, error: error.message };
  }
};

// ==================== INTERVENTIONS ====================

/**
 * Email intervention créée (client)
 */
const sendInterventionCreatedEmail = async (intervention, customer) => {
  const template = interventionCreatedTemplate(intervention, customer);
  return sendEmailSafely(customer.email, template.subject, template.html);
};

/**
 * Email intervention assignée (technicien)
 */
const sendInterventionAssignedEmail = async (intervention, technician, customer) => {
  const template = interventionAssignedTemplate(intervention, technician, customer);
  return sendEmailSafely(technician.email, template.subject, template.html);
};

/**
 * Email intervention démarrée (client)
 */
const sendInterventionStartedEmail = async (intervention, technician, customer) => {
  const template = interventionStartedTemplate(intervention, technician, customer);
  return sendEmailSafely(customer.email, template.subject, template.html);
};

/**
 * Email intervention terminée (client)
 */
const sendInterventionCompletedEmail = async (intervention, customer) => {
  const template = interventionCompletedTemplate(intervention, customer);
  return sendEmailSafely(customer.email, template.subject, template.html);
};

/**
 * Email rapport d'intervention soumis (client)
 */
const sendInterventionReportEmail = async (intervention, report, customer) => {
  const template = interventionReportTemplate(intervention, report, customer);
  return sendEmailSafely(customer.email, template.subject, template.html);
};

/**
 * Email évaluation reçue (technicien)
 */
const sendInterventionRatingEmail = async (intervention, rating, technician) => {
  const template = interventionRatingTemplate(intervention, rating, technician);
  return sendEmailSafely(technician.email, template.subject, template.html);
};

// ==================== COMMANDES ====================

/**
 * Email commande créée (client)
 */
const sendOrderCreatedEmail = async (order, customer) => {
  const template = orderCreatedTemplate(order, customer);
  return sendEmailSafely(customer.email, template.subject, template.html);
};

/**
 * Email commande confirmée/en préparation (client)
 */
const sendOrderConfirmedEmail = async (order, customer) => {
  const template = orderConfirmedTemplate(order, customer);
  return sendEmailSafely(customer.email, template.subject, template.html);
};

/**
 * Email commande expédiée (client)
 */
const sendOrderShippedEmail = async (order, customer) => {
  const template = orderShippedTemplate(order, customer);
  return sendEmailSafely(customer.email, template.subject, template.html);
};

/**
 * Email commande livrée (client)
 */
const sendOrderDeliveredEmail = async (order, customer) => {
  const template = orderDeliveredTemplate(order, customer);
  return sendEmailSafely(customer.email, template.subject, template.html);
};

// ==================== DEVIS ====================

/**
 * Email devis créé (client)
 */
const sendQuoteCreatedEmail = async (quote, customer) => {
  const template = quoteCreatedTemplate(quote, customer);
  return sendEmailSafely(customer.email, template.subject, template.html);
};

/**
 * Email devis accepté (admin)
 */
const sendQuoteAcceptedEmail = async (quote, customer) => {
  const template = quoteAcceptedTemplate(quote, customer);
  return sendEmailSafely(ADMIN_EMAIL, template.subject, template.html);
};

/**
 * Email devis rejeté (admin)
 */
const sendQuoteRejectedEmail = async (quote, customer) => {
  const template = quoteRejectedTemplate(quote, customer);
  return sendEmailSafely(ADMIN_EMAIL, template.subject, template.html);
};

// ==================== RÉCLAMATIONS ====================

/**
 * Email réclamation créée (admin)
 */
const sendComplaintCreatedEmail = async (complaint, customer) => {
  const template = complaintCreatedTemplate(complaint, customer);
  return sendEmailSafely(ADMIN_EMAIL, template.subject, template.html);
};

/**
 * Email réponse à la réclamation (client)
 */
const sendComplaintResponseEmail = async (complaint, response, customer) => {
  const template = complaintResponseTemplate(complaint, response, customer);
  return sendEmailSafely(customer.email, template.subject, template.html);
};

/**
 * Email réclamation résolue (client)
 */
const sendComplaintResolvedEmail = async (complaint, customer) => {
  const template = complaintResolvedTemplate(complaint, customer);
  return sendEmailSafely(customer.email, template.subject, template.html);
};

// ==================== CONTRATS ====================

/**
 * Email souscription contrat (client)
 */
const sendContractSubscribedEmail = async (contract, customer) => {
  const template = contractSubscribedTemplate(contract, customer);
  return sendEmailSafely(customer.email, template.subject, template.html);
};

/**
 * Email expiration contrat proche (client)
 */
const sendContractExpiringEmail = async (contract, customer) => {
  const template = contractExpiringTemplate(contract, customer);
  return sendEmailSafely(customer.email, template.subject, template.html);
};

module.exports = {
  // Interventions (6)
  sendInterventionCreatedEmail,
  sendInterventionAssignedEmail,
  sendInterventionStartedEmail,
  sendInterventionCompletedEmail,
  sendInterventionReportEmail,
  sendInterventionRatingEmail,
  
  // Commandes (4)
  sendOrderCreatedEmail,
  sendOrderConfirmedEmail,
  sendOrderShippedEmail,
  sendOrderDeliveredEmail,
  
  // Devis (3)
  sendQuoteCreatedEmail,
  sendQuoteAcceptedEmail,
  sendQuoteRejectedEmail,
  
  // Réclamations (3)
  sendComplaintCreatedEmail,
  sendComplaintResponseEmail,
  sendComplaintResolvedEmail,
  
  // Contrats (2)
  sendContractSubscribedEmail,
  sendContractExpiringEmail,
  
  // Utils
  isEmailEnabled
};
