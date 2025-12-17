/**
 * Test manuel à exécuter dans la console du navigateur (Dashboard)
 * 
 * Instructions:
 * 1. Ouvrir le dashboard (http://localhost:3001)
 * 2. Se connecter comme admin
 * 3. NE PAS aller dans l'onglet Chat (rester sur Dashboard ou autre page)
 * 4. Ouvrir la console navigateur (F12)
 * 5. Copier-coller ce code et appuyer sur Entrée
 * 6. Observer le badge sur l'icône Chat dans le menu latéral
 */

console.log('🧪 Test du badge de notification Chat\n');

// Simuler la réception d'un nouveau message client
const simulateNewMessage = () => {
  // Créer un message de test
  const testMessage = {
    id: Math.floor(Math.random() * 10000),
    sender_id: 14, // ID d'un client
    sender_role: 'customer', // Important: doit être 'customer'
    recipient_id: null,
    message: 'Message de test pour le badge',
    created_at: new Date().toISOString(),
    sender: {
      id: 14,
      first_name: 'Test',
      last_name: 'Client',
      email: 'test@client.com',
      customerProfile: {
        first_name: 'Test',
        last_name: 'Client'
      }
    }
  };

  console.log('📤 Émission d\'un message de test:', testMessage);

  // Émettre l'événement via Socket.IO (si disponible)
  if (window.io) {
    console.log('✅ Socket.IO trouvé, émission du message...');
    // Simuler la réception du message
    window.dispatchEvent(new CustomEvent('test:new_chat_message', { 
      detail: testMessage 
    }));
  } else {
    console.log('⚠️  Socket.IO non disponible dans window');
  }

  console.log('\n🔍 Vérifications à faire:');
  console.log('   1. Regardez le menu latéral gauche');
  console.log('   2. L\'icône Chat devrait avoir un badge rouge avec "1"');
  console.log('   3. Un toast devrait apparaître en haut à droite');
  console.log('   4. Regardez les logs ci-dessus pour les détails\n');
};

// Attendre 2 secondes puis simuler
setTimeout(() => {
  console.log('\n🚀 Simulation du message dans 1 seconde...\n');
  setTimeout(simulateNewMessage, 1000);
}, 1000);

console.log('⏳ Préparation du test...');
