const { MaintenanceSchedule, User, Equipment, TechnicianProfile } = require('../models');

// Liste des plannings de maintenance
const listSchedules = async (req, res) => {
  try {
    const schedules = await MaintenanceSchedule.findAll({
      include: [
        { 
          model: User, 
          as: 'technician', 
          attributes: ['id', 'email'],
          include: [{
            model: TechnicianProfile,
            as: 'technicianProfile',
            attributes: ['first_name', 'last_name']
          }]
        },
        {
          model: Equipment,
          as: 'equipment',
          attributes: ['id', 'name', 'type', 'brand', 'model']
        }
      ],
      order: [['scheduled_date', 'DESC']]
    });

    // Aplatir les données pour le frontend
    const formattedSchedules = schedules.map(schedule => {
      const scheduleData = schedule.toJSON();
      console.log('🔍 Schedule brut:', JSON.stringify(scheduleData, null, 2));
      const formatted = {
        ...scheduleData,
        equipmentName: scheduleData.equipment ? scheduleData.equipment.name : '-',
        technicianName: scheduleData.technician?.technicianProfile 
          ? `${scheduleData.technician.technicianProfile.first_name} ${scheduleData.technician.technicianProfile.last_name}`
          : '-'
      };
      console.log('✅ equipmentName:', formatted.equipmentName);
      console.log('✅ technicianName:', formatted.technicianName);
      return formatted;
    });

    res.json({ success: true, data: formattedSchedules });
  } catch (err) {
    console.error('Error listing schedules:', err);
    res.status(500).json({ success: false, message: 'Erreur lors du chargement des plannings', error: err.message });
  }
};

// Détail d'un planning
const getSchedule = async (req, res) => {
  try {
    const schedule = await MaintenanceSchedule.findByPk(req.params.id, {
      include: [
        { 
          model: User, 
          as: 'technician', 
          attributes: ['id', 'email'],
          include: [{
            model: TechnicianProfile,
            as: 'technicianProfile',
            attributes: ['first_name', 'last_name']
          }]
        },
        {
          model: Equipment,
          as: 'equipment',
          attributes: ['id', 'name', 'type', 'brand', 'model', 'location']
        }
      ]
    });
    if (!schedule) return res.status(404).json({ success: false, message: 'Planning non trouvé' });
    res.json({ success: true, data: schedule });
  } catch (err) {
    console.error('Error getting schedule:', err);
    res.status(500).json({ success: false, message: 'Erreur lors du chargement du planning', error: err.message });
  }
};

// Création d'un planning
const createSchedule = async (req, res) => {
  try {
    const { equipment_id, technician_id, scheduled_date, type, status, notes } = req.body;
    const schedule = await MaintenanceSchedule.create({ equipment_id, technician_id, scheduled_date, type, status, notes });
    res.status(201).json({ success: true, data: schedule });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Erreur lors de la création du planning', error: err.message });
  }
};

// Mise à jour d'un planning
const updateSchedule = async (req, res) => {
  try {
    console.log('🔄 UPDATE Schedule ID:', req.params.id);
    console.log('📥 Body:', JSON.stringify(req.body, null, 2));
    
    const schedule = await MaintenanceSchedule.findByPk(req.params.id);
    if (!schedule) return res.status(404).json({ success: false, message: 'Planning non trouvé' });
    
    const { equipment_id, technician_id, scheduled_date, type, status, notes } = req.body;
    Object.assign(schedule, { equipment_id, technician_id, scheduled_date, type, status, notes });
    await schedule.save();
    
    console.log('✅ Schedule updated successfully:', schedule.id);
    res.json({ success: true, data: schedule });
  } catch (err) {
    console.error('❌ Error updating schedule:', err);
    res.status(500).json({ success: false, message: 'Erreur lors de la mise à jour du planning', error: err.message });
  }
};

// Suppression d'un planning
const deleteSchedule = async (req, res) => {
  try {
    const schedule = await MaintenanceSchedule.findByPk(req.params.id);
    if (!schedule) return res.status(404).json({ success: false, message: 'Planning non trouvé' });
    await schedule.destroy();
    res.json({ success: true, message: 'Planning supprimé' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Erreur lors de la suppression du planning', error: err.message });
  }
};

module.exports = {
  listSchedules,
  getSchedule,
  createSchedule,
  updateSchedule,
  deleteSchedule
};
