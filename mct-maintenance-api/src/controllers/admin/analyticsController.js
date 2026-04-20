const { 
  Intervention, 
  Quote, 
  Order, 
  Complaint,
  User,
  TechnicianProfile,
  CustomerProfile,
  Product,
  sequelize
} = require('../../models');
const { Op } = require('sequelize');
const ExcelJS = require('exceljs');
const PDFDocument = require('pdfkit');

/**
 * Récupérer les statistiques globales du dashboard admin
 */
exports.getGlobalStats = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    
    const dateFilter = {};
    if (startDate && endDate) {
      dateFilter.created_at = {
        [Op.between]: [new Date(startDate), new Date(endDate)]
      };
    }

    // Statistiques interventions
    const totalInterventions = await Intervention.count({ where: dateFilter });
    const completedInterventions = await Intervention.count({
      where: { ...dateFilter, status: 'completed' }
    });
    const pendingInterventions = await Intervention.count({
      where: { ...dateFilter, status: { [Op.in]: ['pending', 'assigned', 'accepted'] } }
    });
    const inProgressInterventions = await Intervention.count({
      where: { ...dateFilter, status: { [Op.in]: ['on_the_way', 'arrived', 'in_progress'] } }
    });

    // Statistiques par statut
    const interventionsByStatus = await Intervention.findAll({
      where: dateFilter,
      attributes: [
        'status',
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      group: ['status']
    });

    // Statistiques commandes
    const totalOrders = await Order.count({ where: dateFilter });
    const totalRevenue = await Order.sum('total_amount', {
      where: { ...dateFilter, payment_status: 'paid' }
    }) || 0;
    
    const pendingOrders = await Order.count({
      where: { ...dateFilter, status: { [Op.in]: ['pending', 'processing'] } }
    });

    // Statistiques devis
    const totalQuotes = await Quote.count({ where: dateFilter });
    const acceptedQuotes = await Quote.count({
      where: { ...dateFilter, status: 'accepted' }
    });
    const rejectedQuotes = await Quote.count({
      where: { ...dateFilter, status: 'rejected' }
    });
    const pendingQuotes = await Quote.count({
      where: { ...dateFilter, status: 'pending' }
    });

    // Taux de conversion devis
    const conversionRate = totalQuotes > 0 
      ? ((acceptedQuotes / totalQuotes) * 100).toFixed(2)
      : 0;

    // Statistiques réclamations
    const totalComplaints = await Complaint.count({ where: dateFilter });
    const openComplaints = await Complaint.count({
      where: { ...dateFilter, status: 'open' }
    });
    const resolvedComplaints = await Complaint.count({
      where: { ...dateFilter, status: 'resolved' }
    });

    // Statistiques utilisateurs
    const totalUsers = await User.count();
    const totalTechnicians = await TechnicianProfile.count();
    const totalCustomers = await CustomerProfile.count();

    // Interventions par mois (derniers 6 mois)
    const interventionsByMonth = await Intervention.findAll({
      attributes: [
        [sequelize.fn('to_char', sequelize.col('created_at'), 'YYYY-MM'), 'month'],
        [sequelize.fn('COUNT', sequelize.col('id')), 'count']
      ],
      where: {
        created_at: {
          [Op.gte]: new Date(new Date().setMonth(new Date().getMonth() - 6))
        }
      },
      group: [sequelize.fn('to_char', sequelize.col('created_at'), 'YYYY-MM')],
      order: [[sequelize.fn('to_char', sequelize.col('created_at'), 'YYYY-MM'), 'ASC']]
    });

    // Chiffre d'affaires par mois
    const revenueByMonth = await Order.findAll({
      attributes: [
        [sequelize.fn('to_char', sequelize.col('created_at'), 'YYYY-MM'), 'month'],
        [sequelize.fn('SUM', sequelize.col('total_amount')), 'revenue']
      ],
      where: {
        payment_status: 'paid',
        created_at: {
          [Op.gte]: new Date(new Date().setMonth(new Date().getMonth() - 6))
        }
      },
      group: [sequelize.fn('to_char', sequelize.col('created_at'), 'YYYY-MM')],
      order: [[sequelize.fn('to_char', sequelize.col('created_at'), 'YYYY-MM'), 'ASC']]
    });

    res.json({
      success: true,
      data: {
        interventions: {
          total: totalInterventions,
          completed: completedInterventions,
          pending: pendingInterventions,
          inProgress: inProgressInterventions,
          byStatus: interventionsByStatus,
          byMonth: interventionsByMonth
        },
        orders: {
          total: totalOrders,
          revenue: totalRevenue,
          pending: pendingOrders,
          revenueByMonth: revenueByMonth
        },
        quotes: {
          total: totalQuotes,
          accepted: acceptedQuotes,
          rejected: rejectedQuotes,
          pending: pendingQuotes,
          conversionRate: conversionRate
        },
        complaints: {
          total: totalComplaints,
          open: openComplaints,
          resolved: resolvedComplaints
        },
        users: {
          total: totalUsers,
          technicians: totalTechnicians,
          customers: totalCustomers
        }
      }
    });

  } catch (error) {
    console.error('❌ Erreur récupération stats globales:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des statistiques',
      error: error.message
    });
  }
};

