const admin = require('firebase-admin');
const path = require('path');

class FCMService {
  constructor() {
    this.initialized = false;
  }

  /**
   * Initialiser Firebase Admin SDK
   */
  initialize() {
    if (this.initialized) {
      console.log('🔔 Firebase Admin SDK déjà initialisé');
      return;
    }

    try {
      const serviceAccountPath = path.join(__dirname, '../../firebase-service-account.json');
      const serviceAccount = require(serviceAccountPath);

      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: serviceAccount.project_id
      });

      this.initialized = true;
      console.log('✅ Firebase Admin SDK initialisé avec succès');
      console.log(`   Project ID: ${serviceAccount.project_id}`);
    } catch (error) {
      console.error('❌ Erreur initialisation Firebase Admin SDK:', error.message);
      throw error;
    }
  }

  /**
   * Envoyer une notification push à un utilisateur via son token FCM
   * @param {string} fcmToken - Token FCM de l'utilisateur
   * @param {Object} notification - Objet notification
   * @param {string} notification.title - Titre de la notification
   * @param {string} notification.body - Corps de la notification
   * @param {Object} data - Données supplémentaires
   * @returns {Promise<string>} Message ID de la notification envoyée
   */
  async sendToDevice(fcmToken, notification, data = {}) {
    if (!this.initialized) {
      this.initialize();
    }

    if (!fcmToken) {
      console.log('⚠️  Pas de FCM token, notification non envoyée');
      return null;
    }

    try {
      // Sanitiser les données - FCM requiert que toutes les valeurs soient des strings
      const sanitizedData = {};
      for (const [key, value] of Object.entries(data || {})) {
        // Ignorer les valeurs null/undefined et les objets complexes
        if (value !== null && value !== undefined && typeof value !== 'object') {
          sanitizedData[key] = String(value);
        } else if (typeof value === 'object' && value !== null) {
          // Pour les objets, on les stringify
          try {
            sanitizedData[key] = JSON.stringify(value);
          } catch (e) {
            sanitizedData[key] = String(value);
          }
        }
      }
      
      sanitizedData.click_action = 'FLUTTER_NOTIFICATION_CLICK';
      
      const message = {
        token: fcmToken,
        notification: {
          title: notification.title || 'MCT Maintenance',
          body: notification.body || 'Nouvelle notification'
        },
        data: sanitizedData,
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            color: '#0a543d', // Vert MCT
            channelId: 'default_channel'
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1
            }
          }
        }
      };

      const response = await admin.messaging().send(message);
      
      console.log('✅ Notification FCM envoyée avec succès');
      console.log(`   Token: ${fcmToken.substring(0, 20)}...`);
      console.log(`   Titre: ${notification.title}`);
      console.log(`   Message ID: ${response}`);

      return response;
    } catch (error) {
      console.error('❌ Erreur envoi notification FCM:', error.message);
      
      // Si le token est invalide, on ne throw pas pour ne pas bloquer
      if (error.code === 'messaging/invalid-registration-token' ||
          error.code === 'messaging/registration-token-not-registered') {
        console.log('⚠️  Token FCM invalide ou non enregistré, ignoré');
        return null;
      }
      
      throw error;
    }
  }

  /**
   * Envoyer une notification push à plusieurs utilisateurs
   * @param {Array<string>} fcmTokens - Liste des tokens FCM
   * @param {Object} notification - Objet notification
   * @param {Object} data - Données supplémentaires
   * @returns {Promise<Object>} Résultats de l'envoi
   */
  async sendToMultipleDevices(fcmTokens, notification, data = {}) {
    if (!this.initialized) {
      this.initialize();
    }

    if (!fcmTokens || fcmTokens.length === 0) {
      console.log('⚠️  Aucun FCM token, notifications non envoyées');
      return { successCount: 0, failureCount: 0 };
    }

    // Filtrer les tokens null/undefined
    const validTokens = fcmTokens.filter(token => token && token.trim());

    if (validTokens.length === 0) {
      console.log('⚠️  Aucun FCM token valide, notifications non envoyées');
      return { successCount: 0, failureCount: 0 };
    }

    try {
      const message = {
        notification: {
          title: notification.title || 'MCT Maintenance',
          body: notification.body || 'Nouvelle notification'
        },
        data: {
          ...data,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          ...Object.keys(data).reduce((acc, key) => {
            acc[key] = String(data[key]);
            return acc;
          }, {})
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            color: '#0a543d',
            channelId: 'default_channel'
          }
        }
      };

      const response = await admin.messaging().sendMulticast({
        tokens: validTokens,
        ...message
      });

      console.log('✅ Notifications FCM envoyées');
      console.log(`   Tokens: ${validTokens.length}`);
      console.log(`   Succès: ${response.successCount}`);
      console.log(`   Échecs: ${response.failureCount}`);

      return response;
    } catch (error) {
      console.error('❌ Erreur envoi notifications FCM multiples:', error.message);
      return { successCount: 0, failureCount: validTokens.length };
    }
  }

  /**
   * Vérifier si un token FCM est valide
   * @param {string} fcmToken - Token FCM à vérifier
   * @returns {Promise<boolean>} true si valide, false sinon
   */
  async verifyToken(fcmToken) {
    if (!this.initialized) {
      this.initialize();
    }

    if (!fcmToken) {
      return false;
    }

    try {
      await admin.messaging().send({
        token: fcmToken,
        data: { test: 'true' }
      }, true); // dry run

      return true;
    } catch (error) {
      return false;
    }
  }
}

// Export singleton
module.exports = new FCMService();
