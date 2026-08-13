const { CustomerProfile } = require('../models');

const INTERNAL_ROLES = new Set(['admin', 'manager']);

class InterventionAccessDeniedError extends Error {
  constructor() {
    super('Accès refusé à cette intervention');
    this.name = 'InterventionAccessDeniedError';
    this.statusCode = 403;
  }
}

/**
 * Construit le filtre Sequelize qui limite la lecture d'une intervention
 * au périmètre de l'utilisateur authentifié.
 *
 * Intervention.customer_id référence exclusivement CustomerProfile.id.
 */
const buildInterventionReadWhere = async ({ interventionId, user }) => {
  if (!user) {
    throw new InterventionAccessDeniedError();
  }

  const where = { id: interventionId };

  if (INTERNAL_ROLES.has(user.role)) {
    return where;
  }

  if (user.role === 'technician') {
    return {
      ...where,
      technician_id: user.id
    };
  }

  if (user.role === 'customer') {
    const customerProfile = await CustomerProfile.findOne({
      where: { user_id: user.id },
      attributes: ['id']
    });
    return {
      ...where,
      customer_id: customerProfile?.id ?? -1
    };
  }

  throw new InterventionAccessDeniedError();
};

/**
 * Construit le filtre Sequelize pour la liste des interventions
 * selon le rôle de l'utilisateur authentifié.
 *
 * - admin / manager : aucun filtre (voient tout)
 * - technician     : uniquement leurs interventions (technician_id)
 * - customer       : uniquement leurs interventions (customer_id = CustomerProfile.id)
 */
const buildInterventionListWhere = async ({ user } = {}) => {
  if (!user) {
    throw new InterventionAccessDeniedError();
  }

  if (INTERNAL_ROLES.has(user.role)) {
    return {};
  }

  if (user.role === 'technician') {
    return { technician_id: user.id };
  }

  if (user.role === 'customer') {
    const customerProfile = await CustomerProfile.findOne({
      where: { user_id: user.id },
      attributes: ['id']
    });
    return { customer_id: customerProfile?.id ?? -1 };
  }

  throw new InterventionAccessDeniedError();
};

module.exports = {
  buildInterventionReadWhere,
  buildInterventionListWhere,
  InterventionAccessDeniedError
};
