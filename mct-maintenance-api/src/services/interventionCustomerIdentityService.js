const { CustomerProfile } = require('../models');

const INTERNAL_ROLES = new Set(['admin', 'manager']);

class InterventionCustomerIdentityError extends Error {
  constructor(statusCode, code, message) {
    super(message);
    this.name = 'InterventionCustomerIdentityError';
    this.statusCode = statusCode;
    this.code = code;
  }
}

const resolveInterventionCustomerProfile = async ({
  user,
  requestedCustomerId,
  model = CustomerProfile,
  transaction
}) => {
  if (!user) {
    throw new InterventionCustomerIdentityError(401, 'AUTH_REQUIRED', 'Authentification requise');
  }

  let profile;
  if (user.role === 'customer') {
    profile = await model.findOne({
      where: { user_id: user.id },
      transaction
    });
  } else if (INTERNAL_ROLES.has(user.role)) {
    if (!requestedCustomerId) {
      throw new InterventionCustomerIdentityError(
        400,
        'CUSTOMER_PROFILE_REQUIRED',
        'customer_id doit être fourni'
      );
    }
    // Pour les rôles internes, le customer_id fourni doit être un CustomerProfile.id explicite
    profile = await model.findByPk(requestedCustomerId, {
      transaction
    });
  } else {
    throw new InterventionCustomerIdentityError(
      403,
      'CUSTOMER_IDENTITY_FORBIDDEN',
      'Ce rôle ne peut pas créer une intervention client'
    );
  }

  if (!profile) {
    throw new InterventionCustomerIdentityError(
      400,
      'CUSTOMER_PROFILE_NOT_FOUND',
      'Profil client introuvable'
    );
  }
  return profile;
};

module.exports = {
  InterventionCustomerIdentityError,
  resolveInterventionCustomerProfile
};
