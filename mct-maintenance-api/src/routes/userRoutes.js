const express = require('express');
const { authenticate, authorize, authorizeOrSelf, adminOnly } = require('../middleware/auth');
const userController = require('../controllers/user/userController');
const nodemailer = require('nodemailer');

const router = express.Router();

/**
 * Échappe les caractères HTML spéciaux pour prévenir les injections XSS dans les templates email.
 */
const escapeHtml = (str) => {
  if (str === null || str === undefined) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
};

// Demande de suppression de compte (public - pas d'authentification requise)
router.post('/request-deletion', async (req, res) => {
  try {
    const { email, phone, reason } = req.body;
    
    if (!email) {
      return res.status(400).json({ success: false, message: 'Email requis' });
    }

    // Configuration du transporteur
    const transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST || 'smtp.gmail.com',
      port: parseInt(process.env.SMTP_PORT) || 587,
      secure: process.env.SMTP_SECURE === 'true',
      auth: {
        user: process.env.SMTP_USER || process.env.EMAIL_USER,
        pass: process.env.SMTP_PASS || process.env.SMTP_PASSWORD || process.env.EMAIL_PASSWORD
      }
    });

    // Email au support
    const mailOptions = {
      from: {
        name: 'SMART MAINTENANCE',
        address: process.env.SMTP_FROM || process.env.EMAIL_FROM || process.env.EMAIL_USER
      },
      to: ['supportuser@mct.ci', 'bassirou.ouedraogo@mct.ci'],
      subject: '🗑️ Demande de suppression de compte - SMART MAINTENANCE',
      html: ` // nosemgrep: raw-html-format
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: #dc3545; color: white; padding: 20px; text-align: center;">
            <h1>Demande de Suppression de Compte</h1>
          </div>
          <div style="padding: 30px; background: #f8f9fa;">
            <h2 style="color: #333;">Informations de la demande</h2>
            <table style="width: 100%; border-collapse: collapse;">
              <tr>
                <td style="padding: 10px; border-bottom: 1px solid #ddd;"><strong>Email du compte :</strong></td>
                <td style="padding: 10px; border-bottom: 1px solid #ddd;">${escapeHtml(email) /* nosemgrep: raw-html-format */}</td>
              </tr>
              <tr>
                <td style="padding: 10px; border-bottom: 1px solid #ddd;"><strong>Téléphone :</strong></td>
                <td style="padding: 10px; border-bottom: 1px solid #ddd;">${(escapeHtml(phone) || 'Non renseigné') /* nosemgrep: raw-html-format */}</td>
              </tr>
              <tr>
                <td style="padding: 10px; border-bottom: 1px solid #ddd;"><strong>Raison :</strong></td>
                <td style="padding: 10px; border-bottom: 1px solid #ddd;">${(escapeHtml(reason) || 'Non renseignée') /* nosemgrep: raw-html-format */}</td>
              </tr>
              <tr>
                <td style="padding: 10px; border-bottom: 1px solid #ddd;"><strong>Date de demande :</strong></td>
                <td style="padding: 10px; border-bottom: 1px solid #ddd;">${new Date().toLocaleString('fr-FR')}</td>
              </tr>
            </table>
            <div style="margin-top: 20px; padding: 15px; background: #fff3cd; border-radius: 8px;">
              <strong>⚠️ Action requise :</strong> Veuillez traiter cette demande dans un délai de 7 jours ouvrables.
            </div>
          </div>
          <div style="padding: 20px; text-align: center; color: #666; font-size: 12px;">
            <p>© 2026 SMART MAINTENANCE</p>
          </div>
        </div>
      `
    };

    // Enregistrer systématiquement la demande en BDD (ContactRequest)
    try {
      const { ContactRequest } = require('../models');
      await ContactRequest.create({
        name: email.split('@')[0] || 'Client',
        email: email,
        phone: phone || 'Non renseigné',
        motive: 'Suppression de compte',
        message: `Demande de suppression de compte pour ${email}.${reason ? ' Raison: ' + reason : ''}`,
        preferredChannel: 'email',
        preferredTime: 'dès que possible',
        urgencyLevel: 'high',
        status: 'pending'
      });
    } catch (dbErr) {
      console.error('⚠️  Impossible d\'enregistrer la demande de suppression en BDD:', dbErr.message);
    }

    // Tenter l'envoi d'email
    try {
      await transporter.sendMail(mailOptions);
      console.log(`📧 Demande de suppression envoyée par email pour: ${email}`);
    } catch (emailErr) {
      console.error('⚠️  Échec envoi email suppression (conservé en BDD):', emailErr.message);
    }

    res.json({ success: true, message: 'Demande de suppression enregistrée avec succès' });
  } catch (error) {
    console.error('Erreur traitement demande suppression:', error);
    res.status(500).json({ success: false, message: 'Erreur lors du traitement de la demande de suppression' });
  }
});

// List & filter users
router.get('/', authenticate, authorize('admin', 'manager'), userController.listUsers);
// Get one
router.get('/:id', authenticate, authorizeOrSelf('admin', 'manager'), userController.getUser);
// Update full (limited fields)
router.put('/:id', authenticate, authorizeOrSelf('admin', 'manager'), userController.updateUser);
// Update status only
router.patch('/:id/status', authenticate, authorize('admin', 'manager'), userController.updateStatus);
// Delete (admin only)
router.delete('/:id', authenticate, adminOnly, userController.deleteUser);

module.exports = router;
