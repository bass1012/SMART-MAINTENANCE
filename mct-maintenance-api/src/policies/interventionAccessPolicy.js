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

module.exports = {
  buildInterventionReadWhere,
  InterventionAccessDeniedError
};
