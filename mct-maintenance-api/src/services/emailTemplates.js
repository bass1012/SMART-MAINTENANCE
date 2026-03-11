/**
 * Templates d'emails transactionnels
 * 18 templates pour interventions, commandes, devis, réclamations, contrats
 */

const baseStyle = `
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
    background-color: white;
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
    font-size: 24px;
  }
  .content {
    padding: 30px;
  }
  .content h2 {
    color: #0a543d;
    margin-top: 0;
  }
  .info-box {
    background-color: #f9f9f9;
    border-left: 4px solid #0a543d;
    padding: 15px;
    margin: 20px 0;
  }
  .info-row {
    display: flex;
    justify-content: space-between;
    padding: 8px 0;
    border-bottom: 1px solid #eee;
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
  }
  .button {
    display: inline-block;
    padding: 12px 30px;
    background-color: #0a543d;
    color: white !important;
    text-decoration: none;
    border-radius: 5px;
    margin: 20px 0;
    font-weight: 600;
  }
  .button:hover {
    background-color: #0d6b4d;
  }
  .status-badge {
    display: inline-block;
    padding: 5px 12px;
    border-radius: 15px;
    font-size: 12px;
    font-weight: 600;
    text-transform: uppercase;
  }
  .status-pending { background-color: #fff3cd; color: #856404; }
  .status-in-progress { background-color: #cce5ff; color: #004085; }
  .status-completed { background-color: #d4edda; color: #155724; }
  .status-cancelled { background-color: #f8d7da; color: #721c24; }
  .footer {
    background-color: #f9f9f9;
    padding: 20px;
    text-align: center;
    color: #666;
    font-size: 12px;
  }
  .footer p {
    margin: 5px 0;
  }
`;

// ==================== INTERVENTIONS (6 emails) ====================

/**
 * 1. Intervention créée - Email client
 */
const interventionCreatedTemplate = (intervention, customer) => ({
  subject: `Nouvelle intervention #${intervention.id} - SMART MAINTENANCE`,
  html: `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; background-color: #f5f5f5;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 20px 0;">
        <tr>
          <td align="center">
            <table width="600" cellpadding="0" cellspacing="0" style="background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
              <!-- Header -->
              <tr>
                <td style="background: linear-gradient(135deg, #0a543d 0%, #0d6b4d 100%); color: white; padding: 30px 20px; text-align: center;">
                  <h1 style="margin: 0 0 10px 0; font-size: 24px;">✅ Intervention créée</h1>
                  <p style="margin: 0; font-size: 14px;">Votre demande a été enregistrée</p>
                </td>
              </tr>
              
              <!-- Content -->
              <tr>
                <td style="padding: 30px;">
                  <h2 style="color: #0a543d; margin-top: 0; font-size: 20px;">Bonjour ${customer.first_name} ${customer.last_name},</h2>
                  
                  <p style="margin: 15px 0;">Nous avons bien reçu votre demande d'intervention. Notre équipe va traiter votre demande dans les plus brefs délais.</p>
                  
                  <!-- Info Box -->
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f9f9f9; border-left: 4px solid #0a543d; margin: 20px 0;">
                    <tr>
                      <td style="padding: 15px;">
                        <table width="100%" cellpadding="8" cellspacing="0">
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; width: 50%;">Numéro d'intervention</td>
                            <td style="color: #333; text-align: right;">#${intervention.id}</td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding-top: 8px;">Type</td>
                            <td style="color: #333; text-align: right; padding-top: 8px;">${intervention.intervention_type || 'Standard'}</td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding-top: 8px;">Priorité</td>
                            <td style="color: #333; text-align: right; padding-top: 8px;">${intervention.priority || 'Normale'}</td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding-top: 8px;">Date souhaitée</td>
                            <td style="color: #333; text-align: right; padding-top: 8px;">${intervention.scheduled_date ? new Date(intervention.scheduled_date).toLocaleDateString('fr-FR') : 'Non spécifiée'}</td>
                          </tr>
                          <tr>
                            <td style="font-weight: 600; color: #666; padding-top: 8px;">Statut</td>
                            <td style="text-align: right; padding-top: 8px;">
                              <span style="display: inline-block; padding: 5px 12px; border-radius: 15px; font-size: 12px; font-weight: 600; text-transform: uppercase; background-color: #fff3cd; color: #856404;">${intervention.status}</span>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                  
                  <p style="margin: 20px 0 5px 0;"><strong>Description du problème :</strong></p>
                  <p style="margin: 5px 0 20px 0; color: #555;">${intervention.description || 'Non spécifiée'}</p>
                  
                  <p style="margin: 20px 0;">Vous recevrez une notification dès qu'un technicien sera assigné à votre intervention.</p>
                </td>
              </tr>
              
              <!-- Footer -->
              <tr>
                <td style="background-color: #f9f9f9; padding: 20px; text-align: center; color: #666; font-size: 12px;">
                  <p style="margin: 5px 0; font-weight: bold;">SMART MAINTENANCE</p>
                  <p style="margin: 5px 0;">Email: smartmaintenance@mct.ci | Téléphone: +225 XX XX XX XX XX</p>
                  <p style="margin: 10px 0 5px 0;">Cet email a été envoyé automatiquement, merci de ne pas y répondre directement.</p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
  `
});

/**
 * 2. Intervention assignée - Email technicien
 */
