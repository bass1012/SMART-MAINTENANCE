// Génération PDF moderne et professionnelle
const generateQuotePdf = async (req, res) => {
  try {
    const { id } = req.params;
    const quote = await Quote.findByPk(id, { include: [{ model: QuoteItem, as: 'items' }] });
    if (!quote) {
      return res.status(404).json({ success: false, message: 'Devis non trouvé' });
    }
    const PDFDocument = require('pdfkit');
    const doc = new PDFDocument({ margin: 40, size: 'A4' });
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=devis-${quote.reference}.pdf`);
    doc.pipe(res);

    // Logo (optionnel, remplacer par le chemin de votre logo si besoin)
    // doc.image('public/logo.png', 40, 30, { width: 100 });

    // En-tête
    doc
      .fontSize(22)
      .fillColor('#1a237e')
      .text('DEVIS', { align: 'right' })
      .moveDown(0.5);
    doc
      .fontSize(10)
      .fillColor('#333')
      .text(`Référence : ${quote.reference}`, { align: 'right' })
      .text(`Date d'émission : ${quote.issueDate}`, { align: 'right' })
      .text(`Date d'expiration : ${quote.expiryDate}`, { align: 'right' })
      .moveDown(1);

    // Infos client
    doc
      .fontSize(12)
      .fillColor('#1a237e')
      .text('Client', 40, 160)
      .fontSize(10)
      .fillColor('#333')
      .text(quote.customerName || '', 40, 180)
      .moveDown(1);

    // Tableau des articles
    const tableTop = 180;
    const itemHeight = 22;
    let y = tableTop;
    doc
      .fontSize(11)
      .fillColor('#1a237e')
      .text('Désignation', 40, y)
      .text('Qté', 250, y)
      .text('PU HT', 300, y)
      .text('Remise', 360, y)
      .text('TVA', 420, y)
      .text('Total HT', 480, y);
    y += itemHeight - 8;
    doc.moveTo(40, y).lineTo(550, y).stroke('#1a237e');
    y += 8;
    doc.fontSize(10).fillColor('#333');
    quote.items.forEach((item, idx) => {
      doc
        .text(item.productName, 40, y)
        .text(item.quantity, 250, y)
        .text(`${item.unitPrice.toLocaleString('fr-FR', { minimumFractionDigits: 0 })} F`, 300, y)
        .text(`${item.discount || 0}%`, 360, y)
        .text(`${item.taxRate || 0}%`, 420, y)
        .text(`${(item.unitPrice * item.quantity * (1 - (item.discount || 0) / 100)).toLocaleString('fr-FR', { minimumFractionDigits: 0 })} F`, 480, y);
      y += itemHeight;
      if (y > 700) {
        doc.addPage();
        y = 40;
      }
    });
    y += 10;
    doc.moveTo(40, y).lineTo(550, y).stroke('#1a237e');

    // Totaux
    y += 20;
    doc
      .fontSize(11)
      .fillColor('#1a237e')
      .text('Sous-total', 400, y)
      .fontSize(10)
      .fillColor('#333')
      .text(`${quote.subtotal.toLocaleString('fr-FR', { minimumFractionDigits: 0 })} F CFA`, 480, y);
    y += 18;
    doc
      .fontSize(11)
      .fillColor('#1a237e')
      .text('Remise', 400, y)
      .fontSize(10)
      .fillColor('#333')
      .text(`${quote.discountAmount.toLocaleString('fr-FR', { minimumFractionDigits: 0 })} F CFA`, 480, y);
    y += 18;
    doc
      .fontSize(11)
      .fillColor('#1a237e')
      .text('TVA', 400, y)
      .fontSize(10)
      .fillColor('#333')
      .text(`${quote.taxAmount.toLocaleString('fr-FR', { minimumFractionDigits: 0 })} F CFA`, 480, y);
    y += 18;
    doc
      .fontSize(12)
      .fillColor('#1a237e')
      .text('Total TTC', 400, y)
      .fontSize(12)
      .fillColor('#388e3c')
      .text(`${quote.total.toLocaleString('fr-FR', { minimumFractionDigits: 0 })} F CFA`, 480, y);

    // Notes et conditions
    y += 40;
    if (quote.notes) {
      doc
        .fontSize(10)
        .fillColor('#333')
        .text('Notes :', 40, y)
        .font('Helvetica-Oblique')
        .text(quote.notes, 100, y, { width: 400 });
      y += 30;
    }
    if (quote.termsAndConditions) {
      doc
        .fontSize(10)
        .fillColor('#333')
        .text('Conditions :', 40, y)
        .font('Helvetica-Oblique')
        .text(quote.termsAndConditions, 110, y, { width: 400 });
    }

    // Footer
    doc.fontSize(8).fillColor('#999').text('Document généré le ' + new Date().toLocaleDateString('fr-FR'), 40, 500, { align: 'center' });

    doc.end();
  } catch (error) {
    res.status(500).json({ success: false, message: 'Erreur lors de la génération du PDF', error: error.message });
  }
};
// Quote Controller - Placeholder implementation

