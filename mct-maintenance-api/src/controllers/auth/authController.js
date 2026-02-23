const jwt = require('jsonwebtoken');
const { User, CustomerProfile, TechnicianProfile, EmailVerificationCode } = require('../../models');
const { cache } = require('../../config/redis');
const { validationResult } = require('express-validator');
const PasswordResetCode = require('../../models/PasswordResetCode');
const { Op } = require('sequelize');
const nodemailer = require('nodemailer');
const { createTransporter, sendVerificationEmail } = require('../../services/emailService');
const { sendVerificationCodeSMS, sendPasswordResetCodeSMS, formatPhoneNumber } = require('../../services/smsService');
const crypto = require('crypto');
require('dotenv').config();

// Demander un code de réinitialisation
const requestResetCode = async (req, res) => {
  try {
    const { email } = req.body;
    
    // Déterminer si c'est un email ou un téléphone
    const isEmail = email && email.includes('@');
    const isPhone = email && !email.includes('@') && /^\d+$/.test(email.replace(/[\s\-\+]/g, ''));
    
    let user = null;
    
    if (isEmail) {
      user = await User.findOne({ where: { email } });
    } else if (isPhone) {
      // Formater le numéro de téléphone
      const formattedPhone = formatPhoneNumber(email);
      console.log('📱 Réinitialisation par téléphone:', email, '→', formattedPhone);
      
      user = await User.findOne({ 
        where: { 
          [Op.or]: [
            { phone: formattedPhone },
            { phone: email }
          ]
        } 
      });
    } else {
      user = await User.findOne({ 
        where: { 
          [Op.or]: [
            { email },
            { phone: email }
          ]
        } 
      });
    }
    
    if (!user) {
      return res.status(404).json({ success: false, message: 'Aucun compte associé à ce contact' });
    }
    // Générer un code à 6 chiffres
    const code = PasswordResetCode.generateCode();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 min
    // Sauvegarder en base
    await PasswordResetCode.create({ user_id: user.id, code, expires_at: expiresAt });

    // Vérifier si l'utilisateur a un numéro de téléphone
    const useSMS = user.phone && process.env.USE_SMS_VERIFICATION === 'true';

    if (useSMS) {
      // Envoyer le code par SMS
      try {
        console.log(`📱 Envoi du code de réinitialisation par SMS à ${user.phone}`);
        const smsResult = await sendPasswordResetCodeSMS(user.phone, code, user.first_name);
        
        if (smsResult.success) {
          console.log('✅ SMS de réinitialisation envoyé avec succès');
          return res.json({ 
            success: true, 
            message: 'Code envoyé par SMS',
            method: 'sms'
          });
        } else {
          console.error('❌ Échec envoi SMS:', smsResult.error);
          // Fallback vers email en cas d'échec SMS
          console.log('📧 Fallback: envoi par email...');
        }
      } catch (smsError) {
        console.error('❌ Erreur SMS:', smsError.message);
        // Continuer avec l'email en cas d'erreur
      }
    }

    // Configurer le transporteur nodemailer en utilisant le service email (par défaut ou fallback)
    const transporter = createTransporter();
    const fromAddress = process.env.EMAIL_SERVICE === 'gmail' 
      ? process.env.EMAIL_USER 
      : (process.env.SMTP_FROM || process.env.EMAIL_USER);

    // Préparer le mail
    const mailOptions = {
      from: {
        name: process.env.SMTP_FROM_NAME || 'SMART MAINTENANCE',
        address: fromAddress
      },
      to: email,
      subject: 'Réinitialisation de mot de passe - SMART MAINTENANCE',
      headers: {
        'X-Priority': '1',
        'X-MSMail-Priority': 'High',
        'Importance': 'high',
        'X-Mailer': 'SMART MAINTENANCE System',
        'List-Unsubscribe': `<mailto:${fromAddress}?subject=unsubscribe>`
      },
      text: `Bonjour ${user.first_name},

Vous avez demandé la réinitialisation de votre mot de passe.

Votre code de réinitialisation est : ${code}

Ce code expire dans 15 minutes.

Entrez ce code dans l'application pour réinitialiser votre mot de passe.

Si vous n'avez pas demandé cette réinitialisation, ignorez simplement cet email.

© ${new Date().getFullYear()} SMART MAINTENANCE - Tous droits réservés`,
      html: `
        <!DOCTYPE html>
        <html lang="fr">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { 
              font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
              line-height: 1.6; 
              color: #333; 
              background-color: #f4f4f4;
              padding: 20px;
            }
            .email-wrapper { 
              max-width: 600px; 
              margin: 0 auto; 
              background: white;
              border-radius: 10px;
              overflow: hidden;
              box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            }
            .header { 
              background: linear-gradient(135deg, #f44336 0%, #d32f2f 100%);
              color: white; 
              padding: 40px 20px; 
              text-align: center;
            }
            .header h1 {
              font-size: 28px;
              margin-bottom: 10px;
              font-weight: 600;
            }
            .header p {
              font-size: 16px;
              opacity: 0.9;
            }
            .icon {
              font-size: 48px;
              margin-bottom: 15px;
            }
            .content { 
              background-color: #ffffff; 
              padding: 40px 30px;
            }
            .greeting {
              font-size: 20px;
              color: #d32f2f;
              margin-bottom: 20px;
              font-weight: 600;
            }
            .message {
              font-size: 15px;
              color: #555;
              margin-bottom: 25px;
              line-height: 1.8;
            }
            .code-container {
              background: linear-gradient(135deg, #ffebee 0%, #ffcdd2 100%);
              border: 2px dashed #f44336;
              border-radius: 10px;
              padding: 30px;
              margin: 30px 0;
              text-align: center;
            }
            .code-label {
              font-size: 14px;
              color: #666;
              margin-bottom: 10px;
              text-transform: uppercase;
              letter-spacing: 1px;
            }
            .code { 
              font-size: 40px; 
              font-weight: bold; 
              color: #d32f2f; 
              letter-spacing: 8px;
              font-family: 'Courier New', monospace;
              display: inline-block;
              padding: 10px 20px;
              background: white;
              border-radius: 8px;
              box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }
            .expiry-notice {
              background-color: #fff3cd;
              border-left: 4px solid #ffc107;
              padding: 15px;
              margin: 25px 0;
              border-radius: 4px;
            }
            .expiry-notice strong {
              color: #856404;
              display: flex;
              align-items: center;
              gap: 8px;
            }
            .security-notice {
              background-color: #ffebee;
              border-left: 4px solid #f44336;
              padding: 15px;
              margin: 25px 0;
              border-radius: 4px;
              font-size: 14px;
              color: #c62828;
            }
            .footer { 
              background-color: #f8f9fa;
              text-align: center; 
              padding: 30px 20px; 
              color: #666; 
              font-size: 13px;
              border-top: 1px solid #e0e0e0;
            }
            .footer-logo {
              font-size: 20px;
              font-weight: bold;
              color: #d32f2f;
              margin-bottom: 10px;
            }
            .divider {
              height: 1px;
              background: linear-gradient(to right, transparent, #ddd, transparent);
              margin: 20px 0;
            }
            @media only screen and (max-width: 600px) {
              .code { font-size: 32px; letter-spacing: 6px; }
              .content { padding: 25px 20px; }
              .header h1 { font-size: 24px; }
            }
          </style>
        </head>
        <body>
          <div class="email-wrapper">
            <div class="header">
              <div class="icon">&#128274;</div>
              <h1>Réinitialisation de mot de passe</h1>
              <p>SMART MAINTENANCE</p>
            </div>
            
            <div class="content">
              <div class="greeting">Bonjour ${user.first_name} ! &#128075;</div>
              
              <p class="message">
                Vous avez demandé la réinitialisation de votre mot de passe. 
                Utilisez le code ci-dessous pour créer un nouveau mot de passe sécurisé.
              </p>
              
              <div class="code-container">
                <div class="code-label">Code de réinitialisation</div>
                <div class="code">${code}</div>
              </div>
              
              <div class="expiry-notice">
                <strong>⏱️ Important : Ce code expire dans 15 minutes</strong>
              </div>
              
              <p class="message">
                Entrez ce code dans l'application mobile SMART MAINTENANCE pour définir 
                votre nouveau mot de passe.
              </p>
              
              <div class="divider"></div>
              
              <div class="security-notice">
                🛡️ <strong>Attention :</strong> Si vous n'avez pas demandé cette réinitialisation, 
                ignorez cet email et votre mot de passe actuel restera inchangé. Nous vous recommandons 
                de changer votre mot de passe si vous pensez que votre compte a été compromis.
              </div>
            </div>
            
            <div class="footer">
              <div class="footer-logo">SMART MAINTENANCE</div>
              <p>Votre sécurité est notre priorité</p>
              <div class="divider"></div>
              <p>© ${new Date().getFullYear()} SMART MAINTENANCE - Tous droits réservés</p>
              <p style="margin-top: 15px; font-size: 11px; color: #999;">
                Cet email a été envoyé automatiquement, merci de ne pas y répondre directement.
              </p>
            </div>
          </div>
        </body>
        </html>
      `
    };

    // Envoyer le mail
    try {
      const info = await transporter.sendMail(mailOptions);
      console.log('📧 [Reset Code] Email envoyé avec succès à:', email);
      console.log('📧 [Reset Code] Code:', code);
      console.log('📧 [Reset Code] Message ID:', info.messageId);
      res.json({ success: true, message: 'Code envoyé par email' });
    } catch (mailError) {
      console.error('❌ [Reset Code] Erreur envoi email:', mailError);
      // En cas d'erreur email, on affiche quand même le code dans la console pour dev
      console.log('🔑 [Reset Code - DEV] Code pour', email, ':', code);
      res.status(500).json({ success: false, message: 'Erreur lors de l\'envoi du code par email' });
    }
  } catch (error) {
    console.error('❌ Erreur requestResetCode:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Vérifier uniquement le code (sans changer le mot de passe)
const checkResetCode = async (req, res) => {
  try {
    const { email, code } = req.body;
    
    // Détecter si c'est un email ou un téléphone
    const isPhone = email && !email.includes('@');
    let whereClause;
    
    if (isPhone) {
      const formattedPhone = formatPhoneNumber(email);
      whereClause = {
        [Op.or]: [
          { phone: formattedPhone },
          { phone: email }
        ]
      };
    } else {
      whereClause = { email };
    }
    
    const user = await User.findOne({ where: whereClause });
    if (!user) {
      return res.status(404).json({ success: false, message: 'Aucun compte associé à ce contact' });
    }
    
    // Vérifier si le code existe (même s'il est déjà utilisé)
    const existingCode = await PasswordResetCode.findOne({
      where: {
        user_id: user.id,
        code
      }
    });
    
    // Si le code existe et a déjà été utilisé
    if (existingCode && existingCode.used) {
      return res.status(400).json({ success: false, message: 'Ce code a déjà été utilisé. Veuillez demander un nouveau code.' });
    }
    
    // Vérifier si le code est valide et non expiré
    const resetCode = await PasswordResetCode.findOne({
      where: {
        user_id: user.id,
        code,
        used: false,
        expires_at: { [Op.gt]: new Date() }
      }
    });
    
    if (!resetCode) {
      return res.status(400).json({ success: false, message: 'Code invalide ou expiré' });
    }
    
    res.json({ success: true, message: 'Code valide' });
  } catch (error) {
    console.error('Erreur checkResetCode:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Vérifier le code et changer le mot de passe
const verifyResetCode = async (req, res) => {
  try {
    const { email, code, newPassword } = req.body;
    
    // Détecter si c'est un email ou un téléphone
    const isPhone = email && !email.includes('@');
    let whereClause;
    
    if (isPhone) {
      const formattedPhone = formatPhoneNumber(email);
      whereClause = {
        [Op.or]: [
          { phone: formattedPhone },
          { phone: email }
        ]
      };
    } else {
      whereClause = { email };
    }
    
    const user = await User.findOne({ where: whereClause });
    if (!user) {
      return res.status(404).json({ success: false, message: 'Aucun compte associé à ce contact' });
    }
    
    // Vérifier si le code existe (même s'il est déjà utilisé)
    const existingCode = await PasswordResetCode.findOne({
      where: {
        user_id: user.id,
        code
      }
    });
    
    // Si le code existe et a déjà été utilisé
    if (existingCode && existingCode.used) {
      return res.status(400).json({ success: false, message: 'Ce code a déjà été utilisé. Veuillez demander un nouveau code.' });
    }
    
    // Vérifier si le code est valide et non expiré
    const resetCode = await PasswordResetCode.findOne({
      where: {
        user_id: user.id,
        code,
        used: false,
        expires_at: { [Op.gt]: new Date() }
      }
    });
    
    if (!resetCode) {
      return res.status(400).json({ success: false, message: 'Code invalide ou expiré' });
    }
    // Changer le mot de passe
    user.password_hash = newPassword;
    await user.save();
    resetCode.used = true;
    await resetCode.save();
    res.json({ success: true, message: 'Mot de passe réinitialisé avec succès' });
  } catch (error) {
    console.error('Erreur verifyResetCode:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Generate JWT tokens
const generateTokens = (user) => {
  const accessToken = jwt.sign(
    { id: user.id, email: user.email, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRE || '7d' }
  );

  const refreshToken = jwt.sign(
    { id: user.id, email: user.email, role: user.role },
    process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_REFRESH_EXPIRE || '30d' }
  );

  return { accessToken, refreshToken };
};

// Register new user
const register = async (req, res) => {
  try {
    // Debug: Afficher les données reçues
    console.log('📝 Données d\'inscription reçues:', {
      email: req.body.email,
      phone: req.body.phone,
      role: req.body.role,
      first_name: req.body.first_name,
      last_name: req.body.last_name,
      hasPassword: !!req.body.password,
      bodyKeys: Object.keys(req.body)
    });

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log('❌ Erreurs de validation:', errors.array());
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }


  const { email, password, phone, role, first_name, last_name, verification_method, ...profileData } = req.body;

    // verification_method peut être: 'sms', 'email', ou 'auto' (défaut)
    // 'auto' = SMS si disponible, sinon email
    const preferredMethod = verification_method || 'auto';
    console.log('📧 Méthode de vérification demandée:', preferredMethod);

    // 🔒 RESTRICTION: Seul un admin peut créer un admin ou manager
    let creatorId = null;
    if (role === 'admin' || role === 'manager') {
      // Vérifier si un token est présent dans la requête
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(403).json({
          success: false,
          message: 'Seul un administrateur peut créer un compte admin ou manager'
        });
      }
      
      const token = authHeader.split(' ')[1];
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const currentUser = await User.findByPk(decoded.id);
        
        if (!currentUser || currentUser.role !== 'admin') {
          return res.status(403).json({
            success: false,
            message: 'Seul un administrateur peut créer un compte admin ou manager'
          });
        }
        
        creatorId = currentUser.id;
        console.log(`🔐 Admin ${currentUser.id} crée un compte ${role}`);
      } catch (tokenError) {
        return res.status(403).json({
          success: false,
          message: 'Seul un administrateur peut créer un compte admin ou manager'
        });
      }
    }

    // Nettoyer et valider les données
    const cleanEmail = email && email.trim() !== '' ? email.trim() : null;
    let cleanPhone = phone && phone.trim() !== '' ? phone.trim() : null;
    
    // Formater le téléphone pour la Côte d'Ivoire
    if (cleanPhone) {
      const originalPhone = cleanPhone;
      cleanPhone = formatPhoneNumber(cleanPhone);
      console.log('📞 Téléphone formaté:', originalPhone, '→', cleanPhone);
    }

    // Vérifier qu'au moins email ou phone est fourni
    if (!cleanEmail && !cleanPhone) {
      return res.status(400).json({
        success: false,
        message: 'Email or phone number is required'
      });
    }

    // Check if user already exists by email (si email fourni)
    let existingUser = null;
    if (cleanEmail) {
      existingUser = await User.findOne({ where: { email: cleanEmail } });
    }
    
    // Si l'utilisateur existe et est supprimé, on modifie son email pour libérer l'adresse
    if (existingUser && existingUser.status === 'deleted') {
      // Modifier l'email de l'ancien compte pour libérer l'adresse
      const oldEmail = existingUser.email;
      const timestamp = Date.now();
      await existingUser.update({
        email: existingUser.email ? `deleted_${timestamp}_${existingUser.email}` : null,
        phone: existingUser.phone ? `deleted_${timestamp}_${existingUser.phone}` : null
      });
      console.log(`✅ Email libéré pour réutilisation: ${oldEmail}`);
      
      // Revérifier que l'email est bien libéré
      existingUser = cleanEmail ? await User.findOne({ where: { email: cleanEmail } }) : null;
    }
    
    if (existingUser) {
      // Si l'utilisateur existe et n'est pas supprimé
      return res.status(409).json({
        success: false,
        message: 'User with this email already exists'
      });
    }

    // Check phone number if provided
    if (cleanPhone) {
      let existingPhone = await User.findOne({ where: { phone: cleanPhone } });
      
      // Si le téléphone existe et est supprimé, on le libère aussi
      if (existingPhone && existingPhone.status === 'deleted') {
        const oldPhone = existingPhone.phone;
        const timestamp = Date.now();
        await existingPhone.update({
          email: existingPhone.email ? `deleted_${timestamp}_${existingPhone.email}` : null,
          phone: `deleted_${timestamp}_${existingPhone.phone}`
        });
        console.log(`✅ Téléphone libéré pour réutilisation: ${oldPhone}`);
        
        // Revérifier
        existingPhone = await User.findOne({ where: { phone: cleanPhone } });
      }
      
      if (existingPhone) {
        return res.status(409).json({
          success: false,
          message: 'User with this phone already exists'
        });
      }
    }

    // Create user with pending status
    const user = await User.create({
      email: cleanEmail, // Peut être NULL si inscription par téléphone uniquement
      password_hash: password,
      phone: cleanPhone,
      role: role || 'customer',
      status: 'pending', // Toujours pending jusqu'à vérification
      first_name,
      last_name,
      profile_image: req.body.profile_image || null,
      created_by: creatorId // ID de l'admin qui a créé ce compte (pour admin/manager)
    });

    console.log('✅ Utilisateur créé:', {
      id: user.id,
      email: user.email,
      phone: user.phone,
      role: user.role,
      created_by: user.created_by
    });

    // Create profile based on role
    if (user.role === 'customer') {
      await CustomerProfile.create({
        user_id: user.id,
        first_name,
        last_name,
        ...profileData
      });
    } else if (user.role === 'technician') {
      await TechnicianProfile.create({
        user_id: user.id,
        first_name,
        last_name,
        phone: cleanPhone, // Ajout explicite du téléphone pour le profil technicien
        ...profileData
      });
    }

    // Generate verification code
    const verificationCode = EmailVerificationCode.generateCode();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes
    
    await EmailVerificationCode.create({
      user_id: user.id,
      code: verificationCode,
      expires_at: expiresAt
    });

    // Déterminer la méthode de vérification à utiliser
    // preferredMethod: 'sms', 'email', ou 'auto'
    const smsAvailable = user.phone && process.env.USE_SMS_VERIFICATION === 'true';
    const emailAvailable = user.email && user.email.trim() !== '';
    
    let useSMS = false;
    let useEmail = false;
    
    if (preferredMethod === 'sms') {
      // L'utilisateur veut SMS
      if (smsAvailable) {
        useSMS = true;
      } else if (emailAvailable) {
        // Fallback vers email si SMS non disponible
        useEmail = true;
        console.log('⚠️ SMS demandé mais non disponible, fallback vers email');
      }
    } else if (preferredMethod === 'email') {
      // L'utilisateur veut Email
      if (emailAvailable) {
        useEmail = true;
      } else if (smsAvailable) {
        // Fallback vers SMS si email non disponible
        useSMS = true;
        console.log('⚠️ Email demandé mais non disponible, fallback vers SMS');
      }
    } else {
      // Mode auto: SMS prioritaire si disponible
      if (smsAvailable) {
        useSMS = true;
      } else if (emailAvailable) {
        useEmail = true;
      }
    }

    console.log('🔍 Vérification:', {
      preferredMethod,
      hasPhone: !!user.phone,
      hasEmail: !!user.email,
      smsAvailable,
      emailAvailable,
      willUseSMS: useSMS,
      willUseEmail: useEmail
    });

    if (useSMS) {
      // Envoyer le code par SMS
      try {
        console.log(`📱 Envoi du code de vérification par SMS à ${user.phone}`);
        console.log(`🔢 Code de vérification: ${verificationCode}`);
        
        const smsResult = await sendVerificationCodeSMS(user.phone, verificationCode, user.first_name);
        
        console.log('📊 Résultat envoi SMS:', smsResult);
        
        if (smsResult.success) {
          console.log('✅ SMS de vérification envoyé avec succès');
          const { accessToken, refreshToken } = generateTokens(user);
          
          return res.status(201).json({
            success: true,
            message: 'Inscription réussie. Code de vérification envoyé par SMS',
            user: {
              id: user.id,
              email: user.email,
              phone: user.phone,
              role: user.role,
              first_name: user.first_name,
              last_name: user.last_name,
              status: user.status
            },
            accessToken,
            refreshToken,
            verificationMethod: 'sms'
          });
        } else {
          console.error('❌ Échec envoi SMS:', smsResult.error);
          // Fallback vers email en cas d'échec SMS (seulement si email disponible)
          if (emailAvailable) {
            console.log('📧 Fallback: envoi par email...');
            useEmail = true;
          }
        }
      } catch (smsError) {
        console.error('❌ Erreur SMS:', smsError.message);
        // Continuer avec l'email en cas d'erreur (seulement si disponible)
        if (emailAvailable) {
          useEmail = true;
        }
      }
    }

    // Envoyer par email si demandé ou en fallback
    if (useEmail && emailAvailable) {
    try {
      const transporter = createTransporter();
      const fromAddress = process.env.EMAIL_SERVICE === 'gmail' 
        ? process.env.EMAIL_USER 
        : (process.env.SMTP_FROM || process.env.EMAIL_USER);
      
      const mailOptions = {
        from: {
          name: process.env.SMTP_FROM_NAME || 'SMART MAINTENANCE',
          address: fromAddress
        },
        to: user.email,
        subject: 'Code de vérification - SMART MAINTENANCE',
        headers: {
          'X-Priority': '1',
          'X-MSMail-Priority': 'High',
          'Importance': 'high',
          'X-Mailer': 'SMART MAINTENANCE System',
          'List-Unsubscribe': `<mailto:${process.env.SMTP_FROM}?subject=unsubscribe>`
        },
        text: `Bonjour ${user.first_name},

Merci de vous être inscrit sur SMART MAINTENANCE !

Votre code de vérification est : ${verificationCode}

Ce code expire dans 15 minutes.

Entrez ce code dans l'application pour activer votre compte.

Si vous n'avez pas créé de compte, ignorez simplement cet email.

© ${new Date().getFullYear()} SMART MAINTENANCE - Tous droits réservés`,
        html: `
          <!DOCTYPE html>
          <html lang="fr">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              * { margin: 0; padding: 0; box-sizing: border-box; }
              body { 
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                line-height: 1.6; 
                color: #333; 
                background-color: #f4f4f4;
                padding: 20px;
              }
              .email-wrapper { 
                max-width: 600px; 
                margin: 0 auto; 
                background: white;
                border-radius: 10px;
                overflow: hidden;
                box-shadow: 0 4px 6px rgba(0,0,0,0.1);
              }
              .header { 
                background: linear-gradient(135deg, #0a543d 0%, #0d7050 100%);
                color: white; 
                padding: 40px 20px; 
                text-align: center;
              }
              .header h1 {
                font-size: 28px;
                margin-bottom: 10px;
                font-weight: 600;
              }
              .header p {
                font-size: 16px;
                opacity: 0.9;
              }
              .icon {
                font-size: 48px;
                margin-bottom: 15px;
              }
              .content { 
                background-color: #ffffff; 
                padding: 40px 30px;
              }
              .greeting {
                font-size: 20px;
                color: #0a543d;
                margin-bottom: 20px;
                font-weight: 600;
              }
              .message {
                font-size: 15px;
                color: #555;
                margin-bottom: 25px;
                line-height: 1.8;
              }
              .code-container {
                background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
                border: 2px dashed #0a543d;
                border-radius: 10px;
                padding: 30px;
                margin: 30px 0;
                text-align: center;
              }
              .code-label {
                font-size: 14px;
                color: #666;
                margin-bottom: 10px;
                text-transform: uppercase;
                letter-spacing: 1px;
              }
              .code { 
                font-size: 40px; 
                font-weight: bold; 
                color: #0a543d; 
                letter-spacing: 8px;
                font-family: 'Courier New', monospace;
                display: inline-block;
                padding: 10px 20px;
                background: white;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
              }
              .expiry-notice {
                background-color: #fff3cd;
                border-left: 4px solid #ffc107;
                padding: 15px;
                margin: 25px 0;
                border-radius: 4px;
              }
              .expiry-notice strong {
                color: #856404;
                display: flex;
                align-items: center;
                gap: 8px;
              }
              .security-notice {
                background-color: #e8f5e9;
                border-left: 4px solid #4caf50;
                padding: 15px;
                margin: 25px 0;
                border-radius: 4px;
                font-size: 14px;
                color: #2e7d32;
              }
              .footer { 
                background-color: #f8f9fa;
                text-align: center; 
                padding: 30px 20px; 
                color: #666; 
                font-size: 13px;
                border-top: 1px solid #e0e0e0;
              }
              .footer-logo {
                font-size: 20px;
                font-weight: bold;
                color: #0a543d;
                margin-bottom: 10px;
              }
              .footer-links {
                margin: 15px 0;
              }
              .footer-links a {
                color: #0a543d;
                text-decoration: none;
                margin: 0 10px;
                font-size: 12px;
              }
              .divider {
                height: 1px;
                background: linear-gradient(to right, transparent, #ddd, transparent);
                margin: 20px 0;
              }
              @media only screen and (max-width: 600px) {
                .code { font-size: 32px; letter-spacing: 6px; }
                .content { padding: 25px 20px; }
                .header h1 { font-size: 24px; }
              }
            </style>
          </head>
          <body>
            <div class="email-wrapper">
              <div class="header">
                <div class="icon">&#128272;</div>
                <h1>Bienvenue sur SMART MAINTENANCE</h1>
                <p>Vérification de votre compte</p>
              </div>
              
              <div class="content">
                <div class="greeting">Bonjour ${user.first_name} ! &#128075;</div>
                
                <p class="message">
                  Nous sommes ravis de vous compter parmi nous ! Pour finaliser la création de votre compte 
                  et accéder à tous nos services de maintenance, veuillez utiliser le code de vérification ci-dessous.
                </p>
                
                <div class="code-container">
                  <div class="code-label">Votre code de vérification</div>
                  <div class="code">${verificationCode}</div>
                </div>
                
                <div class="expiry-notice">
                  <strong>&#9201;&#65039; Important : Ce code expire dans 15 minutes</strong>
                </div>
                
                <p class="message">
                  Entrez ce code dans l'application mobile SMART MAINTENANCE pour activer votre compte 
                  et commencer à profiter de nos services.
                </p>
                
                <div class="divider"></div>
                
                <div class="security-notice">
                  &#128737;&#65039; <strong>Note de sécurité :</strong> Si vous n'avez pas créé de compte, 
                  ignorez simplement cet email. Votre adresse email ne sera pas utilisée sans votre consentement.
                </div>
              </div>
              
              <div class="footer">
                <div class="footer-logo">SMART MAINTENANCE</div>
                <p>Votre partenaire pour une maintenance intelligente et efficace</p>
                <div class="divider"></div>
                <p>© ${new Date().getFullYear()} SMART MAINTENANCE - Tous droits réservés</p>
                <div class="footer-links">
                  <a href="#">Politique de confidentialité</a> | 
                  <a href="#">Conditions d'utilisation</a> | 
                  <a href="#">Support</a>
                </div>
                <p style="margin-top: 15px; font-size: 11px; color: #999;">
                  Cet email a été envoyé automatiquement, merci de ne pas y répondre directement.
                </p>
              </div>
            </div>
          </body>
          </html>
        `
      };
      
      await transporter.sendMail(mailOptions);
      console.log('✅ Code de vérification envoyé à:', user.email, '- Code:', verificationCode);
      
      // Retourner immédiatement après envoi email réussi
      const { accessToken, refreshToken } = generateTokens(user);
      
      return res.status(201).json({
        success: true,
        message: 'Inscription réussie. Code de vérification envoyé par email',
        user: {
          id: user.id,
          email: user.email,
          phone: user.phone,
          role: user.role,
          first_name: user.first_name,
          last_name: user.last_name,
          status: user.status
        },
        accessToken,
        refreshToken,
        verificationMethod: 'email'
      });
    } catch (emailError) {
      console.error('❌ Erreur envoi email vérification:', emailError);
      // On continue même si l'email échoue
    }
    }

    // Si aucune méthode n'a fonctionné ou en cas d'erreur, retourner quand même un succès
    // (le compte est créé, l'utilisateur peut demander un renvoi du code)
    const { accessToken, refreshToken } = generateTokens(user);

    // Cache user data
    await cache.set(`user:${user.id}`, user.toJSON(), 3600);

    // Déterminer la méthode qui aurait dû être utilisée pour le message
    const fallbackMethod = emailAvailable ? 'email' : (smsAvailable ? 'sms' : 'none');

    res.status(201).json({
      success: true,
      message: fallbackMethod === 'email' 
        ? 'Un code de vérification a été envoyé à votre email.'
        : fallbackMethod === 'sms'
          ? 'Un code de vérification a été envoyé par SMS.'
          : 'Compte créé. Veuillez contacter le support pour la vérification.',
      requiresVerification: true,
      verificationMethod: fallbackMethod,
      userId: user.id,
      user: {
        id: user.id,
        email: user.email,
        phone: user.phone,
        role: user.role,
        first_name: user.first_name,
        last_name: user.last_name,
        status: user.status
      },
      accessToken,
      refreshToken
    });
  } catch (error) {
    console.error('Registration error:', error);
    // Gestion explicite des erreurs de contrainte unique (email déjà utilisé)
    if (error.name === 'SequelizeUniqueConstraintError' && error.errors && error.errors.length > 0) {
      const field = error.errors[0].path;
      const value = error.errors[0].value;
      return res.status(409).json({
        success: false,
        message: `Un utilisateur avec ce ${field} existe déjà (${value})`
      });
    }
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Login user
const login = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const { email, password } = req.body;
    
    // Déterminer si c'est un email ou un téléphone
    const isEmail = email && email.includes('@');
    const isPhone = email && !email.includes('@') && /^\d+$/.test(email.replace(/[\s\-\+]/g, ''));
    
    let user = null;
    
    if (isEmail) {
      // Recherche par email
      user = await User.findOne({ where: { email } });
    } else if (isPhone) {
      // Formater le numéro de téléphone (formatPhoneNumber est déjà importé en haut du fichier)
      const formattedPhone = formatPhoneNumber(email);
      console.log('📱 Connexion par téléphone:', email, '→', formattedPhone);
      
      // Recherche par téléphone (essayer le format original et le format avec 225)
      user = await User.findOne({ 
        where: { 
          [Op.or]: [
            { phone: formattedPhone },
            { phone: email }
          ]
        } 
      });
    } else {
      // Essayer les deux (email ou téléphone)
      user = await User.findOne({ 
        where: { 
          [Op.or]: [
            { email },
            { phone: email }
          ]
        } 
      });
    }

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Check password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Ne pas bloquer si le compte est pending, mais le signaler dans la réponse
    // Bloquer uniquement si le compte est deleted ou inactive
    if (user.status === 'deleted' || user.status === 'inactive') {
      return res.status(401).json({
        success: false,
        message: 'Account is not active. Please contact support.'
      });
    }

    // Update last login
    await user.update({ last_login: new Date() });

    // Generate tokens
    const { accessToken, refreshToken } = generateTokens(user);

    // Get user profile
    let profile = null;
    if (user.role === 'customer') {
      profile = await CustomerProfile.findOne({ where: { user_id: user.id } });
    } else if (user.role === 'technician') {
      profile = await TechnicianProfile.findOne({ where: { user_id: user.id } });
    }

    // Cache user data
    await cache.set(`user:${user.id}`, user.toJSON(), 3600);

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: user.toJSON(),
        profile: profile ? profile.toJSON() : null,
        accessToken,
        refreshToken
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get current user profile
const getProfile = async (req, res) => {
  try {
    const user = req.user;
    let profile = null;

    if (user.role === 'customer') {
      profile = await CustomerProfile.findOne({ where: { user_id: user.id } });
    } else if (user.role === 'technician') {
      profile = await TechnicianProfile.findOne({ where: { user_id: user.id } });
    }

    res.json({
      success: true,
      data: {
        user: user.toJSON(),
        profile: profile ? profile.toJSON() : null
      }
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Update user profile
const updateProfile = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const user = req.user;
    const { email, phone, profile_image, first_name, last_name, ...profileData } = req.body;

    console.log('📝 Mise à jour du profil pour user:', user.id);
    console.log('📦 Données reçues:', req.body);
    console.log('🖼️ profile_image reçu:', profile_image);
    console.log('🖼️ profile_image actuel:', user.profile_image);

    // Update user basic info including profile image, first_name, last_name
    if (email || phone || profile_image || first_name || last_name) {
      const updateData = {
        ...(email && { email }),
        ...(phone && { phone }),
        ...(profile_image && { profile_image }),
        ...(first_name && { first_name }),
        ...(last_name && { last_name })
      };
      
      console.log('🔄 Mise à jour de la table users avec:', updateData);
      await user.update(updateData);
      // Rafraîchir pour avoir les données à jour
      await user.reload();
      console.log('✅ Table users mise à jour');
      console.log('🖼️ profile_image après update:', user.profile_image);
    }

    // Update profile
    let profile = null;
    if (user.role === 'customer') {
      profile = await CustomerProfile.findOne({ where: { user_id: user.id } });
      if (profile) {
        await profile.update(profileData);
      }
    } else if (user.role === 'technician') {
      profile = await TechnicianProfile.findOne({ where: { user_id: user.id } });
      if (profile) {
        await profile.update(profileData);
      }
    }

    // Clear cache
    await cache.del(`user:${user.id}`);

    console.log('📤 Envoi de la réponse avec profile_image:', user.profile_image);

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        user: user.toJSON(),
        profile: profile ? profile.toJSON() : null
      }
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Change password
const changePassword = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const user = req.user;
    const { currentPassword, newPassword } = req.body;

    // Verify current password
    const isCurrentPasswordValid = await user.comparePassword(currentPassword);
    if (!isCurrentPasswordValid) {
      return res.status(400).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }

    // Update password
    await user.update({ password_hash: newPassword });

    // Clear cache
    await cache.del(`user:${user.id}`);

    res.json({
      success: true,
      message: 'Password changed successfully'
    });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Logout user
const logout = async (req, res) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (token) {
      // Blacklist the token
      const decoded = jwt.decode(token);
      const expiresIn = decoded.exp - Math.floor(Date.now() / 1000);
      if (expiresIn > 0) {
        await cache.set(`blacklist:${token}`, true, expiresIn);
      }
    }

    // Clear user cache
    if (req.user) {
      await cache.del(`user:${req.user.id}`);
      
      // ⭐ Supprimer le FCM token lors de la déconnexion
      try {
        const user = await User.findByPk(req.user.id);
        if (user && user.fcm_token) {
          console.log(`🔕 Suppression du FCM token pour user ${req.user.id}`);
          await user.update({ fcm_token: null });
        }
      } catch (fcmError) {
        console.error('⚠️  Erreur suppression FCM token:', fcmError.message);
        // Ne pas bloquer la déconnexion si ça échoue
      }
    }

    res.json({
      success: true,
      message: 'Logout successful'
    });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Update FCM token
const updateFcmToken = async (req, res) => {
  try {
    const { fcm_token } = req.body;
    const userId = req.user.id;

    console.log('📱 Mise à jour du token FCM');
    console.log(`   User ID: ${userId}`);
    console.log(`   Token: ${fcm_token ? fcm_token.substring(0, 20) + '...' : 'null'}`);

    if (!fcm_token) {
      return res.status(400).json({
        success: false,
        message: 'Token FCM requis'
      });
    }

    // IMPORTANT : Supprimer ce token des autres utilisateurs pour éviter les doublons
    // (cas où le même appareil est utilisé par plusieurs comptes)
    const usersWithSameToken = await User.findAll({
      where: {
        fcm_token,
        id: { [Op.ne]: userId } // Exclure l'utilisateur actuel
      },
      attributes: ['id', 'email']
    });

    if (usersWithSameToken.length > 0) {
      console.log(`⚠️  Token FCM déjà utilisé par ${usersWithSameToken.length} autre(s) utilisateur(s):`);
      usersWithSameToken.forEach(u => console.log(`   - User ${u.id} (${u.email})`));
      
      // Supprimer le token des autres utilisateurs
      await User.update(
        { fcm_token: null },
        {
          where: {
            fcm_token,
            id: { [Op.ne]: userId }
          },
          validate: false, // Éviter les erreurs de validation
          hooks: false
        }
      );
      console.log('🧹 Token supprimé des autres utilisateurs');
    }

    // Mettre à jour le token FCM de l'utilisateur actuel
    await User.update(
      { fcm_token },
      { 
        where: { id: userId },
        validate: false, // Éviter les erreurs de validation emailOrPhone
        hooks: false
      }
    );

    console.log(`✅ Token FCM enregistré avec succès pour user ${userId}`);

    res.json({
      success: true,
      message: 'Token FCM enregistré avec succès'
    });
  } catch (error) {
    console.error('❌ Erreur mise à jour token FCM:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'enregistrement du token FCM'
    });
  }
};

// Vérifier le code de vérification email
const verifyEmailCode = async (req, res) => {
  try {
    console.log('🔍 Début vérification code');
    const { email, phone, code } = req.body;
    console.log('📧 Email:', email, '- 📱 Phone:', phone, '- Code:', code);

    if ((!email && !phone) || !code) {
      return res.status(400).json({
        success: false,
        message: 'Email ou téléphone et code requis'
      });
    }

    // Trouver l'utilisateur par email ou téléphone
    console.log('🔍 Recherche utilisateur...');
    let whereClause = {};
    if (email && email.trim() !== '') {
      whereClause.email = email;
    } else if (phone && phone.trim() !== '') {
      whereClause.phone = phone;
    }

    const user = await User.findOne({ where: whereClause });
    if (!user) {
      console.log('❌ Utilisateur non trouvé');
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }
    console.log('✅ Utilisateur trouvé:', user.id);

    // Vérifier si le code existe et est valide
    console.log('🔍 Recherche du code de vérification...');
    const verificationCode = await EmailVerificationCode.findOne({
      where: {
        user_id: user.id,
        code,
        used: false,
        expires_at: { [Op.gt]: new Date() }
      }
    });

    if (!verificationCode) {
      console.log('❌ Code invalide ou expiré');
      return res.status(400).json({
        success: false,
        message: 'Code invalide ou expiré'
      });
    }
    console.log('✅ Code valide trouvé');

    // Marquer le code comme utilisé
    console.log('🔄 Marquage du code comme utilisé...');
    await verificationCode.update({ used: true });

    // Activer le compte
    console.log('🔄 Activation du compte...');
    await user.update({ status: 'active' });

    // Mettre à jour le cache
    await cache.set(`user:${user.id}`, user.toJSON(), 3600);

    console.log(`✅ Email vérifié pour: ${user.email}`);

    res.json({
      success: true,
      message: 'Email vérifié avec succès. Votre compte est maintenant actif.'
    });
  } catch (error) {
    console.error('❌ Erreur vérification code email:', error);
    console.error('Stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Renvoyer le code de vérification
const resendEmailVerificationCode = async (req, res) => {
  try {
    const { email, phone, verification_method } = req.body;
    console.log('🔄 Renvoi code - Email:', email, '- Phone:', phone, '- Méthode:', verification_method);

    // verification_method peut être: 'sms', 'email', ou 'auto' (défaut)
    const preferredMethod = verification_method || 'auto';

    if (!email && !phone) {
      return res.status(400).json({
        success: false,
        message: 'Email ou téléphone requis'
      });
    }

    // Trouver l'utilisateur par email ou téléphone
    let whereClause = {};
    if (email && email.trim() !== '') {
      whereClause.email = email;
    } else if (phone && phone.trim() !== '') {
      // Formater le téléphone avant la recherche
      whereClause.phone = formatPhoneNumber(phone.trim());
      console.log('📱 Recherche avec téléphone formaté:', whereClause.phone);
    }

    const user = await User.findOne({ where: whereClause });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Aucun compte trouvé avec cet email'
      });
    }

    if (user.status === 'active') {
      return res.status(400).json({
        success: false,
        message: 'Ce compte est déjà vérifié'
      });
    }

    // Générer un nouveau code
    const verificationCode = EmailVerificationCode.generateCode();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes

    await EmailVerificationCode.create({
      user_id: user.id,
      code: verificationCode,
      expires_at: expiresAt
    });

    // Déterminer la méthode de vérification à utiliser
    const smsAvailable = user.phone && process.env.USE_SMS_VERIFICATION === 'true';
    const emailAvailable = user.email && user.email.trim() !== '';
    
    let useSMS = false;
    let useEmail = false;
    
    if (preferredMethod === 'sms') {
      if (smsAvailable) {
        useSMS = true;
      } else if (emailAvailable) {
        useEmail = true;
        console.log('⚠️ SMS demandé mais non disponible, fallback vers email');
      }
    } else if (preferredMethod === 'email') {
      if (emailAvailable) {
        useEmail = true;
      } else if (smsAvailable) {
        useSMS = true;
        console.log('⚠️ Email demandé mais non disponible, fallback vers SMS');
      }
    } else {
      // Mode auto: SMS prioritaire si disponible
      if (smsAvailable) {
        useSMS = true;
      } else if (emailAvailable) {
        useEmail = true;
      }
    }

    console.log('🔍 Méthode renvoi:', { preferredMethod, useSMS, useEmail });

    if (useSMS) {
      // Envoyer par SMS
      try {
        console.log(`📱 Renvoi code par SMS à ${user.phone}`);
        const smsResult = await sendVerificationCodeSMS(user.phone, verificationCode, user.first_name);
        
        if (smsResult.success) {
          console.log('✅ Nouveau code envoyé par SMS:', verificationCode);
          return res.json({
            success: true,
            message: 'Un nouveau code de vérification a été envoyé par SMS',
            verificationMethod: 'sms'
          });
        } else {
          console.error('❌ Échec envoi SMS:', smsResult.error);
          // Continuer vers l'email en fallback si disponible
          if (emailAvailable) {
            useEmail = true;
          }
        }
      } catch (smsError) {
        console.error('❌ Erreur SMS:', smsError.message);
        // Continuer vers l'email en fallback si disponible
        if (emailAvailable) {
          useEmail = true;
        }
      }
    }

    // Envoyer l'email si demandé ou en fallback
    if (useEmail && emailAvailable) {
    try {
      const transporter = createTransporter();
      const fromAddress = process.env.EMAIL_SERVICE === 'gmail' 
        ? process.env.EMAIL_USER 
        : (process.env.SMTP_FROM || process.env.EMAIL_USER);
      
      const mailOptions = {
        from: {
          name: process.env.SMTP_FROM_NAME || 'SMART MAINTENANCE',
          address: fromAddress
        },
        to: user.email,
        subject: 'Code de vérification - SMART MAINTENANCE',
        headers: {
          'X-Priority': '1',
          'X-MSMail-Priority': 'High',
          'Importance': 'high',
          'X-Mailer': 'SMART MAINTENANCE System',
          'List-Unsubscribe': `<mailto:${process.env.SMTP_FROM}?subject=unsubscribe>`
        },
        text: `Bonjour ${user.first_name},

Voici votre nouveau code de vérification : ${verificationCode}

Ce code expire dans 15 minutes.

© ${new Date().getFullYear()} SMART MAINTENANCE - Tous droits réservés`,
        html: `
          <!DOCTYPE html>
          <html lang="fr">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              * { margin: 0; padding: 0; box-sizing: border-box; }
              body { 
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                line-height: 1.6; 
                color: #333; 
                background-color: #f4f4f4;
                padding: 20px;
              }
              .email-wrapper { 
                max-width: 600px; 
                margin: 0 auto; 
                background: white;
                border-radius: 10px;
                overflow: hidden;
                box-shadow: 0 4px 6px rgba(0,0,0,0.1);
              }
              .header { 
                background: linear-gradient(135deg, #2196F3 0%, #1976D2 100%);
                color: white; 
                padding: 40px 20px; 
                text-align: center;
              }
              .header h1 {
                font-size: 28px;
                margin-bottom: 10px;
                font-weight: 600;
              }
              .header p {
                font-size: 16px;
                opacity: 0.9;
              }
              .icon {
                font-size: 48px;
                margin-bottom: 15px;
              }
              .content { 
                background-color: #ffffff; 
                padding: 40px 30px;
              }
              .greeting {
                font-size: 20px;
                color: #1976D2;
                margin-bottom: 20px;
                font-weight: 600;
              }
              .message {
                font-size: 15px;
                color: #555;
                margin-bottom: 25px;
                line-height: 1.8;
              }
              .code-container {
                background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%);
                border: 2px dashed #2196F3;
                border-radius: 10px;
                padding: 30px;
                margin: 30px 0;
                text-align: center;
              }
              .code-label {
                font-size: 14px;
                color: #666;
                margin-bottom: 10px;
                text-transform: uppercase;
                letter-spacing: 1px;
              }
              .code { 
                font-size: 40px; 
                font-weight: bold; 
                color: #1976D2; 
                letter-spacing: 8px;
                font-family: 'Courier New', monospace;
                display: inline-block;
                padding: 10px 20px;
                background: white;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
              }
              .expiry-notice {
                background-color: #fff3cd;
                border-left: 4px solid #ffc107;
                padding: 15px;
                margin: 25px 0;
                border-radius: 4px;
              }
              .expiry-notice strong {
                color: #856404;
                display: flex;
                align-items: center;
                gap: 8px;
              }
              .footer { 
                background-color: #f8f9fa;
                text-align: center; 
                padding: 30px 20px; 
                color: #666; 
                font-size: 13px;
                border-top: 1px solid #e0e0e0;
              }
              .footer-logo {
                font-size: 20px;
                font-weight: bold;
                color: #1976D2;
                margin-bottom: 10px;
              }
              .divider {
                height: 1px;
                background: linear-gradient(to right, transparent, #ddd, transparent);
                margin: 20px 0;
              }
              @media only screen and (max-width: 600px) {
                .code { font-size: 32px; letter-spacing: 6px; }
                .content { padding: 25px 20px; }
                .header h1 { font-size: 24px; }
              }
            </style>
          </head>
          <body>
            <div class="email-wrapper">
              <div class="header">
                <div class="icon">&#128260;</div>
                <h1>Nouveau code de vérification</h1>
                <p>SMART MAINTENANCE</p>
              </div>
              
              <div class="content">
                <div class="greeting">Bonjour ${user.first_name} ! &#128075;</div>
                
                <p class="message">
                  Vous avez demandé un nouveau code de vérification. Voici votre nouveau code :
                </p>
                
                <div class="code-container">
                  <div class="code-label">Votre nouveau code</div>
                  <div class="code">${verificationCode}</div>
                </div>
                
                <div class="expiry-notice">
                  <strong>&#9201;&#65039; Important : Ce code expire dans 15 minutes</strong>
                </div>
                
                <p class="message">
                  Entrez ce code dans l'application mobile pour continuer la vérification de votre compte.
                </p>
              </div>
              
              <div class="footer">
                <div class="footer-logo">SMART MAINTENANCE</div>
                <div class="divider"></div>
                <p>© ${new Date().getFullYear()} SMART MAINTENANCE - Tous droits réservés</p>
              </div>
            </div>
          </body>
          </html>
        `
      };

      await transporter.sendMail(mailOptions);
      console.log('✅ Nouveau code envoyé à:', user.email, '- Code:', verificationCode);

      return res.json({
        success: true,
        message: 'Un nouveau code de vérification a été envoyé à votre email',
        verificationMethod: 'email'
      });
    } catch (emailError) {
      console.error('❌ Erreur envoi email:', emailError);
      return res.status(500).json({
        success: false,
        message: 'Erreur lors de l\'envoi de l\'email'
      });
    }
    }

    // Si aucune méthode n'a fonctionné
    res.status(500).json({
      success: false,
      message: 'Impossible d\'envoyer le code de vérification. Vérifiez votre email ou numéro de téléphone.'
    });
  } catch (error) {
    console.error('Erreur resendEmailVerificationCode:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
};

// Forgot Password - Send reset email with code
const forgotPassword = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const { email } = req.body;

    // Check if user exists
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Aucun compte associé à cet email'
      });
    }

    // Generate 6-digit reset code
    const resetCode = PasswordResetCode.generateCode();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes

    // Save reset code to database
    await PasswordResetCode.create({
      user_id: user.id,
      code: resetCode,
      expires_at: expiresAt,
      used: false
    });

    console.log('🔐 [Forgot Password] Code generated for:', email, '- Code:', resetCode);

    // Send email with reset code
    try {
      const transporter = createTransporter();
      const fromAddress = process.env.EMAIL_SERVICE === 'gmail' 
        ? process.env.EMAIL_USER 
        : (process.env.SMTP_FROM || process.env.EMAIL_USER);

      const mailOptions = {
        from: {
          name: process.env.SMTP_FROM_NAME || 'SMART MAINTENANCE',
          address: fromAddress
        },
        to: user.email,
        subject: 'Réinitialisation de mot de passe - SMART MAINTENANCE',
        headers: {
          'X-Priority': '1',
          'X-MSMail-Priority': 'High',
          'Importance': 'high',
          'X-Mailer': 'SMART MAINTENANCE System',
          'List-Unsubscribe': `<mailto:${process.env.SMTP_FROM}?subject=unsubscribe>`
        },
        text: `Bonjour ${user.first_name},

Vous avez demandé la réinitialisation de votre mot de passe.

Votre code de réinitialisation est : ${resetCode}

Ce code expire dans 15 minutes.

Entrez ce code dans l'application pour réinitialiser votre mot de passe.

Si vous n'avez pas demandé cette réinitialisation, ignorez simplement cet email.

© ${new Date().getFullYear()} SMART MAINTENANCE - Tous droits réservés`,
        html: `
          <!DOCTYPE html>
          <html lang="fr">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              * { margin: 0; padding: 0; box-sizing: border-box; }
              body { 
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                line-height: 1.6; 
                color: #333; 
                background-color: #f4f4f4;
                padding: 20px;
              }
              .email-wrapper { 
                max-width: 600px; 
                margin: 0 auto; 
                background: white;
                border-radius: 10px;
                overflow: hidden;
                box-shadow: 0 4px 6px rgba(0,0,0,0.1);
              }
              .header { 
                background: linear-gradient(135deg, #f44336 0%, #d32f2f 100%);
                color: white; 
                padding: 40px 20px; 
                text-align: center;
              }
              .header h1 {
                font-size: 28px;
                margin-bottom: 10px;
                font-weight: 600;
              }
              .header p {
                font-size: 16px;
                opacity: 0.9;
              }
              .icon {
                font-size: 48px;
                margin-bottom: 15px;
              }
              .content { 
                background-color: #ffffff; 
                padding: 40px 30px;
              }
              .greeting {
                font-size: 20px;
                color: #d32f2f;
                margin-bottom: 20px;
                font-weight: 600;
              }
              .message {
                font-size: 15px;
                color: #555;
                margin-bottom: 25px;
                line-height: 1.8;
              }
              .code-container {
                background: linear-gradient(135deg, #ffebee 0%, #ffcdd2 100%);
                border: 2px dashed #f44336;
                border-radius: 10px;
                padding: 30px;
                margin: 30px 0;
                text-align: center;
              }
              .code-label {
                font-size: 14px;
                color: #666;
                margin-bottom: 10px;
                text-transform: uppercase;
                letter-spacing: 1px;
              }
              .code { 
                font-size: 40px; 
                font-weight: bold; 
                color: #d32f2f; 
                letter-spacing: 8px;
                font-family: 'Courier New', monospace;
                display: inline-block;
                padding: 10px 20px;
                background: white;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
              }
              .expiry-notice {
                background-color: #fff3cd;
                border-left: 4px solid #ffc107;
                padding: 15px;
                margin: 25px 0;
                border-radius: 4px;
              }
              .expiry-notice strong {
                color: #856404;
                display: flex;
                align-items: center;
                gap: 8px;
              }
              .security-notice {
                background-color: #ffebee;
                border-left: 4px solid #f44336;
                padding: 15px;
                margin: 25px 0;
                border-radius: 4px;
                font-size: 14px;
                color: #c62828;
              }
              .footer { 
                background-color: #f8f9fa;
                text-align: center; 
                padding: 30px 20px; 
                color: #666; 
                font-size: 13px;
                border-top: 1px solid #e0e0e0;
              }
              .footer-logo {
                font-size: 20px;
                font-weight: bold;
                color: #d32f2f;
                margin-bottom: 10px;
              }
              .divider {
                height: 1px;
                background: linear-gradient(to right, transparent, #ddd, transparent);
                margin: 20px 0;
              }
              @media only screen and (max-width: 600px) {
                .code { font-size: 32px; letter-spacing: 6px; }
                .content { padding: 25px 20px; }
                .header h1 { font-size: 24px; }
              }
            </style>
          </head>
          <body>
            <div class="email-wrapper">
              <div class="header">
                <div class="icon">&#128274;</div>
                <h1>Réinitialisation de mot de passe</h1>
                <p>SMART MAINTENANCE</p>
              </div>
              
              <div class="content">
                <div class="greeting">Bonjour ${user.first_name} ! &#128075;</div>
                
                <p class="message">
                  Vous avez demandé la réinitialisation de votre mot de passe. 
                  Utilisez le code ci-dessous pour créer un nouveau mot de passe sécurisé.
                </p>
                
                <div class="code-container">
                  <div class="code-label">Code de réinitialisation</div>
                  <div class="code">${resetCode}</div>
                </div>
                
                <div class="expiry-notice">
                  <strong>&#9201;&#65039; Important : Ce code expire dans 15 minutes</strong>
                </div>
                
                <p class="message">
                  Entrez ce code dans l'application mobile SMART MAINTENANCE pour définir 
                  votre nouveau mot de passe.
                </p>
                
                <div class="divider"></div>
                
                <div class="security-notice">
                  &#128737;&#65039; <strong>Attention :</strong> Si vous n'avez pas demandé cette réinitialisation, 
                  ignorez cet email et votre mot de passe actuel restera inchangé. Nous vous recommandons 
                  de changer votre mot de passe si vous pensez que votre compte a été compromis.
                </div>
              </div>
              
              <div class="footer">
                <div class="footer-logo">SMART MAINTENANCE</div>
                <p>Votre sécurité est notre priorité</p>
                <div class="divider"></div>
                <p>© ${new Date().getFullYear()} SMART MAINTENANCE - Tous droits réservés</p>
                <p style="margin-top: 15px; font-size: 11px; color: #999;">
                  Cet email a été envoyé automatiquement, merci de ne pas y répondre directement.
                </p>
              </div>
            </div>
          </body>
          </html>
        `
      };

      await transporter.sendMail(mailOptions);
      console.log('✅ Code de réinitialisation envoyé à:', user.email);
    } catch (emailError) {
      console.error('❌ Erreur envoi email réinitialisation:', emailError);
      return res.status(500).json({
        success: false,
        message: "Erreur lors de l'envoi de l'email"
      });
    }

    res.status(200).json({
      success: true,
      message: 'Un code de réinitialisation a été envoyé à votre email',
      requiresCode: true
    });

  } catch (error) {
    console.error('❌ [Forgot Password] Error:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la réinitialisation du mot de passe',
      error: error.message
    });
  }
};

// Vérifier l'email avec le token
const verifyEmail = async (req, res) => {
  try {
    const { token } = req.query;

    if (!token) {
      return res.status(400).json({
        success: false,
        message: 'Token de vérification manquant'
      });
    }

    // Trouver l'utilisateur avec ce token
    const user = await User.findOne({
      where: {
        email_verification_token: token,
        email_verification_expires: { [Op.gt]: new Date() }
      }
    });

    if (!user) {
      return res.status(400).json({
        success: false,
        message: 'Token invalide ou expiré'
      });
    }

    // Activer le compte
    user.status = 'active';
    user.email_verification_token = null;
    user.email_verification_expires = null;
    await user.save();

    // Mettre à jour le cache
    await cache.set(`user:${user.id}`, user.toJSON(), 3600);

    res.json({
      success: true,
      message: 'Email vérifié avec succès. Votre compte est maintenant actif.'
    });
  } catch (error) {
    console.error('Erreur vérification email:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
};

// Renvoyer l'email de vérification
const resendVerificationEmail = async (req, res) => {
  try {
    const { email } = req.body;

    const user = await User.findOne({ where: { email } });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Aucun compte trouvé avec cet email'
      });
    }

    if (user.status === 'active') {
      return res.status(400).json({
        success: false,
        message: 'Ce compte est déjà vérifié'
      });
    }

    // Générer un nouveau token
    const verificationToken = crypto.randomBytes(32).toString('hex');
    const verificationExpires = new Date(Date.now() + 24 * 60 * 60 * 1000);

    user.email_verification_token = verificationToken;
    user.email_verification_expires = verificationExpires;
    await user.save();

    // Envoyer l'email
    try {
      await sendVerificationEmail(user, verificationToken);
      res.json({
        success: true,
        message: 'Email de vérification renvoyé avec succès'
      });
    } catch (emailError) {
      console.error('❌ Erreur envoi email:', emailError);
      res.status(500).json({
        success: false,
        message: 'Erreur lors de l\'envoi de l\'email'
      });
    }
  } catch (error) {
    console.error('Erreur resendVerificationEmail:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
};

// Delete my account (soft delete)
const deleteMyAccount = async (req, res) => {
  try {
    const userId = req.user.id;
    const user = await User.findByPk(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }

    // Soft delete: modifier le statut, préfixer email et phone
    const timestamp = Date.now();
    const updateData = {
      status: 'deleted',
      phone: user.phone ? `deleted_${timestamp}_${user.phone}` : null
    };
    
    // Seulement modifier l'email s'il existe
    if (user.email) {
      updateData.email = `deleted_${timestamp}_${user.email}`;
    }
    
    await user.update(updateData);

    // Supprimer du cache
    const { cache } = require('../../config/redis');
    if (cache) {
      await cache.del(`user:${userId}`);
    }

    console.log(`✅ Compte supprimé (soft delete): ${user.email}`);

    res.json({
      success: true,
      message: 'Votre compte a été supprimé avec succès'
    });
  } catch (error) {
    console.error('Erreur deleteMyAccount:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la suppression du compte'
    });
  }
};

module.exports = {
  register,
  login,
  getProfile,
  updateProfile,
  changePassword,
  logout,
  updateFcmToken,
  forgotPassword,
  requestResetCode,
  checkResetCode,
  verifyResetCode,
  verifyEmailCode,
  resendEmailVerificationCode,
  deleteMyAccount
};