const interventionAssignedTemplate = (intervention, technician, customer) => ({
  subject: `Nouvelle mission #${intervention.id} assignée - SMART MAINTENANCE`,
  html: `
    <!DOCTYPE html>
    <html>
    <head><style>${baseStyle}</style></head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🔧 Nouvelle mission assignée</h1>
          <p>Intervention #${intervention.id}</p>
        </div>
        
        <div class="content">
          <h2>Bonjour ${technician.first_name},</h2>
          
          <p>Une nouvelle intervention vous a été assignée. Merci de prendre contact avec le client dans les plus brefs délais.</p>
          
          <div class="info-box">
            <h3 style="margin-top: 0; color: #0a543d;">Détails de l'intervention</h3>
            <div class="info-row">
              <span class="info-label">Numéro</span>
              <span class="info-value">#${intervention.id}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Type</span>
              <span class="info-value">${intervention.intervention_type || 'Standard'}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Priorité</span>
              <span class="info-value">${intervention.priority || 'Normale'}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Date prévue</span>
              <span class="info-value">${intervention.scheduled_date ? new Date(intervention.scheduled_date).toLocaleDateString('fr-FR') : 'À définir'}</span>
            </div>
          </div>
          
          <div class="info-box">
            <h3 style="margin-top: 0; color: #0a543d;">Informations client</h3>
            <div class="info-row">
              <span class="info-label">Nom</span>
              <span class="info-value">${customer.first_name} ${customer.last_name}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Téléphone</span>
              <span class="info-value">${customer.phone || 'Non renseigné'}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Adresse</span>
              <span class="info-value">${intervention.address || customer.address || 'Non renseignée'}</span>
            </div>
          </div>
          
          <p><strong>Description du problème :</strong><br>
          ${intervention.description || 'Non spécifiée'}</p>
          
          <p>Connectez-vous à l'application mobile pour accepter cette mission et démarrer l'intervention.</p>
        </div>
        
        <div class="footer">
          <p><strong>SMART MAINTENANCE</strong></p>
          <p>Email: contact@mct-maintenance.com | Téléphone: +225 XX XX XX XX XX</p>
        </div>
      </div>
    </body>
    </html>
  `
});

/**
 * 3. Intervention démarrée - Email client
 */
const interventionStartedTemplate = (intervention, technician, customer) => ({
  subject: `Le technicien est en route - Intervention #${intervention.id}`,
  html: `
    <!DOCTYPE html>
    <html>
    <head><style>${baseStyle}</style></head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🚗 Technicien en route</h1>
          <p>Intervention #${intervention.id}</p>
        </div>
        
        <div class="content">
          <h2>Bonjour ${customer.first_name},</h2>
          
          <p>Votre technicien est en route vers votre domicile pour l'intervention.</p>
          
          <div class="info-box">
            <h3 style="margin-top: 0; color: #0a543d;">Votre technicien</h3>
            <div class="info-row">
              <span class="info-label">Nom</span>
              <span class="info-value">${technician.first_name} ${technician.last_name}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Téléphone</span>
              <span class="info-value">${technician.phone || 'Non disponible'}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Statut</span>
              <span class="info-value"><span class="status-badge status-in-progress">En route</span></span>
            </div>
          </div>
          
          <p>Le technicien devrait arriver d'ici peu. Si vous avez des questions, n'hésitez pas à le contacter directement.</p>
        </div>
        
        <div class="footer">
          <p><strong>SMART MAINTENANCE</strong></p>
          <p>Email: contact@mct-maintenance.com | Téléphone: +225 XX XX XX XX XX</p>
        </div>
      </div>
    </body>
    </html>
  `
});

/**
 * 4. Intervention terminée - Email client
 */
const interventionCompletedTemplate = (intervention, customer) => ({
  subject: `Intervention #${intervention.id} terminée - Votre avis compte !`,
  html: `
    <!DOCTYPE html>
    <html>
    <head><style>${baseStyle}</style></head>
    <body>
      <div class="container">
        <div class="header">
          <h1>✅ Intervention terminée</h1>
          <p>Merci de votre confiance</p>
        </div>
        
        <div class="content">
          <h2>Bonjour ${customer.first_name},</h2>
          
          <p>Votre intervention a été terminée avec succès.</p>
          
          <div class="info-box">
            <div class="info-row">
              <span class="info-label">Numéro</span>
              <span class="info-value">#${intervention.id}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Type</span>
              <span class="info-value">${intervention.intervention_type || 'Standard'}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Date de réalisation</span>
              <span class="info-value">${new Date().toLocaleDateString('fr-FR')}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Statut</span>
              <span class="info-value"><span class="status-badge status-completed">Terminée</span></span>
            </div>
          </div>
          
          <p><strong>Votre avis nous intéresse !</strong></p>
          <p>Merci de prendre quelques instants pour évaluer la qualité du service de notre technicien. Votre retour nous aide à améliorer nos services.</p>
          
          <p>Vous pouvez évaluer cette intervention depuis votre application mobile dans la section "Mes interventions".</p>
        </div>
        
        <div class="footer">
          <p><strong>SMART MAINTENANCE</strong></p>
          <p>Email: contact@mct-maintenance.com | Téléphone: +225 XX XX XX XX XX</p>
        </div>
      </div>
    </body>
    </html>
  `
});

/**
 * 5. Rapport d'intervention soumis - Email client
 */
const interventionReportTemplate = (intervention, report, customer) => ({
  subject: `Rapport d'intervention #${intervention.id} disponible`,
  html: `
    <!DOCTYPE html>
    <html>
    <head><style>${baseStyle}</style></head>
    <body>
      <div class="container">
        <div class="header">
          <h1>📋 Rapport disponible</h1>
          <p>Intervention #${intervention.id}</p>
        </div>
        
        <div class="content">
          <h2>Bonjour ${customer.first_name},</h2>
          
          <p>Le rapport détaillé de votre intervention est maintenant disponible.</p>
          
          <div class="info-box">
            <h3 style="margin-top: 0; color: #0a543d;">Résumé de l'intervention</h3>
            <p><strong>Travaux effectués :</strong><br>
            ${report.work_description || 'Voir le rapport complet'}</p>
            
            ${report.parts_used ? `
            <p><strong>Pièces utilisées :</strong><br>
            ${report.parts_used}</p>
            ` : ''}
            
            <p><strong>Durée :</strong> ${report.duration || 'Non spécifiée'}</p>
          </div>
          
          <p>Vous pouvez consulter le rapport complet et les photos (avant/après) depuis votre application mobile.</p>
        </div>
        
        <div class="footer">
          <p><strong>SMART MAINTENANCE</strong></p>
          <p>Email: contact@mct-maintenance.com | Téléphone: +225 XX XX XX XX XX</p>
        </div>
      </div>
    </body>
    </html>
  `
});

