const { GoogleAuth } = require('google-auth-library');
const path = require('path');
const https = require('https');

class FCMService {
  constructor() {
    this.initialized = false;
    this.auth = null;
    this.projectId = null;
  }

  /**
   * Initialiser Google Auth pour FCM API v1
   */
  initialize() {
    if (this.initialized) {
      console.log('🔔 FCM Service déjà initialisé');
      return;
    }

    try {
      const serviceAccountPath = path.join(__dirname, '../../firebase-service-account.json');
      const serviceAccount = require(serviceAccountPath);
      this.projectId = serviceAccount.project_id;

      this.auth = new GoogleAuth({
        keyFile: serviceAccountPath,
        scopes: ['https://www.googleapis.com/auth/cloud-platform']
      });

      this.initialized = true;
      console.log('✅ FCM Service initialisé avec succès (HTTP v1)');
      console.log(`   Project ID: ${this.projectId}`);
    } catch (error) {
      console.error('❌ Erreur initialisation FCM Service:', error.message);
      throw error;
    }
  }

  /**
   * Envoyer un message via FCM HTTP v1 API
   */
  async _sendFCMv1(messagePayload) {
    const token = await this.auth.getAccessToken();
    const postData = JSON.stringify({ message: messagePayload });

    return new Promise((resolve, reject) => {
      const req = https.request({
        hostname: 'fcm.googleapis.com',
        path: `/v1/projects/${this.projectId}/messages:send`,
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(postData)
        }
      }, res => {
        let body = '';
        res.on('data', d => body += d);
        res.on('end', () => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            const data = JSON.parse(body);
            resolve(data.name);
          } else {
            const err = JSON.parse(body);
            const error = new Error(err.error?.message || 'FCM error');
            error.code = err.error?.details?.[0]?.errorCode || `messaging/${res.statusCode}`;
            reject(error);
          }
        });
      });
      req.on('error', reject);
      req.write(postData);
      req.end();
    });
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
            color: '#0a543d',
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

      const response = await this._sendFCMv1(message);
      
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

      // Envoyer individuellement via HTTP v1
      let successCount = 0;
      let failureCount = 0;
      
      for (const token of validTokens) {
        try {
          await this._sendFCMv1({
            token,
            ...message
          });
          successCount++;
        } catch (err) {
          failureCount++;
        }
      }

      const response = { successCount, failureCount };

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
      await this._sendFCMv1({
        token: fcmToken,
        data: { test: 'true' }
      });

      return true;
    } catch (error) {
      return false;
    }
  }
}

// Export singleton
module.exports = new FCMService();
