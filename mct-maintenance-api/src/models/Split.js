const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

/**
 * Modèle Split - Représente une unité de climatisation individuelle
 * 
 * Un client peut avoir plusieurs splits, et chaque split peut avoir
 * sa propre offre d'entretien (abonnement).
 * 
 * Le split_code est un identifiant unique qui sera encodé dans un QR code
 * que les techniciens colleront sur l'équipement pour la traçabilité.
 */
const Split = sequelize.define('Split', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  
  // Code unique du split (ex: SPLIT-2026-000124)
  split_code: {
    type: DataTypes.STRING(50),
    allowNull: false,
    unique: true
  },
  
  // URL du QR code généré (stocké dans /uploads/qrcodes/)
  qr_code_url: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  
  // Client propriétaire du split
  customer_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'id'
    }
  },
  
  // Informations techniques
  brand: {
    type: DataTypes.STRING(100),
    allowNull: true,
    comment: 'Marque du split (Samsung, LG, Daikin, etc.)'
  },
  
  model: {
    type: DataTypes.STRING(100),
    allowNull: true,
    comment: 'Modèle du split'
  },
  
  serial_number: {
    type: DataTypes.STRING(100),
    allowNull: true,
    comment: 'Numéro de série du fabricant'
  },
  
  power: {
    type: DataTypes.STRING(50),
    allowNull: true,
    comment: 'Puissance (ex: 9000 BTU, 12000 BTU, 2.5 kW)'
  },
  
  power_type: {
    type: DataTypes.ENUM('BTU', 'kW', 'CV'),
    defaultValue: 'BTU',
    comment: 'Unité de puissance'
  },
  
  // Localisation dans le logement
  location: {
    type: DataTypes.STRING(100),
    allowNull: true,
    comment: 'Pièce où est installé le split (salon, chambre, cuisine, etc.)'
  },
  
  floor: {
    type: DataTypes.STRING(50),
    allowNull: true,
    comment: 'Étage (RDC, 1er, 2ème, etc.)'
  },
  
  // Dates importantes
  installation_date: {
    type: DataTypes.DATEONLY,
    allowNull: true,
    comment: 'Date d\'installation du split'
  },
  
  warranty_end_date: {
    type: DataTypes.DATEONLY,
    allowNull: true,
    comment: 'Date de fin de garantie constructeur'
  },
  
  last_maintenance_date: {
    type: DataTypes.DATEONLY,
    allowNull: true,
    comment: 'Date du dernier entretien'
  },
  
  next_maintenance_date: {
    type: DataTypes.DATEONLY,
    allowNull: true,
    comment: 'Date du prochain entretien prévu'
  },
  
  // État du split
  status: {
    type: DataTypes.ENUM('active', 'inactive', 'out_of_service', 'pending_installation'),
    defaultValue: 'active',
    comment: 'État actuel du split'
  },
  
  // Informations complémentaires
  notes: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'Notes libres sur le split'
  },
  
  // Photo du split (pour identification visuelle)
  photo_url: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  
  // Compteur d'interventions pour statistiques
  intervention_count: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  
  // Adresse d'installation (si différente de l'adresse client)
  installation_address: {
    type: DataTypes.STRING(255),
    allowNull: true,
    comment: 'Adresse d\'installation si différente de l\'adresse du client'
  }
}, {
  tableName: 'Splits',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  
  hooks: {
    // Générer automatiquement le split_code avant création
    beforeCreate: async (split, options) => {
      if (!split.split_code) {
        const year = new Date().getFullYear();
        
        // Trouver le dernier numéro de l'année
        const lastSplit = await Split.findOne({
          where: {
            split_code: {
              [require('sequelize').Op.like]: `SPLIT-${year}-%`
            }
          },
          order: [['id', 'DESC']]
        });
        
        let nextNumber = 1;
        if (lastSplit) {
          const lastNumber = parseInt(lastSplit.split_code.split('-')[2]);
          nextNumber = lastNumber + 1;
        }
        
        split.split_code = `SPLIT-${year}-${String(nextNumber).padStart(6, '0')}`;
      }
    }
  }
});

module.exports = Split;