/**
 * 6. Évaluation reçue - Email technicien
 */
const interventionRatingTemplate = (intervention, rating, technician) => ({
  subject: `Nouvelle évaluation reçue - Intervention #${intervention.id}`,
  html: `
    <!DOCTYPE html>
    <html>
    <head><style>${baseStyle}</style></head>
    <body>
      <div class="container">
        <div class="header">
          <h1>⭐ Nouvelle évaluation</h1>
          <p>Intervention #${intervention.id}</p>
        </div>
        
        <div class="content">
          <h2>Bonjour ${technician.first_name},</h2>
          
          <p>Vous avez reçu une nouvelle évaluation de la part du client.</p>
          
          <div class="info-box">
            <div class="info-row">
              <span class="info-label">Note</span>
              <span class="info-value" style="font-size: 20px; color: #ffa500;">
                ${'⭐'.repeat(Math.round(rating.rating || 0))}
                <strong>${rating.rating}/5</strong>
              </span>
            </div>
            ${rating.comment ? `
            <div class="info-row">
              <span class="info-label">Commentaire</span>
              <span class="info-value">${rating.comment}</span>
            </div>
            ` : ''}
          </div>
          
          <p>${rating.rating >= 4 ? '🎉 Excellent travail ! Continuez comme ça !' : 'Merci pour votre professionnalisme. Continuez vos efforts pour satisfaire nos clients.'}</p>
        </div>
        
        <div class="footer">
          <p><strong>SMART MAINTENANCE</strong></p>
          <p>Email: contact@mct-maintenance.com | Téléphone: +225 XX XX XX XX XX</p>
        </div>
      </div>
    </body>
    </html>
  `
});

// ==================== COMMANDES (4 emails) ====================

/**
 * 7. Commande créée - Email client
 */
const orderCreatedTemplate = (order, customer) => ({
  subject: `Commande #${order.reference || order.id} confirmée - SMART MAINTENANCE`,
  html: `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; background-color: #f5f5f5;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 20px 0;">
        <tr>
          <td align="center">
            <table width="600" cellpadding="0" cellspacing="0" style="background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
              <!-- Header -->
              <tr>
                <td style="background: linear-gradient(135deg, #0a543d 0%, #0d6b4d 100%); color: white; padding: 30px 20px; text-align: center;">
                  <h1 style="margin: 0 0 10px 0; font-size: 24px;">🛒 Commande confirmée</h1>
                  <p style="margin: 0; font-size: 14px;">Commande #${order.reference || order.id}</p>
                </td>
              </tr>
              
              <!-- Content -->
              <tr>
                <td style="padding: 30px;">
                  <h2 style="color: #0a543d; margin-top: 0; font-size: 20px;">Bonjour ${customer.first_name || 'Client'},</h2>
                  
                  <p style="margin: 15px 0;">Nous avons bien reçu votre commande. Merci de votre confiance !</p>
                  
                  <!-- Info Box -->
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f9f9f9; border-left: 4px solid #0a543d; margin: 20px 0;">
                    <tr>
                      <td style="padding: 15px;">
                        <table width="100%" cellpadding="0" cellspacing="0">
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; width: 50%; padding: 8px 8px 8px 0;">Numéro de commande</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;"><strong>#${order.reference || order.id}</strong></td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Date</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${order.createdAt || order.created_at ? new Date(order.createdAt || order.created_at).toLocaleDateString('fr-FR') : new Date().toLocaleDateString('fr-FR')}</td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Montant total</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;"><strong>${(order.totalAmount || order.total_amount || 0).toLocaleString('fr-FR')} FCFA</strong></td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Mode de paiement</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${order.paymentMethod || order.payment_method || 'Non spécifié'}</td>
                          </tr>
                          <tr>
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Statut</td>
                            <td style="text-align: right; padding: 8px 0 8px 8px;">
                              <span style="display: inline-block; padding: 5px 12px; border-radius: 15px; font-size: 12px; font-weight: 600; text-transform: uppercase; background-color: #fff3cd; color: #856404;">En cours</span>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                  
                  <p style="margin: 20px 0 5px 0;"><strong>Adresse de livraison :</strong></p>
                  <p style="margin: 5px 0 20px 0; color: #555;">${order.deliveryAddress || order.delivery_address || order.shippingAddress || order.shipping_address || customer.address || 'Non spécifiée'}</p>
                  
                  <p style="margin: 20px 0;">Votre commande est en cours de préparation. Vous recevrez une notification dès son expédition.</p>
                </td>
              </tr>
              
              <!-- Footer -->
              <tr>
                <td style="background-color: #f9f9f9; padding: 20px; text-align: center; color: #666; font-size: 12px;">
                  <p style="margin: 5px 0; font-weight: bold;">SMART MAINTENANCE</p>
                  <p style="margin: 5px 0;">Email: contact@mct.ci | Téléphone: +225 07 09 09 09 42</p>
                  <p style="margin: 10px 0 5px 0;">Cet email a été envoyé automatiquement, merci de ne pas y répondre directement.</p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
  `
});

