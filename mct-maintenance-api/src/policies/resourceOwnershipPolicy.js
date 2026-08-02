const { CustomerProfile, Intervention } = require('../models');

const INTERNAL_ROLES = new Set(['admin', 'manager']);

const isInternalUser = (user) => Boolean(user && INTERNAL_ROLES.has(user.role));

const canReadQuote = async ({ quote, user, models = { CustomerProfile, Intervention } }) => {
  if (!quote || !user) return false;
  if (isInternalUser(user)) return true;

  if (user.role === 'customer') {
    const profile = await models.CustomerProfile.findOne({
      where: { user_id: user.id },
      attributes: ['id']
    });
    return Boolean(profile && Number(quote.customerId) === Number(profile.id));
  }

  if (user.role === 'technician') {
    if (quote.intervention_id) {
      const intervention = await models.Intervention.findOne({
        where: { id: quote.intervention_id, technician_id: user.id },
        attributes: ['id']
      });
      if (intervention) return true;
    }
    if (quote.diagnostic_report_id) {
      const DiagnosticReport = models.DiagnosticReport || require('../models').DiagnosticReport;
      const report = await DiagnosticReport.findOne({
        where: { id: quote.diagnostic_report_id, technician_id: user.id },
        attributes: ['id']
      });
      if (report) return true;
    }
    if (quote.intervention && Number(quote.intervention.technician_id) === Number(user.id)) {
      return true;
    }
  }

  return false;
};

const canReadOrder = async ({ order, user, models = { CustomerProfile } }) => {
  if (!order || !user) return false;
  if (isInternalUser(user)) return true;
  if (user.role !== 'customer') return false;

  const profile = await models.CustomerProfile.findOne({
    where: { user_id: user.id },
    attributes: ['id']
  });
  const orderCustomerId = order.customerId ?? order.customer_id;
  return Boolean(profile && Number(orderCustomerId) === Number(profile.id));
};

const canReadUserOwnedResource = ({ resource, user, ownerField = 'customer_id' }) => {
  if (!resource || !user) return false;
  if (isInternalUser(user)) return true;
  return user.role === 'customer' && Number(resource[ownerField]) === Number(user.id);
};

module.exports = {
  isInternalUser,
  canReadQuote,
  canReadOrder,
  canReadUserOwnedResource
};
