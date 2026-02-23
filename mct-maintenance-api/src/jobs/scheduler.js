/**
 * Scheduler principal pour tous les jobs CRON
 * À importer et initialiser dans server.js au démarrage de l'application
 */

const cron = require('node-cron');
const { setupCronJob: setupContractExpirationJob } = require('./contractExpirationReminder');

/**
 * Initialiser tous les jobs CRON de l'application
 */
function initializeScheduler() {
  console.log('🚀 Initialisation du scheduler CRON...');
  
  const jobs = [];
  
  try {
    // 1. Job de vérification d'expiration des contrats (tous les jours à 9h00)
    const contractJob = setupContractExpirationJob(cron);
    jobs.push({
      name: 'Contract Expiration Reminder',
      schedule: '0 9 * * *',
      job: contractJob
    });
    
    // Ajouter d'autres jobs ici si nécessaire :
    // const anotherJob = setupAnotherJob(cron);
    // jobs.push({ name: 'Another Job', schedule: '...' , job: anotherJob });
    
    console.log(`✅ Scheduler initialisé avec succès : ${jobs.length} job(s) actif(s)`);
    jobs.forEach(({ name, schedule }) => {
      console.log(`   - ${name} : ${schedule}`);
    });
    
    return jobs;
    
  } catch (error) {
    console.error('❌ Erreur lors de l\'initialisation du scheduler:', error);
    throw error;
  }
}

/**
 * Arrêter tous les jobs CRON (utile lors du shutdown)
 */
function stopScheduler(jobs) {
  if (!jobs || jobs.length === 0) return;
  
  console.log('🛑 Arrêt du scheduler...');
  jobs.forEach(({ name, job }) => {
    if (job && job.stop) {
      job.stop();
      console.log(`   - ${name} arrêté`);
    }
  });
  console.log('✅ Scheduler arrêté');
}

module.exports = {
  initializeScheduler,
  stopScheduler
};
