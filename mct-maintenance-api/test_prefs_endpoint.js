const axios = require('axios');

async function test() {
  try {
    // 1. Login pour obtenir un token
    console.log('🔐 Login...');
    const loginRes = await axios.post('http://localhost:3000/api/auth/login', {
      email: 'test.client@example.com',
      password: 'password123'
    });
    
    const token = loginRes.data.data.accessToken;
    console.log('✅ Token obtenu:', token.substring(0, 20) + '...');
    
    // 2. Tester l'endpoint préférences
    console.log('\n📬 GET /api/notification-preferences');
    const prefsRes = await axios.get('http://localhost:3000/api/notification-preferences', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log('✅ Réponse:', JSON.stringify(prefsRes.data, null, 2));
  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
    if (error.response?.data) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    }
  }
}

test();
