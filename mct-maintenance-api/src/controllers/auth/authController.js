const jwt = require('jsonwebtoken');
const { User, CustomerProfile, TechnicianProfile } = require('../../models');
const { cache } = require('../../config/redis');
const { validationResult } = require('express-validator');
const PasswordResetCode = require('../../models/PasswordResetCode');
const { Op } = require('sequelize');
const nodemailer = require('nodemailer');
const { createTransporter } = require('../../services/emailService');
require('dotenv').config();

// Demander un code de réinitialisation
const requestResetCode = async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(404).json({ success: false, message: 'Aucun compte associé à cet email' });
    }
    // Générer un code à 6 chiffres
    const code = PasswordResetCode.generateCode();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 min
    // Sauvegarder en base
    await PasswordResetCode.create({ user_id: user.id, code, expires_at: expiresAt });

    // Configurer le transporteur nodemailer en utilisant le service email
    const transporter = createTransporter();

    // Préparer le mail
    const mailOptions = {
      from: {
        name: 'MCT Maintenance',
        address: process.env.EMAIL_FROM || process.env.EMAIL_USER
      },
      to: email,
      subject: 'Code de réinitialisation de mot de passe',
      text: `Votre code de réinitialisation est : ${code}\nCe code est valable 15 minutes.`
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
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(404).json({ success: false, message: 'Aucun compte associé à cet email' });
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
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(404).json({ success: false, message: 'Aucun compte associé à cet email' });
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
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }


  const { email, password, phone, role, first_name, last_name, ...profileData } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'User with this email already exists'
      });
    }

    if (phone) {
      const existingPhone = await User.findOne({ where: { phone } });
      if (existingPhone) {
        return res.status(409).json({
          success: false,
          message: 'User with this phone already exists'
        });
      }
    }

    // Create user
    const user = await User.create({
      email,
      password_hash: password,
      phone,
      role: role || 'customer',
      status: req.body.status || 'active', // Utiliser le statut fourni ou 'active' par défaut
      first_name,
      last_name,
      profile_image: req.body.profile_image || null
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
        phone, // Ajout explicite du téléphone pour le profil technicien
        ...profileData
      });
    }

    // Generate tokens
    const { accessToken, refreshToken } = generateTokens(user);

    // Cache user data
    await cache.set(`user:${user.id}`, user.toJSON(), 3600);

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user: user.toJSON(),
        accessToken,
        refreshToken
      }
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

    // Find user by email
    const user = await User.findOne({ where: { email } });
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

    // Check user status
    if (user.status !== 'active') {
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
          }
        }
      );
      console.log('🧹 Token supprimé des autres utilisateurs');
    }

    // Mettre à jour le token FCM de l'utilisateur actuel
    await User.update(
      { fcm_token },
      { where: { id: userId } }
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

// Forgot Password - Send reset email
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

    // Generate reset token (valid for 1 hour)
    const resetToken = jwt.sign(
      { id: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );

    // In production, you would send an email here with the reset link
    // For now, we'll just log it and return success
    const resetLink = `${process.env.FRONTEND_URL || 'http://localhost:3001'}/reset-password?token=${resetToken}`;
    
    console.log('🔐 [Forgot Password] Reset link generated for:', email);
    console.log('🔗 Reset link:', resetLink);

    // TODO: Implement email service to send reset link
    // await sendPasswordResetEmail(user.email, resetLink);

    res.status(200).json({
      success: true,
      message: 'Un email de réinitialisation a été envoyé à votre adresse',
      // In production, don't send the token in the response
      // This is only for development/testing
      ...(process.env.NODE_ENV === 'development' && { resetToken, resetLink })
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
  verifyResetCode
};
