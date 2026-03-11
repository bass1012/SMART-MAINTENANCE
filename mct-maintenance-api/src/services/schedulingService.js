const { User, Intervention } = require('../models');
const { Op } = require('sequelize');

/**
 * Service de planification automatique des interventions
 * Algorithme de scoring multi-critères pour suggérer les meilleurs techniciens
 */
class SchedulingService {
  constructor() {
    // Poids par défaut de chaque critère (total = 100)
    this.defaultWeights = {
      distance: 30,      // Impact coûts déplacement
      skills: 25,        // Qualité service
      availability: 20,  // Rapidité intervention
      workload: 15,      // Équité charge travail
      performance: 10    // Historique qualité
    };

    // Configuration
    this.MAX_DAILY_INTERVENTIONS = 6;
    this.MAX_DISTANCE_KM = 100; // Distance max acceptable
    this.MIN_INTERVENTION_INTERVAL_MINUTES = 90; // 1h30 entre interventions
    this.DEFAULT_INTERVENTION_DURATION_MINUTES = 90; // Durée estimée d'une intervention
  }

  /**
   * Suggérer les meilleurs techniciens pour une intervention
   * @param {number} interventionId - ID de l'intervention
   * @param {Object} options - Options (max_results, weights)
   * @returns {Promise<Array>} Liste techniciens avec scores
   */
  async suggestTechnicians(interventionId, options = {}) {
    const startTime = Date.now();

    try {
      const { sequelize } = require('../models');

      // 1. Récupérer l'intervention avec coordonnées client (requête SQL directe)
      const [intervention] = await sequelize.query(`
        SELECT 
          i.*,
          c.id as customer_id,
          c.first_name as customer_first_name,
          c.last_name as customer_last_name,
          c.latitude as customer_latitude,
          c.longitude as customer_longitude
        FROM interventions i
        LEFT JOIN users c ON i.customer_id = c.id
        WHERE i.id = ?
      `, {
        replacements: [interventionId],
        type: sequelize.QueryTypes.SELECT
      });

      if (!intervention) {
        throw new Error('Intervention non trouvée');
      }

      if (intervention.technician_id) {
        throw new Error('Intervention déjà assignée');
      }

      // 2. Récupérer tous les techniciens actifs avec coordonnées (SQL directe)
      const technicians = await sequelize.query(`
        SELECT 
          id, 
          first_name, 
          last_name, 
          email, 
          phone, 
          profile_image,
          latitude,
          longitude
        FROM users
        WHERE role = 'technician' AND status = 'active'
      `, {
        type: sequelize.QueryTypes.SELECT
      });

      if (technicians.length === 0) {
        throw new Error('Aucun technicien disponible');
      }

      // 3. Calculer les scores pour chaque technicien
      const weights = options.weights || this.defaultWeights;
      const suggestions = [];

      for (const technician of technicians) {
        // Vérifier la limite journalière avant de calculer les scores
        const interventionDate = intervention.scheduled_date 
          ? new Date(intervention.scheduled_date).toISOString().split('T')[0]
          : new Date().toISOString().split('T')[0];

        const dailyCount = await Intervention.count({
          where: {
            technician_id: technician.id,
            scheduled_date: {
              [Op.gte]: new Date(interventionDate),
              [Op.lt]: new Date(new Date(interventionDate).getTime() + 24 * 60 * 60 * 1000)
            },
            status: { [Op.notIn]: ['cancelled', 'completed'] }
          }
        });

        // Si le technicien a atteint sa limite, on le saute
        if (dailyCount >= this.MAX_DAILY_INTERVENTIONS) {
          console.log(`⚠️ Technicien ${technician.id} a atteint sa limite journalière (${dailyCount}/${this.MAX_DAILY_INTERVENTIONS})`);
          continue;
        }

        const scores = await this.calculateAllScores(
          technician,
          intervention,
          weights
        );

        // Filtrer techniciens trop éloignés
        if (scores.distance_km > this.MAX_DISTANCE_KM) {
          continue;
        }

        suggestions.push({
          technician_id: technician.id,
          name: `${technician.first_name} ${technician.last_name}`,
          email: technician.email,
          phone: technician.phone,
          avatar: technician.profile_image,
          total_score: scores.total_score,
          daily_interventions: dailyCount,
          details: {
            distance_score: scores.distance_score,
            distance_km: scores.distance_km,
            skills_score: scores.skills_score,
            matched_skills: scores.matched_skills,
            availability_score: scores.availability_score,
            next_available: scores.next_available,
            workload_score: scores.workload_score,
            recent_interventions: scores.recent_interventions,
            performance_score: scores.performance_score,
            avg_rating: scores.avg_rating,
            total_ratings: scores.total_ratings
          }
        });
      }

      // 4. Trier par score décroissant
      suggestions.sort((a, b) => b.total_score - a.total_score);

      // 5. Limiter résultats
      const maxResults = options.max_results || 5;
      const topSuggestions = suggestions.slice(0, maxResults);

      const computationTime = Date.now() - startTime;

      return {
        intervention_id: interventionId,
        suggestions: topSuggestions,
        computed_at: new Date().toISOString(),
        computation_time_ms: computationTime
      };

    } catch (error) {
      console.error('❌ Erreur suggestTechnicians:', error);
      throw error;
    }
  }

