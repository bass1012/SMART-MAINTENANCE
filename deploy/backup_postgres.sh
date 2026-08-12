#!/bin/bash
# ============================================================
# Script de sauvegarde PostgreSQL automatique - Smart Maintenance
# A deployer sur sandbox.mct.ci
# Installation : crontab -e -> ajouter la ligne cron en bas
# ============================================================

set -euo pipefail

# --- Configuration ---
DB_NAME="smartmaintenance_db"
DB_USER="smartmaintenance"
BACKUP_DIR="/var/backups/smartmaintenance"
RETENTION_DAYS=14
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/db_${TIMESTAMP}.sql.gz"
LOG_FILE="/var/log/smartmaintenance/backup.log"
ALERT_EMAIL="admin@mct.ci"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

mkdir -p "${BACKUP_DIR}"
mkdir -p "$(dirname "${LOG_FILE}")"

log "Demarrage de la sauvegarde PostgreSQL..."

if PGPASSWORD="${DB_PASSWORD}" pg_dump \
    -U "${DB_USER}" \
    -h localhost \
    -d "${DB_NAME}" \
    --no-password \
    --clean \
    --if-exists \
    | gzip > "${BACKUP_FILE}"; then

  BACKUP_SIZE=$(du -sh "${BACKUP_FILE}" | cut -f1)
  log "OK Sauvegarde reussie : ${BACKUP_FILE} (${BACKUP_SIZE})"
else
  log "ECHEC de la sauvegarde PostgreSQL !"
  echo "ALERTE : Echec sauvegarde DB SmartMaintenance le $(date)." \
    | mail -s "ECHEC Backup DB SmartMaintenance" "${ALERT_EMAIL}" 2>/dev/null || true
  exit 1
fi

DELETED=$(find "${BACKUP_DIR}" -name "db_*.sql.gz" -mtime "+${RETENTION_DAYS}" -delete -print | wc -l)
log "Suppression de ${DELETED} ancienne(s) sauvegarde(s) (retention: ${RETENTION_DAYS} jours)"

TOTAL_BACKUPS=$(find "${BACKUP_DIR}" -name "db_*.sql.gz" | wc -l)
TOTAL_SIZE=$(du -sh "${BACKUP_DIR}" | cut -f1)
log "Total: ${TOTAL_BACKUPS} sauvegardes | Espace: ${TOTAL_SIZE}"
log "Sauvegarde terminee avec succes."

# INSTALLATION :
# 1. scp deploy/backup_postgres.sh root@sandbox.mct.ci:/usr/local/bin/
# 2. chmod +x /usr/local/bin/backup_postgres.sh
# 3. crontab -e -> 0 2 * * * DB_PASSWORD="mdp_postgres" /usr/local/bin/backup_postgres.sh
# 4. Test : DB_PASSWORD="mdp_postgres" /usr/local/bin/backup_postgres.sh
# 5. Restauration : gunzip -c /var/backups/smartmaintenance/db_YYYYMMDD.sql.gz | PGPASSWORD="mdp" psql -U smartmaintenance -d smartmaintenance_db
