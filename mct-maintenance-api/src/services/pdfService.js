const PDFDocument = require('pdfkit');
const path = require('path');
const fs = require('fs').promises;
const fsSync = require('fs');

/**
 * Échappe les caractères HTML spéciaux pour prévenir les injections XSS dans les templates PDF.
 * @param {any} str - Valeur à échapper
 * @returns {string} Chaîne échappée sûre pour l'insertion dans du HTML
 */
const escapeHtml = (str) => {
  if (str === null || str === undefined) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
};

/**
 * Service de génération de PDF pour les factures
 */

/**
 * Traduire le statut en français
 */
const translateStatus = (status) => {
  const statusMap = {
    'pending': 'En attente',
    'processing': 'En cours',
    'completed': 'Terminé',
    'delivered': 'Livré',
    'cancelled': 'Annulé',
    'canceled': 'Annulé',
    'paid': 'Payé',
    'PENDING': 'En attente',
    'PROCESSING': 'En cours',
    'COMPLETED': 'Terminé',
    'DELIVERED': 'Livré',
    'CANCELLED': 'Annulé',
    'PAID': 'Payé'
  };
  return statusMap[status] || status;
};

/**
 * Obtenir la classe CSS pour le statut
 */
const getStatusClass = (status) => {
  const normalizedStatus = status?.toLowerCase();
  if (normalizedStatus === 'completed' || normalizedStatus === 'delivered' || normalizedStatus === 'paid') {
    return 'status-completed';
  } else if (normalizedStatus === 'processing') {
    return 'status-processing';
  } else if (normalizedStatus === 'cancelled' || normalizedStatus === 'canceled') {
    return 'status-cancelled';
  }
  return 'status-pending';
};

/**
 * Générer le HTML de la facture
 */
