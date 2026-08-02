const {
  INTERVENTION_STATES,
  canTransition,
  validateTransition,
  InterventionStateTransitionError
} = require('../../../src/services/interventionStateMachineService');

describe('InterventionStateMachineService', () => {
  describe('canTransition', () => {
    it('devrait autoriser les transitions valides', () => {
      expect(canTransition('pending', 'assigned')).toBe(true);
      expect(canTransition('assigned', 'accepted')).toBe(true);
      expect(canTransition('accepted', 'on_the_way')).toBe(true);
      expect(canTransition('on_the_way', 'arrived')).toBe(true);
      expect(canTransition('arrived', 'in_progress')).toBe(true);
      expect(canTransition('in_progress', 'completed')).toBe(true);
      expect(canTransition('pending', 'cancelled')).toBe(true);
    });

    it('devrait refuser les transitions directes invalides', () => {
      expect(canTransition('pending', 'completed')).toBe(false);
      expect(canTransition('pending', 'arrived')).toBe(false);
      expect(canTransition('completed', 'in_progress')).toBe(false);
      expect(canTransition('cancelled', 'pending')).toBe(false);
    });
  });

  describe('validateTransition', () => {
    it('devrait valider avec succès si l’état ne change pas', () => {
      const intervention = { status: 'assigned', technician_id: 10 };
      expect(validateTransition(intervention, 'assigned')).toBe(true);
    });

    it('devrait lever une erreur si l’intervention est manquante', () => {
      expect(() => validateTransition(null, 'assigned')).toThrow(InterventionStateTransitionError);
    });

    it('devrait lever une erreur pour une transition interdite', () => {
      const intervention = { status: 'pending' };
      expect(() => validateTransition(intervention, 'completed')).toThrow(InterventionStateTransitionError);
    });

    it('devrait lever une erreur si aucun technicien n’est spécifié lors de l’assignation', () => {
      const intervention = { status: 'pending', technician_id: null };
      expect(() => validateTransition(intervention, 'assigned', {})).toThrow(InterventionStateTransitionError);
    });

    it('devrait valider l’assignation si un technicien est fourni', () => {
      const intervention = { status: 'pending', technician_id: null };
      expect(validateTransition(intervention, 'assigned', { technician_id: 5 })).toBe(true);
    });

    it('devrait lever une erreur si une intervention terminée tente d’être annulée', () => {
      const intervention = { status: 'completed' };
      expect(() => validateTransition(intervention, 'cancelled')).toThrow(InterventionStateTransitionError);
    });

    it('devrait refuser l’action si l’ID du technicien ne correspond pas', () => {
      const intervention = { status: 'accepted', technician_id: 10 };
      expect(() => validateTransition(intervention, 'on_the_way', { user_id: 99 })).toThrow(InterventionStateTransitionError);
    });
  });
});
