/**
 * Templates d'emails transactionnels
 * 18 templates pour interventions, commandes, devis, réclamations, contrats
 * Tous les templates utilisent des styles inline pour une compatibilité maximale avec les clients email
 */

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
                  <p style="margin: 5px 0;">Email: smartmaintenance@mct.ci | Téléphone: +225 07 59 50 50 50</p>
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
                  <h1 style="margin: 0 0 10px 0; font-size: 24px;">🔧 Nouvelle mission assignée</h1>
                  <p style="margin: 0; font-size: 14px;">Intervention #${intervention.id}</p>
                </td>
              </tr>
              
              <!-- Content -->
              <tr>
                <td style="padding: 30px;">
                  <h2 style="color: #0a543d; margin-top: 0; font-size: 20px;">Bonjour ${technician.first_name},</h2>
                  
                  <p style="margin: 15px 0;">Une nouvelle intervention vous a été assignée. Merci de prendre contact avec le client dans les plus brefs délais.</p>
                  
                  <!-- Détails intervention -->
                  <p style="margin: 20px 0 10px 0; font-weight: 600; color: #0a543d;">Détails de l'intervention</p>
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f9f9f9; border-left: 4px solid #0a543d; margin: 0 0 20px 0;">
                    <tr>
                      <td style="padding: 15px;">
                        <table width="100%" cellpadding="0" cellspacing="0">
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; width: 50%; padding: 8px 8px 8px 0;">Numéro</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">#${intervention.id}</td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Type</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${intervention.intervention_type || 'Standard'}</td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Priorité</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${intervention.priority || 'Normale'}</td>
                          </tr>
                          <tr>
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Date prévue</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${intervention.scheduled_date ? new Date(intervention.scheduled_date).toLocaleDateString('fr-FR') : 'À définir'}</td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                  
                  <!-- Informations client -->
                  <p style="margin: 20px 0 10px 0; font-weight: 600; color: #0a543d;">Informations client</p>
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f9f9f9; border-left: 4px solid #0a543d; margin: 0 0 20px 0;">
                    <tr>
                      <td style="padding: 15px;">
                        <table width="100%" cellpadding="0" cellspacing="0">
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; width: 50%; padding: 8px 8px 8px 0;">Nom</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${customer.first_name} ${customer.last_name}</td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Téléphone</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${customer.phone || 'Non renseigné'}</td>
                          </tr>
                          <tr>
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Adresse</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${intervention.address || customer.address || 'Non renseignée'}</td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                  
                  <p style="margin: 20px 0 5px 0;"><strong>Description du problème :</strong></p>
                  <p style="margin: 5px 0 20px 0; color: #555;">${intervention.description || 'Non spécifiée'}</p>
                  
                  <p style="margin: 20px 0;">Connectez-vous à l'application mobile pour accepter cette mission et démarrer l'intervention.</p>
                </td>
              </tr>
              
              <!-- Footer -->
              <tr>
                <td style="background-color: #f9f9f9; padding: 20px; text-align: center; color: #666; font-size: 12px;">
                  <p style="margin: 5px 0; font-weight: bold;">SMART MAINTENANCE</p>
                  <p style="margin: 5px 0;">Email: smartmaintenance@mct.ci | Téléphone: +225 07 59 50 50 50</p>
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
 * 3. Intervention démarrée - Email client
 */
