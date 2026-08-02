'use strict';

/**
 * Etats valides d'une intervention
 */
const INTERVENTION_STATES = Object.freeze({
  PENDING: 'pending',
  ASSIGNED: 'assigned',
  ACCEPTED: 'accepted',
  ON_THE_WAY: 'on_the_way',
  ARRIVED: 'arrived',
  IN_PROGRESS: 'in_progress',
  COMPLETED: 'completed',
  CANCELLED: 'cancelled'
});

/**
 * Matrice des transitions d'état autorisées
 */
const ALLOWED_TRANSITIONS = Object.freeze({
  [INTERVENTION_STATES.PENDING]: [INTERVENTION_STATES.ASSIGNED, INTERVENTION_STATES.CANCELLED],
  [INTERVENTION_STATES.ASSIGNED]: [INTERVENTION_STATES.ACCEPTED, INTERVENTION_STATES.ASSIGNED, INTERVENTION_STATES.CANCELLED],
  [INTERVENTION_STATES.ACCEPTED]: [INTERVENTION_STATES.ON_THE_WAY, INTERVENTION_STATES.CANCELLED],
  [INTERVENTION_STATES.ON_THE_WAY]: [INTERVENTION_STATES.ARRIVED, INTERVENTION_STATES.CANCELLED],
  [INTERVENTION_STATES.ARRIVED]: [INTERVENTION_STATES.IN_PROGRESS, INTERVENTION_STATES.CANCELLED],
  [INTERVENTION_STATES.IN_PROGRESS]: [INTERVENTION_STATES.COMPLETED, INTERVENTION_STATES.CANCELLED],
  [INTERVENTION_STATES.COMPLETED]: [],
  [INTERVENTION_STATES.CANCELLED]: []
});

class InterventionStateTransitionError extends Error {
  constructor(statusCode, code, message) {
    super(message);
    this.name = 'InterventionStateTransitionError';
    this.statusCode = statusCode;
    this.code = code;
  }
}

/**
 * Vérifie si une transition d'état directe est théoriquement autorisée
 */
const canTransition = (currentStatus, targetStatus) => {
  if (!currentStatus || !targetStatus) return false;
  if (currentStatus === targetStatus) return true;
  const allowed = ALLOWED_TRANSITIONS[currentStatus];
  return Array.isArray(allowed) && allowed.includes(targetStatus);
};

/**
 * Valide les préconditions métier pour effectuer une transition d'état
 */
const validateTransition = (intervention, targetStatus, context = {}) => {
  if (!intervention) {
    throw new InterventionStateTransitionError(404, 'INTERVENTION_NOT_FOUND', 'Intervention non trouvée');
  }

  const currentStatus = intervention.status || INTERVENTION_STATES.PENDING;

  if (currentStatus === targetStatus) {
    return true;
  }

  if (!canTransition(currentStatus, targetStatus)) {
    throw new InterventionStateTransitionError(
      400,
      'INVALID_STATUS_TRANSITION',
      `Impossible de passer l'intervention du statut '${currentStatus}' au statut '${targetStatus}'`
    );
  }

  // Vérification des préconditions spécifiques selon le statut cible
  switch (targetStatus) {
    case INTERVENTION_STATES.ASSIGNED:
      if (!context.technician_id && !intervention.technician_id) {
        throw new InterventionStateTransitionError(
          400,
          'TECHNICIAN_REQUIRED',
          'Un technicien doit être assigné pour passer au statut assigned'
        );
      }
      break;

    case INTERVENTION_STATES.ACCEPTED:
      if (!intervention.technician_id && !context.technician_id) {
        throw new InterventionStateTransitionError(
          400,
          'ASSIGNED_TECHNICIAN_REQUIRED',
          'L’intervention doit être assignée à un technicien avant d’être acceptée'
        );
      }
      break;

    case INTERVENTION_STATES.ON_THE_WAY:
    case INTERVENTION_STATES.ARRIVED:
    case INTERVENTION_STATES.IN_PROGRESS:
      if (context.user_id && intervention.technician_id && Number(context.user_id) !== Number(intervention.technician_id)) {
        throw new InterventionStateTransitionError(
          403,
          'TECHNICIAN_MISMATCH',
          'Seul le technicien assigné peut faire évoluer cette étape de l’intervention'
        );
      }
      break;

    case INTERVENTION_STATES.COMPLETED:
      if (currentStatus !== INTERVENTION_STATES.IN_PROGRESS && currentStatus !== INTERVENTION_STATES.ARRIVED) {
        throw new InterventionStateTransitionError(
          400,
          'IN_PROGRESS_REQUIRED_BEFORE_COMPLETION',
          'L’intervention doit être en cours avant de pouvoir être terminée'
        );
      }
      break;

    case INTERVENTION_STATES.CANCELLED:
      if (currentStatus === INTERVENTION_STATES.COMPLETED) {
        throw new InterventionStateTransitionError(
          400,
          'CANNOT_CANCEL_COMPLETED_INTERVENTION',
          'Une intervention déjà terminée ne peut pas être annulée'
        );
      }
      break;
  }

  return true;
};

module.exports = {
  INTERVENTION_STATES,
  ALLOWED_TRANSITIONS,
  InterventionStateTransitionError,
  canTransition,
  validateTransition
};
