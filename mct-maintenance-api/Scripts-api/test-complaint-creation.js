// Script pour tester la création d'une réclamation et la notification
const { Complaint, CustomerProfile, User } = require('../src/models');
const { notifyNewComplaint } = require('../src/services/notificationHelpers');

async function testComplaintCreation() {
  try {
    console.log('🧪 Test de création de réclamation et notification\n');

    // 1. Trouver un client
    console.log('1️⃣  Recherche d\'un client...');
    const customer = await CustomerProfile.findOne({
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'email', 'first_name', 'last_name']
        }
      ]
    });

    if (!customer) {
      console.log('❌ Aucun client trouvé en base');
      console.log('💡 Créez d\'abord un compte client dans l\'application mobile');
      return;
    }

    console.log('✅ Client trouvé:');
    console.log(`   ID: ${customer.id}`);
    console.log(`   Nom: ${customer.first_name} ${customer.last_name}`);
    if (customer.user) {
      console.log(`   Email: ${customer.user.email}`);
      console.log(`   User ID: ${customer.user.id}`);
    } else {
      console.log('   ⚠️  Pas de user associé');
    }
    console.log('');

    // 2. Créer une réclamation
    console.log('2️⃣  Création d\'une réclamation de test...');
    const currentYear = new Date().getFullYear();
    const count = await Complaint.count() + 1;
    const reference = `REC-${currentYear}-${count.toString().padStart(3, '0')}`;

    const complaint = await Complaint.create({
      reference,
      customerId: customer.id,
      subject: 'Test notification - Produit défectueux',
      description: 'Test du système de notifications pour les réclamations',
      priority: 'high',
      category: 'product_quality',
      status: 'open'
    });

    console.log('✅ Réclamation créée:');
    console.log(`   ID: ${complaint.id}`);
    console.log(`   Référence: ${complaint.reference}`);
    console.log('');

    // 3. Récupérer avec les relations
    console.log('3️⃣  Récupération avec relations...');
    const complaintWithRelations = await Complaint.findByPk(complaint.id, {
      include: [
        {
          model: CustomerProfile,
          as: 'customer',
          attributes: ['id', 'first_name', 'last_name'],
          include: [
            {
              model: User,
              as: 'user',
              attributes: ['id', 'email', 'first_name', 'last_name']
            }
          ]
        }
      ]
    });

    console.log('✅ Relations chargées:');
    console.log('   Customer:', complaintWithRelations.customer ? 'Oui' : 'Non');
    if (complaintWithRelations.customer) {
      console.log('   Customer.user:', complaintWithRelations.customer.user ? 'Oui' : 'Non');
    }
    console.log('');

    // 4. Envoyer la notification
    console.log('4️⃣  Envoi de la notification...');
    const customerUser = complaintWithRelations.customer?.user;
    
    if (!customerUser) {
      console.log('❌ Pas de user associé au customer');
      console.log('💡 Le customer existe mais n\'a pas de user lié');
      return;
    }

    const customerData = {
      id: customerUser.id,
      first_name: complaintWithRelations.customer.first_name,
      last_name: complaintWithRelations.customer.last_name,
      email: customerUser.email
    };

    console.log('   Données client:');
    console.log(`   - ID: ${customerData.id}`);
    console.log(`   - Nom: ${customerData.first_name} ${customerData.last_name}`);
    console.log(`   - Email: ${customerData.email}`);
    console.log('');

    await notifyNewComplaint(complaintWithRelations, customerData);
    console.log('✅ Notification envoyée avec succès !');
    console.log('');

    // 5. Vérifier en base
    const { Notification } = require('../src/models');
    const notif = await Notification.findOne({
      where: { type: 'complaint_created' },
      order: [['created_at', 'DESC']]
    });

    if (notif) {
      console.log('5️⃣  Notification créée en base:');
      console.log(`   User ID: ${notif.user_id}`);
      console.log(`   Type: ${notif.type}`);
      console.log(`   Title: ${notif.title}`);
      console.log(`   Message: ${notif.message}`);
      console.log(`   URL: ${notif.action_url}`);
    }

  } catch (error) {
    console.error('❌ Erreur:', error.message);
    console.error('Stack:', error.stack);
  }
  
  process.exit(0);
}

testComplaintCreation();
