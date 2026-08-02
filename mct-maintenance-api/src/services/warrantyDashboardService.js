const { Op } = require('sequelize');
const { Equipment, Intervention, Complaint, Subscription } = require('../models');

/**
 * Construit le tableau de bord SAV (Service Après-Vente) d'un client.
 *
 * Agrège pour un customerId :
 *  - Équipements avec statut de garantie calculé (active / expirée / bientôt)
 *  - Interventions récentes liées à chaque équipement
 *  - Réclamations ouvertes
 *  - Contrats/souscriptions actifs et prochaines maintenances
 */
async function buildWarrantyDashboard(customerId) {
  const now = new Date();
  const thirtyDaysFromNow = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

  const [equipments, recentInterventions, openComplaints, activeSubscriptions] =
    await Promise.all([
      // 1. Équipements du client avec date de garantie
      Equipment.findAll({
        where: { customer_id: customerId },
        order: [['name', 'ASC']],
      }),

      // 2. Interventions des 90 derniers jours (toutes, pour lier aux équipements)
      Intervention.findAll({
        where: {
          customer_id: customerId,
          created_at: {
            [Op.gte]: new Date(now - 90 * 24 * 60 * 60 * 1000),
          },
        },
        order: [['created_at', 'DESC']],
        limit: 20,
      }),

      // 3. Réclamations non résolues
      Complaint.findAll({
        where: {
          customer_id: customerId,
          status: { [Op.in]: ['pending', 'in_progress'] },
        },
        order: [['created_at', 'DESC']],
      }),

      // 4. Souscriptions actives + prochaine maintenance
      Subscription.findAll({
        where: {
          customer_id: customerId,
          status: 'active',
        },
        order: [['end_date', 'ASC']],
      }),
    ]);

  // Enrichir chaque équipement avec son statut de garantie
  const enrichedEquipments = equipments.map((eq) => {
    const expiry = eq.warranty_expiry ? new Date(eq.warranty_expiry) : null;
    let warrantyStatus = 'unknown';
    let daysRemaining = null;

    if (expiry) {
      if (expiry < now) {
        warrantyStatus = 'expired';
        daysRemaining = 0;
      } else if (expiry <= thirtyDaysFromNow) {
        warrantyStatus = 'expiring_soon';
        daysRemaining = Math.ceil((expiry - now) / (1000 * 60 * 60 * 24));
      } else {
        warrantyStatus = 'active';
        daysRemaining = Math.ceil((expiry - now) / (1000 * 60 * 60 * 24));
      }
    }

    return {
      id: eq.id,
      name: eq.name,
      type: eq.type,
      brand: eq.brand,
      model: eq.model,
      serial_number: eq.serial_number,
      status: eq.status,
      installation_date: eq.installation_date,
      warranty_expiry: eq.warranty_expiry,
      warranty_status: warrantyStatus,
      days_remaining: daysRemaining,
      last_maintenance_date: eq.last_maintenance_date,
      next_maintenance_date: eq.next_maintenance_date,
    };
  });

  return {
    generated_at: now.toISOString(),
    summary: {
      total_equipments: equipments.length,
      warranties_active: enrichedEquipments.filter(
        (e) => e.warranty_status === 'active'
      ).length,
      warranties_expiring_soon: enrichedEquipments.filter(
        (e) => e.warranty_status === 'expiring_soon'
      ).length,
      warranties_expired: enrichedEquipments.filter(
        (e) => e.warranty_status === 'expired'
      ).length,
      open_complaints: openComplaints.length,
      active_subscriptions: activeSubscriptions.length,
    },
    equipments: enrichedEquipments,
    recent_interventions: recentInterventions.map((i) => ({
      id: i.id,
      title: i.title,
      status: i.status,
      scheduled_date: i.scheduled_date,
      created_at: i.created_at,
    })),
    open_complaints: openComplaints.map((c) => ({
      id: c.id,
      subject: c.subject,
      status: c.status,
      created_at: c.created_at,
    })),
    active_subscriptions: activeSubscriptions.map((s) => ({
      id: s.id,
      end_date: s.end_date,
      days_remaining: Math.ceil(
        (new Date(s.end_date) - now) / (1000 * 60 * 60 * 24)
      ),
    })),
  };
}

module.exports = { buildWarrantyDashboard };
