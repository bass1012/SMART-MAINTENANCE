const { Op } = require('sequelize');
const { Intervention, User, CustomerProfile } = require('../models');

// Créneaux horaires standards avec capacité max par défaut (ex: 5 interventions simultanées par créneau)
const STANDARD_SLOTS = [
  { id: '08:00-10:00', label: '08:00 - 10:00 (Matin)', startHour: 8, endHour: 10, maxCapacity: 5 },
  { id: '10:00-12:00', label: '10:00 - 12:00 (Matin)', startHour: 10, endHour: 12, maxCapacity: 5 },
  { id: '14:00-16:00', label: '14:00 - 16:00 (Après-midi)', startHour: 14, endHour: 16, maxCapacity: 5 },
  { id: '16:00-18:00', label: '16:00 - 18:00 (Fin d\'après-midi)', startHour: 16, endHour: 18, maxCapacity: 5 },
];

/**
 * Calcule la disponibilité des créneaux capacitaires pour une date donnée.
 */
async function getAvailableSlots(dateString) {
  const targetDate = new Date(dateString);
  if (isNaN(targetDate.getTime())) {
    throw new Error('Date invalide (format YYYY-MM-DD attendu)');
  }

  const startOfDay = new Date(targetDate);
  startOfDay.setHours(0, 0, 0, 0);

  const endOfDay = new Date(targetDate);
  endOfDay.setHours(23, 59, 59, 999);

  // Récupérer toutes les interventions prévues ce jour-là (non annulées)
  const dayInterventions = await Intervention.findAll({
    where: {
      scheduled_date: { [Op.between]: [startOfDay, endOfDay] },
      status: { [Op.notIn]: ['cancelled', 'rejected'] }
    },
    attributes: ['id', 'time_slot', 'scheduled_date']
  });

  const slots = STANDARD_SLOTS.map(slot => {
    // Compter les interventions réservées sur ce créneau
    const bookedCount = dayInterventions.filter(i => {
      if (i.time_slot) return i.time_slot === slot.id;
      // Fallback sur l'heure si time_slot n'est pas rempli
      if (i.scheduled_date) {
        const h = new Date(i.scheduled_date).getHours();
        return h >= slot.startHour && h < slot.endHour;
      }
      return false;
    }).length;

    const availableCapacity = Math.max(0, slot.maxCapacity - bookedCount);
    const isAvailable = availableCapacity > 0;

    return {
      id: slot.id,
      label: slot.label,
      max_capacity: slot.maxCapacity,
      booked_count: bookedCount,
      remaining_capacity: availableCapacity,
      is_available: isAvailable
    };
  });

  return {
    date: dateString,
    total_slots: slots.length,
    available_slots: slots.filter(s => s.is_available).length,
    slots
  };
}

/**
 * Replanification self-service contrôlant la capacité du créneau et l'éligibilité de l'intervention.
 */
async function rescheduleInterventionWithCapacity({ interventionId, customerUserId, newDateString, newSlotId }) {
  const customerProfile = await CustomerProfile.findOne({ where: { user_id: customerUserId } });
  if (!customerProfile) {
    throw new Error('Profil client non trouvé');
  }

  const intervention = await Intervention.findOne({
    where: { id: interventionId, customer_id: customerProfile.id }
  });

  if (!intervention) {
    throw new Error('Intervention non trouvée ou non autorisée');
  }

  if (['completed', 'cancelled', 'rejected'].includes(intervention.status)) {
    throw new Error(`Impossible de replanifier une intervention au statut "${intervention.status}"`);
  }

  // Vérifier la disponibilité du créneau
  const slotData = await getAvailableSlots(newDateString);
  const selectedSlot = slotData.slots.find(s => s.id === newSlotId);

  if (!selectedSlot) {
    throw new Error(`Créneau horaire "${newSlotId}" non reconnu`);
  }

  if (!selectedSlot.is_available) {
    throw new Error(`Le créneau "${selectedSlot.label}" est complet pour le ${newDateString}`);
  }

  // Construire la date/heure exacte de début du créneau
  const newScheduledDate = new Date(newDateString);
  const [startHour] = newSlotId.split('-')[0].split(':').map(Number);
  newScheduledDate.setHours(startHour, 0, 0, 0);

  // Mettre à jour l'intervention
  await intervention.update({
    scheduled_date: newScheduledDate,
    time_slot: newSlotId,
    status: intervention.technician_id ? 'assigned' : 'pending'
  });

  return {
    intervention_id: intervention.id,
    new_scheduled_date: newScheduledDate.toISOString(),
    new_time_slot: newSlotId,
    status: intervention.status
  };
}

/**
 * Autorise la géolocalisation et l'ETA du technicien UNIQUEMENT pendant la fenêtre autorisée (1h avant le rdv jusqu'à la fin de la prestation).
 */
async function getTechnicianTrackingAccess({ interventionId, customerUserId }) {
  const customerProfile = await CustomerProfile.findOne({ where: { user_id: customerUserId } });
  if (!customerProfile) {
    throw new Error('Profil client non trouvé');
  }

  const intervention = await Intervention.findOne({
    where: { id: interventionId, customer_id: customerProfile.id },
    include: [{ association: 'technician', required: false }]
  });

  if (!intervention) {
    throw new Error('Intervention non trouvée');
  }

  if (!intervention.technician_id || !intervention.technician) {
    return {
      tracking_enabled: false,
      reason: 'TECHNICIAN_NOT_ASSIGNED',
      message: 'Aucun technicien n\'a encore été assigné à cette intervention'
    };
  }

  const now = new Date();
  const scheduledDate = new Date(intervention.scheduled_date);
  
  // Fenêtre de suivi autorisée : de (scheduledDate - 1h) jusqu'à (scheduledDate + 4h)
  const trackingStartWindow = new Date(scheduledDate.getTime() - 60 * 60 * 1000);
  const trackingEndWindow = new Date(scheduledDate.getTime() + 4 * 60 * 60 * 1000);

  const isInWindow = now >= trackingStartWindow && now <= trackingEndWindow;
  const isEnRouteOrInProgress = ['en_route', 'in_progress'].includes(intervention.status);

  if (!isInWindow && !isEnRouteOrInProgress) {
    return {
      tracking_enabled: false,
      reason: 'OUTSIDE_TIME_WINDOW',
      message: 'Le suivi en direct et l\'ETA sont uniquement accessibles 1h avant votre créneau de rendez-vous',
      scheduled_date: scheduledDate.toISOString(),
      tracking_opens_at: trackingStartWindow.toISOString()
    };
  }

  // Si on est dans la fenêtre autorisée
  const tech = intervention.technician;
  return {
    tracking_enabled: true,
    intervention_id: intervention.id,
    status: intervention.status,
    scheduled_date: scheduledDate.toISOString(),
    technician: {
      id: tech.id,
      first_name: tech.first_name,
      last_name: tech.last_name,
      phone: tech.phone_number || tech.phone,
      latitude: tech.latitude || 5.3484, // Coordonnées exemple (Abidjan)
      longitude: tech.longitude || -4.0305,
      eta_minutes: Math.max(5, Math.floor((scheduledDate - now) / 60000))
    }
  };
}

module.exports = {
  STANDARD_SLOTS,
  getAvailableSlots,
  rescheduleInterventionWithCapacity,
  getTechnicianTrackingAccess
};