  /**
   * Calculer tous les scores pour un technicien
   */
  async calculateAllScores(technician, intervention, weights) {
    // 1. Score distance (calcul réel avec géolocalisation)
    let distanceResult;
    
    console.log(`📍 Technicien ${technician.id}: lat=${technician.latitude}, lng=${technician.longitude}`);
    console.log(`📍 Client: lat=${intervention.customer_latitude}, lng=${intervention.customer_longitude}`);
    
    if (technician.latitude && technician.longitude && intervention.customer_latitude && intervention.customer_longitude) {
      distanceResult = this.calculateDistanceScore(
        technician.latitude,
        technician.longitude,
        intervention.customer_latitude,
        intervention.customer_longitude
      );
      console.log(`✅ Distance calculée: ${distanceResult.distance_km} km (score: ${distanceResult.score})`);
    } else {
      // Fallback: score neutre si pas de coordonnées
      distanceResult = { score: 50, distance_km: 0 };
      console.warn(`⚠️  Coordonnées manquantes pour technicien ${technician.id} ou client`);
    }

    // 2. Score compétences (calcul réel depuis DB)
    const skillsResult = await this.calculateSkillsScore(
      technician.id,
      intervention.intervention_type
    );

    // 3. Score disponibilité
    const availabilityResult = await this.calculateAvailabilityScore(
      technician.id,
      intervention.scheduled_date,
      intervention.scheduled_time
    );

    // 4. Score charge travail
    const workloadResult = await this.calculateWorkloadScore(technician.id);

    // 5. Score performance
    const performanceResult = await this.calculatePerformanceScore(technician.id);

    // Calcul score total pondéré
    const totalScore = Math.round(
      (weights.distance * distanceResult.score +
       weights.skills * skillsResult.score +
       weights.availability * availabilityResult.score +
       weights.workload * workloadResult.score +
       weights.performance * performanceResult.score) / 100
    );

    return {
      total_score: totalScore,
      distance_score: distanceResult.score,
      distance_km: distanceResult.distance_km,
      skills_score: skillsResult.score,
      matched_skills: skillsResult.matched_skills,
      availability_score: availabilityResult.score,
      next_available: availabilityResult.next_available,
      workload_score: workloadResult.score,
      recent_interventions: workloadResult.recent_interventions,
      performance_score: performanceResult.score,
      avg_rating: performanceResult.avg_rating,
      total_ratings: performanceResult.total_ratings
    };
  }

