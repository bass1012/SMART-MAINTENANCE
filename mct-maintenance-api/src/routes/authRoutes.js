const express = require('express');
const { body } = require('express-validator');
const { authenticate } = require('../middleware/auth');
const authController = require('../controllers/auth/authController');

const router = express.Router();

// Validation pour le code de réinitialisation
const requestResetCodeValidation = [body('email').isEmail().withMessage('Email requis')];
const checkResetCodeValidation = [
  body('email').isEmail().withMessage('Email requis'),
  body('code').isLength({ min: 6, max: 6 }).withMessage('Code à 6 chiffres requis')
];
const verifyResetCodeValidation = [
  body('email').isEmail().withMessage('Email requis'),
  body('code').isLength({ min: 6, max: 6 }).withMessage('Code à 6 chiffres requis'),
  body('newPassword').isLength({ min: 6 }).withMessage('Mot de passe trop court')
];
router.post('/request-reset-code', requestResetCodeValidation, authController.requestResetCode);
router.post('/check-reset-code', checkResetCodeValidation, authController.checkResetCode);
router.post('/verify-reset-code', verifyResetCodeValidation, authController.verifyResetCode);

// Validation rules
const registerValidation = [
  body('email')
    .optional({ checkFalsy: true })
    .isEmail()
    .withMessage('Please provide a valid email'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters long'),
  body('phone')
    .optional({ checkFalsy: true })
    .matches(/^[+]?[(]?[0-9]{1,4}[)]?[-\s./0-9]*$/)
    .withMessage('Please provide a valid phone number'),
  body('role').optional().isIn(['customer', 'technician', 'manager', 'admin']).withMessage('Invalid role'),
  body('first_name').optional().trim().isLength({ min: 1 }).withMessage('First name is required'),
  body('last_name').optional().trim().isLength({ min: 1 }).withMessage('Last name is required'),
  // Custom validator: au moins email OU phone doit être fourni
  body().custom((value, { req }) => {
    const hasEmail = req.body.email && req.body.email.trim() !== '';
    const hasPhone = req.body.phone && req.body.phone.trim() !== '';
    if (!hasEmail && !hasPhone) {
      throw new Error('Either email or phone number is required');
    }
    return true;
  })
];

const loginValidation = [
  body('email').notEmpty().withMessage('Email ou téléphone requis'),
  body('password').notEmpty().withMessage('Password is required')
];

const forgotPasswordValidation = [
  body('email').notEmpty().withMessage('Email ou téléphone requis')
];

const updateProfileValidation = [
  body('email').optional().isEmail().withMessage('Please provide a valid email'),
  body('phone').optional().matches(/^[+]?[(]?[0-9]{1,4}[)]?[-\s./0-9]*$/).withMessage('Please provide a valid phone number'),
  body('first_name').optional().isLength({ min: 2, max: 100 }).withMessage('First name must be between 2 and 100 characters'),
  body('last_name').optional().isLength({ min: 2, max: 100 }).withMessage('Last name must be between 2 and 100 characters')
];

const changePasswordValidation = [
  body('currentPassword').notEmpty().withMessage('Current password is required'),
  body('newPassword').isLength({ min: 6 }).withMessage('New password must be at least 6 characters long')
];

// Routes
/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               password:
 *                 type: string
 *                 minLength: 6
 *               phone:
 *                 type: string
 *               role:
 *                 type: string
 *                 enum: [customer, technician]
 *               first_name:
 *                 type: string
 *               last_name:
 *                 type: string
 *     responses:
 *       201:
 *         description: User registered successfully
 *       400:
 *         description: Validation error
 *       409:
 *         description: User already exists
 */
router.post('/register', registerValidation, authController.register);

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Login user
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Login successful
 *       401:
 *         description: Invalid credentials
 */
router.post('/login', loginValidation, authController.login);

// Email verification routes
router.post('/verify-email-code', [
  body('email').isEmail().withMessage('Email valide requis'),
  body('code').isLength({ min: 6, max: 6 }).withMessage('Code à 6 chiffres requis')
], authController.verifyEmailCode);

router.post('/resend-verification-code', [
  body('email').isEmail().withMessage('Email valide requis')
], authController.resendEmailVerificationCode);

/**
 * @swagger
 * /api/auth/forgot-password:
 *   post:
 *     summary: Request password reset
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *     responses:
 *       200:
 *         description: Password reset email sent
 *       404:
 *         description: User not found
 */
router.post('/forgot-password', forgotPasswordValidation, authController.forgotPassword);

/**
 * @swagger
 * /api/auth/profile:
 *   get:
 *     summary: Get current user profile
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User profile retrieved successfully
 *       401:
 *         description: Unauthorized
 */
router.get('/profile', authenticate, authController.getProfile);

/**
 * @swagger
 * /api/auth/profile:
 *   put:
 *     summary: Update user profile
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               phone:
 *                 type: string
 *               first_name:
 *                 type: string
 *               last_name:
 *                 type: string
 *     responses:
 *       200:
 *         description: Profile updated successfully
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 */
router.put('/profile', authenticate, updateProfileValidation, authController.updateProfile);

/**
 * @swagger
 * /api/auth/change-password:
 *   post:
 *     summary: Change user password
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - currentPassword
 *               - newPassword
 *             properties:
 *               currentPassword:
 *                 type: string
 *               newPassword:
 *                 type: string
 *                 minLength: 6
 *     responses:
 *       200:
 *         description: Password changed successfully
 *       400:
 *         description: Validation error or incorrect current password
 *       401:
 *         description: Unauthorized
 */
router.post('/change-password', authenticate, changePasswordValidation, authController.changePassword);

/**
 * @swagger
 * /api/auth/logout:
 *   post:
 *     summary: Logout user
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Logout successful
 *       401:
 *         description: Unauthorized
 */
router.post('/logout', authenticate, authController.logout);

/**
 * @route   POST /api/auth/fcm-token
 * @desc    Enregistrer le token FCM de l'utilisateur
 * @access  Private
 */
router.post('/fcm-token', authenticate, authController.updateFcmToken);

/**
 * @swagger
 * /api/auth/delete-account:
 *   delete:
 *     summary: Delete my account (soft delete)
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Account deleted successfully
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: User not found
 */
router.delete('/delete-account', authenticate, authController.deleteMyAccount);

module.exports = router;
