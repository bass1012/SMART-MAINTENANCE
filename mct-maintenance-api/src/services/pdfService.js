const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs').promises;
const fsSync = require('fs');

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
  
  // Charger le logo en base64
  let logoBase64 = '';
  try {
    const logoPath = path.join(__dirname, '../../public/logo-maintenance.png');
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
          ${logoBase64 ? `<img src="${logoBase64}" alt="MCT Maintenance" class="logo" />` : ''}
        </div>
        <div class="info-section">
          <h1>FACTURE</h1>
          <div class="company-name">MCT Maintenance</div>
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
            <strong>Statut:</strong>
            <span class="status-badge ${getStatusClass(order.status)}">
              ${translateStatus(order.status || 'pending')}
            </span>
          </div>
        </div>
        
        <div class="info-box">
          <h3>Client</h3>
          <div class="info-row">
            <strong>Nom:</strong>
            <span>${customer.first_name || ''} ${customer.last_name || ''}</span>
          </div>
          <div class="info-row">
            <strong>Email:</strong>
            <span>${customer.email || order.customerEmail || 'N/A'}</span>
          </div>
          <div class="info-row">
            <strong>Téléphone:</strong>
            <span>${customer.phone || 'N/A'}</span>
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
        <p>MCT Maintenance - Service de maintenance professionnel</p>
        <p>Email: contact@mct-maintenance.com | Téléphone: +225 XX XX XX XX XX</p>
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
const generateInvoicePDF = async (order) => {
  let browser;
  
  try {
    console.log('🚀 Démarrage génération PDF...');
    
    // Générer le HTML
    const html = generateInvoiceHTML(order);
    console.log('📝 HTML généré, longueur:', html.length, 'caractères');
    
    // Lancer Puppeteer
    console.log('🌐 Lancement de Puppeteer...');
    browser = await puppeteer.launch({
      headless: 'new',
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    console.log('✅ Puppeteer lancé');
    
    const page = await browser.newPage();
    console.log('📄 Nouvelle page créée');
    
    // Charger le HTML
    console.log('⏳ Chargement du contenu HTML...');
    await page.setContent(html, {
      waitUntil: 'networkidle0'
    });
    console.log('✅ HTML chargé');
    
    // Générer le PDF
    console.log('🖨️ Génération du PDF...');
    const pdfData = await page.pdf({
      format: 'A4',
      printBackground: true,
      margin: {
        top: '20px',
        right: '20px',
        bottom: '20px',
        left: '20px'
      }
    });
    console.log('✅ PDF généré, taille:', pdfData.length, 'bytes');
    console.log('🔍 Type de données:', typeof pdfData, '- isBuffer:', Buffer.isBuffer(pdfData));
    
    await browser.close();
    console.log('🔒 Navigateur fermé');
    
    // S'assurer que c'est un Buffer Node.js
    const pdfBuffer = Buffer.isBuffer(pdfData) ? pdfData : Buffer.from(pdfData);
    console.log('✅ Buffer final créé, taille:', pdfBuffer.length, 'bytes');
    
    return pdfBuffer;
    
  } catch (error) {
    if (browser) {
      await browser.close();
    }
    console.error('❌ Erreur lors de la génération du PDF:', error);
    console.error('Stack:', error.stack);
    throw new Error(`Erreur de génération PDF: ${error.message}`);
  }
};

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