  /**
   * Score 1 : Distance géographique (0-100)
   * Formule Haversine pour distance géodésique
   */
  calculateDistanceScore(techLat, techLng, clientLat, clientLng) {
    // Valeurs par défaut si coordonnées manquantes
    if (!techLat || !techLng || !clientLat || !clientLng) {
      return { score: 50, distance_km: 0 };
    }

    const R = 6371; // Rayon Terre en km
    const dLat = this.toRad(clientLat - techLat);
    const dLng = this.toRad(clientLng - techLng);

    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(this.toRad(techLat)) * Math.cos(this.toRad(clientLat)) *
              Math.sin(dLng / 2) * Math.sin(dLng / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distanceKm = R * c;

    // Scoring inverse : plus proche = meilleur score
    let score;
    if (distanceKm <= 5) score = 100;
    else if (distanceKm <= 10) score = 80;
    else if (distanceKm <= 20) score = 60;
    else if (distanceKm <= 50) score = 40;
    else score = 20;

    return {
      score,
      distance_km: Math.round(distanceKm * 10) / 10
    };
  }

  /**
   * Score 2 : Compétences techniques (0-100)
   * Matching compétences technicien vs type intervention depuis DB
   */
  async calculateSkillsScore(technicianId, interventionType) {
    try {
      const { sequelize } = require('../models');

      // 1. Récupérer compétences requises pour ce type d'intervention
      const requirementsResult = await sequelize.query(`
        SELECT required_skills 
        FROM intervention_skill_requirements 
        WHERE intervention_type = ?
      `, {
        replacements: [interventionType],
        type: sequelize.QueryTypes.SELECT
      });

      let requiredSkills = [];
      if (requirementsResult.length > 0) {
        try {
          requiredSkills = JSON.parse(requirementsResult[0].required_skills);
        } catch (e) {
          console.warn(`⚠️  Erreur parsing required_skills pour type ${interventionType}`);
        }
      }

      // Si pas de mapping, utiliser score neutre
      if (requiredSkills.length === 0) {
        return { score: 70, matched_skills: [], tech_skills: [] };
      }

      // 2. Récupérer compétences du technicien
      const techSkillsResult = await sequelize.query(`
        SELECT skill_name, skill_level, years_experience
        FROM technician_skills
        WHERE technician_id = ?
      `, {
        replacements: [technicianId],
        type: sequelize.QueryTypes.SELECT
      });

      const techSkills = techSkillsResult.map(s => s.skill_name.toLowerCase());

      // 3. Calculer matching
      const matchedSkills = [];
      let totalScore = 0;

      requiredSkills.forEach(reqSkill => {
        const reqSkillLower = reqSkill.toLowerCase();
        
        // Chercher un match (exact ou partiel)
        const match = techSkillsResult.find(ts => 
          ts.skill_name.toLowerCase().includes(reqSkillLower) || 
          reqSkillLower.includes(ts.skill_name.toLowerCase())
        );

        if (match) {
          matchedSkills.push(reqSkill);
          
          // Bonus selon niveau de compétence
          const levelBonus = {
            'expert': 1.0,
            'advanced': 0.9,
            'intermediate': 0.75,
            'beginner': 0.5
          }[match.skill_level] || 0.75;

          totalScore += levelBonus;
        }
      });

      // 4. Calculer score final
      let score;
      if (matchedSkills.length === 0) {
        score = 30; // Score minimum
      } else {
        // Score basé sur % matching + bonus niveaux
        const matchRatio = matchedSkills.length / requiredSkills.length;
        const avgBonus = matchedSkills.length > 0 ? totalScore / matchedSkills.length : 0;
        score = Math.round(matchRatio * avgBonus * 100);
        score = Math.min(100, Math.max(30, score)); // Clamp entre 30-100
      }

      return {
        score,
        matched_skills: matchedSkills,
        tech_skills: techSkills
      };

    } catch (error) {
      console.error('❌ Erreur calculateSkillsScore:', error);
      return { score: 50, matched_skills: [], tech_skills: [] };
    }
  }

  /**
   * Score 3 : Disponibilité (0-100)
   * Vérifier conflits horaires dans calendrier avec buffer de 1h30
   */
  async calculateAvailabilityScore(technicianId, interventionDate, interventionTime) {
    try {
      // Récupérer interventions existantes ce jour
      const existingInterventions = await Intervention.findAll({
        where: {
          technician_id: technicianId,
          scheduled_date: interventionDate,
          status: {
            [Op.in]: ['assigned', 'accepted', 'on_the_way', 'in_progress']
          }
        }
      });

      // Aucune intervention = 100% disponible
      if (existingInterventions.length === 0) {
        return {
          score: 100,
          next_available: interventionDate
        };
      }

      // Vérifier conflits horaires avec buffer de 1h30 (90 minutes)
      const timeSlotCheck = await this.checkTimeSlotAvailability(
        technicianId,
        interventionDate,
        interventionTime
      );

      if (!timeSlotCheck.available) {
        console.log(`⚠️ Conflit horaire pour technicien ${technicianId}: ${timeSlotCheck.message}`);
        return { 
          score: 0, 
          next_available: null,
          conflict: timeSlotCheck.conflict
        };
      }

      // Disponible mais déjà occupé (réduire score selon charge)
      const occupancyRate = existingInterventions.length / this.MAX_DAILY_INTERVENTIONS;
      const score = Math.round(100 * (1 - occupancyRate));

      return {
        score,
        next_available: interventionDate
      };

    } catch (error) {
      console.error('Erreur calculateAvailabilityScore:', error);
      return { score: 50, next_available: null };
    }
  }

  /**
   * Score 4 : Charge de travail (0-100)
   * Équilibrer charge entre techniciens
   */
  async calculateWorkloadScore(technicianId) {
    try {
      const now = new Date();
      const last7Days = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

      // Compter interventions 7 derniers jours
      const recentInterventions = await Intervention.count({
        where: {
          technician_id: technicianId,
          created_at: { [Op.gte]: last7Days },
          status: { [Op.ne]: 'cancelled' }
        }
      });

      // Scoring inverse : moins chargé = meilleur score
      let score;
      if (recentInterventions === 0) score = 100;
      else if (recentInterventions <= 5) score = 80;
      else if (recentInterventions <= 10) score = 60;
      else if (recentInterventions <= 15) score = 40;
      else score = 20;

      return {
        score,
        recent_interventions: recentInterventions
      };

    } catch (error) {
      console.error('Erreur calculateWorkloadScore:', error);
      return { score: 50, recent_interventions: 0 };
    }
  }

  /**
   * Score 5 : Performance historique (0-100)
   * Moyenne notes évaluations clients
   */
  async calculatePerformanceScore(technicianId) {
    try {
      const { sequelize } = require('../models');

      const result = await Intervention.findOne({
        attributes: [
          [sequelize.fn('AVG', sequelize.col('rating')), 'avg_rating'],
          [sequelize.fn('COUNT', sequelize.col('id')), 'count']
        ],
        where: {
          technician_id: technicianId,
          rating: { [Op.ne]: null }
        },
        raw: true
      });

      const count = parseInt(result?.count || 0);
      const avgRating = parseFloat(result?.avg_rating || 0);

      // Données insuffisantes = score neutre
      if (count < 5) {
        return {
          score: 50,
          avg_rating: 0,
          total_ratings: count
        };
      }

      // Conversion note 0-5 vers score 0-100
      const score = Math.round((avgRating / 5) * 100);

      return {
        score,
        avg_rating: Math.round(avgRating * 10) / 10,
        total_ratings: count
      };

    } catch (error) {
      console.error('Erreur calculatePerformanceScore:', error);
      return { score: 50, avg_rating: 0, total_ratings: 0 };
    }
  }

  /**
   * Assigner automatiquement le meilleur technicien
   */
  async autoAssignIntervention(interventionId, options = {}) {
    try {
      // 1. Obtenir suggestions
      const result = await this.suggestTechnicians(interventionId, { max_results: 1 });

      if (result.suggestions.length === 0) {
        throw new Error('Aucun technicien disponible trouvé');
      }

      const bestTechnician = result.suggestions[0];

      // 2. Assigner intervention
      const intervention = await Intervention.findByPk(interventionId);
      
      if (intervention.technician_id) {
        throw new Error('Intervention déjà assignée');
      }

      await intervention.update({
        technician_id: bestTechnician.technician_id,
        status: 'assigned'
      });

      // 3. Retourner résultat
      return {
        intervention_id: interventionId,
        assigned_technician: {
          id: bestTechnician.technician_id,
          name: bestTechnician.name,
          email: bestTechnician.email,
          phone: bestTechnician.phone
        },
        score: bestTechnician.total_score,
        assigned_at: new Date().toISOString()
      };

    } catch (error) {
      console.error('❌ Erreur autoAssignIntervention:', error);
      throw error;
    }
  }

  /**
   * Vérifier si un technicien est disponible pour un créneau donné
   * Retourne true si disponible, false si conflit temporel
   * @param {number} technicianId - ID du technicien
   * @param {Date|string} scheduledDate - Date de l'intervention
   * @param {string} scheduledTime - Heure de l'intervention (HH:MM)
   * @returns {Promise<{available: boolean, conflict: Object|null, message: string}>}
   */
  async checkTimeSlotAvailability(technicianId, scheduledDate, scheduledTime) {
    try {
      console.log('🔍 [TimeSlot] Vérification créneau pour technicien:', technicianId);
      console.log('🔍 [TimeSlot] scheduledDate:', scheduledDate);
      console.log('🔍 [TimeSlot] scheduledTime:', scheduledTime);
      
      // scheduled_date dans PostgreSQL est un timestamp avec l'heure intégrée
      // Construire la date/heure demandée
      let requestedDateTime;
      if (scheduledTime) {
        // Si on a une heure séparée, combiner date + heure
        requestedDateTime = this.buildDateTime(scheduledDate, scheduledTime);
      } else {
        // Sinon, utiliser scheduled_date tel quel (c'est déjà un timestamp complet)
        requestedDateTime = new Date(scheduledDate);
      }
      
      console.log('🔍 [TimeSlot] requestedDateTime:', requestedDateTime.toISOString());
      
      const intervalMinutes = this.MIN_INTERVENTION_INTERVAL_MINUTES;
      const durationMinutes = this.DEFAULT_INTERVENTION_DURATION_MINUTES;
      
      console.log('🔍 [TimeSlot] Intervalle minimum:', intervalMinutes, 'min, Durée:', durationMinutes, 'min');

      // Calculer la fenêtre de temps pour ce jour
      const dayStart = new Date(requestedDateTime);
      dayStart.setHours(0, 0, 0, 0);
      const dayEnd = new Date(dayStart);
      dayEnd.setDate(dayEnd.getDate() + 1);
      
      console.log('🔍 [TimeSlot] Recherche interventions entre', dayStart.toISOString(), 'et', dayEnd.toISOString());

      // Récupérer les interventions du technicien pour ce jour
      const conflictingInterventions = await Intervention.findAll({
        where: {
          technician_id: technicianId,
          scheduled_date: {
            [Op.gte]: dayStart,
            [Op.lt]: dayEnd
          },
          status: {
            [Op.in]: ['assigned', 'accepted', 'on_the_way', 'in_progress']
          }
        },
        order: [['scheduled_date', 'ASC']]
      });
      
      console.log('🔍 [TimeSlot] Interventions trouvées:', conflictingInterventions.length);

      // Vérifier chaque intervention existante pour conflit
      for (const existingInt of conflictingInterventions) {
        // scheduled_date contient déjà la date et l'heure
        const existingDateTime = new Date(existingInt.scheduled_date);
        
        console.log('🔍 [TimeSlot] Vérification conflit avec intervention #', existingInt.id, 'à', existingDateTime.toISOString());
        
        // Conflit si la nouvelle intervention commence avant que la précédente ne soit finie + buffer
        // OU si la nouvelle intervention finit après que la suivante commence
        const newEndTime = new Date(requestedDateTime.getTime() + durationMinutes * 60 * 1000);

        // Vérifie si les créneaux se chevauchent avec le buffer de 1h30
        const conflictStart = new Date(existingDateTime.getTime() - intervalMinutes * 60 * 1000);
        const conflictEnd = new Date(existingDateTime.getTime() + durationMinutes * 60 * 1000 + intervalMinutes * 60 * 1000);
        
        console.log('🔍 [TimeSlot] Fenêtre de conflit:', conflictStart.toISOString(), '-', conflictEnd.toISOString());
        console.log('🔍 [TimeSlot] Nouvelle intervention:', requestedDateTime.toISOString(), '-', newEndTime.toISOString());

        if (requestedDateTime < conflictEnd && newEndTime > conflictStart) {
          console.log('❌ [TimeSlot] CONFLIT DÉTECTÉ!');
          // Formater l'heure pour affichage
          const timeStr = existingDateTime.toISOString().split('T')[1].substring(0, 5);
          return {
            available: false,
            conflict: {
              intervention_id: existingInt.id,
              scheduled_date: existingInt.scheduled_date,
              scheduled_time: timeStr,
              status: existingInt.status,
              conflict_window: {
                start: conflictStart.toISOString(),
                end: conflictEnd.toISOString()
              }
            },
            message: `Le technicien a déjà une intervention (#${existingInt.id}) à ${timeStr}. Un délai minimum de ${intervalMinutes} minutes est requis entre les interventions.`
          };
        }
      }

      return {
        available: true,
        conflict: null,
        message: 'Créneau disponible'
      };

    } catch (error) {
      console.error('❌ Erreur checkTimeSlotAvailability:', error);
      // En cas d'erreur, on autorise par défaut pour ne pas bloquer
      return {
        available: true,
        conflict: null,
        message: 'Vérification impossible, autorisé par défaut'
      };
    }
  }

  /**
   * Construire un objet Date à partir de date et heure
   */
  buildDateTime(date, time) {
    const dateStr = typeof date === 'string' ? date : date.toISOString().split('T')[0];
    const timeStr = time || '09:00';
    return new Date(`${dateStr}T${timeStr}:00`);
  }

  // Utilitaires
  toRad(degrees) {
    return degrees * (Math.PI / 180);
  }

  parseTimeToHour(timeString) {
    if (!timeString) return 9; // Défaut 9h
    const [hours] = timeString.split(':');
    return parseInt(hours);
  }
}

module.exports = new SchedulingService();