/**
 * 8. Commande en préparation - Email client
 */
const orderConfirmedTemplate = (order, customer) => ({
  subject: `Commande #${order.reference || order.id} en préparation`,
  html: `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; background-color: #f5f5f5;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 20px 0;">
        <tr>
          <td align="center">
            <table width="600" cellpadding="0" cellspacing="0" style="background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
              <!-- Header -->
              <tr>
                <td style="background: linear-gradient(135deg, #0a543d 0%, #0d6b4d 100%); color: white; padding: 30px 20px; text-align: center;">
                  <h1 style="margin: 0 0 10px 0; font-size: 24px;">📦 Préparation en cours</h1>
                  <p style="margin: 0; font-size: 14px;">Commande #${order.reference || order.id}</p>
                </td>
              </tr>
              
              <!-- Content -->
              <tr>
                <td style="padding: 30px;">
                  <h2 style="color: #0a543d; margin-top: 0; font-size: 20px;">Bonjour ${customer.first_name || 'Client'},</h2>
                  
                  <p style="margin: 15px 0;">Votre commande est actuellement en cours de préparation dans nos entrepôts.</p>
                  
                  <!-- Info Box -->
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f9f9f9; border-left: 4px solid #0a543d; margin: 20px 0;">
                    <tr>
                      <td style="padding: 15px;">
                        <table width="100%" cellpadding="0" cellspacing="0">
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; width: 50%; padding: 8px 8px 8px 0;">Numéro de commande</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;"><strong>#${order.reference || order.id}</strong></td>
                          </tr>
                          <tr>
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Statut</td>
                            <td style="text-align: right; padding: 8px 0 8px 8px;">
                              <span style="display: inline-block; padding: 5px 12px; border-radius: 15px; font-size: 12px; font-weight: 600; text-transform: uppercase; background-color: #cce5ff; color: #004085;">En préparation</span>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                  
                  <p style="margin: 20px 0;">Votre colis sera bientôt prêt pour l'expédition. Nous vous tiendrons informé de chaque étape.</p>
                </td>
              </tr>
              
              <!-- Footer -->
              <tr>
                <td style="background-color: #f9f9f9; padding: 20px; text-align: center; color: #666; font-size: 12px;">
                  <p style="margin: 5px 0; font-weight: bold;">SMART MAINTENANCE</p>
                  <p style="margin: 5px 0;">Email: contact@mct.ci | Téléphone: +225 07 09 09 09 42</p>
                  <p style="margin: 10px 0 5px 0;">Cet email a été envoyé automatiquement, merci de ne pas y répondre directement.</p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
  `
});

/**
 * 9. Commande expédiée - Email client
 */
const orderShippedTemplate = (order, customer) => ({
  subject: `Commande #${order.reference || order.id} expédiée - Suivi disponible`,
  html: `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; background-color: #f5f5f5;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 20px 0;">
        <tr>
          <td align="center">
            <table width="600" cellpadding="0" cellspacing="0" style="background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
              <!-- Header -->
              <tr>
                <td style="background: linear-gradient(135deg, #0a543d 0%, #0d6b4d 100%); color: white; padding: 30px 20px; text-align: center;">
                  <h1 style="margin: 0 0 10px 0; font-size: 24px;">🚚 Commande expédiée</h1>
                  <p style="margin: 0; font-size: 14px;">Commande #${order.reference || order.id}</p>
                </td>
              </tr>
              
              <!-- Content -->
              <tr>
                <td style="padding: 30px;">
                  <h2 style="color: #0a543d; margin-top: 0; font-size: 20px;">Bonjour ${customer.first_name || 'Client'},</h2>
                  
                  <p style="margin: 15px 0;">Bonne nouvelle ! Votre commande a été expédiée et est en route vers vous.</p>
                  
                  <!-- Info Box -->
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f9f9f9; border-left: 4px solid #0a543d; margin: 20px 0;">
                    <tr>
                      <td style="padding: 15px;">
                        <table width="100%" cellpadding="0" cellspacing="0">
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; width: 50%; padding: 8px 8px 8px 0;">Numéro de commande</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;"><strong>#${order.reference || order.id}</strong></td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Date d'expédition</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${new Date().toLocaleDateString('fr-FR')}</td>
                          </tr>
                          ${order.tracking_link ? `
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Suivi</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;"><a href="${order.tracking_link}" style="color: #0a543d; text-decoration: none;">Suivre mon colis</a></td>
                          </tr>
                          ` : ''}
                          <tr>
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Statut</td>
                            <td style="text-align: right; padding: 8px 0 8px 8px;">
                              <span style="display: inline-block; padding: 5px 12px; border-radius: 15px; font-size: 12px; font-weight: 600; text-transform: uppercase; background-color: #cce5ff; color: #004085;">En livraison</span>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                  
                  ${order.tracking_link ? `
                  <table width="100%" cellpadding="0" cellspacing="0" style="margin: 20px 0;">
                    <tr>
                      <td align="center">
                        <a href="${order.tracking_link}" style="display: inline-block; padding: 12px 30px; background-color: #0a543d; color: white; text-decoration: none; border-radius: 5px; font-weight: 600;">Suivre ma commande</a>
                      </td>
                    </tr>
                  </table>
                  ` : ''}
                  
                  <p style="margin: 20px 0;">Vous recevrez une notification dès la livraison de votre colis.</p>
                </td>
              </tr>
              
              <!-- Footer -->
              <tr>
                <td style="background-color: #f9f9f9; padding: 20px; text-align: center; color: #666; font-size: 12px;">
                  <p style="margin: 5px 0; font-weight: bold;">SMART MAINTENANCE</p>
                  <p style="margin: 5px 0;">Email: contact@mct.ci | Téléphone: +225 07 09 09 09 42</p>
                  <p style="margin: 10px 0 5px 0;">Cet email a été envoyé automatiquement, merci de ne pas y répondre directement.</p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
  `
});