const { Quote, QuoteItem, CustomerProfile, User } = require('../../models');
const { 
  notifyNewQuote,
  notifyQuoteSent,
  notifyQuoteAccepted, 
  notifyQuoteRejected,
  notifyQuoteUpdated
} = require('../../services/notificationHelpers');

const getAllQuotes = async (req, res) => {
  try {
    console.log('📋 Récupération de tous les devis...');
    const quotes = await Quote.findAll({
      include: [{ model: QuoteItem, as: 'items' }],
      order: [['created_at', 'DESC']]
    });
    console.log(`✅ ${quotes.length} devis récupérés`);
    res.status(200).json({ success: true, data: quotes });
  } catch (error) {
    console.error('❌ Erreur lors de la récupération des devis:', error.message);
    console.error('Stack:', error.stack);
    res.status(500).json({ success: false, message: 'Erreur lors de la récupération des devis', error: error.message });
  }
};

const getQuoteById = async (req, res) => {
  try {
    const quote = await Quote.findByPk(req.params.id, {
      include: [{ model: QuoteItem, as: 'items' }]
    });
    if (!quote) {
      return res.status(404).json({ success: false, message: 'Devis non trouvé' });
    }
    res.status(200).json({ success: true, data: quote });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Erreur lors de la récupération du devis', error: error.message });
  }
};

const createQuote = async (req, res) => {
  try {
    console.log('📝 Création de devis - Données reçues:', JSON.stringify(req.body, null, 2));
    
    const { reference, customerId, customerName, issueDate, expiryDate, status, subtotal, taxAmount, discountAmount, total, notes, termsAndConditions, items } = req.body;
    
    console.log('📝 Création du devis principal...');
    const quote = await Quote.create({
      reference,
      customerId,
      customerName,
      issueDate,
      expiryDate,
      status,
      subtotal,
      taxAmount,
      discountAmount,
      total,
      notes,
      termsAndConditions
    });
    
    console.log('✅ Devis créé avec ID:', quote.id);
    
    if (items && Array.isArray(items)) {
      console.log(`📝 Création de ${items.length} items...`);
      for (const item of items) {
        await QuoteItem.create({
          quoteId: quote.id,
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          discount: item.discount,
          taxRate: item.taxRate
        });
      }
      console.log('✅ Items créés avec succès');
    }
    
    const createdQuote = await Quote.findByPk(quote.id, { include: [{ model: QuoteItem, as: 'items' }] });
    console.log('✅ Devis complet récupéré');
    
    // 📬 Envoyer notification au client
    try {
      console.log('📬 Tentative d\'envoi de notification pour devis, customerId:', customerId);
      
      if (customerId) {
        const customerProfile = await CustomerProfile.findByPk(customerId, {
          include: [{ model: User, as: 'user' }]
        });
        
        console.log('CustomerProfile trouvé:', customerProfile ? {
          id: customerProfile.id,
          user_id: customerProfile.user_id,
          name: `${customerProfile.first_name} ${customerProfile.last_name}`,
          hasUser: !!customerProfile.user
        } : 'NULL');
        
        if (customerProfile) {
          console.log('📤 Envoi notification au client user_id:', customerProfile.user_id);
          await notifyNewQuote(createdQuote, customerProfile);
          console.log('✅ Notification envoyée au client pour le nouveau devis');
        } else {
          console.log('⚠️  CustomerProfile non trouvé pour customerId:', customerId);
        }
      } else {
        console.log('⚠️  Pas de customerId fourni');
      }
    } catch (notifError) {
      console.error('⚠️  Erreur notification devis:', notifError.message);
      console.error('Stack:', notifError.stack);
      // Ne pas bloquer la création du devis si la notification échoue
    }
    
    res.status(201).json({ success: true, data: createdQuote });
  } catch (error) {
    console.error('❌ Erreur lors de la création du devis:', error.message);
    console.error('Stack:', error.stack);
    res.status(500).json({ success: false, message: 'Erreur lors de la création du devis', error: error.message });
  }
};