/**
 * Récupérer les performances des techniciens
 */
exports.getTechnicianPerformance = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    
    const dateFilter = {};
    if (startDate && endDate) {
      dateFilter.created_at = {
        [Op.between]: [new Date(startDate), new Date(endDate)]
      };
    }

    const technicians = await TechnicianProfile.findAll({
      include: [{
        model: User,
        as: 'user',
        attributes: ['id', 'first_name', 'last_name', 'email']
      }]
    });

    const performanceData = await Promise.all(
      technicians.filter(tech => tech.user).map(async (tech) => {
        const interventions = await Intervention.findAll({
          where: {
            technician_id: tech.user_id,
            ...dateFilter
          }
        });

        const totalInterventions = interventions.length;
        const completedInterventions = interventions.filter(i => i.status === 'completed').length;
        const avgRating = interventions
          .filter(i => i.rating)
          .reduce((sum, i) => sum + i.rating, 0) / (interventions.filter(i => i.rating).length || 1);

        const completionRate = totalInterventions > 0
          ? ((completedInterventions / totalInterventions) * 100).toFixed(2)
          : 0;

        return {
          technicianId: tech.user_id,
          name: `${tech.user.first_name || tech.first_name || ''} ${tech.user.last_name || tech.last_name || ''}`.trim() || 'Sans nom',
          email: tech.user.email || '',
          totalInterventions,
          completedInterventions,
          completionRate: parseFloat(completionRate),
          avgRating: avgRating.toFixed(2),
          specialty: tech.specialization || ''
        };
      })
    );

    // Trier par nombre d'interventions complétées
    performanceData.sort((a, b) => b.completedInterventions - a.completedInterventions);

    res.json({
      success: true,
      data: performanceData
    });

  } catch (error) {
    console.error('❌ Erreur récupération performance techniciens:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des performances',
      error: error.message
    });
  }
};

/**
 * Exporter les rapports en Excel
 */
