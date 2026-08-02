jest.mock('../../../src/models', () => ({
  Intervention: { findAll: jest.fn(), findOne: jest.fn() },
  User: { findOne: jest.fn() },
  CustomerProfile: { findOne: jest.fn() }
}));

const { Intervention, CustomerProfile } = require('../../../src/models');
const {
  getAvailableSlots,
  rescheduleInterventionWithCapacity,
  getTechnicianTrackingAccess
} = require('../../../src/services/capacityAndTrackingService');

describe('capacityAndTrackingService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('getAvailableSlots', () => {
    it('doit calculer les créneaux disponibles et leur capacité restante', async () => {
      Intervention.findAll.mockResolvedValue([
        { id: 1, time_slot: '08:00-10:00' },
        { id: 2, time_slot: '08:00-10:00' }
      ]);

      const res = await getAvailableSlots('2026-08-10');

      expect(res.total_slots).toBe(4);
      expect(res.slots[0].booked_count).toBe(2);
      expect(res.slots[0].remaining_capacity).toBe(3); // 5 - 2
      expect(res.slots[0].is_available).toBe(true);
    });

    it('doit lever une erreur pour une date invalide', async () => {
      await expect(getAvailableSlots('invalid-date')).rejects.toThrow('Date invalide');
    });
  });

  describe('rescheduleInterventionWithCapacity', () => {
    it('doit replanifier avec succès si le créneau est disponible', async () => {
      const mockIntervention = {
        id: 10,
        status: 'pending',
        technician_id: null,
        update: jest.fn().mockResolvedValue(true)
      };

      CustomerProfile.findOne.mockResolvedValue({ id: 5 });
      Intervention.findOne.mockResolvedValue(mockIntervention);
      Intervention.findAll.mockResolvedValue([]); // aucun slot réservé

      const res = await rescheduleInterventionWithCapacity({
        interventionId: 10,
        customerUserId: 1,
        newDateString: '2026-08-10',
        newSlotId: '10:00-12:00'
      });

      expect(res.intervention_id).toBe(10);
      expect(res.new_time_slot).toBe('10:00-12:00');
      expect(mockIntervention.update).toHaveBeenCalled();
    });

    it('doit rejeter la replanification si l\'intervention est déjà terminée', async () => {
      CustomerProfile.findOne.mockResolvedValue({ id: 5 });
      Intervention.findOne.mockResolvedValue({ id: 10, status: 'completed' });

      await expect(
        rescheduleInterventionWithCapacity({
          interventionId: 10,
          customerUserId: 1,
          newDateString: '2026-08-10',
          newSlotId: '10:00-12:00'
        })
      ).rejects.toThrow('Impossible de replanifier');
    });
  });

  describe('getTechnicianTrackingAccess', () => {
    it('doit refuser l\'accès si le technicien n\'est pas encore assigné', async () => {
      CustomerProfile.findOne.mockResolvedValue({ id: 5 });
      Intervention.findOne.mockResolvedValue({ id: 10, technician_id: null, technician: null });

      const res = await getTechnicianTrackingAccess({ interventionId: 10, customerUserId: 1 });

      expect(res.tracking_enabled).toBe(false);
      expect(res.reason).toBe('TECHNICIAN_NOT_ASSIGNED');
    });

    it('doit refuser l\'accès si hors de la fenêtre horaire (ex: 24h avant)', async () => {
      const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000);
      CustomerProfile.findOne.mockResolvedValue({ id: 5 });
      Intervention.findOne.mockResolvedValue({
        id: 10,
        status: 'assigned',
        scheduled_date: tomorrow,
        technician_id: 20,
        technician: { id: 20, first_name: 'Jean', last_name: 'Kouassi' }
      });

      const res = await getTechnicianTrackingAccess({ interventionId: 10, customerUserId: 1 });

      expect(res.tracking_enabled).toBe(false);
      expect(res.reason).toBe('OUTSIDE_TIME_WINDOW');
    });

    it('doit accorder l\'accès ETA et coordonnées pendant la fenêtre de rdv ou en route', async () => {
      const now = new Date();
      CustomerProfile.findOne.mockResolvedValue({ id: 5 });
      Intervention.findOne.mockResolvedValue({
        id: 10,
        status: 'en_route',
        scheduled_date: now,
        technician_id: 20,
        technician: { id: 20, first_name: 'Jean', last_name: 'Kouassi', phone: '0707070707' }
      });

      const res = await getTechnicianTrackingAccess({ interventionId: 10, customerUserId: 1 });

      expect(res.tracking_enabled).toBe(true);
      expect(res.technician.first_name).toBe('Jean');
      expect(res.technician.eta_minutes).toBeGreaterThanOrEqual(5);
    });
  });
});
