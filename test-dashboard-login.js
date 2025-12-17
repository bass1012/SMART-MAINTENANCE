const axios = require('axios');

async function testDashboardLogin() {
  try {
    console.log('🔍 Test de connexion au dashboard MCT Maintenance');
    console.log('📡 API URL: http://192.168.1.29:3000/api');
    
    // Test de connexion
    const loginResponse = await axios.post('http://192.168.1.29:3000/api/auth/login', {
      email: 'admin@mct-maintenance.com',
      password: 'P@ssword'
    });
    
    console.log('✅ Connexion réussie');
    console.log('👤 Utilisateur:', loginResponse.data.data.user.first_name, loginResponse.data.data.user.last_name);
    console.log('🔑 Token reçu:', loginResponse.data.data.accessToken.substring(0, 20) + '...');
    
    // Test de récupération du profil
    const token = loginResponse.data.data.accessToken;
    const profileResponse = await axios.get('http://192.168.1.29:3000/api/auth/profile', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log('✅ Profil récupéré');
    console.log('📧 Email:', profileResponse.data.data.user.email);
    console.log('👔 Rôle:', profileResponse.data.data.user.role);
    console.log('🟢 Statut:', profileResponse.data.data.user.status);
    
    console.log('\n🎉 Tous les tests sont passés ! Le dashboard devrait maintenant fonctionner.');
    
  } catch (error) {
    console.error('❌ Erreur lors du test:', error.response?.data || error.message);
  }
}

testDashboardLogin();