exports.exportToExcel = async (req, res) => {
  try {
    const { type, startDate, endDate } = req.query;

    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'MCT Maintenance';
    workbook.created = new Date();

    const dateFilter = {};
    if (startDate && endDate) {
      dateFilter.created_at = {
        [Op.between]: [new Date(startDate), new Date(endDate)]
      };
    }

    if (type === 'interventions' || !type) {
      const worksheet = workbook.addWorksheet('Interventions');
      
      worksheet.columns = [
        { header: 'ID', key: 'id', width: 10 },
        { header: 'Date', key: 'date', width: 15 },
        { header: 'Client', key: 'customer', width: 25 },
        { header: 'Technicien', key: 'technician', width: 25 },
        { header: 'Type', key: 'type', width: 20 },
        { header: 'Statut', key: 'status', width: 15 },
        { header: 'Note', key: 'rating', width: 10 },
        { header: 'Adresse', key: 'address', width: 30 }
      ];

      const interventions = await Intervention.findAll({
        where: dateFilter,
        include: [
          {
            model: User,
            as: 'customer',
            attributes: ['first_name', 'last_name']
          },
          {
            model: User,
            as: 'technician',
            attributes: ['first_name', 'last_name']
          }
        ],
        order: [['created_at', 'DESC']]
      });

      interventions.forEach(intervention => {
        worksheet.addRow({
          id: intervention.id,
          date: new Date(intervention.created_at).toLocaleDateString('fr-FR'),
          customer: intervention.customer 
            ? `${intervention.customer.first_name} ${intervention.customer.last_name}`
            : 'N/A',
          technician: intervention.technician
            ? `${intervention.technician.first_name} ${intervention.technician.last_name}`
            : 'Non assigné',
          type: intervention.type || 'N/A',
          status: intervention.status,
          rating: intervention.rating || 'N/A',
          address: intervention.address || 'N/A'
        });
      });

      // Style de l'en-tête
      worksheet.getRow(1).font = { bold: true };
      worksheet.getRow(1).fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FF0a543d' }
      };
      worksheet.getRow(1).font = { color: { argb: 'FFFFFFFF' }, bold: true };
    }

    if (type === 'orders' || !type) {
      const worksheet = workbook.addWorksheet('Commandes');
      
      worksheet.columns = [
        { header: 'ID', key: 'id', width: 10 },
        { header: 'Date', key: 'date', width: 15 },
        { header: 'Client', key: 'customer', width: 25 },
        { header: 'Montant', key: 'amount', width: 15 },
        { header: 'Statut', key: 'status', width: 15 },
        { header: 'Mode Paiement', key: 'paymentMode', width: 20 },
        { header: 'Adresse Livraison', key: 'address', width: 30 }
      ];

      const orders = await Order.findAll({
        where: dateFilter,
        include: [{
          model: User,
          as: 'customer',
          attributes: ['first_name', 'last_name']
        }],
        order: [['created_at', 'DESC']]
      });

      orders.forEach(order => {
        worksheet.addRow({
          id: order.id,
          date: new Date(order.created_at).toLocaleDateString('fr-FR'),
          customer: order.customer 
            ? `${order.customer.first_name} ${order.customer.last_name}`
            : 'N/A',
          amount: `${order.total_amount} FCFA`,
          status: order.status,
          paymentMode: order.payment_mode || 'N/A',
          address: order.delivery_address || 'N/A'
        });
      });

      worksheet.getRow(1).font = { bold: true };
      worksheet.getRow(1).fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FF0a543d' }
      };
      worksheet.getRow(1).font = { color: { argb: 'FFFFFFFF' }, bold: true };
    }

    // Définir le nom du fichier
    const filename = `rapport_${type || 'complet'}_${new Date().toISOString().split('T')[0]}.xlsx`;

    // Configurer les headers pour le téléchargement
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

    // Écrire dans la réponse
    await workbook.xlsx.write(res);
    res.end();

  } catch (error) {
    console.error('❌ Erreur export Excel:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'export Excel',
      error: error.message
    });
  }
};

/**
 * Exporter les rapports en PDF
 */
exports.exportToPDF = async (req, res) => {
  try {
    const { type, startDate, endDate } = req.query;

    const doc = new PDFDocument({ margin: 50 });
    
    const filename = `rapport_${type || 'complet'}_${new Date().toISOString().split('T')[0]}.pdf`;
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

    doc.pipe(res);

    // En-tête
    doc.fontSize(20).fillColor('#0a543d').text('MCT Maintenance', { align: 'center' });
    doc.moveDown();
    doc.fontSize(16).fillColor('#000').text('Rapport d\'Activité', { align: 'center' });
    doc.moveDown();
    doc.fontSize(10).text(`Généré le ${new Date().toLocaleDateString('fr-FR')}`, { align: 'center' });
    
    if (startDate && endDate) {
      doc.text(`Période: ${new Date(startDate).toLocaleDateString('fr-FR')} - ${new Date(endDate).toLocaleDateString('fr-FR')}`, { align: 'center' });
    }
    
    doc.moveDown(2);

    const dateFilter = {};
    if (startDate && endDate) {
      dateFilter.created_at = {
        [Op.between]: [new Date(startDate), new Date(endDate)]
      };
    }

    // Statistiques globales
    doc.fontSize(14).fillColor('#0a543d').text('Statistiques Globales');
    doc.moveDown();

    const totalInterventions = await Intervention.count({ where: dateFilter });
    const completedInterventions = await Intervention.count({
      where: { ...dateFilter, status: 'completed' }
    });
    const totalOrders = await Order.count({ where: dateFilter });
    const totalRevenue = await Order.sum('total_amount', {
      where: { ...dateFilter, payment_status: 'paid' }
    }) || 0;

    doc.fontSize(10).fillColor('#000');
    doc.text(`• Total Interventions: ${totalInterventions}`);
    doc.text(`• Interventions Complétées: ${completedInterventions}`);
    doc.text(`• Total Commandes: ${totalOrders}`);
    doc.text(`• Chiffre d'Affaires: ${totalRevenue.toLocaleString('fr-FR')} FCFA`);

    doc.moveDown(2);

    // Finaliser le PDF
    doc.end();

  } catch (error) {
    console.error('❌ Erreur export PDF:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'export PDF',
      error: error.message
    });
  }
};

