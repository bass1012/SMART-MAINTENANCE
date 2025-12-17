const nodemailer = require('nodemailer');
const { generateInvoicePDF } = require('./pdfService');

/**
 * Service d'envoi d'emails
 */

// Configuration du transporteur d'emails
const createTransporter = () => {
  // Configuration pour Gmail (à adapter selon votre service)
  if (process.env.EMAIL_SERVICE === 'gmail') {
    return nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASSWORD // Utiliser un mot de passe d'application
      }
    });
  }
  
  // Configuration SMTP générique
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: process.env.SMTP_PORT || 587,
    secure: process.env.SMTP_SECURE === 'true', // true pour 465, false pour autres ports
    auth: {
      user: process.env.SMTP_USER || process.env.EMAIL_USER,
      pass: process.env.SMTP_PASSWORD || process.env.EMAIL_PASSWORD
    }
  });
};

/**
 * Envoyer un email avec la facture en pièce jointe
 */
const sendInvoiceEmail = async (order, customerEmail) => {
  try {
    const transporter = createTransporter();
    
    // Générer le PDF de la facture
    const pdfBuffer = await generateInvoicePDF(order);
    
    const customer = order.customer || {};
    const customerName = `${customer.first_name || ''} ${customer.last_name || ''}`.trim() || 'Client';
    
    // Configuration de l'email
    const mailOptions = {
      from: {
        name: 'MCT Maintenance',
        address: process.env.EMAIL_FROM || process.env.EMAIL_USER
      },
      to: customerEmail || customer.email,
      subject: `Facture ${order.reference || `#${order.id}`} - MCT Maintenance`,
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body {
              font-family: Arial, sans-serif;
              line-height: 1.6;
              color: #333;
            }
            .container {
              max-width: 600px;
              margin: 0 auto;
              padding: 20px;
            }
            .header {
              background-color: #0a543d;
              color: white;
              padding: 20px;
              text-align: center;
              border-radius: 5px 5px 0 0;
            }
            .content {
              background-color: #f9f9f9;
              padding: 30px;
              border: 1px solid #e0e0e0;
            }
            .button {
              display: inline-block;
              padding: 12px 30px;
              background-color: #0a543d;
              color: white;
              text-decoration: none;
              border-radius: 5px;
              margin: 20px 0;
            }
            .footer {
              text-align: center;
              padding: 20px;
              color: #666;
              font-size: 12px;
            }
            .info-box {
              background-color: white;
              padding: 15px;
              margin: 15px 0;
              border-left: 4px solid #0a543d;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>MCT Maintenance</h1>
              <p>Votre facture est prête</p>
            </div>
            
            <div class="content">
              <h2>Bonjour ${customerName},</h2>
              
              <p>Merci pour votre commande ! Nous vous confirmons que votre commande a bien été enregistrée.</p>
              
              <div class="info-box">
                <strong>Référence de commande:</strong> ${order.reference || `#${order.id}`}<br>
                <strong>Date:</strong> ${order.createdAt ? new Date(order.createdAt).toLocaleDateString('fr-FR') : new Date().toLocaleDateString('fr-FR')}<br>
                <strong>Montant total:</strong> ${(order.totalAmount || 0).toLocaleString('fr-FR')} FCFA
              </div>
              
              <p>Vous trouverez votre facture en pièce jointe de cet email.</p>
              
              ${order.paymentStatus !== 'PAID' ? `
                <p style="color: #ff9800; font-weight: bold;">
                  ⚠️ Votre paiement est en attente. Veuillez procéder au paiement pour que nous puissions traiter votre commande.
                </p>
              ` : `
                <p style="color: #4caf50; font-weight: bold;">
                  ✅ Votre paiement a été confirmé. Nous préparons votre commande.
                </p>
              `}
              
              <p>Si vous avez des questions, n'hésitez pas à nous contacter.</p>
              
              <p>Cordialement,<br>
              <strong>L'équipe MCT Maintenance</strong></p>
            </div>
            
            <div class="footer">
              <p>MCT Maintenance - Service de maintenance professionnel</p>
              <p>Email: contact@mct-maintenance.com | Téléphone: +225 XX XX XX XX XX</p>
              <p style="margin-top: 10px; font-size: 10px;">
                Cet email a été envoyé automatiquement, merci de ne pas y répondre directement.
              </p>
            </div>
          </div>
        </body>
        </html>
      `,
      attachments: [
        {
          filename: `facture-${order.reference || order.id}.pdf`,
          content: pdfBuffer,
          contentType: 'application/pdf'
        }
      ]
    };
    
    // Envoyer l'email
    const info = await transporter.sendMail(mailOptions);
    
    console.log('Email envoyé:', info.messageId);
    
    return {
      success: true,
      messageId: info.messageId,
      recipient: customerEmail || customer.email
    };
    
  } catch (error) {
    console.error('Erreur lors de l\'envoi de l\'email:', error);
    throw new Error(`Erreur d'envoi d'email: ${error.message}`);
  }
};

/**
 * Envoyer un email de confirmation de paiement
 */
const sendPaymentConfirmationEmail = async (order, customerEmail) => {
  try {
    const transporter = createTransporter();
    
    const customer = order.customer || {};
    const customerName = `${customer.first_name || ''} ${customer.last_name || ''}`.trim() || 'Client';
    
    const mailOptions = {
      from: {
        name: 'MCT Maintenance',
        address: process.env.EMAIL_FROM || process.env.EMAIL_USER
      },
      to: customerEmail || customer.email,
      subject: `Confirmation de paiement - Commande ${order.reference || `#${order.id}`}`,
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body {
              font-family: Arial, sans-serif;
              line-height: 1.6;
              color: #333;
            }
            .container {
              max-width: 600px;
              margin: 0 auto;
              padding: 20px;
            }
            .header {
              background-color: #4caf50;
              color: white;
              padding: 20px;
              text-align: center;
              border-radius: 5px 5px 0 0;
            }
            .content {
              background-color: #f9f9f9;
              padding: 30px;
              border: 1px solid #e0e0e0;
            }
            .success-icon {
              font-size: 48px;
              text-align: center;
              margin: 20px 0;
            }
            .info-box {
              background-color: white;
              padding: 15px;
              margin: 15px 0;
              border-left: 4px solid #4caf50;
            }
            .footer {
              text-align: center;
              padding: 20px;
              color: #666;
              font-size: 12px;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Paiement confirmé !</h1>
            </div>
            
            <div class="content">
              <div class="success-icon">✅</div>
              
              <h2>Bonjour ${customerName},</h2>
              
              <p>Nous avons bien reçu votre paiement pour la commande <strong>${order.reference || `#${order.id}`}</strong>.</p>
              
              <div class="info-box">
                <strong>Montant payé:</strong> ${(order.totalAmount || 0).toLocaleString('fr-FR')} FCFA<br>
                <strong>Date du paiement:</strong> ${new Date().toLocaleDateString('fr-FR')}<br>
                <strong>Mode de paiement:</strong> ${order.paymentMethod || 'Non spécifié'}
              </div>
              
              <p>Votre commande est maintenant en cours de traitement. Nous vous tiendrons informé de son avancement.</p>
              
              <p>Merci pour votre confiance !</p>
              
              <p>Cordialement,<br>
              <strong>L'équipe MCT Maintenance</strong></p>
            </div>
            
            <div class="footer">
              <p>MCT Maintenance - Service de maintenance professionnel</p>
              <p>Email: contact@mct-maintenance.com</p>
            </div>
          </div>
        </body>
        </html>
      `
    };
    
    const info = await transporter.sendMail(mailOptions);
    
    console.log('Email de confirmation envoyé:', info.messageId);
    
    return {
      success: true,
      messageId: info.messageId
    };
    
  } catch (error) {
    console.error('Erreur lors de l\'envoi de l\'email de confirmation:', error);
    throw error;
  }
};

/**
 * Tester la configuration email
 */
const testEmailConfiguration = async () => {
  try {
    const transporter = createTransporter();
    await transporter.verify();
    console.log('✅ Configuration email valide');
    return true;
  } catch (error) {
    console.error('❌ Erreur de configuration email:', error.message);
    return false;
  }
};

module.exports = {
  createTransporter,
  sendInvoiceEmail,
  sendPaymentConfirmationEmail,
  testEmailConfiguration
};
