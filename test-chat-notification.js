/**
 * Script de test pour vérifier les notifications de chat
 * Usage: node test-chat-notification.js
 */

const io = require('socket.io-client');

// Configuration
const BACKEND_URL = 'http://localhost:3000';
const CLIENT_USER_ID = 14; // ID d'un client (pkanta@gmail.com)
const CLIENT_TOKEN = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MTQsImVtYWlsIjoicGthbnRhQGdtYWlsLmNvbSIsInJvbGUiOiJjdXN0b21lciIsImlhdCI6MTc2MjE4NjE0MiwiZXhwIjoxNzYyNzkwOTQyfQ.gCKI4xJdCEqvsn8Kl-8dzVEdu8xdkMJWXJlrbTZK4LY';

console.log('🧪 Test des notifications de chat\n');
console.log('📊 Configuration:');
console.log(`   Backend: ${BACKEND_URL}`);
console.log(`   Client ID: ${CLIENT_USER_ID}\n`);

// Connexion Socket.IO comme client
const socket = io(BACKEND_URL, {
  transports: ['polling', 'websocket'],
  auth: {
    token: CLIENT_TOKEN
  }
});

socket.on('connect', () => {
  console.log('✅ Connecté au serveur Socket.IO\n');
  
  // Authentification
  console.log('🔐 Authentification en cours...');
  socket.emit('chat:authenticate', {
    userId: CLIENT_USER_ID,
    token: CLIENT_TOKEN
  });
});

socket.on('chat:authenticated', (data) => {
  console.log('✅ Authentifié:', data);
  console.log(`   Utilisateur: ${data.userName}`);
  console.log(`   Rôle: ${data.userRole}\n`);
  
  // Envoyer un message de test
  setTimeout(() => {
    console.log('📤 Envoi d\'un message de test...');
    const testMessage = `Test notification - ${new Date().toLocaleTimeString()}`;
    
    socket.emit('chat:send_message', {
      message: testMessage,
      sender_role: 'customer',
      recipient_id: null
    });
    
    console.log(`   Message: "${testMessage}"`);
  }, 1000);
});

socket.on('chat:message_sent', (data) => {
  console.log('\n✅ Message envoyé avec succès!');
  console.log('   ID:', data.message?.id);
  console.log('   Contenu:', data.message?.message);
  console.log('\n💡 Vérifications:');
  console.log('   1. Regardez les logs du serveur backend');
  console.log('      → Devrait afficher: "📱 [Chat] Notification envoyée à X admin(s)"');
  console.log('   2. Regardez le dashboard admin');
  console.log('      → Un toast devrait apparaître en haut à droite');
  console.log('   3. Vérifiez le badge sur l\'avatar du client');
  console.log('      → Le compteur devrait augmenter\n');
  
  // Attendre 3 secondes puis fermer
  setTimeout(() => {
    console.log('✅ Test terminé!');
    socket.disconnect();
    process.exit(0);
  }, 3000);
});

socket.on('chat:error', (error) => {
  console.error('❌ Erreur:', error);
});

socket.on('disconnect', () => {
  console.log('\n🔌 Déconnecté du serveur');
});

socket.on('connect_error', (error) => {
  console.error('❌ Erreur de connexion:', error.message);
  process.exit(1);
});

// Timeout de sécurité
setTimeout(() => {
  console.error('\n⏱️  Timeout - Test trop long');
  process.exit(1);
}, 15000);