/**
 * 10. Commande livrée - Email client
 */
const orderDeliveredTemplate = (order, customer) => ({
  subject: `Commande #${order.reference || order.id} livrée - Merci !`,
  html: `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; background-color: #f5f5f5;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 20px 0;">
        <tr>
          <td align="center">
            <table width="600" cellpadding="0" cellspacing="0" style="background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
              <!-- Header -->
              <tr>
                <td style="background: linear-gradient(135deg, #0a543d 0%, #0d6b4d 100%); color: white; padding: 30px 20px; text-align: center;">
                  <h1 style="margin: 0 0 10px 0; font-size: 24px;">✅ Commande livrée</h1>
                  <p style="margin: 0; font-size: 14px;">Merci de votre confiance !</p>
                </td>
              </tr>
              
              <!-- Content -->
              <tr>
                <td style="padding: 30px;">
                  <h2 style="color: #0a543d; margin-top: 0; font-size: 20px;">Bonjour ${customer.first_name || 'Client'},</h2>
                  
                  <p style="margin: 15px 0;">Votre commande a été livrée avec succès. Nous espérons que tout est conforme à vos attentes !</p>
                  
                  <!-- Info Box -->
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f9f9f9; border-left: 4px solid #0a543d; margin: 20px 0;">
                    <tr>
                      <td style="padding: 15px;">
                        <table width="100%" cellpadding="0" cellspacing="0">
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; width: 50%; padding: 8px 8px 8px 0;">Numéro de commande</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;"><strong>#${order.reference || order.id}</strong></td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Date de livraison</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${new Date().toLocaleDateString('fr-FR')}</td>
                          </tr>
                          <tr>
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Statut</td>
                            <td style="text-align: right; padding: 8px 0 8px 8px;">
                              <span style="display: inline-block; padding: 5px 12px; border-radius: 15px; font-size: 12px; font-weight: 600; text-transform: uppercase; background-color: #d4edda; color: #155724;">Livrée</span>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                  
                  <p style="margin: 20px 0 5px 0;"><strong>Votre avis nous intéresse !</strong></p>
                  <p style="margin: 5px 0 20px 0;">Merci de prendre un moment pour évaluer votre expérience d'achat. Vos retours nous aident à améliorer nos services.</p>
                  
                  <p style="margin: 20px 0;">Si vous rencontrez le moindre problème avec votre commande, n'hésitez pas à nous contacter.</p>
                </td>
              </tr>
              
              <!-- Footer -->
              <tr>
                <td style="background-color: #f9f9f9; padding: 20px; text-align: center; color: #666; font-size: 12px;">
                  <p style="margin: 5px 0; font-weight: bold;">SMART MAINTENANCE</p>
                  <p style="margin: 5px 0;">Email: contact@mct.ci | Téléphone: +225 07 09 09 09 42</p>
                  <p style="margin: 10px 0 5px 0;">Cet email a été envoyé automatiquement, merci de ne pas y répondre directement.</p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
  `
});

// ==================== DEVIS (3 emails) ====================

/**
 * 11. Devis créé - Email client
 */
const quoteCreatedTemplate = (quote, customer) => ({
  subject: `Nouveau devis #${quote.reference || quote.id} - SMART MAINTENANCE`,
  html: `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; background-color: #f5f5f5;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 20px 0;">
        <tr>
          <td align="center">
            <table width="600" cellpadding="0" cellspacing="0" style="background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
              <!-- Header -->
              <tr>
                <td style="background: linear-gradient(135deg, #0a543d 0%, #0d6b4d 100%); color: white; padding: 30px 20px; text-align: center;">
                  <h1 style="margin: 0 0 10px 0; font-size: 24px;">📄 Nouveau devis disponible</h1>
                  <p style="margin: 0; font-size: 14px;">Devis #${quote.reference || quote.id}</p>
                </td>
              </tr>
              
              <!-- Content -->
              <tr>
                <td style="padding: 30px;">
                  <h2 style="color: #0a543d; margin-top: 0; font-size: 20px;">Bonjour ${customer.first_name || 'Client'},</h2>
                  
                  <p style="margin: 15px 0;">Nous avons le plaisir de vous transmettre votre devis personnalisé.</p>
                  
                  <!-- Info Box -->
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f9f9f9; border-left: 4px solid #0a543d; margin: 20px 0;">
                    <tr>
                      <td style="padding: 15px;">
                        <table width="100%" cellpadding="0" cellspacing="0">
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; width: 50%; padding: 8px 8px 8px 0;">Numéro de devis</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;"><strong>#${quote.reference || quote.id}</strong></td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Date</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${new Date(quote.created_at).toLocaleDateString('fr-FR')}</td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Montant total</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;"><strong>${(quote.total || quote.total_amount)?.toLocaleString('fr-FR')} FCFA</strong></td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Validité</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${quote.valid_until ? new Date(quote.valid_until).toLocaleDateString('fr-FR') : '30 jours'}</td>
                          </tr>
                          <tr>
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Statut</td>
                            <td style="text-align: right; padding: 8px 0 8px 8px;">
                              <span style="display: inline-block; padding: 5px 12px; border-radius: 15px; font-size: 12px; font-weight: 600; text-transform: uppercase; background-color: #fff3cd; color: #856404;">En attente</span>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                  
                  ${quote.description ? `
                  <p style="margin: 20px 0 5px 0;"><strong>Description :</strong></p>
                  <p style="margin: 5px 0 20px 0;">${quote.description}</p>
                  ` : ''}
                  
                  <p style="margin: 20px 0;">Vous pouvez consulter, accepter ou refuser ce devis depuis votre application mobile dans la section "Mes devis".</p>
                  
                  <p style="margin: 20px 0;">Notre équipe reste à votre disposition pour toute question.</p>
                </td>
              </tr>
              
              <!-- Footer -->
              <tr>
                <td style="background-color: #f9f9f9; padding: 20px; text-align: center; color: #666; font-size: 12px;">
                  <p style="margin: 5px 0; font-weight: bold;">SMART MAINTENANCE</p>
                  <p style="margin: 5px 0;">Email: contact@mct.ci | Téléphone: +225 07 09 09 09 42</p>
                  <p style="margin: 10px 0 5px 0;">Cet email a été envoyé automatiquement, merci de ne pas y répondre directement.</p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
  `
});

