const { SystemConfig } = require('../models');

// Valeurs par défaut centralisées
const DEFAULT_CATALOG = {
  pricing: {
    diagnostic_fee: 4000,
    hourly_rate: 15000,
    emergency_surcharge_percent: 25,
    tax_rate_percent: 18
  },
  warranties: {
    installation_warranty_months: 3,
    maintenance_warranty_weeks: 2,
    spare_parts_default_warranty_months: 6
  },
  contacts: {
    support_phone: '+225 07 00 00 00 00',
    support_email: 'support@mctmaintenance.ci',
    support_whatsapp: '+225 07 00 00 00 00',
    emergency_phone: '+225 07 99 99 99 99',
    opening_hours: 'Lun - Sam: 07h30 - 18h30'
  },
  contractual_contents: {
    company_name: 'MCT Maintenance CI',
    cgu_url: '/legal/cgu',
    cgv_url: '/legal/cgv',
    privacy_policy_url: '/legal/privacy',
    warranty_policy_summary: 'Engagements de service MCT Maintenance garantis pièces et main d\'œuvre'
  }
};

/**
 * Récupère le catalogue complet des configurations serveur administrables.
 */
async function getSystemCatalog() {
  try {
    const catalogConfig = await SystemConfig.getValue('system_catalog', null);
    if (catalogConfig) {
      return {
        pricing: { ...DEFAULT_CATALOG.pricing, ...(catalogConfig.pricing || {}) },
        warranties: { ...DEFAULT_CATALOG.warranties, ...(catalogConfig.warranties || {}) },
        contacts: { ...DEFAULT_CATALOG.contacts, ...(catalogConfig.contacts || {}) },
        contractual_contents: { ...DEFAULT_CATALOG.contractual_contents, ...(catalogConfig.contractual_contents || {}) }
      };
    }
  } catch (error) {
    console.warn('⚠️ Impossible de lire system_catalog dans SystemConfig, retour fallback:', error.message);
  }
  return DEFAULT_CATALOG;
}

/**
 * Met à jour une section ou la totalité du catalogue de configurations (Admin).
 */
async function updateSystemCatalog(newCatalogData) {
  const currentCatalog = await getSystemCatalog();

  const updatedCatalog = {
    pricing: { ...currentCatalog.pricing, ...(newCatalogData.pricing || {}) },
    warranties: { ...currentCatalog.warranties, ...(newCatalogData.warranties || {}) },
    contacts: { ...currentCatalog.contacts, ...(newCatalogData.contacts || {}) },
    contractual_contents: { ...currentCatalog.contractual_contents, ...(newCatalogData.contractual_contents || {}) }
  };

  await SystemConfig.setValue('system_catalog', updatedCatalog, {
    category: 'catalog',
    description: 'Catalogue centralisé des tarifs, garanties, contacts et contenus contractuels',
    is_public: true
  });

  return updatedCatalog;
}

module.exports = {
  DEFAULT_CATALOG,
  getSystemCatalog,
  updateSystemCatalog
};