const interventionStartedTemplate = (intervention, technician, customer) => ({
  subject: `Le technicien est en route - Intervention #${intervention.id}`,
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
                  <h1 style="margin: 0 0 10px 0; font-size: 24px;">🚗 Technicien en route</h1>
                  <p style="margin: 0; font-size: 14px;">Intervention #${intervention.id}</p>
                </td>
              </tr>
              
              <!-- Content -->
              <tr>
                <td style="padding: 30px;">
                  <h2 style="color: #0a543d; margin-top: 0; font-size: 20px;">Bonjour ${customer.first_name},</h2>
                  
                  <p style="margin: 15px 0;">Votre technicien est en route vers votre domicile pour l'intervention.</p>
                  
                  <!-- Info Box -->
                  <p style="margin: 20px 0 10px 0; font-weight: 600; color: #0a543d;">Votre technicien</p>
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f9f9f9; border-left: 4px solid #0a543d; margin: 0 0 20px 0;">
                    <tr>
                      <td style="padding: 15px;">
                        <table width="100%" cellpadding="0" cellspacing="0">
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; width: 50%; padding: 8px 8px 8px 0;">Nom</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${technician.first_name} ${technician.last_name}</td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Téléphone</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${technician.phone || 'Non disponible'}</td>
                          </tr>
                          <tr>
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Statut</td>
                            <td style="text-align: right; padding: 8px 0 8px 8px;">
                              <span style="display: inline-block; padding: 5px 12px; border-radius: 15px; font-size: 12px; font-weight: 600; text-transform: uppercase; background-color: #cce5ff; color: #004085;">En route</span>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                  
                  <p style="margin: 20px 0;">Le technicien devrait arriver d'ici peu. Si vous avez des questions, n'hésitez pas à le contacter directement.</p>
                </td>
              </tr>
              
              <!-- Footer -->
              <tr>
                <td style="background-color: #f9f9f9; padding: 20px; text-align: center; color: #666; font-size: 12px;">
                  <p style="margin: 5px 0; font-weight: bold;">SMART MAINTENANCE</p>
                  <p style="margin: 5px 0;">Email: smartmaintenance@mct.ci | Téléphone: +225 07 59 50 50 50</p>
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
 * 4. Intervention terminée - Email client
 */
const interventionCompletedTemplate = (intervention, customer) => ({
  subject: `Intervention #${intervention.id} terminée - Votre avis compte !`,
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
                  <h1 style="margin: 0 0 10px 0; font-size: 24px;">✅ Intervention terminée</h1>
                  <p style="margin: 0; font-size: 14px;">Merci de votre confiance</p>
                </td>
              </tr>
              
              <!-- Content -->
              <tr>
                <td style="padding: 30px;">
                  <h2 style="color: #0a543d; margin-top: 0; font-size: 20px;">Bonjour ${customer.first_name},</h2>
                  
                  <p style="margin: 15px 0;">Votre intervention a été terminée avec succès.</p>
                  
                  <!-- Info Box -->
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f9f9f9; border-left: 4px solid #0a543d; margin: 20px 0;">
                    <tr>
                      <td style="padding: 15px;">
                        <table width="100%" cellpadding="0" cellspacing="0">
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; width: 50%; padding: 8px 8px 8px 0;">Numéro</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">#${intervention.id}</td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Type</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${intervention.intervention_type || 'Standard'}</td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Date de réalisation</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${new Date().toLocaleDateString('fr-FR')}</td>
                          </tr>
                          <tr>
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Statut</td>
                            <td style="text-align: right; padding: 8px 0 8px 8px;">
                              <span style="display: inline-block; padding: 5px 12px; border-radius: 15px; font-size: 12px; font-weight: 600; text-transform: uppercase; background-color: #d4edda; color: #155724;">Terminée</span>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                  
                  <p style="margin: 20px 0 5px 0;"><strong>Votre avis nous intéresse !</strong></p>
                  <p style="margin: 5px 0 20px 0;">Merci de prendre quelques instants pour évaluer la qualité du service de notre technicien. Votre retour nous aide à améliorer nos services.</p>
                  
                  <p style="margin: 20px 0;">Vous pouvez évaluer cette intervention depuis votre application mobile dans la section "Mes interventions".</p>
                </td>
              </tr>
              
              <!-- Footer -->
              <tr>
                <td style="background-color: #f9f9f9; padding: 20px; text-align: center; color: #666; font-size: 12px;">
                  <p style="margin: 5px 0; font-weight: bold;">SMART MAINTENANCE</p>
                  <p style="margin: 5px 0;">Email: smartmaintenance@mct.ci | Téléphone: +225 07 59 50 50 50</p>
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
 * 5. Rapport d'intervention soumis - Email client
 */
const interventionReportTemplate = (intervention, report, customer) => ({
  subject: `Rapport d'intervention #${intervention.id} disponible`,
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
                  <h1 style="margin: 0 0 10px 0; font-size: 24px;">📋 Rapport disponible</h1>
                  <p style="margin: 0; font-size: 14px;">Intervention #${intervention.id}</p>
                </td>
              </tr>
              
              <!-- Content -->
              <tr>
                <td style="padding: 30px;">
                  <h2 style="color: #0a543d; margin-top: 0; font-size: 20px;">Bonjour ${customer.first_name},</h2>
                  
                  <p style="margin: 15px 0;">Le rapport détaillé de votre intervention est maintenant disponible.</p>
                  
                  <!-- Info Box -->
                  <p style="margin: 20px 0 10px 0; font-weight: 600; color: #0a543d;">Résumé de l'intervention</p>
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f9f9f9; border-left: 4px solid #0a543d; margin: 0 0 20px 0;">
                    <tr>
                      <td style="padding: 15px;">
                        <p style="margin: 0 0 10px 0;"><strong>Travaux effectués :</strong></p>
                        <p style="margin: 0 0 15px 0; color: #555;">${report.work_description || 'Voir le rapport complet'}</p>
                        
                        ${report.parts_used ? `
                        <p style="margin: 0 0 10px 0;"><strong>Pièces utilisées :</strong></p>
                        <p style="margin: 0 0 15px 0; color: #555;">${report.parts_used}</p>
                        ` : ''}
                        
                        <p style="margin: 0;"><strong>Durée :</strong> ${report.duration || 'Non spécifiée'}</p>
                      </td>
                    </tr>
                  </table>
                  
                  <p style="margin: 20px 0;">Vous pouvez consulter le rapport complet et les photos (avant/après) depuis votre application mobile.</p>
                </td>
              </tr>
              
              <!-- Footer -->
              <tr>
                <td style="background-color: #f9f9f9; padding: 20px; text-align: center; color: #666; font-size: 12px;">
                  <p style="margin: 5px 0; font-weight: bold;">SMART MAINTENANCE</p>
                  <p style="margin: 5px 0;">Email: smartmaintenance@mct.ci | Téléphone: +225 07 59 50 50 50</p>
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
 * 6. Évaluation reçue - Email technicien
 */
const interventionRatingTemplate = (intervention, rating, technician) => ({
  subject: `Nouvelle évaluation reçue - Intervention #${intervention.id}`,
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
                  <h1 style="margin: 0 0 10px 0; font-size: 24px;">⭐ Nouvelle évaluation</h1>
                  <p style="margin: 0; font-size: 14px;">Intervention #${intervention.id}</p>
                </td>
              </tr>
              
              <!-- Content -->
              <tr>
                <td style="padding: 30px;">
                  <h2 style="color: #0a543d; margin-top: 0; font-size: 20px;">Bonjour ${technician.first_name},</h2>
                  
                  <p style="margin: 15px 0;">Vous avez reçu une nouvelle évaluation de la part du client.</p>
                  
                  <!-- Info Box -->
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f9f9f9; border-left: 4px solid #0a543d; margin: 20px 0;">
                    <tr>
                      <td style="padding: 15px;">
                        <table width="100%" cellpadding="0" cellspacing="0">
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; width: 50%; padding: 8px 8px 8px 0;">Note</td>
                            <td style="color: #ffa500; text-align: right; padding: 8px 0 8px 8px; font-size: 18px;">
                              ${'⭐'.repeat(Math.round(rating.rating || 0))}
                              <strong>${rating.rating}/5</strong>
                            </td>
                          </tr>
                          ${rating.comment ? `
                          <tr>
                            <td style="font-weight: 600; color: #666; padding: 12px 8px 8px 0; vertical-align: top;">Commentaire</td>
                            <td style="color: #333; text-align: right; padding: 12px 0 8px 8px;">${rating.comment}</td>
                          </tr>
                          ` : ''}
                        </table>
                      </td>
                    </tr>
                  </table>
                  
                  <p style="margin: 20px 0;">${rating.rating >= 4 ? '🎉 Excellent travail ! Continuez comme ça !' : 'Merci pour votre professionnalisme. Continuez vos efforts pour satisfaire nos clients.'}</p>
                </td>
              </tr>
              
              <!-- Footer -->
              <tr>
                <td style="background-color: #f9f9f9; padding: 20px; text-align: center; color: #666; font-size: 12px;">
                  <p style="margin: 5px 0; font-weight: bold;">SMART MAINTENANCE</p>
                  <p style="margin: 5px 0;">Email: smartmaintenance@mct.ci | Téléphone: +225 07 59 50 50 50</p>
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
                  <p style="margin: 5px 0;">Email: smartmaintenance@mct.ci | Téléphone: +225 07 59 50 50 50</p>
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
                  <p style="margin: 5px 0;">Email: smartmaintenance@mct.ci | Téléphone: +225 07 59 50 50 50</p>
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
                  <p style="margin: 5px 0;">Email: smartmaintenance@mct.ci | Téléphone: +225 07 59 50 50 50</p>
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
                  <p style="margin: 5px 0;">Email: smartmaintenance@mct.ci | Téléphone: +225 07 59 50 50 50</p>
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
                  <p style="margin: 5px 0;">Email: smartmaintenance@mct.ci | Téléphone: +225 07 59 50 50 50</p>
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
                  <h1 style="margin: 0 0 10px 0; font-size: 24px;">🚨 Nouvelle réclamation</h1>
                  <p style="margin: 0; font-size: 14px;">Réclamation #${complaint.id}</p>
                </td>
              </tr>
              
              <!-- Content -->
              <tr>
                <td style="padding: 30px;">
                  <h2 style="color: #0a543d; margin-top: 0; font-size: 20px;">Notification administrative</h2>
                  
                  <p style="margin: 15px 0;">Un client vient de soumettre une réclamation nécessitant votre attention.</p>
                  
                  <!-- Info Box -->
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f9f9f9; border-left: 4px solid #0a543d; margin: 20px 0;">
                    <tr>
                      <td style="padding: 15px;">
                        <table width="100%" cellpadding="0" cellspacing="0">
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; width: 50%; padding: 8px 8px 8px 0;">Numéro</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;"><strong>#${complaint.id}</strong></td>
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
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Priorité</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;"><strong>${complaint.priority || 'Normale'}</strong></td>
                          </tr>
                          <tr>
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Date</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${new Date(complaint.created_at).toLocaleDateString('fr-FR')}</td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                  
                  <p style="margin: 20px 0 5px 0;"><strong>Objet :</strong> ${complaint.subject}</p>
                  
                  <p style="margin: 20px 0 5px 0;"><strong>Description :</strong></p>
                  <p style="margin: 5px 0 20px 0; color: #555;">${complaint.description}</p>
                  
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #fff3cd; border-left: 4px solid #ffc107; margin: 20px 0;">
                    <tr>
                      <td style="padding: 15px;">
                        <strong>⚠️ Action requise :</strong> Merci de traiter cette réclamation dans les plus brefs délais et d'apporter une réponse au client.
                      </td>
                    </tr>
                  </table>
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
 * 15. Réponse à la réclamation - Email client
 */
const complaintResponseTemplate = (complaint, response, customer) => ({
  subject: `Réponse à votre réclamation #${complaint.id} - SMART MAINTENANCE`,
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
                  <h1 style="margin: 0 0 10px 0; font-size: 24px;">💬 Réponse à votre réclamation</h1>
                  <p style="margin: 0; font-size: 14px;">Réclamation #${complaint.id}</p>
                </td>
              </tr>
              
              <!-- Content -->
              <tr>
                <td style="padding: 30px;">
                  <h2 style="color: #0a543d; margin-top: 0; font-size: 20px;">Bonjour ${customer.first_name},</h2>
                  
                  <p style="margin: 15px 0;">Nous avons bien pris en compte votre réclamation et sommes heureux de pouvoir vous apporter une réponse.</p>
                  
                  <!-- Info Box -->
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f9f9f9; border-left: 4px solid #0a543d; margin: 20px 0;">
                    <tr>
                      <td style="padding: 15px;">
                        <table width="100%" cellpadding="0" cellspacing="0">
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; width: 50%; padding: 8px 8px 8px 0;">Numéro de réclamation</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;"><strong>#${complaint.id}</strong></td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Objet</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${complaint.subject}</td>
                          </tr>
                          <tr>
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Statut</td>
                            <td style="text-align: right; padding: 8px 0 8px 8px;">
                              <span style="display: inline-block; padding: 5px 12px; border-radius: 15px; font-size: 12px; font-weight: 600; text-transform: uppercase; background-color: #cce5ff; color: #004085;">En cours de traitement</span>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                  
                  <p style="margin: 20px 0 5px 0;"><strong>Notre réponse :</strong></p>
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f9f9f9; margin: 10px 0 20px 0; border-radius: 5px;">
                    <tr>
                      <td style="padding: 20px;">
                        ${response}
                      </td>
                    </tr>
                  </table>
                  
                  <p style="margin: 20px 0;">Si vous avez d'autres questions ou si cette réponse ne vous satisfait pas pleinement, n'hésitez pas à nous contacter ou à répondre via l'application.</p>
                  
                  <p style="margin: 20px 0;">Nous restons à votre disposition.</p>
                </td>
              </tr>
              
              <!-- Footer -->
              <tr>
                <td style="background-color: #f9f9f9; padding: 20px; text-align: center; color: #666; font-size: 12px;">
                  <p style="margin: 5px 0; font-weight: bold;">SMART MAINTENANCE</p>
                  <p style="margin: 5px 0;">Email: smartmaintenance@mct.ci | Téléphone: +225 07 59 50 50 50</p>
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
 * 16. Réclamation résolue - Email client
 */
const complaintResolvedTemplate = (complaint, customer) => ({
  subject: `Réclamation #${complaint.id} résolue - SMART MAINTENANCE`,
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
                  <h1 style="margin: 0 0 10px 0; font-size: 24px;">✅ Réclamation résolue</h1>
                  <p style="margin: 0; font-size: 14px;">Réclamation #${complaint.id}</p>
                </td>
              </tr>
              
              <!-- Content -->
              <tr>
                <td style="padding: 30px;">
                  <h2 style="color: #0a543d; margin-top: 0; font-size: 20px;">Bonjour ${customer.first_name},</h2>
                  
                  <p style="margin: 15px 0;">Votre réclamation a été traitée et est maintenant clôturée.</p>
                  
                  <!-- Info Box -->
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f9f9f9; border-left: 4px solid #0a543d; margin: 20px 0;">
                    <tr>
                      <td style="padding: 15px;">
                        <table width="100%" cellpadding="0" cellspacing="0">
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; width: 50%; padding: 8px 8px 8px 0;">Numéro de réclamation</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;"><strong>#${complaint.id}</strong></td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Objet</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${complaint.subject}</td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Date de résolution</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${new Date().toLocaleDateString('fr-FR')}</td>
                          </tr>
                          <tr>
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Statut</td>
                            <td style="text-align: right; padding: 8px 0 8px 8px;">
                              <span style="display: inline-block; padding: 5px 12px; border-radius: 15px; font-size: 12px; font-weight: 600; text-transform: uppercase; background-color: #d4edda; color: #155724;">Résolue</span>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                  
                  ${complaint.resolution_notes ? `
                  <p style="margin: 20px 0 5px 0;"><strong>Notes de résolution :</strong></p>
                  <p style="margin: 5px 0 20px 0; color: #555;">${complaint.resolution_notes}</p>
                  ` : ''}
                  
                  <p style="margin: 20px 0;">Nous espérons que la solution apportée vous satisfait pleinement.</p>
                  
                  <p style="margin: 20px 0;">Si vous avez la moindre question ou préoccupation concernant cette réclamation, n'hésitez pas à nous recontacter.</p>
                  
                  <p style="margin: 20px 0;">Merci de votre confiance.</p>
                </td>
              </tr>
              
              <!-- Footer -->
              <tr>
                <td style="background-color: #f9f9f9; padding: 20px; text-align: center; color: #666; font-size: 12px;">
                  <p style="margin: 5px 0; font-weight: bold;">SMART MAINTENANCE</p>
                  <p style="margin: 5px 0;">Email: smartmaintenance@mct.ci | Téléphone: +225 07 59 50 50 50</p>
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

// ==================== CONTRATS (2 emails) ====================

/**
 * 17. Souscription contrat - Email client
 */
const contractSubscribedTemplate = (contract, customer) => ({
  subject: `Contrat de maintenance activé - SMART MAINTENANCE`,
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
                  <h1 style="margin: 0 0 10px 0; font-size: 24px;">🎉 Contrat activé</h1>
                  <p style="margin: 0; font-size: 14px;">Bienvenue dans notre programme de maintenance</p>
                </td>
              </tr>
              
              <!-- Content -->
              <tr>
                <td style="padding: 30px;">
                  <h2 style="color: #0a543d; margin-top: 0; font-size: 20px;">Bonjour ${customer.first_name},</h2>
                  
                  <p style="margin: 15px 0;">Félicitations ! Votre contrat de maintenance est maintenant actif.</p>
                  
                  <!-- Info Box -->
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f9f9f9; border-left: 4px solid #0a543d; margin: 20px 0;">
                    <tr>
                      <td style="padding: 15px;">
                        <table width="100%" cellpadding="0" cellspacing="0">
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; width: 50%; padding: 8px 8px 8px 0;">Offre</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;"><strong>${contract.offer_name || 'Contrat de maintenance'}</strong></td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Date de début</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${new Date(contract.start_date).toLocaleDateString('fr-FR')}</td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Date de fin</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${new Date(contract.end_date).toLocaleDateString('fr-FR')}</td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Prix</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;">${contract.price?.toLocaleString('fr-FR')} FCFA / ${contract.billing_period || 'mois'}</td>
                          </tr>
                          <tr>
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Statut</td>
                            <td style="text-align: right; padding: 8px 0 8px 8px;">
                              <span style="display: inline-block; padding: 5px 12px; border-radius: 15px; font-size: 12px; font-weight: 600; text-transform: uppercase; background-color: #d4edda; color: #155724;">Actif</span>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                  
                  <p style="margin: 20px 0 10px 0;"><strong>Vos avantages :</strong></p>
                  <ul style="margin: 0 0 20px 0; padding-left: 20px;">
                    <li style="margin: 5px 0;">Interventions prioritaires</li>
                    <li style="margin: 5px 0;">Tarifs préférentiels</li>
                    <li style="margin: 5px 0;">Support technique dédié</li>
                    <li style="margin: 5px 0;">Maintenance préventive régulière</li>
                  </ul>
                  
                  <p style="margin: 20px 0;">Vous pouvez consulter les détails de votre contrat à tout moment depuis votre application mobile.</p>
                  
                  <p style="margin: 20px 0;">Merci de nous faire confiance pour l'entretien de vos équipements !</p>
                </td>
              </tr>
              
              <!-- Footer -->
              <tr>
                <td style="background-color: #f9f9f9; padding: 20px; text-align: center; color: #666; font-size: 12px;">
                  <p style="margin: 5px 0; font-weight: bold;">SMART MAINTENANCE</p>
                  <p style="margin: 5px 0;">Email: smartmaintenance@mct.ci | Téléphone: +225 07 59 50 50 50</p>
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
 * 18. Expiration contrat proche - Email client
 */
const contractExpiringTemplate = (contract, customer) => ({
  subject: `⚠️ Votre contrat expire bientôt - SMART MAINTENANCE`,
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
                  <h1 style="margin: 0 0 10px 0; font-size: 24px;">⚠️ Renouvellement de contrat</h1>
                  <p style="margin: 0; font-size: 14px;">Votre contrat arrive à expiration</p>
                </td>
              </tr>
              
              <!-- Content -->
              <tr>
                <td style="padding: 30px;">
                  <h2 style="color: #0a543d; margin-top: 0; font-size: 20px;">Bonjour ${customer.first_name},</h2>
                  
                  <p style="margin: 15px 0;">Nous vous informons que votre contrat de maintenance arrive bientôt à expiration.</p>
                  
                  <!-- Info Box -->
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f9f9f9; border-left: 4px solid #0a543d; margin: 20px 0;">
                    <tr>
                      <td style="padding: 15px;">
                        <table width="100%" cellpadding="0" cellspacing="0">
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; width: 50%; padding: 8px 8px 8px 0;">Offre actuelle</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;"><strong>${contract.offer_name || 'Contrat de maintenance'}</strong></td>
                          </tr>
                          <tr style="border-bottom: 1px solid #eee;">
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Date d'expiration</td>
                            <td style="color: #d32f2f; text-align: right; padding: 8px 0 8px 8px;"><strong>${new Date(contract.end_date).toLocaleDateString('fr-FR')}</strong></td>
                          </tr>
                          <tr>
                            <td style="font-weight: 600; color: #666; padding: 8px 8px 8px 0;">Jours restants</td>
                            <td style="color: #333; text-align: right; padding: 8px 0 8px 8px;"><strong>${Math.ceil((new Date(contract.end_date) - new Date()) / (1000 * 60 * 60 * 24))} jours</strong></td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                  
                  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #fff3cd; border-left: 4px solid #ffc107; margin: 20px 0;">
                    <tr>
                      <td style="padding: 15px;">
                        <strong>⏰ N'oubliez pas de renouveler !</strong><br>
                        Pour continuer à bénéficier de nos services et avantages, pensez à renouveler votre contrat avant son expiration.
                      </td>
                    </tr>
                  </table>
                  
                  <p style="margin: 20px 0 10px 0;"><strong>Pourquoi renouveler ?</strong></p>
                  <ul style="margin: 0 0 20px 0; padding-left: 20px;">
                    <li style="margin: 5px 0;">Maintenir vos avantages et tarifs préférentiels</li>
                    <li style="margin: 5px 0;">Assurer la continuité de la maintenance de vos équipements</li>
                    <li style="margin: 5px 0;">Éviter les interruptions de service</li>
                    <li style="margin: 5px 0;">Bénéficier d'éventuelles offres de fidélité</li>
                  </ul>
                  
                  <p style="margin: 20px 0;">Connectez-vous à votre application mobile pour renouveler votre contrat en quelques clics, ou contactez-nous pour plus d'informations.</p>
                </td>
              </tr>
              
              <!-- Footer -->
              <tr>
                <td style="background-color: #f9f9f9; padding: 20px; text-align: center; color: #666; font-size: 12px;">
                  <p style="margin: 5px 0; font-weight: bold;">SMART MAINTENANCE</p>
                  <p style="margin: 5px 0;">Email: smartmaintenance@mct.ci | Téléphone: +225 07 59 50 50 50</p>
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
