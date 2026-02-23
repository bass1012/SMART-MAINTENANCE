/**
 * Script de test de configuration SMTP mail.mct.ci
 * 
 * Usage: node test-smtp-mct.js [email-destinataire]
 * Exemple: node test-smtp-mct.js test@example.com
 */

require('dotenv').config();
const nodemailer = require('nodemailer');

// Email destinataire (argument ou valeur par défaut)
const recipientEmail = process.argv[2] || 'supportuser@mct.ci';

console.log('🧪 Test Configuration SMTP MCT\n');
console.log('📋 Configuration détectée:');
console.log(`   - Serveur SMTP: ${process.env.SMTP_HOST}`);
console.log(`   - Port: ${process.env.SMTP_PORT}`);
console.log(`   - Sécurisé: ${process.env.SMTP_SECURE}`);
console.log(`   - Utilisateur: ${process.env.SMTP_USER}`);
console.log(`   - From: ${process.env.SMTP_FROM}`);
console.log(`   - From Name: ${process.env.SMTP_FROM_NAME}`);
console.log(`   - Email activé: ${process.env.EMAIL_ENABLED !== 'false' ? 'Oui' : 'Non'}\n`);

// Créer le transporteur SMTP
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT) || 587,
  secure: process.env.SMTP_SECURE === 'true', // true pour 465, false pour 587
  auth: {
    user: process.env.SMTP_USER || process.env.EMAIL_USER,
    pass: process.env.SMTP_PASS || process.env.EMAIL_PASSWORD
  },
  tls: {
    // Ne pas échouer sur certificats invalides (développement)
    rejectUnauthorized: false
  }
});

// Email de test
const mailOptions = {
  from: {
    name: process.env.SMTP_FROM_NAME || 'SMART MAINTENANCE',
    address: process.env.SMTP_FROM || process.env.EMAIL_FROM || process.env.EMAIL_USER
  },
  to: recipientEmail,
  subject: '✅ Test Configuration SMTP mail.mct.ci - SMART MAINTENANCE',
  html: `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          line-height: 1.6;
          color: #333;
          margin: 0;
          padding: 0;
          background-color: #f5f5f5;
        }
        .container {
          max-width: 600px;
          margin: 20px auto;
          background-color: #ffffff;
          border-radius: 8px;
          overflow: hidden;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .header {
          background: linear-gradient(135deg, #0a543d 0%, #0d6b4d 100%);
          color: white;
          padding: 30px 20px;
          text-align: center;
        }
        .header h1 {
          margin: 0 0 10px 0;
          font-size: 28px;
        }
        .content {
          padding: 30px 20px;
        }
        .success-icon {
          font-size: 64px;
          text-align: center;
          margin: 20px 0;
        }
        .info-box {
          background-color: #f8f9fa;
          padding: 20px;
          border-radius: 6px;
          margin: 20px 0;
          border-left: 4px solid #0a543d;
        }
        .info-row {
          display: flex;
          justify-content: space-between;
          padding: 8px 0;
          border-bottom: 1px solid #e0e0e0;
        }
        .info-row:last-child {
          border-bottom: none;
        }
        .info-label {
          font-weight: 600;
          color: #666;
        }
        .info-value {
          color: #333;
          text-align: right;
        }
        .status-badge {
          display: inline-block;
          padding: 6px 14px;
          border-radius: 20px;
          font-size: 14px;
          font-weight: 600;
          background-color: #4caf50;
          color: white;
        }
        .footer {
          background-color: #f5f5f5;
          padding: 20px;
          text-align: center;
          font-size: 12px;
          color: #666;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>✅ Test SMTP Réussi</h1>
          <p>Configuration mail.mct.ci validée</p>
        </div>
        
        <div class="content">
          <div class="success-icon">🎉</div>
          
          <h2>Configuration SMTP Opérationnelle</h2>
          <p>Ce message confirme que la configuration SMTP du serveur <strong>mail.mct.ci</strong> fonctionne correctement.</p>
          
          <div class="info-box">
            <div class="info-row">
              <span class="info-label">Serveur SMTP</span>
              <span class="info-value">${process.env.SMTP_HOST}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Port</span>
              <span class="info-value">${process.env.SMTP_PORT}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Expéditeur</span>
              <span class="info-value">${process.env.SMTP_FROM}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Destinataire</span>
              <span class="info-value">${recipientEmail}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Date/Heure</span>
              <span class="info-value">${new Date().toLocaleString('fr-FR')}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Status</span>
              <span class="info-value"><span class="status-badge">✅ Opérationnel</span></span>
            </div>
          </div>
          
          <p><strong>🎯 Système d'emails transactionnels prêt :</strong></p>
          <ul>
            <li>✅ 6 emails interventions</li>
            <li>✅ 4 emails commandes</li>
            <li>✅ 3 emails devis</li>
            <li>✅ 3 emails réclamations</li>
            <li>✅ 2 emails contrats</li>
          </ul>
          
          <p style="color: #666; font-size: 14px; margin-top: 30px;">
            <strong>Note:</strong> Si vous recevez ce message, le serveur SMTP est correctement configuré et les 18 emails transactionnels seront envoyés automatiquement lors des événements business de l'application SMART MAINTENANCE.
          </p>
        </div>
        
        <div class="footer">
          <p><strong>SMART MAINTENANCE</strong> - Votre partenaire de confiance</p>
          <p>Email: ${process.env.SMTP_FROM} | Serveur: ${process.env.SMTP_HOST}</p>
          <p style="margin-top: 10px;">
            Cet email de test a été envoyé automatiquement par le système.
          </p>
        </div>
      </div>
    </body>
    </html>
  `
};

