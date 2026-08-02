jest.mock('../../../src/models', () => ({
  SystemConfig: {
    getValue: jest.fn(),
    setValue: jest.fn()
  }
}));

const { SystemConfig } = require('../../../src/models');
const { DEFAULT_CATALOG, getSystemCatalog, updateSystemCatalog } = require('../../../src/services/systemConfigCatalogService');

describe('systemConfigCatalogService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('doit retourner le catalogue par défaut en l\'absence de configuration en BDD', async () => {
    SystemConfig.getValue.mockResolvedValue(null);

    const catalog = await getSystemCatalog();

    expect(catalog.pricing.diagnostic_fee).toBe(4000);
    expect(catalog.contacts.support_email).toBe('support@mctmaintenance.ci');
    expect(catalog.warranties.installation_warranty_months).toBe(3);
  });

  it('doit fusionner la configuration BDD avec le catalogue par défaut', async () => {
    SystemConfig.getValue.mockResolvedValue({
      pricing: { diagnostic_fee: 5000 }
    });

    const catalog = await getSystemCatalog();

    expect(catalog.pricing.diagnostic_fee).toBe(5000);
    expect(catalog.pricing.hourly_rate).toBe(15000); // valeur par défaut préservée
  });

  it('doit sauvegarder la mise à jour du catalogue en BDD (updateSystemCatalog)', async () => {
    SystemConfig.getValue.mockResolvedValue(DEFAULT_CATALOG);
    SystemConfig.setValue.mockResolvedValue(true);

    const updated = await updateSystemCatalog({
      pricing: { diagnostic_fee: 6000 },
      contacts: { support_phone: '+225 01 02 03 04 05' }
    });

    expect(updated.pricing.diagnostic_fee).toBe(6000);
    expect(updated.contacts.support_phone).toBe('+225 01 02 03 04 05');
    expect(SystemConfig.setValue).toHaveBeenCalledWith('system_catalog', expect.any(Object), expect.any(Object));
  });
});
