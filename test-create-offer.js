const axios = require('axios');

// Configuration
const API_URL = 'http://localhost:3000/api';
const ADMIN_EMAIL = 'admin@mct.com';
const ADMIN_PASSWORD = 'admin123';

async function testCreateOffer() {
  try {
    console.log('🔐 Connexion admin...');
    
    // 1. Login admin
    const loginResponse = await axios.post(`${API_URL}/auth/login`, {
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD
    });
    
    const token = loginResponse.data.data.token;
    console.log('✅ Token obtenu:', token.substring(0, 20) + '...');
    
    // 2. Créer une offre d'entretien active
    console.log('\n📝 Création d\'une offre d\'entretien...');
    const offerResponse = await axios.post(`${API_URL}/maintenance-offers`, {
      title: 'Offre Test Notification',
      description: 'Offre créée pour tester les notifications',
      price: 50000,
      duration: '6 mois',
      features: ['Test 1', 'Test 2', 'Test 3'],
      isActive: true
    }, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log('✅ Offre créée:', offerResponse.data.data);
    console.log('\n🔔 Vérifiez le dashboard et le mobile pour les notifications !');
    
  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
  }
}

testCreateOffer();
