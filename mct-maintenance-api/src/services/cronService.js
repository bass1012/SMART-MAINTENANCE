const cron = require('node-cron');
const { cleanupExpiredCodes, getCodesStats } = require('../utils/cleanupExpiredCodes');
const { checkExpiringContracts } = require('../jobs/contractExpirationReminder');
const { sendPendingDiagnosticReminders } = require('../jobs/pendingDiagnosticReminder');
const { sendSubscriptionExpiryReminders } = require('../jobs/subscriptionExpiryReminder');

/**
 * Service de gestion des tâches planifiées (CRON)
 */
class CronService {
  constructor() {
    this.jobs = [];
  }

  /**
   * Initialise tous les jobs cron
   */
  initializeJobs() {
    console.log('⏰ [Cron] Initialisation des tâches planifiées...');

    // Job 1: Nettoyer les codes expirés toutes les heures
    const cleanupJob = cron.schedule('0 * * * *', async () => {
      console.log('\n⏰ [Cron] Exécution du nettoyage automatique...');
      await cleanupExpiredCodes();
    }, {
      scheduled: true,
      timezone: "Africa/Abidjan" // Fuseau horaire de la Côte d'Ivoire
    });

    this.jobs.push({
      name: 'cleanup-expired-codes',
      schedule: 'Toutes les heures',
      job: cleanupJob
    });

    // Job 2: Afficher les statistiques tous les jours à 9h
    const statsJob = cron.schedule('0 9 * * *', async () => {
      console.log('\n📊 [Cron] Rapport quotidien des codes:');
      const stats = await getCodesStats();
      if (stats) {
        console.log('📧 Codes de vérification email:');
        console.log(`   - Total: ${stats.emailVerification.total}`);
        console.log(`   - Actifs: ${stats.emailVerification.active}`);
        console.log(`   - Expirés: ${stats.emailVerification.expired}`);
        console.log(`   - Utilisés: ${stats.emailVerification.used}`);
        console.log('🔑 Codes de réinitialisation:');
        console.log(`   - Total: ${stats.passwordReset.total}`);
        console.log(`   - Actifs: ${stats.passwordReset.active}`);
        console.log(`   - Expirés: ${stats.passwordReset.expired}`);
        console.log(`   - Utilisés: ${stats.passwordReset.used}`);
      }
    }, {
      scheduled: true,
      timezone: "Africa/Abidjan"
    });

    this.jobs.push({
      name: 'daily-stats',
      schedule: 'Tous les jours à 9h',
      job: statsJob
    });

    // Job 3: Vérifier les contrats arrivant à expiration (30, 15, 7 jours) tous les jours à 9h30
    const contractExpirationJob = cron.schedule('30 9 * * *', async () => {
      console.log('\n📝 [Cron] Vérification des contrats arrivant à expiration...');
      const result = await checkExpiringContracts();
      if (result.success) {
        console.log(`✅ [Cron] ${result.sent} rappel(s) d'expiration envoyé(s)`);
        if (result.errors > 0) {
          console.warn(`⚠️  [Cron] ${result.errors} erreur(s) lors de l'envoi`);
        }
      } else {
        console.error('❌ [Cron] Erreur:', result.error);
      }
    }, {
      scheduled: true,
      timezone: "Africa/Abidjan"
    });

    this.jobs.push({
      name: 'contract-expiration-reminder',
      schedule: 'Tous les jours à 9h30',
      job: contractExpirationJob
    });

    // Job 4: Rappel des paiements de diagnostic en attente (tous les jours à 10h et 18h)
    const diagnosticReminderJob = cron.schedule('0 10,18 * * *', async () => {
      console.log('\n💳 [Cron] Envoi des rappels de paiement diagnostic...');
      const result = await sendPendingDiagnosticReminders();
      if (result.success) {
        console.log(`✅ [Cron] ${result.sent} rappel(s) envoyé(s) sur ${result.checked} intervention(s)`);
        if (result.errors > 0) {
          console.warn(`⚠️  [Cron] ${result.errors} erreur(s) lors de l'envoi`);
        }
      } else {
        console.error('❌ [Cron] Erreur:', result.error);
      }
    }, {
      scheduled: true,
      timezone: "Africa/Abidjan"
    });

    this.jobs.push({
      name: 'diagnostic-payment-reminder',
      schedule: 'Tous les jours à 10h et 18h',
      job: diagnosticReminderJob
    });

    // Job 5: Rappel des abonnements qui vont expirer (tous les jours à 9h)
    const subscriptionExpiryJob = cron.schedule('0 9 * * *', async () => {
      console.log('\n📅 [Cron] Vérification des abonnements expirants...');
      const result = await sendSubscriptionExpiryReminders();
      if (result.success) {
        console.log(`✅ [Cron] ${result.sent} rappel(s) envoyé(s) (7j: ${result.checked7Days}, 1j: ${result.checked1Day})`);
        if (result.errors > 0) {
          console.warn(`⚠️  [Cron] ${result.errors} erreur(s) lors de l'envoi`);
        }
      } else {
        console.error('❌ [Cron] Erreur:', result.error);
      }
    }, {
      scheduled: true,
      timezone: "Africa/Abidjan"
    });

    this.jobs.push({
      name: 'subscription-expiry-reminder',
      schedule: 'Tous les jours à 9h',
      job: subscriptionExpiryJob
    });

    console.log(`✅ [Cron] ${this.jobs.length} tâche(s) planifiée(s):`);
    this.jobs.forEach(job => {
      console.log(`   - ${job.name}: ${job.schedule}`);
    });

    // Exécuter un premier nettoyage au démarrage
    setTimeout(async () => {
      console.log('\n🧹 [Cron] Nettoyage initial au démarrage...');
      await cleanupExpiredCodes();
    }, 5000); // Attendre 5 secondes après le démarrage
  }

  /**
   * Arrête tous les jobs cron
   */
  stopAllJobs() {
    console.log('🛑 [Cron] Arrêt de toutes les tâches planifiées...');
    this.jobs.forEach(({ name, job }) => {
      job.stop();
      console.log(`   - ${name} arrêté`);
    });
    this.jobs = [];
  }

  /**
   * Obtient le statut de tous les jobs
   */
  getJobsStatus() {
    return this.jobs.map(({ name, schedule, job }) => ({
      name,
      schedule,
      running: job.getStatus() === 'scheduled'
    }));
  }
}

// Export une instance unique (Singleton)
const cronService = new CronService();

module.exports = cronService;