const updateQuote = async (req, res) => {
  const transaction = await Quote.sequelize.transaction();
  
  try {
    const { id } = req.params;
    const { items, ...quoteData } = req.body;
    
    const quote = await Quote.findByPk(id, { transaction });
    if (!quote) {
      await transaction.rollback();
      return res.status(404).json({ success: false, message: 'Devis non trouvé' });
    }
    
    // Sauvegarder l'ancien statut pour détecter le changement
    const oldStatus = quote.status;
    
    // Mettre à jour les données du devis
    await quote.update(quoteData, { transaction });
    
    // Si des items sont fournis, les mettre à jour
    if (items && Array.isArray(items)) {
      // Supprimer tous les anciens items
      await QuoteItem.destroy({ where: { quoteId: id }, transaction });
      
      // Créer les nouveaux items
      for (const item of items) {
        await QuoteItem.create({
          quoteId: id,
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          discount: item.discount || 0,
          taxRate: item.taxRate || 20
        }, { transaction });
      }
    }
    
    await transaction.commit();
    
    // Retourner le devis mis à jour avec les items
    const updatedQuote = await Quote.findByPk(id, { include: [{ model: QuoteItem, as: 'items' }] });
    
    // 📬 Notifier le client selon le type de modification
    try {
      const newStatus = updatedQuote.status;
      const statusChanged = oldStatus !== newStatus;
      const wasSent = oldStatus !== 'sent' && newStatus === 'sent';
      const wasRejected = oldStatus === 'rejected';
      const isModified = Object.keys(quoteData).length > 0 || (items && Array.isArray(items));
      
      console.log(`📬 Notification devis ID ${id}:`);
      console.log(`   - oldStatus: ${oldStatus}, newStatus: ${newStatus}`);
      console.log(`   - statusChanged: ${statusChanged}, wasSent: ${wasSent}`);
      console.log(`   - wasRejected: ${wasRejected}, isModified: ${isModified}`);
      console.log(`   - quoteData keys: ${Object.keys(quoteData).join(', ')}`);
      console.log(`   - items present: ${items ? 'yes' : 'no'}`);
      
      if (updatedQuote.customerId) {
        const customerProfile = await CustomerProfile.findByPk(updatedQuote.customerId, {
          include: [{ model: User, as: 'user' }]
        });
        
        if (customerProfile) {
          console.log('📤 Envoi notification au client user_id:', customerProfile.user_id);
          
          // Si le devis vient d'être envoyé, notification spécifique
          if (wasSent) {
            await notifyQuoteSent(updatedQuote, customerProfile);
            console.log('✅ Notification "Devis envoyé" envoyée au client');
          } else if (wasRejected && isModified) {
            // Si un devis rejeté est modifié (quelque soit le champ), envoyer une notification
            await notifyQuoteSent(updatedQuote, customerProfile);
            console.log('✅ Notification "Devis rejeté modifié et renvoyé" envoyée au client');
          } else if (statusChanged || isModified) {
            // Si le statut change ou si des données sont modifiées, notifier
            await notifyQuoteUpdated(updatedQuote, customerProfile);
            console.log('✅ Notification "Devis modifié" envoyée au client');
          } else {
            console.log('⚠️  Aucune modification détectée, pas de notification envoyée');
          }
        } else {
          console.log('⚠️  CustomerProfile non trouvé pour customerId:', updatedQuote.customerId);
        }
      } else {
        console.log('⚠️  Pas de customerId dans le devis');
      }
    } catch (notifError) {
      console.error('⚠️  Erreur notification modification devis:', notifError.message);
      console.error('Stack:', notifError.stack);
      // Ne pas bloquer la mise à jour du devis si la notification échoue
    }
    
    res.status(200).json({ success: true, data: updatedQuote });
  } catch (error) {
    await transaction.rollback();
    res.status(500).json({ success: false, message: 'Erreur lors de la mise à jour du devis', error: error.message });
  }
};

