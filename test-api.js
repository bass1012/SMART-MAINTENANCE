const axios = require('axios');

async function testDetailedAPI() {
  try {
    // Connexion admin
    console.log('1. Connexion admin...');
    const loginResponse = await axios.post('http://localhost:3000/api/auth/login', {
      email: 'admin@mct-maintenance.com',
      password: 'P@ssword'
    });

    console.log('Login success:', loginResponse.data.success);
    const token = loginResponse.data.data.accessToken;
    
    // Test détaillé de l'API technicians
    console.log('\n2. Test API /api/admin/technicians...');
    const techResponse = await axios.get('http://localhost:3000/api/admin/technicians', {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('=== API Response Structure ===');
    console.log('success:', techResponse.data.success);
    console.log('data keys:', Object.keys(techResponse.data.data));
    console.log('technicians array length:', techResponse.data.data.technicians.length);
    console.log('First technician:', JSON.stringify(techResponse.data.data.technicians[0], null, 2));
    
  } catch (error) {
    console.error('Erreur:', error.response?.data || error.message);
  }
}

testDetailedAPI();