/**
 * Récupérer les données pour les graphiques avancés
 */
exports.getChartData = async (req, res) => {
  try {
    const { chartType } = req.params;
    const { period = 6 } = req.query;

    const monthsAgo = parseInt(period);
    const startDate = new Date();
    startDate.setMonth(startDate.getMonth() - monthsAgo);

    let chartData = {};

    switch (chartType) {
      case 'interventions-timeline':
        // Interventions par jour sur la période
        chartData = await Intervention.findAll({
          attributes: [
            [sequelize.fn('DATE', sequelize.col('created_at')), 'date'],
            [sequelize.fn('COUNT', sequelize.col('id')), 'count']
          ],
          where: {
            created_at: { [Op.gte]: startDate }
          },
          group: [sequelize.fn('DATE', sequelize.col('created_at'))],
          order: [[sequelize.fn('DATE', sequelize.col('created_at')), 'ASC']]
        });
        break;

      case 'revenue-timeline':
        // Chiffre d'affaires par jour
        chartData = await Order.findAll({
          attributes: [
            [sequelize.fn('DATE', sequelize.col('created_at')), 'date'],
            [sequelize.fn('SUM', sequelize.col('total_amount')), 'revenue']
          ],
          where: {
            payment_status: 'paid',
            created_at: { [Op.gte]: startDate }
          },
          group: [sequelize.fn('DATE', sequelize.col('created_at'))],
          order: [[sequelize.fn('DATE', sequelize.col('created_at')), 'ASC']]
        });
        break;

      case 'interventions-by-type':
        // Répartition par type d'intervention
        chartData = await Intervention.findAll({
          attributes: [
            'intervention_type',
            [sequelize.fn('COUNT', sequelize.col('id')), 'count']
          ],
          where: {
            created_at: { [Op.gte]: startDate }
          },
          group: ['intervention_type']
        });
        break;

      case 'top-products':
        // Top 10 produits les plus vendus
        const topProducts = await sequelize.query(`
          SELECT 
            p.id,
            p.nom,
            SUM(oi.quantity) as total_sold,
            SUM(oi.quantity * oi.unit_price) as total_revenue
          FROM products p
          INNER JOIN order_items oi ON p.id = oi.product_id
          INNER JOIN orders o ON oi.order_id = o.id
          WHERE o.payment_status = 'paid'
          AND o.created_at >= ?
          GROUP BY p.id, p.nom
          ORDER BY total_sold DESC
          LIMIT 10
        `, {
          replacements: [startDate],
          type: sequelize.QueryTypes.SELECT
        });
        chartData = topProducts;
        break;

      case 'customer-satisfaction':
        // Évolution de la satisfaction client
        chartData = await Intervention.findAll({
          attributes: [
            [sequelize.fn('to_char', sequelize.col('created_at'), 'YYYY-MM'), 'month'],
            [sequelize.fn('AVG', sequelize.col('rating')), 'avgRating'],
            [sequelize.fn('COUNT', sequelize.col('id')), 'count']
          ],
          where: {
            rating: { [Op.ne]: null },
            created_at: { [Op.gte]: startDate }
          },
          group: [sequelize.fn('to_char', sequelize.col('created_at'), 'YYYY-MM')],
          order: [[sequelize.fn('to_char', sequelize.col('created_at'), 'YYYY-MM'), 'ASC']]
        });
        break;

      default:
        return res.status(400).json({
          success: false,
          message: 'Type de graphique invalide'
        });
    }

    res.json({
      success: true,
      chartType,
      data: chartData
    });

  } catch (error) {
    console.error('❌ Erreur récupération données graphique:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des données',
      error: error.message
    });
  }
};

module.exports = exports;
