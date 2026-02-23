// Script pour créer une réclamation ET émettre la notification en temps réel
const { Complaint, CustomerProfile, User } = require('../src/models');
const { notifyNewComplaint } = require('../src/services/notificationHelpers');
const notificationService = require('../src/services/notificationService');

// Simuler l'initialisation de Socket.IO (pour le service)
const { Server } = require('socket.io');
const http = require('http');

async function createComplaintWithRealTimeNotification() {
  try {
    console.log('🚀 Création d\'une réclamation avec notification temps réel\n');

    // 1. Initialiser Socket.IO
    console.log('1️⃣  Initialisation de Socket.IO...');
    const server = http.createServer();
    const io = new Server(server, {
      cors: { origin: '*' }
    });
    
    await new Promise((resolve) => {
      server.listen(0, () => {
        const port = server.address().port;
        console.log(`   ✅ Socket.IO démarré sur port ${port}`);
        resolve();
      });
    });

    notificationService.initialize(io);
    console.log('   ✅ NotificationService initialisé avec Socket.IO\n');

    // 2. Trouver un client actif
    console.log('2️⃣  Recherche d\'un client actif...');
    const customer = await CustomerProfile.findOne({
      where: { id: 8 },  // Bassirou
      include: [{
        model: User,
        as: 'user',
        attributes: ['id', 'email', 'first_name', 'last_name']
      }]
    });

    if (!customer || !customer.user) {
      console.log('❌ Client non trouvé ou sans user actif');
      process.exit(1);
    }

    console.log('   ✅ Client trouvé:');
    console.log(`   - Nom: ${customer.first_name} ${customer.last_name}`);
    console.log(`   - Email: ${customer.user.email}\n`);

    // 3. Créer la réclamation
    console.log('3️⃣  Création de la réclamation...');
    const currentYear = new Date().getFullYear();
    const count = await Complaint.count() + 1;
    const reference = `REC-${currentYear}-${count.toString().padStart(3, '0')}`;

    const complaint = await Complaint.create({
      reference,
      customerId: customer.id,
      subject: '🧪 Test notification temps réel - Réclamation',
      description: 'Cette réclamation a été créée pour tester le système de notifications en temps réel',
      priority: 'high',
      category: 'product_quality',
      status: 'open'
    });

    console.log(`   ✅ Réclamation créée: ${complaint.reference}\n`);

    // 4. Récupérer avec relations
    console.log('4️⃣  Chargement des relations...');
    const complaintWithRelations = await Complaint.findByPk(complaint.id, {
      include: [{
        model: CustomerProfile,
        as: 'customer',
        attributes: ['id', 'first_name', 'last_name'],
        include: [{
          model: User,
          as: 'user',
          attributes: ['id', 'email', 'first_name', 'last_name']
        }]
      }]
    });

    const customerData = {
      id: complaintWithRelations.customer.user.id,
      first_name: complaintWithRelations.customer.first_name,
      last_name: complaintWithRelations.customer.last_name,
      email: complaintWithRelations.customer.user.email
    };

    console.log('   ✅ Relations chargées\n');

    // 5. Envoyer la notification EN TEMPS RÉEL
    console.log('5️⃣  📡 Envoi de la notification en temps réel...');
    await notifyNewComplaint(complaintWithRelations, customerData);
    
    console.log('   ✅ Notification envoyée avec Socket.IO !');
    console.log('   📢 Les admins connectés devraient voir le badge/toast instantanément\n');

    // 6. Attendre un peu pour laisser Socket.IO émettre
    console.log('⏳ Attente de 2 secondes pour Socket.IO...');
    await new Promise(resolve => setTimeout(resolve, 2000));

    console.log('\n' + '='.repeat(60));
    console.log('✅ RÉCLAMATION CRÉÉE ET NOTIFICATION ÉMISE !');
    console.log('='.repeat(60));
    console.log('\n👀 Vérifiez le dashboard web :');
    console.log(`   - Badge sur la cloche 🔔`);
    console.log(`   - Toast "Nouvelle réclamation"`);
    console.log(`   - Message: "${customerData.first_name} ${customerData.last_name} a créé une réclamation"`);
    console.log(`   - URL: /reclamations/${complaint.id}`);
    console.log('');

    // Fermer
    io.close();
    server.close();
    process.exit(0);

  } catch (error) {
    console.error('❌ Erreur:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

createComplaintWithRealTimeNotification();
