const { Subscription, SystemConfig } = require('../models');

/**
 * Service gérant le calcul du coût de diagnostic et du statut initial d'une intervention
 */
class InterventionCreationService {
  /**
   * Calcule les frais de diagnostic et détermine le statut initial
   */
  static async calculateDiagnosticFeeAndStatus({ interventionData, customerUserId, actualCustomerId }) {
    const rawType = interventionData.intervention_type?.toLowerCase() || '';
    
    const requiresDiagnosticFee = [
      'diagnostic', 'repair', 'réparation', 'reparation', 'installation', 'dépannage', 'depannage'
    ].includes(rawType);

    const isMaintenanceType = rawType === 'entretien' || rawType === 'maintenance';

    let diagnosticFee = 0;
    let isFreeDiagnosis = true;
    let equipmentCoveredBySubscription = 0;
    let equipmentToPay = 0;
    let hasActiveSubscription = false;
    let activeSubscription = null;

    if (isMaintenanceType && interventionData.maintenance_offer_id) {
      const maintenanceOfferId = parseInt(interventionData.maintenance_offer_id);
      
      activeSubscription = await Subscription.findOne({
        where: {
          customer_id: customerUserId,
          maintenance_offer_id: maintenanceOfferId,
          status: 'active',
          payment_status: 'paid'
        }
      });
      
      if (activeSubscription) {
        const equipmentCount = activeSubscription.equipment_count || 1;
        const equipmentUsed = activeSubscription.equipment_used || 0;
        const equipmentRemaining = equipmentCount - equipmentUsed;
        const requestedEquipment = parseInt(interventionData.equipment_count) || 1;
        
        if (equipmentRemaining > 0) {
          equipmentCoveredBySubscription = Math.min(requestedEquipment, equipmentRemaining);
          equipmentToPay = Math.max(0, requestedEquipment - equipmentRemaining);
          hasActiveSubscription = true;
        }
      }
    }

    if (requiresDiagnosticFee || (isMaintenanceType && (!hasActiveSubscription || equipmentToPay > 0))) {
      isFreeDiagnosis = false;
      const feeConfig = await SystemConfig.findOne({ where: { key: 'diagnostic_fee' } });
      diagnosticFee = feeConfig ? parseFloat(feeConfig.value) : 10000;
    }

    // Déterminer le statut initial de l'intervention
    let initialStatus = 'pending';
    let diagnosticPaid = false;

    if (requiresDiagnosticFee && !isFreeDiagnosis) {
      initialStatus = 'pending_payment';
      diagnosticPaid = false;
    } else if (isMaintenanceType && !hasActiveSubscription && equipmentToPay > 0) {
      initialStatus = 'pending_payment';
      diagnosticPaid = false;
    } else {
      initialStatus = 'pending';
      diagnosticPaid = true;
    }

    return {
      diagnosticFee,
      isFreeDiagnosis,
      equipmentCoveredBySubscription,
      equipmentToPay,
      hasActiveSubscription,
      activeSubscription,
      initialStatus,
      diagnosticPaid
    };
  }
}

module.exports = InterventionCreationService;
