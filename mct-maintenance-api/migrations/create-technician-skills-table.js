/**
 * Migration: Créer table technician_skills
 * Date: 5 Janvier 2026
 * 
 * Structure:
 * - id (PRIMARY KEY)
 * - technician_id (FOREIGN KEY users.id)
 * - skill_name (VARCHAR)
 * - skill_level (VARCHAR: beginner, intermediate, advanced, expert)
 * - years_experience (INTEGER)
 * - created_at (DATETIME)
 */

const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, '../database.sqlite');

// Mapping types interventions → compétences requises
const INTERVENTION_SKILLS_MAP = {
  'plumbing': ['plomberie', 'sanitaire', 'canalisations'],
  'electrical': ['électricité', 'domotique', 'tableau électrique'],
  'hvac': ['climatisation', 'chauffage', 'ventilation'],
  'appliance_repair': ['électroménager', 'réparation'],
  'general_maintenance': ['maintenance générale', 'bricolage'],
  'emergency': ['intervention urgence', 'dépannage']
};

// Compétences test pour techniciens
const TEST_SKILLS = [
  // Technicien 15 (Hamed OUATTARA) - Polyvalent
  { technician_id: 15, skill_name: 'plomberie', skill_level: 'expert', years_experience: 8 },
  { technician_id: 15, skill_name: 'électricité', skill_level: 'advanced', years_experience: 6 },
  { technician_id: 15, skill_name: 'climatisation', skill_level: 'intermediate', years_experience: 4 },
  { technician_id: 15, skill_name: 'maintenance générale', skill_level: 'expert', years_experience: 10 },
  
  // Autres techniciens si existants
  { technician_id: 10, skill_name: 'électricité', skill_level: 'expert', years_experience: 12 },
  { technician_id: 10, skill_name: 'domotique', skill_level: 'advanced', years_experience: 5 },
  
  { technician_id: 12, skill_name: 'plomberie', skill_level: 'expert', years_experience: 15 },
  { technician_id: 12, skill_name: 'sanitaire', skill_level: 'expert', years_experience: 15 },
];

async function up() {
  return new Promise((resolve, reject) => {
    const db = new sqlite3.Database(dbPath);

    db.serialize(() => {
      // 1. Créer table technician_skills
      db.run(`
        CREATE TABLE IF NOT EXISTS technician_skills (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          technician_id INTEGER NOT NULL,
          skill_name VARCHAR(100) NOT NULL,
          skill_level VARCHAR(20) DEFAULT 'intermediate',
          years_experience INTEGER DEFAULT 0,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (technician_id) REFERENCES users(id) ON DELETE CASCADE,
          UNIQUE(technician_id, skill_name)
        )
      `, (err) => {
        if (err) {
          console.error('❌ Erreur création table technician_skills:', err.message);
          reject(err);
          return;
        }
        console.log('✅ Table technician_skills créée');
      });

      // 2. Créer index pour performance
      db.run(`
        CREATE INDEX IF NOT EXISTS idx_technician_skills_technician 
        ON technician_skills(technician_id)
      `, (err) => {
        if (err) {
          console.error('❌ Erreur création index:', err.message);
        } else {
          console.log('✅ Index créé sur technician_id');
        }
      });

      db.run(`
        CREATE INDEX IF NOT EXISTS idx_technician_skills_name 
        ON technician_skills(skill_name)
      `, (err) => {
        if (err) {
          console.error('❌ Erreur création index:', err.message);
        } else {
          console.log('✅ Index créé sur skill_name');
        }
      });

      // 3. Peupler avec données test
      const stmt = db.prepare(`
        INSERT OR IGNORE INTO technician_skills 
        (technician_id, skill_name, skill_level, years_experience)
        VALUES (?, ?, ?, ?)
      `);

      let inserted = 0;
      TEST_SKILLS.forEach((skill) => {
        stmt.run(
          skill.technician_id,
          skill.skill_name,
          skill.skill_level,
          skill.years_experience,
          (err) => {
            if (!err) inserted++;
          }
        );
      });

      stmt.finalize((err) => {
        if (err) {
          console.error('❌ Erreur insertion skills:', err.message);
        } else {
          console.log(`✅ ${inserted} compétences insérées`);
        }
      });

      // 4. Créer table mapping intervention_types → skills
      db.run(`
        CREATE TABLE IF NOT EXISTS intervention_skill_requirements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          intervention_type VARCHAR(50) NOT NULL UNIQUE,
          required_skills TEXT NOT NULL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      `, (err) => {
        if (err) {
          console.error('❌ Erreur création table requirements:', err.message);
        } else {
          console.log('✅ Table intervention_skill_requirements créée');
        }
      });

      // 5. Peupler mapping
      const stmtMap = db.prepare(`
        INSERT OR REPLACE INTO intervention_skill_requirements 
        (intervention_type, required_skills)
        VALUES (?, ?)
      `);

      Object.entries(INTERVENTION_SKILLS_MAP).forEach(([type, skills]) => {
        stmtMap.run(type, JSON.stringify(skills));
      });

      stmtMap.finalize((err) => {
        if (err) {
          console.error('❌ Erreur insertion mappings:', err.message);
        } else {
          console.log(`✅ ${Object.keys(INTERVENTION_SKILLS_MAP).length} mappings insérés`);
        }
      });

      db.close((err) => {
        if (err) {
          console.error('❌ Erreur fermeture DB:', err.message);
          reject(err);
        } else {
          console.log('✅ Migration skills terminée');
          resolve();
        }
      });
    });
  });
}

async function down() {
  return new Promise((resolve, reject) => {
    const db = new sqlite3.Database(dbPath);

    db.serialize(() => {
      db.run('DROP TABLE IF EXISTS technician_skills', (err) => {
        if (err) console.error('❌ Erreur drop technician_skills:', err.message);
        else console.log('✅ Table technician_skills supprimée');
      });

      db.run('DROP TABLE IF EXISTS intervention_skill_requirements', (err) => {
        if (err) console.error('❌ Erreur drop requirements:', err.message);
        else console.log('✅ Table intervention_skill_requirements supprimée');
      });

      db.close((err) => {
        if (err) reject(err);
        else {
          console.log('✅ Rollback terminé');
          resolve();
        }
      });
    });
  });
}

// Exécution si lancé directement
if (require.main === module) {
  console.log('🚀 Démarrage migration skills...\n');
  
  up()
    .then(() => {
      console.log('\n✅ Migration réussie !');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ Migration échouée:', error);
      process.exit(1);
    });
}

module.exports = { up, down };
