const axios = require('axios');

/**
 * Service d'envoi de SMS via HSMS.ci
 * Documentation: https://hsms.ci/
 */

/**
 * Récupérer la configuration HSMS.ci depuis les variables d'environnement
 */
const getConfig = () => ({
  HSMS_API_URL: process.env.HSMS_API_URL || 'https://api.hsms.ci/api/v1',
  HSMS_CLIENT_ID: process.env.HSMS_CLIENT_ID || '',
  HSMS_CLIENT_SECRET: process.env.HSMS_CLIENT_SECRET || '',
  HSMS_TOKEN: process.env.HSMS_TOKEN || '',
  HSMS_SENDER_NAME: process.env.HSMS_SENDER_NAME || 'MCT-MAINT'
});

/**
 * Envoyer un SMS via HSMS.ci
 * @param {string} phoneNumber - Numéro de téléphone (format: 2250170793131)
 * @param {string} message - Message à envoyer
 * @returns {Promise<Object>} Résultat de l'envoi
 */
const sendSMS = async (phoneNumber, message) => {
  try {
    const { HSMS_TOKEN, HSMS_CLIENT_ID, HSMS_CLIENT_SECRET, HSMS_API_URL, HSMS_SENDER_NAME } = getConfig();
    
    // Vérifier la configuration (au moins le token ou client_id+secret)
    if (!HSMS_TOKEN && (!HSMS_CLIENT_ID || !HSMS_CLIENT_SECRET)) {
      throw new Error('HSMS: Configurez soit HSMS_TOKEN, soit HSMS_CLIENT_ID + HSMS_CLIENT_SECRET');
    }

    // Nettoyer le numéro de téléphone (enlever + et espaces)
    const cleanPhone = phoneNumber.replace(/[\s+]/g, '');
    
    // Vérifier le format du numéro (doit commencer par 225 pour la Côte d'Ivoire)
    if (!cleanPhone.startsWith('225')) {
      console.warn(`⚠️ Numéro ${cleanPhone} ne commence pas par 225 (Côte d'Ivoire)`);
    }

    console.log(`📱 Envoi SMS vers ${cleanPhone} via HSMS.ci...`);

    // Préparer les paramètres form-data selon la documentation HSMS
    const formData = new URLSearchParams();
    formData.append('clientid', HSMS_CLIENT_ID);
    formData.append('clientsecret', HSMS_CLIENT_SECRET);
    formData.append('telephone', cleanPhone);
    formData.append('message', message);
    formData.append('expediteur', HSMS_SENDER_NAME); // Nom de l'expéditeur personnalisé

    console.log('📤 Données envoyées:', {
      url: `${HSMS_API_URL}/envoi-sms/`,
      clientid: HSMS_CLIENT_ID,
      telephone: cleanPhone,
      expediteur: HSMS_SENDER_NAME,
      messageLength: message.length
    });

    // Appeler l'API HSMS.ci pour envoyer un SMS (noter le / final)
    const response = await axios.post(`${HSMS_API_URL}/envoi-sms/`, formData.toString(), {
      headers: {
        'Authorization': `Bearer ${HSMS_TOKEN}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      timeout: 10000 // 10 secondes
    });

    console.log('✅ SMS envoyé avec succès:', response.data);

    return {
      success: true,
      messageId: response.data.resultats?.[0]?.ticket || response.data.ticket,
      status: response.data.message,
      data: response.data
    };

  } catch (error) {
    console.error('❌ Erreur envoi SMS HSMS.ci:', error.message);
    
    if (error.response) {
      console.error('Réponse API:', error.response.data);
      return {
        success: false,
        error: error.response.data.message || 'Erreur API HSMS.ci',
        statusCode: error.response.status
      };
    }
    
    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Envoyer un code de vérification par SMS
 * @param {string} phoneNumber - Numéro de téléphone
 * @param {string} code - Code de vérification (6 chiffres)
 * @param {string} firstName - Prénom de l'utilisateur
 * @returns {Promise<Object>} Résultat de l'envoi
 */
const sendVerificationCodeSMS = async (phoneNumber, code, firstName = '') => {
  const message = `Bonjour ${firstName ? firstName + ', ' : ''}

Votre code de verification SMART MAINTENANCE est :

${code}

Ce code expire dans 15 minutes.

Ne partagez jamais ce code avec quelqu'un.`;

  return await sendSMS(phoneNumber, message);
};

/**
 * Envoyer un code de réinitialisation de mot de passe par SMS
 * @param {string} phoneNumber - Numéro de téléphone
 * @param {string} code - Code de réinitialisation
 * @param {string} firstName - Prénom de l'utilisateur
 * @returns {Promise<Object>} Résultat de l'envoi
 */
const sendPasswordResetCodeSMS = async (phoneNumber, code, firstName = '') => {
  const message = `Bonjour ${firstName ? firstName + ', ' : ''}

Votre code de reinitialisation SMART MAINTENANCE :

${code}

Ce code expire dans 15 minutes.

Si vous n'avez pas demande cette reinitialisation, ignorez ce message.`;

  return await sendSMS(phoneNumber, message);
};

/**
 * Envoyer une notification SMS générique
 * @param {string} phoneNumber - Numéro de téléphone
 * @param {string} subject - Sujet du message
 * @param {string} body - Corps du message
 * @returns {Promise<Object>} Résultat de l'envoi
 */
const sendNotificationSMS = async (phoneNumber, subject, body) => {
  const message = `${subject}

${body}

-- SMART MAINTENANCE`;

  return await sendSMS(phoneNumber, message);
};

/**
 * Vérifier le solde de crédits SMS
 * @returns {Promise<Object>} Solde et informations du compte
 */
const checkSMSBalance = async () => {
  try {
    const { HSMS_TOKEN, HSMS_CLIENT_ID, HSMS_CLIENT_SECRET, HSMS_API_URL } = getConfig();
    
    if (!HSMS_TOKEN && (!HSMS_CLIENT_ID || !HSMS_CLIENT_SECRET)) {
      throw new Error('HSMS: Identifiants non configurés');
    }

    // Préparer les paramètres form-data pour vérifier le solde
    const formData = new URLSearchParams();
    formData.append('clientid', HSMS_CLIENT_ID);
    formData.append('clientsecret', HSMS_CLIENT_SECRET);

    const response = await axios.post(`${HSMS_API_URL}/check-sms/`, formData.toString(), {
      headers: {
        'Authorization': `Bearer ${HSMS_TOKEN}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      timeout: 5000
    });

    console.log('💰 Solde SMS HSMS.ci:', response.data);

    return {
      success: true,
      balance: response.data['SMS disponibles'] || response.data.sms_disponibles,
      application: response.data.Application,
      data: response.data
    };

  } catch (error) {
    console.error('❌ Erreur vérification solde:', error.message);
    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Formater un numéro de téléphone pour HSMS.ci
 * @param {string} phone - Numéro brut (peut contenir +, espaces, etc.)
 * @returns {string} Numéro formaté (ex: 2250709822377)
 */
const formatPhoneNumber = (phone) => {
  if (!phone) return '';
  
  // Enlever tous les caractères non numériques
  let cleaned = phone.replace(/\D/g, '');
  
  // Si le numéro commence déjà par 225, le retourner tel quel
  if (cleaned.startsWith('225')) {
    return cleaned;
  }
  
  // Si le numéro commence par 0 (format local ivoirien), ajouter 225 devant
  // Exemple: 0709822377 → 2250709822377
  if (cleaned.startsWith('0') && cleaned.length === 10) {
    cleaned = '225' + cleaned;
    return cleaned;
  }
  
  // Si le numéro a 10 chiffres sans 0, ajouter 225 devant
  if (cleaned.length === 10) {
    cleaned = '225' + cleaned;
  }
  
  return cleaned;
};

/**
 * Valider un numéro de téléphone ivoirien
 * @param {string} phone - Numéro de téléphone
 * @returns {boolean} True si valide
 */
const isValidIvoryCoastPhone = (phone) => {
  const formatted = formatPhoneNumber(phone);
  
  // Format: 225 + 10 chiffres = 13 chiffres au total
  // Les numéros ivoiriens commencent par 01, 05, 07, etc.
  const regex = /^225(0[1-9]|[1-9][0-9])\d{8}$/;
  
  return regex.test(formatted);
};

module.exports = {
  sendSMS,
  sendVerificationCodeSMS,
  sendPasswordResetCodeSMS,
  sendNotificationSMS,
  checkSMSBalance,
  formatPhoneNumber,
  isValidIvoryCoastPhone
};