const generateInvoiceHTML = (order) => {
  console.log('🎨 Génération HTML pour commande:', order.id);
  console.log('📋 Items:', order.items?.length || 0);
  console.log('👤 Customer:', order.customer ? 'Présent' : 'Absent');
  
  const items = order.items || [];
  const customer = order.customer || {};
  
  // Adapter la structure du customer (CustomerProfile avec User imbriqué)
  // Utilisation de escapeHtml pour protéger contre les injections XSS dans le PDF
  const customerEmail = escapeHtml(customer.user?.email || customer.email || order.customerEmail || 'N/A');
  const customerPhone = escapeHtml(customer.user?.phone || customer.phone || 'N/A');
  const customerName = escapeHtml(`${customer.first_name || ''} ${customer.last_name || ''}`.trim() || 'N/A');
  const orderReference = escapeHtml(order.reference || `#${order.id}`);
  const orderAddress = escapeHtml(order.delivery_address || order.address || 'N/A');
  
  // Charger le logo en base64
  let logoBase64 = '';
  try {
    let logoPath = path.join(__dirname, '../../public/logo_smart.png');
    if (!fsSync.existsSync(logoPath)) {
      logoPath = path.join(__dirname, '../../public/logo-maintenance.png');
    }
    if (fsSync.existsSync(logoPath)) {
      const logoBuffer = fsSync.readFileSync(logoPath);
      logoBase64 = `data:image/png;base64,${logoBuffer.toString('base64')}`;
      console.log('✅ Logo chargé depuis:', logoPath);
    } else {
      console.log('⚠️  Logo non trouvé à:', logoPath);
    }
  } catch (error) {
    console.error('❌ Erreur lors du chargement du logo:', error.message);
  }
  
  return `
    <!DOCTYPE html>
    <html lang="fr">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Facture ${order.reference || `#${order.id}`}</title>
      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        
        body {
          font-family: 'Arial', 'Helvetica', sans-serif;
          padding: 40px;
          color: #333;
          line-height: 1.6;
        }
        
        .header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 40px;
          border-bottom: 3px solid #0a543d;
          padding-bottom: 20px;
        }
        
        .header .logo-section {
          flex: 0 0 auto;
        }
        
        .header .logo {
          max-width: 120px;
          height: auto;
        }
        
        .header .info-section {
          flex: 1;
          text-align: right;
          padding-left: 20px;
        }
        
        .header h1 {
          color: #0a543d;
          font-size: 36px;
          margin-bottom: 10px;
          line-height: 1;
        }
        
        .header .company-name {
          font-size: 20px;
          color: #666;
          font-weight: 600;
          margin-bottom: 5px;
        }
        
        .header .tagline {
          font-size: 14px;
          color: #888;
          margin-top: 5px;
        }
        
        .info-section {
          display: flex;
          justify-content: space-between;
          margin-bottom: 30px;
        }
        
        .info-box {
          flex: 1;
          padding: 15px;
        }
        
        .info-box h3 {
          color: #0a543d;
          margin-bottom: 10px;
          font-size: 16px;
          border-bottom: 2px solid #e6ffe6;
          padding-bottom: 5px;
        }
        
        .info-row {
          display: flex;
          justify-content: space-between;
          margin: 8px 0;
          font-size: 14px;
        }
        
        .info-row strong {
          color: #555;
        }
        
        table {
          width: 100%;
          border-collapse: collapse;
          margin: 30px 0;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        thead {
          background-color: #0a543d;
          color: white;
        }
        
        th {
          padding: 15px;
          text-align: left;
          font-weight: 600;
          font-size: 14px;
        }
        
        td {
          padding: 12px 15px;
          border-bottom: 1px solid #e0e0e0;
          font-size: 14px;
        }
        
        tbody tr:hover {
          background-color: #f5f5f5;
        }
        
        tbody tr:last-child td {
          border-bottom: 2px solid #0a543d;
        }
        
        .text-right {
          text-align: right;
        }
        
        .totals {
          margin-top: 30px;
          text-align: right;
        }
        
        .totals-row {
          display: flex;
          justify-content: flex-end;
          margin: 10px 0;
          font-size: 16px;
        }
        
        .totals-row .label {
          width: 200px;
          text-align: right;
          padding-right: 20px;
          font-weight: 600;
        }
        
        .totals-row .value {
          width: 150px;
          text-align: right;
        }
        
        .total-final {
          font-size: 20px;
          color: #0a543d;
          font-weight: bold;
          border-top: 2px solid #0a543d;
          padding-top: 10px;
          margin-top: 10px;
        }
        
        .notes {
          margin-top: 30px;
          padding: 15px;
          background-color: #f9f9f9;
          border-left: 4px solid #0a543d;
        }
        
        .notes h4 {
          color: #0a543d;
          margin-bottom: 10px;
        }
        
        .footer {
          margin-top: 50px;
          text-align: center;
          color: #666;
          font-size: 12px;
          border-top: 1px solid #e0e0e0;
          padding-top: 20px;
        }
        
        .footer p {
          margin: 5px 0;
        }
        
        .status-badge {
          display: inline-block;
          padding: 5px 15px;
          border-radius: 20px;
          font-size: 12px;
          font-weight: 600;
        }
        
        .status-completed {
          background-color: #4caf50;
          color: white;
        }
        
        .status-processing {
          background-color: #2196f3;
          color: white;
        }
        
        .status-pending {
          background-color: #ff9800;
          color: white;
        }
        
        .status-cancelled {
          background-color: #f44336;
          color: white;
        }
        
        @media print {
          body {
            padding: 20px;
          }
        }
      </style>
    </head>
    <body>
      <div class="header">
        <div class="logo-section">
          ${logoBase64 ? `<img src="${logoBase64}" alt="SMART MAINTENANCE" class="logo" />` : ''}
        </div>
        <div class="info-section">
          <h1>FACTURE</h1>
          <div class="company-name">SMART MAINTENANCE</div>
          <div class="tagline">Service de maintenance professionnel - Côte d'Ivoire</div>
        </div>
      </div>
      
      <div class="info-section">
        <div class="info-box">
          <h3>Informations de facturation</h3>
          <div class="info-row">
            <strong>Référence:</strong>
            <span>${order.reference || `#${order.id}`}</span>
          </div>
          <div class="info-row">
            <strong>Date:</strong>
            <span>${order.createdAt ? new Date(order.createdAt).toLocaleDateString('fr-FR', {
              year: 'numeric',
              month: 'long',
              day: 'numeric'
            }) : new Date().toLocaleDateString('fr-FR')}</span>
          </div>
          <div class="info-row">
            <strong>Statut commande:</strong>
            <span class="status-badge ${getStatusClass(order.status)}">
              ${translateStatus(order.status || 'pending')}
            </span>
          </div>
          <div class="info-row">
            <strong>Statut paiement:</strong>
            <span class="status-badge ${getStatusClass(order.paymentStatus)}">
              ${translateStatus(order.paymentStatus || 'pending')}
            </span>
          </div>
        </div>
        
        <div class="info-box">
          <h3>Client</h3>
          <div class="info-row">
            <strong>Nom:</strong>
            <span>${customerName}</span>
          </div>
          <div class="info-row">
            <strong>Email:</strong>
            <span>${customerEmail}</span>
          </div>
          <div class="info-row">
            <strong>Téléphone:</strong>
            <span>${customerPhone}</span>
          </div>
          <div class="info-row">
            <strong>Adresse:</strong>
            <span>${order.shippingAddress || 'Non spécifiée'}</span>
          </div>
        </div>
      </div>
      
      <table>
        <thead>
          <tr>
            <th>Article</th>
            <th class="text-right">Quantité</th>
            <th class="text-right">Prix unitaire</th>
            <th class="text-right">Total</th>
          </tr>
        </thead>
        <tbody>
          ${items.map(item => {
            const productName = item.product?.nom || item.productName || 'Article';
            const quantity = item.quantity || 0;
            const unitPrice = item.unitPrice || item.unit_price || 0;
            const total = item.total || (quantity * unitPrice);
            
            return `
              <tr>
                <td>${productName}</td>
                <td class="text-right">${quantity}</td>
                <td class="text-right">${unitPrice.toLocaleString('fr-FR')} FCFA</td>
                <td class="text-right">${total.toLocaleString('fr-FR')} FCFA</td>
              </tr>
            `;
          }).join('')}
        </tbody>
      </table>
      
      <div class="totals">
        <div class="totals-row">
          <div class="label">Sous-total:</div>
          <div class="value">${(order.totalAmount || 0).toLocaleString('fr-FR')} FCFA</div>
        </div>
        <div class="totals-row">
          <div class="label">Livraison:</div>
          <div class="value">Gratuite</div>
        </div>
        <div class="totals-row total-final">
          <div class="label">Total:</div>
          <div class="value">${(order.totalAmount || 0).toLocaleString('fr-FR')} FCFA</div>
        </div>
      </div>
      
      ${order.notes ? `
        <div class="notes">
          <h4>Notes</h4>
          <p>${order.notes}</p>
        </div>
      ` : ''}
      
      <div class="footer">
        <p><strong>Merci pour votre confiance !</strong></p>
        <p>SMART MAINTENANCE - Service de maintenance professionnel</p>
        <p>Email: contact@mct.ci | Téléphone: +225 XX XX XX XX XX</p>
        <p style="margin-top: 10px; font-size: 10px;">
          Ce document est une facture générée électroniquement et ne nécessite pas de signature.
        </p>
      </div>
    </body>
    </html>
  `;
};

/**
 * Générer un PDF à partir d'une commande
 */
const generateInvoicePDF = async (order) => new Promise((resolve, reject) => {
  const doc = new PDFDocument({ size: 'A4', margin: 50 });
  const chunks = [];
  const green = '#0a543d';
  const lightGreen = '#eaf5f0';
  const pageWidth = doc.page.width - doc.page.margins.left - doc.page.margins.right;
  const items = Array.isArray(order.items) ? order.items : [];
  const customer = order.customer || {};

  const money = (value) => `${new Intl.NumberFormat('fr-FR').format(Number(value) || 0)} FCFA`;
  const date = order.createdAt || order.created_at
    ? new Date(order.createdAt || order.created_at).toLocaleDateString('fr-FR')
    : new Date().toLocaleDateString('fr-FR');
  const customerName = `${customer.first_name || ''} ${customer.last_name || ''}`.trim() || 'N/A';
  const customerEmail = customer.user?.email || customer.email || order.customerEmail || 'N/A';
  const customerPhone = customer.user?.phone || customer.phone || 'N/A';

  const drawTableHeader = () => {
    const y = doc.y;
    doc.rect(50, y, pageWidth, 24).fill(green);
    doc.fillColor('#ffffff').font('Helvetica-Bold').fontSize(9);
    doc.text('Article', 56, y + 7, { width: 235 });
    doc.text('Qté', 300, y + 7, { width: 45, align: 'right' });
    doc.text('Prix unitaire', 355, y + 7, { width: 85, align: 'right' });
    doc.text('Total', 450, y + 7, { width: 90, align: 'right' });
    doc.y = y + 28;
  };

  const ensureSpace = (height) => {
    if (doc.y + height <= doc.page.height - 70) return;
    doc.addPage();
    drawTableHeader();
  };

  doc.on('data', (chunk) => chunks.push(chunk));
  doc.on('end', () => resolve(Buffer.concat(chunks)));
  doc.on('error', reject);

  try {
    let logoPath = path.join(__dirname, '../../public/logo_smart.png');
    if (!fsSync.existsSync(logoPath)) {
      logoPath = path.join(__dirname, '../../public/logo-maintenance.png');
    }
    if (fsSync.existsSync(logoPath)) {
      doc.image(logoPath, 50, 45, { fit: [95, 55] });
    }

    doc.fillColor(green).font('Helvetica-Bold').fontSize(28)
      .text('FACTURE', 300, 48, { width: 245, align: 'right' });
    doc.fillColor('#444444').fontSize(12)
      .text('SMART MAINTENANCE', 300, 82, { width: 245, align: 'right' });
    doc.font('Helvetica').fontSize(9)
      .text("Service de maintenance professionnel - Côte d'Ivoire", 250, 101, {
        width: 295,
        align: 'right'
      });
    doc.moveTo(50, 125).lineTo(545, 125).lineWidth(2).strokeColor(green).stroke();

    const reference = order.reference || `#${order.id}`;
    doc.fillColor(green).font('Helvetica-Bold').fontSize(11)
      .text('Informations de facturation', 50, 145);
    doc.fillColor('#333333').font('Helvetica').fontSize(9)
      .text(`Référence : ${reference}`, 50, 166)
      .text(`Date : ${date}`, 50, 181)
      .text(`Statut commande : ${translateStatus(order.status || 'pending')}`, 50, 196)
      .text(`Statut paiement : ${translateStatus(order.paymentStatus || order.payment_status || 'pending')}`, 50, 211);

    doc.fillColor(green).font('Helvetica-Bold').fontSize(11).text('Client', 310, 145);
    doc.fillColor('#333333').font('Helvetica').fontSize(9)
      .text(`Nom : ${customerName}`, 310, 166, { width: 235 })
      .text(`Email : ${customerEmail}`, 310, 181, { width: 235 })
      .text(`Téléphone : ${customerPhone}`, 310, 196, { width: 235 })
      .text(`Adresse : ${order.shippingAddress || order.shipping_address || 'Non spécifiée'}`, 310, 211, {
        width: 235
      });

    doc.y = 250;
    drawTableHeader();

    if (items.length === 0) {
      doc.fillColor('#555555').font('Helvetica-Oblique').fontSize(9)
        .text('Aucun article détaillé', 56, doc.y + 4, { width: 484 });
      doc.moveDown(2);
    } else {
      items.forEach((item, index) => {
        ensureSpace(34);
        const y = doc.y;
        const productName = item.product?.nom || item.productName || item.name || 'Article';
        const quantity = Number(item.quantity) || 0;
        const unitPrice = Number(item.unitPrice ?? item.unit_price ?? item.product?.prix) || 0;
        const total = Number(item.total) || quantity * unitPrice;

        if (index % 2 === 0) {
          doc.rect(50, y - 2, pageWidth, 28).fill(lightGreen);
        }
        doc.fillColor('#222222').font('Helvetica').fontSize(9);
        doc.text(String(productName), 56, y + 6, { width: 235, ellipsis: true });
        doc.text(String(quantity), 300, y + 6, { width: 45, align: 'right' });
        doc.text(money(unitPrice), 355, y + 6, { width: 85, align: 'right' });
        doc.text(money(total), 450, y + 6, { width: 90, align: 'right' });
        doc.y = y + 30;
      });
    }

    ensureSpace(115);
    doc.moveDown(1);
    const totalAmount = order.totalAmount ?? order.total_amount ?? 0;
    doc.font('Helvetica').fontSize(10).fillColor('#333333')
      .text(`Sous-total : ${money(totalAmount)}`, 345, doc.y, { width: 200, align: 'right' });
    doc.text('Livraison : Gratuite', 345, doc.y + 6, { width: 200, align: 'right' });
    doc.moveDown(0.5);
    doc.moveTo(390, doc.y).lineTo(545, doc.y).strokeColor(green).stroke();
    doc.moveDown(0.5);
    doc.fillColor(green).font('Helvetica-Bold').fontSize(14)
      .text(`TOTAL : ${money(totalAmount)}`, 320, doc.y, { width: 225, align: 'right' });

    if (order.notes) {
      doc.moveDown(1.5);
      doc.fillColor(green).font('Helvetica-Bold').fontSize(10).text('Notes');
      doc.fillColor('#444444').font('Helvetica').fontSize(9).text(String(order.notes), { width: pageWidth });
    }

    doc.moveDown(2);
    doc.fillColor('#666666').font('Helvetica').fontSize(8)
      .text('Merci pour votre confiance !', 50, doc.y, { width: pageWidth, align: 'center' })
      .text('SMART MAINTENANCE - contact@mct.ci', { width: pageWidth, align: 'center' })
      .text('Ce document est une facture générée électroniquement et ne nécessite pas de signature.', {
        width: pageWidth,
        align: 'center'
      });

    doc.end();
  } catch (error) {
    reject(new Error(`Erreur de génération PDF: ${error.message}`));
  }
});

/**
 * Sauvegarder le PDF sur le disque
 */
const saveInvoicePDF = async (order, outputPath) => {
  try {
    const pdfBuffer = await generateInvoicePDF(order);
    await fs.writeFile(outputPath, pdfBuffer);
    return outputPath;
  } catch (error) {
    console.error('Erreur lors de la sauvegarde du PDF:', error);
    throw error;
  }
};

module.exports = {
  generateInvoiceHTML,
  generateInvoicePDF,
  saveInvoicePDF
};
