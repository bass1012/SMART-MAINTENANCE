const { Intervention, User, CustomerProfile } = require('../src/models');

async function testInterventionStatus() {
  try {
    console.log('🔍 Test du statut des interventions\n');

    // Récupérer toutes les interventions
    const interventions = await Intervention.findAll({
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'email'],
          include: [
            {
              model: CustomerProfile,
              as: 'customerProfile',
              attributes: ['first_name', 'last_name']
            }
          ]
        },
        {
          model: User,
          as: 'technician',
          attributes: ['id', 'first_name', 'last_name', 'email'],
          required: false
        }
      ],
      order: [['id', 'DESC']],
      limit: 5
    });

    console.log(`📊 ${interventions.length} dernières interventions:\n`);

    interventions.forEach(intervention => {
      const plain = intervention.get({ plain: true });
      
      const customerName = plain.customer?.customerProfile 
        ? `${plain.customer.customerProfile.first_name} ${plain.customer.customerProfile.last_name}`
        : plain.customer?.email || 'N/A';
      
      const technicianName = plain.technician
        ? `${plain.technician.first_name} ${plain.technician.last_name}`
        : 'Non assigné';

      console.log(`┌─────────────────────────────────────────────┐`);
      console.log(`│ ID: ${plain.id}`);
      console.log(`│ Titre: ${plain.title}`);
      console.log(`│ 🎯 STATUT: ${plain.status.toUpperCase()}`);
      console.log(`│ Client: ${customerName} (ID: ${plain.customer_id})`);
      console.log(`│ Technicien: ${technicianName}`);
      console.log(`│ Créée le: ${plain.created_at}`);
      console.log(`└─────────────────────────────────────────────┘\n`);
    });

    // Test spécifique pour l'intervention #43
    console.log('\n🔎 Test spécifique de l\'intervention #43:\n');
    
    const intervention43 = await Intervention.findByPk(43, {
      include: [
        {
          model: User,
          as: 'customer',
          attributes: ['id', 'email'],
          include: [
            {
              model: CustomerProfile,
              as: 'customerProfile',
              attributes: ['first_name', 'last_name']
            }
          ]
        },
        {
          model: User,
          as: 'technician',
          attributes: ['id', 'first_name', 'last_name'],
          required: false
        }
      ]
    });

    if (intervention43) {
      const plain43 = intervention43.get({ plain: true });
      console.log('✅ Intervention #43 trouvée:');
      console.log(`   - Statut en DB: ${plain43.status}`);
      console.log(`   - Customer ID: ${plain43.customer_id}`);
      console.log(`   - Technician ID: ${plain43.technician_id}`);
      console.log(`   - Ce que l'API retourne:`);
      console.log(JSON.stringify({
        id: plain43.id,
        title: plain43.title,
        status: plain43.status,
        customer_id: plain43.customer_id,
        technician_id: plain43.technician_id
      }, null, 2));
    } else {
      console.log('❌ Intervention #43 non trouvée');
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

testInterventionStatus();