/**
 * 12. Devis accepté - Email admin
 */
const quoteAcceptedTemplate = (quote, customer) => ({
  subject: `✅ Devis #${quote.reference || quote.id} accepté par ${customer.first_name} ${customer.last_name}`,
  html: `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; background-color: #f5f5f5;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 20px 0;">
        <tr>
          <td align="center">
            <table width="600" cellpadding="0" cellspacing="0" style="background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
              <!-- Header -->
              <tr>
                <td style="background: linear-gradient(135deg, #0a543d 0%, #0d6b4d 100%); color: white; padding: 30px 20px; text-align: center;">
                  <h1 style="margin: 0 0 10px 0; font-size: 24px;">✅ Devis accepté</h1>
                  <p style="margin: 0; font-size: 14px;">Devis #${quote.reference || quote.id}</p>
                </td>
              </tr>
              
              <!-- Content -->
              <tr>
                <td style="padding: 30px;">
                  <h2 style="color: #0a543d; margin-top: 0; font-size: 20px;">Notification administrative</h2>
                  
                  <p style="margin: 15px 0;">Le client <strong>${customer.first_name} ${customer.last_name}</strong> vient d'accepter le devis.</p>
                  
                  <!-- Info Box -->
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f9f9f9; border-left: 4px solid #0a543d; margin: 20px 0;">
                    <tr>
                      <td style="padding: 15px;">
                        <table width="100%" cellpadding="0" cellspacing="0">
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; width: 50%; padding: 8px 8px 8px 0;">Numéro de devis</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;"><strong>#${quote.reference || quote.id}</strong></td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Client</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${customer.first_name} ${customer.last_name}</td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Email</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${customer.email}</td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Téléphone</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${customer.phone || 'Non renseigné'}</td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Montant</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;"><strong>${(quote.total || quote.total_amount)?.toLocaleString('fr-FR')} FCFA</strong></td>
                          </tr>
                          <tr>
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Date d'acceptation</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${new Date().toLocaleDateString('fr-FR')}</td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                  
                  <p style="margin: 20px 0;"><strong>Action requise :</strong> Merci de créer la commande correspondante et de contacter le client pour organiser la suite.</p>
                </td>
              </tr>
              
              <!-- Footer -->
              <tr>
                <td style="background-color: #f9f9f9; padding: 20px; text-align: center; color: #666; font-size: 12px;">
                  <p style="margin: 5px 0; font-weight: bold;">SMART MAINTENANCE</p>
                  <p style="margin: 5px 0;">Système de notification automatique</p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
  `
});

/**
 * 13. Devis rejeté - Email admin
 */
const quoteRejectedTemplate = (quote, customer) => ({
  subject: `❌ Devis #${quote.reference || quote.id} refusé par ${customer.first_name} ${customer.last_name}`,
  html: `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; background-color: #f5f5f5;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 20px 0;">
        <tr>
          <td align="center">
            <table width="600" cellpadding="0" cellspacing="0" style="background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
              <!-- Header -->
              <tr>
                <td style="background: linear-gradient(135deg, #0a543d 0%, #0d6b4d 100%); color: white; padding: 30px 20px; text-align: center;">
                  <h1 style="margin: 0 0 10px 0; font-size: 24px;">❌ Devis refusé</h1>
                  <p style="margin: 0; font-size: 14px;">Devis #${quote.reference || quote.id}</p>
                </td>
              </tr>
              
              <!-- Content -->
              <tr>
                <td style="padding: 30px;">
                  <h2 style="color: #0a543d; margin-top: 0; font-size: 20px;">Notification administrative</h2>
                  
                  <p style="margin: 15px 0;">Le client <strong>${customer.first_name} ${customer.last_name}</strong> a refusé le devis.</p>
                  
                  <!-- Info Box -->
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f9f9f9; border-left: 4px solid #0a543d; margin: 20px 0;">
                    <tr>
                      <td style="padding: 15px;">
                        <table width="100%" cellpadding="0" cellspacing="0">
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; width: 50%; padding: 8px 8px 8px 0;">Numéro de devis</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;"><strong>#${quote.reference || quote.id}</strong></td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Client</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${customer.first_name} ${customer.last_name}</td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Email</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${customer.email}</td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Montant</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${(quote.total || quote.total_amount)?.toLocaleString('fr-FR')} FCFA</td>
                          </tr>
                          <tr>
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Date de refus</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${new Date().toLocaleDateString('fr-FR')}</td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                  
                  ${quote.rejection_reason ? `
                  <p style="margin: 20px 0 5px 0;"><strong>Motif du refus :</strong></p>
                  <p style="margin: 5px 0 20px 0;">${quote.rejection_reason}</p>
                  ` : ''}
                  
                  <p style="margin: 20px 0;"><strong>Action recommandée :</strong> Vous pouvez contacter le client pour comprendre les raisons du refus et éventuellement proposer un nouveau devis ajusté.</p>
                </td>
              </tr>
              
              <!-- Footer -->
              <tr>
                <td style="background-color: #f9f9f9; padding: 20px; text-align: center; color: #666; font-size: 12px;">
                  <p style="margin: 5px 0; font-weight: bold;">SMART MAINTENANCE</p>
                  <p style="margin: 5px 0;">Système de notification automatique</p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
  `
});

