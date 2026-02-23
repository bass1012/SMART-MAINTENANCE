const axios = require('axios');

async function test() {
  try {
    // Login avec les vrais identifiants
    const loginResponse = await axios.post('http://127.0.0.1:3000/api/auth/login', {
      email: 'bassirou.ouedraogo@mct.ci',
      password: 'P@ssword'
    });
    
    console.log('📝 Login response:', JSON.stringify(loginResponse.data, null, 2));
    
    const token = loginResponse.data.data?.accessToken || loginResponse.data.data?.token || loginResponse.data.token;
    const userId = loginResponse.data.data?.user?.id || loginResponse.data.user?.id;
    console.log('✅ Token obtenu pour user ID:', userId);
    
    // Récupérer les notifications
    const notifResponse = await axios.get('http://127.0.0.1:3000/api/notifications', {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    console.log('\n📊 Nombre de notifications:', notifResponse.data.data.length);
    console.log('\n📋 Les 10 premières notifications:');
    notifResponse.data.data.slice(0, 10).forEach(n => {
      console.log(`  - ID: ${n.id}, Type: ${n.type}, Titre: ${n.title}`);
    });
  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
  }
}

test();
