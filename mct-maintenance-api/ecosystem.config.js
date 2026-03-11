module.exports = {
  apps: [
    {
      name: 'smartmaintenance-api',
      script: 'src/app.js',
      cwd: '/var/www/smartmaintenance/mct-maintenance-api',
      instances: 'max', // Utilise tous les CPU disponibles
      exec_mode: 'cluster',
      watch: false,
      max_memory_restart: '500M',
      node_args: '-r dotenv/config', // Charge le fichier .env automatiquement
      
      // Variables d'environnement
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      
      // Logs
      error_file: '/var/log/smartmaintenance/api-error.log',
      out_file: '/var/log/smartmaintenance/api-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      
      // Restart policy
      exp_backoff_restart_delay: 100,
      max_restarts: 10,
      min_uptime: '10s',
      
      // Graceful shutdown
      kill_timeout: 5000,
      wait_ready: true,
      listen_timeout: 10000
    }
  ],
  
  // Déploiement (optionnel - pour pm2 deploy)
  deploy: {
    production: {
      user: 'root',
      host: 'IP_SERVEUR_OVH',
      ref: 'origin/main',
      repo: 'git@github.com:bass1012/SMART-MAINTENANCE.git',
      path: '/var/www/mct-maintenance',
      'pre-deploy-local': '',
      'post-deploy': 'cd mct-maintenance-api && npm install --production && pm2 reload ecosystem.config.js --env production',
      'pre-setup': ''
    }
  }
};
