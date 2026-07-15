// Génération PDF moderne et professionnelle
const generateQuotePdf = async (req, res) => {
  try {
    const { id } = req.params;
    const quote = await Quote.findByPk(id, { include: [{ model: QuoteItem, as: 'items' }] });
    if (!quote) {
      return res.status(404).json({ success: false, message: 'Devis non trouvé' });
    }
    
    const PDFDocument = require('pdfkit');
    const path = require('path');
    const fs = require('fs');

    const doc = new PDFDocument({ 
      margin: 40, 
      size: 'A4',
      bufferPages: true
    });
    
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="devis-${quote.reference}.pdf"`);
    doc.pipe(res);

    // Path to Logo
    let logoPath = path.join(__dirname, '../../../public/logo-maintenance.png');
    let hasLogo = fs.existsSync(logoPath);

    // 1. Header Logo (Centered)
    if (hasLogo) {
      doc.image(logoPath, (595.28 - 100) / 2, 30, { width: 100 });
    } else {
      // Fallback logo if missing
      doc.fillColor('#0b2d69').rect((595.28 - 100) / 2, 30, 100, 40).fill();
      doc.fillColor('#ffffff').font('Helvetica-Bold').fontSize(12).text('M.C.T.', (595.28 - 100) / 2, 45, { width: 100, align: 'center' });
    }

    // 2. Client Box (FRANCETRUCK-CI) on the right
    doc.rect(370, 95, 185, 35).lineWidth(1).stroke('#000000');
    doc.font('Helvetica-Bold').fontSize(11).fillColor('#000000')
       .text(quote.customerName || 'CLIENT', 370, 107, { width: 185, align: 'center' });

    // 3. Date (Abidjan, le DD/MM/YYYY)
    const dateObj = quote.issueDate ? new Date(quote.issueDate) : new Date();
    const dateStr = `Abidjan, le ${String(dateObj.getDate()).padStart(2, '0')}/${String(dateObj.getMonth() + 1).padStart(2, '0')}/${dateObj.getFullYear()}`;
    doc.font('Helvetica').fontSize(10).fillColor('#000000')
       .text(dateStr, 370, 140, { width: 185, align: 'right' });

    // 4. Objet
    const objetStr = quote.objet || "Devis d'entretien préventif de la climatisation";
    doc.font('Helvetica-Bold').fontSize(10).fillColor('#000000').text('Objet: ', 40, 160, { continued: true })
       .font('Helvetica').text(objetStr);

    // 5. Devis Reference Box (Full width)
    doc.rect(40, 180, 515, 25).lineWidth(1).stroke('#000000');
    doc.font('Helvetica-Bold').fontSize(10).fillColor('#000000')
       .text(`DEVIS N°: ${quote.reference}`, 50, 188, { width: 495, align: 'left' });

    // 6. Table of Articles
    const tableTop = 215;
    const colX = [40, 85, 305, 345, 385, 470, 555]; // vertical line positions
    
    // Headers
    doc.font('Helvetica-Bold').fontSize(9).fillColor('#000000');
    doc.text('N° Art.', 40, tableTop + 7, { width: 45, align: 'center' });
    doc.text('DESIGNATION', 90, tableTop + 7, { width: 210, align: 'left' });
    doc.text('U.', 305, tableTop + 7, { width: 40, align: 'center' });
    doc.text('Qt.', 345, tableTop + 7, { width: 40, align: 'center' });
    doc.text('P.U. (H.T)', 385, tableTop + 7, { width: 80, align: 'right' });
    doc.text('P.T(H.T)', 470, tableTop + 7, { width: 80, align: 'right' });
    
    // Header borders
    doc.moveTo(40, tableTop).lineTo(555, tableTop).stroke('#000000');
    doc.moveTo(40, tableTop + 22).lineTo(555, tableTop + 22).stroke('#000000');

    // Sub-header EQUIPEMENTS
    doc.font('Helvetica-Bold').fontSize(9).text('EQUIPEMENTS', 90, tableTop + 29, { width: 210, align: 'left', underline: true });
    doc.moveTo(40, tableTop + 42).lineTo(555, tableTop + 42).stroke('#000000');

    // Unify items
    let items = [];
    if (quote.items && quote.items.length > 0) {
      items = quote.items.map(item => ({
        designation: item.productName || '',
        quantity: item.quantity || 0,
        unitPrice: item.unitPrice || 0,
        unit: item.unit || 'ens',
        total: item.quantity * item.unitPrice * (1 - (item.discount || 0) / 100)
      }));
    } else if (quote.line_items) {
      const rawItems = Array.isArray(quote.line_items) 
        ? quote.line_items 
        : (typeof quote.line_items === 'string' ? JSON.parse(quote.line_items) : []);
      items = rawItems.map(item => ({
        designation: item.description || item.productName || '',
        quantity: item.quantity || 0,
        unitPrice: item.unit_price || item.unitPrice || 0,
        unit: item.unit || 'ens',
        total: item.total || (item.quantity * (item.unit_price || item.unitPrice || 0))
      }));
    }

    let y_pos = tableTop + 42;
    const rowHeight = 22;

    items.forEach((item, idx) => {
      // Page break check if y_pos gets too low
      if (y_pos > 700) {
        // Draw vertical borders before adding new page
        colX.forEach(x => {
          doc.moveTo(x, tableTop).lineTo(x, y_pos).stroke('#000000');
        });
        doc.addPage();
        y_pos = 40;
        
        // Redraw headers on new page
        doc.font('Helvetica-Bold').fontSize(9).fillColor('#000000');
        doc.text('N° Art.', 40, y_pos + 7, { width: 45, align: 'center' });
        doc.text('DESIGNATION', 90, y_pos + 7, { width: 210, align: 'left' });
        doc.text('U.', 305, y_pos + 7, { width: 40, align: 'center' });
        doc.text('Qt.', 345, y_pos + 7, { width: 40, align: 'center' });
        doc.text('P.U. (H.T)', 385, y_pos + 7, { width: 80, align: 'right' });
        doc.text('P.T(H.T)', 470, y_pos + 7, { width: 80, align: 'right' });
        
        doc.moveTo(40, y_pos).lineTo(555, y_pos).stroke('#000000');
        doc.moveTo(40, y_pos + 22).lineTo(555, y_pos + 22).stroke('#000000');
        y_pos += 22;
      }

      // Print row fields
      doc.font('Helvetica').fontSize(9).fillColor('#000000');
      doc.text(`${idx + 1}`, 40, y_pos + 6, { width: 45, align: 'center' });
      doc.text(item.designation, 90, y_pos + 6, { width: 210, align: 'left' });
      doc.text(item.unit, 305, y_pos + 6, { width: 40, align: 'center' });
      doc.text(`${item.quantity}`, 345, y_pos + 6, { width: 40, align: 'center' });
      
      const puStr = Number(item.unitPrice).toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
      doc.text(puStr, 385, y_pos + 6, { width: 80, align: 'right' });
      
      const ptStr = Number(item.total).toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
      doc.text(ptStr, 470, y_pos + 6, { width: 80, align: 'right' });

      // Draw bottom line
      doc.moveTo(40, y_pos + rowHeight).lineTo(555, y_pos + rowHeight).stroke('#000000');
      y_pos += rowHeight;
    });

    // Draw all vertical lines of the table
    colX.forEach(x => {
      doc.moveTo(x, tableTop).lineTo(x, y_pos).stroke('#000000');
    });

    // Totals Rows
    const drawTotalRow = (label, amount) => {
      doc.moveTo(85, y_pos).lineTo(85, y_pos + 20).stroke('#000000');
      doc.moveTo(470, y_pos).lineTo(470, y_pos + 20).stroke('#000000');
      doc.moveTo(555, y_pos).lineTo(555, y_pos + 20).stroke('#000000');
      doc.moveTo(85, y_pos + 20).lineTo(555, y_pos + 20).stroke('#000000');
      
      doc.font('Helvetica-Bold').fontSize(9).fillColor('#000000')
         .text(label, 85, y_pos + 6, { width: 375, align: 'right' });
         
      const amountStr = Number(amount || 0).toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
      doc.text(amountStr, 470, y_pos + 6, { width: 80, align: 'right' });
      
      y_pos += 20;
    };

    drawTotalRow('TOTAL H.T.V.A.', quote.subtotal);
    drawTotalRow(`TVA 18 %`, quote.taxAmount);
    drawTotalRow('MONTANT TOTAL TTC', quote.total);

    // Ensure we have enough space for conditions and stamp, otherwise go to next page
    if (y_pos > 600) {
      doc.addPage();
      y_pos = 40;
    }

    // 7. Conditions Générales de vente
    y_pos += 15;
    doc.font('Helvetica-Bold').fontSize(9).fillColor('#000000').text('Conditions Générales de vente:', 40, y_pos, { underline: true });
    
    y_pos += 15;
    doc.font('Helvetica-Bold').fontSize(9).text("Validité de l'offre:", 40, y_pos);
    y_pos += 12;
    doc.font('Helvetica').fontSize(9).text("30 jours", 40, y_pos);
    
    y_pos += 15;
    doc.font('Helvetica-Bold').fontSize(9).text("Conditions de paiement", 40, y_pos, { underline: true });
    y_pos += 12;
    
    let paymentTerms = "100% après le service.";
    if (quote.payment_type === 'split') {
      paymentTerms = "50% d'acompte à la validation, 50% après le service.";
    }
    if (quote.termsAndConditions) {
      paymentTerms = quote.termsAndConditions;
    }
    doc.font('Helvetica').fontSize(9).text(paymentTerms, 40, y_pos);

    // 8. Signature Stamp Block
    y_pos += 30;
    doc.font('Helvetica-Bold').fontSize(9).fillColor('#000000').text('Senior Business Manager Smart Maintenance', 40, y_pos);
    
    let stampPath = path.join(__dirname, '../../../public/signature-stamp.png');
    if (fs.existsSync(stampPath)) {
      // The cropped stamp is 570 x 360 px. Scale to 150 points width (approx 95 points height)
      doc.image(stampPath, 40, y_pos + 10, { width: 150 });
    } else {
      // Fallback custom stamp if missing
      const stampX = 50;
      const stampY = y_pos + 15;
      
      doc.save();
      doc.translate(stampX, stampY);
      doc.rotate(-4); // Rotate slightly (-4 deg)
      
      doc.lineWidth(1.5);
      doc.strokeColor('#0f3d99');
      doc.rect(0, 0, 180, 80).stroke();
      
      doc.lineWidth(0.5);
      doc.rect(3, 3, 174, 74).stroke();
      
      doc.fillColor('#0f3d99');
      doc.font('Helvetica-Bold').fontSize(11).text('Smart Maintenance', 0, 10, { width: 180, align: 'center' });
      doc.font('Helvetica-Bold').fontSize(11).text('by MCT', 0, 24, { width: 180, align: 'center' });
      doc.font('Helvetica-Bold').fontSize(9).text('01 BR 1618 Abidjan 01', 0, 38, { width: 180, align: 'center' });
      doc.font('Helvetica-Bold').fontSize(9).text('Cel: 07 59 50 50 50', 0, 50, { width: 180, align: 'center' });
      doc.font('Helvetica-Bold').fontSize(9).text('E-mail: smartmaintenance@mct.ci', 0, 62, { width: 180, align: 'center' });
      
      doc.restore();
    }

    // 9. Footer Builder (drawn on all pages)
    const drawFooter = (pageDoc) => {
      let footerPath = path.join(__dirname, '../../../public/footer.png');
      if (fs.existsSync(footerPath)) {
        // Height is scaled to fit 595.28 points width (A4 width)
        // 174 / 1240 * 595.28 = 83.53 points
        pageDoc.image(footerPath, 0, 841.89 - 83.53, { width: 595.28 });
      } else {
        // Fallback simple line and text
        pageDoc.save();
        const footerY = 780;
        pageDoc.strokeColor('#cccccc').lineWidth(0.5).moveTo(40, footerY).lineTo(555, footerY).stroke();
        pageDoc.fillColor('#0b2d69').font('Helvetica').fontSize(6.5);
        const footerText = 
          "SA Capital 428 680 000 Francs CFA - Siège social : Biétry - Rue du Canal Rue G103 - 01 BP 1618 Abidjan 01\n" +
          "Côte d'Ivoire - N° service clients : +225 07 09 09 09 42 - Tel. : (+225) 05 45 16 86 13 / 07 09 09 09 42 / 07 07 01\n" +
          "29 26 / 27 21 35 40 40 RC N° : 88556 - Abidjan - Email : contact@mct.ci - Site web : www.mct.ci - C.C. N° 85\n" +
          "00567 L - Régime d'imposition : Réel Normal d'imposition - Centre des Impôts : DGE";
        pageDoc.text(footerText, 40, footerY + 10, { width: 515, align: 'center', lineGap: 2 });
        pageDoc.restore();
      }
    };

    // Draw footer on all pages (dynamic page iteration)
    const range = doc.bufferedPageRange();
    for (let i = range.start; i < range.start + range.count; i++) {
      doc.switchToPage(i);
      drawFooter(doc);
    }

    doc.end();
  } catch (error) {
    console.error('❌ Erreur lors de la génération du PDF:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la génération du PDF', error: error.message });
  }
};
// Quote Controller - Placeholder implementation

const { Quote, QuoteItem, CustomerProfile, User, Order, OrderItem } = require('../../models');
const { 
  notifyNewQuote,
  notifyQuoteSent,
  notifyQuoteAccepted, 
  notifyQuoteRejected,
  notifyQuoteUpdated
} = require('../../services/notificationHelpers');
const { sendEmail } = require('../../services/emailService');
const {
  sendQuoteCreatedEmail,
  sendQuoteAcceptedEmail,
  sendQuoteRejectedEmail
} = require('../../services/emailHelper');

const mapQuoteItems = (quote) => {
  if (!quote) return quote;
  const quotePlain = quote.get({ plain: true });
  if ((!quotePlain.items || quotePlain.items.length === 0) && quotePlain.line_items) {
    let rawLineItems = quotePlain.line_items;
    if (typeof rawLineItems === 'string') {
      try {
        rawLineItems = JSON.parse(rawLineItems);
      } catch (e) {
        rawLineItems = [];
      }
    }
    if (Array.isArray(rawLineItems)) {
      quotePlain.items = rawLineItems.map((item, index) => ({
        id: index + 1,
        productId: item.productId || item.product_id || -1,
        productName: item.productName || item.product_name || item.description || 'Article',
        quantity: item.quantity || 1,
        unitPrice: parseFloat(item.unitPrice || item.unit_price || 0),
        discount: parseFloat(item.discount || 0),
        taxRate: parseFloat(item.taxRate || item.tax_rate || 0),
        isCustom: item.isCustom || item.is_custom || true,
      }));
    }
  }
  return quotePlain;
};

const getAllQuotes = async (req, res) => {
  try {
    console.log(`📋 Récupération de tous les devis...`);
    const quotes = await Quote.findAll({
      include: [{ model: QuoteItem, as: 'items' }],
      order: [['created_at', 'DESC']]
    });
    console.log(`✅ ${quotes.length} devis récupérés`);
    const mappedQuotes = quotes.map(quote => mapQuoteItems(quote));
    res.status(200).json({ success: true, data: mappedQuotes });
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
    const mappedQuote = mapQuoteItems(quote);
    res.status(200).json({ success: true, data: mappedQuote });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Erreur lors de la récupération du devis', error: error.message });
  }
};

const createQuote = async (req, res) => {
  try {
    console.log('📝 Création de devis - Données reçues:', JSON.stringify(req.body, null, 2));
    
    const { reference, customerId, customerName, issueDate, expiryDate, status, subtotal, taxAmount, discountAmount, total, notes, termsAndConditions, items, objet } = req.body;
    
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
      termsAndConditions,
      objet: objet || "Devis d'entretien de climatisation"
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
          
          // 📧 Email au client (nouveau devis - template professionnel)
          if (customerProfile.user) {
            const plainQuote = createdQuote.get({ plain: true });
            console.log('📧 Structure du devis pour email:', {
              id: plainQuote.id,
              reference: plainQuote.reference,
              total: plainQuote.total,
              total_amount: plainQuote.total_amount,
              subtotal: plainQuote.subtotal,
              allKeys: Object.keys(plainQuote)
            });
            await sendQuoteCreatedEmail(
              plainQuote,
              {
                id: customerProfile.user_id,
                email: customerProfile.user.email,
                first_name: customerProfile.first_name,
                last_name: customerProfile.last_name
              }
            );
            console.log('✅ Email professionnel nouveau devis envoyé au client');
          }
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
    
    // Si des items sont fournis, les mettre à jour
    if (items && Array.isArray(items)) {
      // Supprimer tous les anciens items
      await QuoteItem.destroy({ where: { quoteId: id }, transaction });
      
      // Créer les nouveaux items et préparer pour line_items
      const lineItemsForSync = [];
      for (const item of items) {
        await QuoteItem.create({
          quoteId: id,
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          discount: item.discount ?? 0,
          taxRate: item.taxRate ?? 0
        }, { transaction });

        lineItemsForSync.push({
          productId: item.productId,
          productName: item.productName,
          description: item.productName,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          unit_price: item.unitPrice,
          discount: item.discount ?? 0,
          taxRate: item.taxRate ?? 0,
          total: item.quantity * item.unitPrice * (1 - (item.discount ?? 0) / 100)
        });
      }
      
      quoteData.line_items = lineItemsForSync;
    }

    // Mettre à jour les données du devis (incluant line_items s'il a été mis à jour)
    await quote.update(quoteData, { transaction });
    
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
    const { scheduled_date, second_contact, execute_now } = req.body;
    
    const quote = await Quote.findByPk(id);
    if (!quote) {
      return res.status(404).json({ success: false, message: 'Devis non trouvé' });
    }

    let scheduledDateTime;
    
    // Si exécution immédiate demandée
    if (execute_now === true) {
      // Utiliser la date/heure actuelle
      scheduledDateTime = new Date();
      console.log('⚡ Exécution immédiate demandée pour le devis', id);
    } else {
      // Vérifier que la date planifiée est fournie
      if (!scheduled_date) {
        return res.status(400).json({ 
          success: false, 
          message: 'La date et l\'heure de l\'intervention sont requises' 
        });
      }

      // Vérifier que la date est dans le futur
      scheduledDateTime = new Date(scheduled_date);
      if (scheduledDateTime <= new Date()) {
        return res.status(400).json({ 
          success: false, 
          message: 'La date de l\'intervention doit être dans le futur' 
        });
      }
    }

    await quote.update({ 
      status: 'accepted',
      scheduled_date: scheduledDateTime,
      second_contact: second_contact || null,
      execute_now: execute_now || false
    });

    // 🛒 Créer automatiquement une commande à partir du devis accepté
    let createdOrder = null;
    try {
      // Parser line_items si c'est un string JSON
      let lineItems = quote.line_items;
      if (typeof lineItems === 'string') {
        try {
          lineItems = JSON.parse(lineItems);
        } catch (e) {
          lineItems = [];
        }
      }
      if (!Array.isArray(lineItems)) {
        lineItems = [];
      }

      // Générer une référence unique pour la commande
      const orderReference = `CMD-${Date.now()}-${quote.id}`;

      // Déterminer le statut de paiement selon le type d'exécution
      // Exécution immédiate → pending (paiement maintenant)
      // Planifié pour plus tard → deferred (paiement différé)
      const paymentStatus = execute_now ? 'pending' : 'deferred';

      // Créer la commande
      const order = await Order.create({
        reference: orderReference,
        customer_id: quote.customerId,
        quote_id: quote.id,
        total_amount: quote.total || 0,
        status: execute_now ? 'pending' : 'scheduled',
        payment_status: paymentStatus,
        payment_method: null,
        line_items: JSON.stringify(lineItems),
        notes: execute_now 
          ? `Commande créée automatiquement à partir du devis ${quote.reference} - Exécution immédiate`
          : `Commande créée automatiquement à partir du devis ${quote.reference} - Intervention planifiée, paiement différé`,
        scheduled_date: scheduledDateTime
      });

      // Mettre à jour le statut de paiement du devis
      await quote.update({ payment_status: paymentStatus });

      createdOrder = { id: order.id, reference: orderReference };
      console.log(`✅ Commande ${orderReference} créée automatiquement pour le devis ${quote.reference} (paiement: ${paymentStatus})`);
    } catch (orderError) {
      console.error('⚠️  Erreur création commande automatique:', orderError.message);
      // On ne bloque pas l'acceptation si la création de commande échoue
    }
    
    // 📬 Notifier les admins de l'acceptation
    try {
      const customerProfile = await CustomerProfile.findByPk(quote.customerId, {
        include: [{ model: User, as: 'user' }]
      });
      
      if (customerProfile) {
        await notifyQuoteAccepted(quote, customerProfile);
        console.log('✅ Notification envoyée aux admins : devis accepté');
        
        // 📧 Email aux admins (devis accepté - template professionnel)
        if (customerProfile.user) {
          await sendQuoteAcceptedEmail(
            quote.get({ plain: true }),
            {
              id: customerProfile.user_id,
              email: customerProfile.user.email,
              first_name: customerProfile.first_name,
              last_name: customerProfile.last_name
            }
          );
          console.log('✅ Email professionnel acceptation devis envoyé aux admins');
        }
      }
    } catch (notifError) {
      console.error('⚠️  Erreur notification acceptation devis:', notifError.message);
    }
    
    res.status(200).json({ success: true, data: { ...quote.get({ plain: true }), createdOrder }, message: 'Devis accepté avec succès' });
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
        
        // 📧 Email aux admins (devis rejeté - template professionnel)
        if (customerProfile.user) {
          await sendQuoteRejectedEmail(
            quote.get({ plain: true }),
            {
              id: customerProfile.user_id,
              email: customerProfile.user.email,
              first_name: customerProfile.first_name,
              last_name: customerProfile.last_name
            }
          );
          console.log('✅ Email professionnel rejet devis envoyé aux admins');
        }
      }
    } catch (notifError) {
      console.error('⚠️  Erreur notification rejet devis:', notifError.message);
    }
    
    res.status(200).json({ success: true, data: quote, message: 'Devis rejeté avec succès' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Erreur lors du rejet du devis', error: error.message });
  }
};


const { Product } = require('../../models');

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
      customerId: customerProfile.id, // ✅ FIX: Utiliser CustomerProfile.id
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

    // Renvoyer la commande complète avec CustomerProfile
    const orderWithDetails = await Order.findByPk(order.id, {
      include: [
        { 
          model: CustomerProfile, 
          as: 'customer',
          include: [
            {
              model: User,
              as: 'user',
              attributes: ['id', 'email', 'phone']
            }
          ]
        },
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