// ==================== RÉCLAMATIONS (3 emails) ====================

/**
 * 14. Réclamation créée - Email admin
 */
const complaintCreatedTemplate = (complaint, customer) => ({
  subject: `🚨 Nouvelle réclamation #${complaint.id} - ${complaint.subject}`,
  html: `
    <!DOCTYPE html>
    <html>
    <head><style>${baseStyle}</style></head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🚨 Nouvelle réclamation</h1>
          <p>Réclamation #${complaint.id}</p>
        </div>
        
        <div class="content">
          <h2>Notification administrative</h2>
          
          <p>Un client vient de soumettre une réclamation nécessitant votre attention.</p>
          
          <div class="info-box">
            <div class="info-row">
              <span class="info-label">Numéro</span>
              <span class="info-value"><strong>#${complaint.id}</strong></span>
            </div>
            <div class="info-row">
              <span class="info-label">Client</span>
              <span class="info-value">${customer.first_name} ${customer.last_name}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Email</span>
              <span class="info-value">${customer.email}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Téléphone</span>
              <span class="info-value">${customer.phone || 'Non renseigné'}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Priorité</span>
              <span class="info-value"><strong>${complaint.priority || 'Normale'}</strong></span>
            </div>
            <div class="info-row">
              <span class="info-label">Date</span>
              <span class="info-value">${new Date(complaint.created_at).toLocaleDateString('fr-FR')}</span>
            </div>
          </div>
          
          <p><strong>Objet :</strong> ${complaint.subject}</p>
          
          <p><strong>Description :</strong><br>
          ${complaint.description}</p>
          
          <p style="background-color: #fff3cd; padding: 15px; border-radius: 5px; border-left: 4px solid #ffc107;">
            <strong>⚠️ Action requise :</strong> Merci de traiter cette réclamation dans les plus brefs délais et d'apporter une réponse au client.
          </p>
        </div>
        
        <div class="footer">
          <p><strong>SMART MAINTENANCE</strong></p>
          <p>Système de notification automatique</p>
        </div>
      </div>
    </body>
    </html>
  `
});

/**
 * 15. Réponse à la réclamation - Email client
 */
const complaintResponseTemplate = (complaint, response, customer) => ({
  subject: `Réponse à votre réclamation #${complaint.id} - SMART MAINTENANCE`,
  html: `
    <!DOCTYPE html>
    <html>
    <head><style>${baseStyle}</style></head>
    <body>
      <div class="container">
        <div class="header">
          <h1>💬 Réponse à votre réclamation</h1>
          <p>Réclamation #${complaint.id}</p>
        </div>
        
        <div class="content">
          <h2>Bonjour ${customer.first_name},</h2>
          
          <p>Nous avons bien pris en compte votre réclamation et sommes heureux de pouvoir vous apporter une réponse.</p>
          
          <div class="info-box">
            <div class="info-row">
              <span class="info-label">Numéro de réclamation</span>
              <span class="info-value"><strong>#${complaint.id}</strong></span>
            </div>
            <div class="info-row">
              <span class="info-label">Objet</span>
              <span class="info-value">${complaint.subject}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Statut</span>
              <span class="info-value"><span class="status-badge status-in-progress">En cours de traitement</span></span>
            </div>
          </div>
          
          <p><strong>Notre réponse :</strong></p>
          <div style="background-color: #f9f9f9; padding: 20px; border-radius: 5px; margin: 15px 0;">
            ${response}
          </div>
          
          <p>Si vous avez d'autres questions ou si cette réponse ne vous satisfait pas pleinement, n'hésitez pas à nous contacter ou à répondre via l'application.</p>
          
          <p>Nous restons à votre disposition.</p>
        </div>
        
        <div class="footer">
          <p><strong>SMART MAINTENANCE</strong></p>
          <p>Email: contact@mct-maintenance.com | Téléphone: +225 XX XX XX XX XX</p>
        </div>
      </div>
    </body>
    </html>
  `
});

/**
 * 16. Réclamation résolue - Email client
 */
const complaintResolvedTemplate = (complaint, customer) => ({
  subject: `Réclamation #${complaint.id} résolue - SMART MAINTENANCE`,
  html: `
    <!DOCTYPE html>
    <html>
    <head><style>${baseStyle}</style></head>
    <body>
      <div class="container">
        <div class="header">
          <h1>✅ Réclamation résolue</h1>
          <p>Réclamation #${complaint.id}</p>
        </div>
        
        <div class="content">
          <h2>Bonjour ${customer.first_name},</h2>
          
          <p>Votre réclamation a été traitée et est maintenant clôturée.</p>
          
          <div class="info-box">
            <div class="info-row">
              <span class="info-label">Numéro de réclamation</span>
              <span class="info-value"><strong>#${complaint.id}</strong></span>
            </div>
            <div class="info-row">
              <span class="info-label">Objet</span>
              <span class="info-value">${complaint.subject}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Date de résolution</span>
              <span class="info-value">${new Date().toLocaleDateString('fr-FR')}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Statut</span>
              <span class="info-value"><span class="status-badge status-completed">Résolue</span></span>
            </div>
          </div>
          
          ${complaint.resolution_notes ? `
          <p><strong>Notes de résolution :</strong><br>
          ${complaint.resolution_notes}</p>
          ` : ''}
          
          <p>Nous espérons que la solution apportée vous satisfait pleinement.</p>
          
          <p>Si vous avez la moindre question ou préoccupation concernant cette réclamation, n'hésitez pas à nous recontacter.</p>
          
          <p>Merci de votre confiance.</p>
        </div>
        
        <div class="footer">
          <p><strong>SMART MAINTENANCE</strong></p>
          <p>Email: contact@mct-maintenance.com | Téléphone: +225 XX XX XX XX XX</p>
        </div>
      </div>
    </body>
    </html>
  `
});