// Test de connexion et envoi
async function testSMTP() {
  try {
    // 1. Vérifier la connexion
    console.log('🔌 Test de connexion au serveur SMTP...');
    await transporter.verify();
    console.log('✅ Connexion au serveur SMTP réussie!\n');
    
    // 2. Envoyer l'email de test
    console.log(`📧 Envoi de l'email de test vers ${recipientEmail}...`);
    const info = await transporter.sendMail(mailOptions);
    
    console.log('✅ Email envoyé avec succès!\n');
    console.log('📋 Détails:');
    console.log(`   - Message ID: ${info.messageId}`);
    console.log(`   - Destinataire accepté: ${info.accepted.join(', ')}`);
    if (info.rejected.length > 0) {
      console.log(`   - Destinataire rejeté: ${info.rejected.join(', ')}`);
    }
    console.log(`   - Réponse serveur: ${info.response}\n`);
    
    console.log('🎉 Test terminé avec succès!');
    console.log('\n💡 Conseils:');
    console.log('   1. Vérifiez la réception dans la boîte email');
    console.log('   2. Vérifiez aussi le dossier spam/indésirables');
    console.log('   3. Les 18 emails transactionnels sont maintenant opérationnels\n');
    
    process.exit(0);
    
  } catch (error) {
    console.error('\n❌ Erreur lors du test SMTP:\n');
    console.error(`Type: ${error.name}`);
    console.error(`Message: ${error.message}`);
    
    if (error.code) {
      console.error(`Code: ${error.code}`);
    }
    
    if (error.response) {
      console.error(`Réponse serveur: ${error.response}`);
    }
    
    console.error('\n🔧 Vérifications suggérées:');
    console.error('   1. Vérifier les identifiants SMTP (SMTP_USER, SMTP_PASS)');
    console.error('   2. Vérifier le serveur SMTP (mail.mct.ci accessible?)');
    console.error('   3. Vérifier le port (587 pour TLS/STARTTLS)');
    console.error('   4. Vérifier le firewall (port 587 ouvert?)');
    console.error('   5. Contacter l\'administrateur serveur si problème persiste\n');
    
    process.exit(1);
  }
}

// Lancer le test
testSMTP();
