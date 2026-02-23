const { SystemConfig } = require('../src/models');

async function initConfig() {
  try {
    // Sync the table
    await SystemConfig.sync();
    console.log('✅ SystemConfig table synced');
    
    // Set default diagnostic fee
    await SystemConfig.setValue('diagnostic_default_fee', 4000, {
      type: 'number',
      category: 'diagnostic',
      description: 'Frais de diagnostic par défaut (FCFA)'
    });
    console.log('✅ Default diagnostic fee set: 4000 FCFA');
    
    // Set default locations
    await SystemConfig.setValue('service_locations', [
      { name: 'Dakar', code: 'DKR', active: true },
      { name: 'Thiès', code: 'THS', active: true },
      { name: 'Saint-Louis', code: 'SLO', active: true },
      { name: 'Mbour', code: 'MBR', active: true },
      { name: 'Ziguinchor', code: 'ZIG', active: true }
    ], {
      type: 'array',
      category: 'location',
      description: 'Zones de service disponibles'
    });
    console.log('✅ Default locations set');
    
    // Verify
    const fee = await SystemConfig.getValue('diagnostic_default_fee', 0);
    console.log('📋 Verified diagnostic fee:', fee);
    
    const locations = await SystemConfig.getValue('service_locations', []);
    console.log('📋 Verified locations:', locations.length, 'zones');
    
    console.log('\n✅ Configuration système initialisée avec succès!');
  } catch (err) {
    console.error('❌ Error:', err.message);
  }
  process.exit(0);
}

initConfig();