// ==================== CONTRATS (2 emails) ====================

/**
 * 17. Souscription contrat - Email client
 */
const contractSubscribedTemplate = (contract, customer) => ({
  subject: `Contrat de maintenance activé - SMART MAINTENANCE`,
  html: `
    <!DOCTYPE html>
    <html>
    <head><style>${baseStyle}</style></head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🎉 Contrat activé</h1>
          <p>Bienvenue dans notre programme de maintenance</p>
        </div>
        
        <div class="content">
          <h2>Bonjour ${customer.first_name},</h2>
          
          <p>Félicitations ! Votre contrat de maintenance est maintenant actif.</p>
          
          <div class="info-box">
            <div class="info-row">
              <span class="info-label">Offre</span>
              <span class="info-value"><strong>${contract.offer_name || 'Contrat de maintenance'}</strong></span>
            </div>
            <div class="info-row">
              <span class="info-label">Date de début</span>
              <span class="info-value">${new Date(contract.start_date).toLocaleDateString('fr-FR')}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Date de fin</span>
              <span class="info-value">${new Date(contract.end_date).toLocaleDateString('fr-FR')}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Prix</span>
              <span class="info-value">${contract.price?.toLocaleString('fr-FR')} FCFA / ${contract.billing_period || 'mois'}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Statut</span>
              <span class="info-value"><span class="status-badge status-completed">Actif</span></span>
            </div>
          </div>
          
          <p><strong>Vos avantages :</strong></p>
          <ul>
            <li>Interventions prioritaires</li>
            <li>Tarifs préférentiels</li>
            <li>Support technique dédié</li>
            <li>Maintenance préventive régulière</li>
          </ul>
          
          <p>Vous pouvez consulter les détails de votre contrat à tout moment depuis votre application mobile.</p>
          
          <p>Merci de nous faire confiance pour l'entretien de vos équipements !</p>
        </div>
        
        <div class="footer">
          <p><strong>SMART MAINTENANCE</strong></p>
          <p>Email: contact@mct-maintenance.com | Téléphone: +225 XX XX XX XX XX</p>
        </div>
      </div>
    </body>
    </html>
  `
});

/**
 * 18. Expiration contrat proche - Email client
 */
const contractExpiringTemplate = (contract, customer) => ({
  subject: `⚠️ Votre contrat expire bientôt - SMART MAINTENANCE`,
  html: `
    <!DOCTYPE html>
    <html>
    <head><style>${baseStyle}</style></head>
    <body>
      <div class="container">
        <div class="header">
          <h1>⚠️ Renouvellement de contrat</h1>
          <p>Votre contrat arrive à expiration</p>
        </div>
        
        <div class="content">
          <h2>Bonjour ${customer.first_name},</h2>
          
          <p>Nous vous informons que votre contrat de maintenance arrive bientôt à expiration.</p>
          
          <div class="info-box">
            <div class="info-row">
              <span class="info-label">Offre actuelle</span>
              <span class="info-value"><strong>${contract.offer_name || 'Contrat de maintenance'}</strong></span>
            </div>
            <div class="info-row">
              <span class="info-label">Date d'expiration</span>
              <span class="info-value"><strong style="color: #d32f2f;">${new Date(contract.end_date).toLocaleDateString('fr-FR')}</strong></span>
            </div>
            <div class="info-row">
              <span class="info-label">Jours restants</span>
              <span class="info-value"><strong>${Math.ceil((new Date(contract.end_date) - new Date()) / (1000 * 60 * 60 * 24))} jours</strong></span>
            </div>
          </div>
          
          <p style="background-color: #fff3cd; padding: 15px; border-radius: 5px; border-left: 4px solid #ffc107;">
            <strong>⏰ N'oubliez pas de renouveler !</strong><br>
            Pour continuer à bénéficier de nos services et avantages, pensez à renouveler votre contrat avant son expiration.
          </p>
          
          <p><strong>Pourquoi renouveler ?</strong></p>
          <ul>
            <li>Maintenir vos avantages et tarifs préférentiels</li>
            <li>Assurer la continuité de la maintenance de vos équipements</li>
            <li>Éviter les interruptions de service</li>
            <li>Bénéficier d'éventuelles offres de fidélité</li>
          </ul>
          
          <p>Connectez-vous à votre application mobile pour renouveler votre contrat en quelques clics, ou contactez-nous pour plus d'informations.</p>
        </div>
        
        <div class="footer">
          <p><strong>SMART MAINTENANCE</strong></p>
          <p>Email: contact@mct-maintenance.com | Téléphone: +225 XX XX XX XX XX</p>
        </div>
      </div>
    </body>
    </html>
  `
});

// Export de tous les templates
module.exports = {
  // Interventions (6)
  interventionCreatedTemplate,
  interventionAssignedTemplate,
  interventionStartedTemplate,
  interventionCompletedTemplate,
  interventionReportTemplate,
  interventionRatingTemplate,
  
  // Commandes (4)
  orderCreatedTemplate,
  orderConfirmedTemplate,
  orderShippedTemplate,
  orderDeliveredTemplate,
  
  // Devis (3)
  quoteCreatedTemplate,
  quoteAcceptedTemplate,
  quoteRejectedTemplate,
  
  // Réclamations (3)
  complaintCreatedTemplate,
  complaintResponseTemplate,
  complaintResolvedTemplate,
  
  // Contrats (2)
  contractSubscribedTemplate,
  contractExpiringTemplate
};