const deleteQuote = async (req, res) => {
  try {
    const { id } = req.params;
    const quote = await Quote.findByPk(id, { include: [{ model: QuoteItem, as: 'items' }] });
    if (!quote) {
      return res.status(404).json({ success: false, message: 'Devis non trouvé' });
    }
    // Supprimer les items associés
    await QuoteItem.destroy({ where: { quoteId: id } });
    // Supprimer le devis
    await quote.destroy();
    res.status(200).json({ success: true, message: 'Devis supprimé avec succès' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Erreur lors de la suppression du devis', error: error.message });
  }
};

const acceptQuote = async (req, res) => {
  try {
    const { id } = req.params;
    const quote = await Quote.findByPk(id);
    if (!quote) {
      return res.status(404).json({ success: false, message: 'Devis non trouvé' });
    }
    await quote.update({ status: 'accepted' });
    
    // 📬 Notifier les admins de l'acceptation
    try {
      const customerProfile = await CustomerProfile.findByPk(quote.customerId, {
        include: [{ model: User, as: 'user' }]
      });
      
      if (customerProfile) {
        await notifyQuoteAccepted(quote, customerProfile);
        console.log('✅ Notification envoyée aux admins : devis accepté');
      }
    } catch (notifError) {
      console.error('⚠️  Erreur notification acceptation devis:', notifError.message);
    }
    
    res.status(200).json({ success: true, data: quote, message: 'Devis accepté avec succès' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Erreur lors de l\'acceptation du devis', error: error.message });
  }
};

const rejectQuote = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const quote = await Quote.findByPk(id);
    if (!quote) {
      return res.status(404).json({ success: false, message: 'Devis non trouvé' });
    }
    await quote.update({ 
      status: 'rejected', 
      rejection_reason: reason || 'Refusé par le client'
    });
    
    // 📬 Notifier les admins du rejet
    try {
      const customerProfile = await CustomerProfile.findByPk(quote.customerId, {
        include: [{ model: User, as: 'user' }]
      });
      
      if (customerProfile) {
        await notifyQuoteRejected(quote, customerProfile);
        console.log('✅ Notification envoyée aux admins : devis rejeté');
      }
    } catch (notifError) {
      console.error('⚠️  Erreur notification rejet devis:', notifError.message);
    }
    
    res.status(200).json({ success: true, data: quote, message: 'Devis rejeté avec succès' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Erreur lors du rejet du devis', error: error.message });
  }
};


const { Order, OrderItem, Product } = require('../../models');

const convertQuoteToOrder = async (req, res) => {
  const transaction = await Order.sequelize.transaction();
  try {
    const { id } = req.params;
    console.log('Conversion devis #', id);
    
    // Récupérer le devis avec ses items
    const quote = await Quote.findByPk(id, { include: [{ model: QuoteItem, as: 'items' }] });
    if (!quote) {
      await transaction.rollback();
      return res.status(404).json({ success: false, message: 'Devis non trouvé' });
    }
    
    console.log('Devis trouvé:', {
      customerId: quote.customerId,
      total: quote.total,
      items: quote.items?.length
    });
    
    // IMPORTANT: Le devis utilise customer_profiles.id, mais Order utilise users.id
    // Il faut récupérer le user_id depuis customer_profiles
    const { CustomerProfile } = require('../../models');
    const customerProfile = await CustomerProfile.findByPk(quote.customerId);
    
    if (!customerProfile) {
      await transaction.rollback();
      return res.status(404).json({ 
        success: false, 
        message: 'Profil client non trouvé pour ce devis' 
      });
    }
    
    console.log('Profil client trouvé:', {
      customerProfileId: customerProfile.id,
      userId: customerProfile.user_id,
      name: `${customerProfile.first_name} ${customerProfile.last_name}`
    });
    
    // Créer la commande avec le user_id (pas customer_profiles.id)
    const order = await Order.create({
      customerId: customerProfile.user_id, // ← FIX: Utiliser user_id au lieu de customer_profiles.id
      totalAmount: quote.total,
      status: 'pending',
      notes: quote.notes,
    }, { transaction });
    
    console.log('Commande créée avec ID:', order.id);

    // Créer les OrderItems
    for (const item of quote.items) {
      // Détecter si c'est un article personnalisé
      const isCustomItem = item.isCustom || item.productId < 0;
      
      console.log('Création OrderItem:', {
        order_id: order.id,
        product_id: isCustomItem ? null : item.productId,
        product_name: item.productName,
        is_custom: isCustomItem,
        quantity: item.quantity,
        unit_price: item.unitPrice
      });
      
      await OrderItem.create({
        order_id: order.id,
        product_id: isCustomItem ? null : item.productId, // NULL pour articles personnalisés
        product_name: item.productName,
        is_custom: isCustomItem,
        quantity: item.quantity,
        unit_price: item.unitPrice,
        total: item.quantity * item.unitPrice
      }, { transaction });
    }

    // Mettre à jour le statut du devis
    await quote.update({ status: 'converted' }, { transaction });

    await transaction.commit();

    // Renvoyer la commande complète
    const orderWithDetails = await Order.findByPk(order.id, {
      include: [
        { model: User, as: 'customer' },
        { model: OrderItem, as: 'items', include: [{ model: Product, as: 'product' }] }
      ]
    });
    
    console.log('Commande retournée:', orderWithDetails?.id);
    
    res.status(201).json({
      success: true,
      message: 'Commande créée avec succès',
      data: orderWithDetails
    });
  } catch (error) {
    console.error('Erreur conversion devis:', error.message);
    console.error('Stack:', error.stack);
    await transaction.rollback();
    res.status(500).json({ success: false, message: 'Erreur lors de la conversion du devis', error: error.message });
  }
};

// Met à jour uniquement le statut d'un devis
const updateQuoteStatus = async (id, status) => {
  const { Quote } = require('../../models');
  const quote = await Quote.findByPk(id);
  if (!quote) return null;
  quote.status = status;
  await quote.save();
  return quote;
};

module.exports = {
  getAllQuotes,
  getQuoteById,
  createQuote,
  updateQuote,
  deleteQuote,
  acceptQuote,
  rejectQuote,
  convertQuoteToOrder,
  generateQuotePdf
  ,updateQuoteStatus
};
