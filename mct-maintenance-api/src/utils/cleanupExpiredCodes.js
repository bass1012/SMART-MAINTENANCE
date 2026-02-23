const { EmailVerificationCode } = require('../models');
const PasswordResetCode = require('../models/PasswordResetCode');
const { Op } = require('sequelize');

/**
 * Nettoie les codes de vérification et de réinitialisation expirés
 * Supprime les codes expirés depuis plus de 24 heures
 */
const cleanupExpiredCodes = async () => {
  try {
    const now = new Date();
    const twentyFourHoursAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);

    console.log('🧹 [Cleanup] Démarrage du nettoyage des codes expirés...');
    console.log('🕐 [Cleanup] Date limite:', twentyFourHoursAgo.toISOString());

    // Nettoyer les codes de vérification d'email
    const deletedEmailCodes = await EmailVerificationCode.destroy({
      where: {
        expires_at: {
          [Op.lt]: twentyFourHoursAgo
        }
      }
    });

    // Nettoyer les codes de réinitialisation de mot de passe
    const deletedResetCodes = await PasswordResetCode.destroy({
      where: {
        expires_at: {
          [Op.lt]: twentyFourHoursAgo
        }
      }
    });

    const totalDeleted = deletedEmailCodes + deletedResetCodes;

    if (totalDeleted > 0) {
      console.log(`✅ [Cleanup] Nettoyage terminé:`);
      console.log(`   - ${deletedEmailCodes} code(s) de vérification supprimé(s)`);
      console.log(`   - ${deletedResetCodes} code(s) de réinitialisation supprimé(s)`);
      console.log(`   - Total: ${totalDeleted} code(s) supprimé(s)`);
    } else {
      console.log('✨ [Cleanup] Aucun code expiré à nettoyer');
    }

    return {
      success: true,
      emailCodesDeleted: deletedEmailCodes,
      resetCodesDeleted: deletedResetCodes,
      totalDeleted
    };

  } catch (error) {
    console.error('❌ [Cleanup] Erreur lors du nettoyage:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Obtient des statistiques sur les codes en base
 */
const getCodesStats = async () => {
  try {
    const now = new Date();

    // Statistiques des codes de vérification
    const totalEmailCodes = await EmailVerificationCode.count();
    const expiredEmailCodes = await EmailVerificationCode.count({
      where: {
        expires_at: {
          [Op.lt]: now
        }
      }
    });
    const usedEmailCodes = await EmailVerificationCode.count({
      where: { used: true }
    });

    // Statistiques des codes de réinitialisation
    const totalResetCodes = await PasswordResetCode.count();
    const expiredResetCodes = await PasswordResetCode.count({
      where: {
        expires_at: {
          [Op.lt]: now
        }
      }
    });
    const usedResetCodes = await PasswordResetCode.count({
      where: { used: true }
    });

    return {
      emailVerification: {
        total: totalEmailCodes,
        expired: expiredEmailCodes,
        used: usedEmailCodes,
        active: totalEmailCodes - expiredEmailCodes - usedEmailCodes
      },
      passwordReset: {
        total: totalResetCodes,
        expired: expiredResetCodes,
        used: usedResetCodes,
        active: totalResetCodes - expiredResetCodes - usedResetCodes
      }
    };
  } catch (error) {
    console.error('❌ [Cleanup] Erreur lors de la récupération des stats:', error);
    return null;
  }
};

module.exports = {
  cleanupExpiredCodes,
  getCodesStats
};
