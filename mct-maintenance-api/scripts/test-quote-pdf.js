const { Quote, QuoteItem, CustomerProfile, User } = require('../src/models');
const { sequelize } = require('../src/config/database');
const fs = require('fs');
const path = require('path');
const { Writable } = require('stream');

const out = fs.createWriteStream(path.join(__dirname, '../test_quote_output.pdf'));

// Mock req
const req = {
  params: { id: 1 }
};

// Mock res as a writable stream
const res = new Writable({
  write(chunk, encoding, callback) {
    out.write(chunk, encoding, callback);
  }
});

res.headers = {};
res.setHeader = (name, value) => {
  res.headers[name] = value;
};
res.status = (code) => {
  return {
    json(data) {
      console.error(`❌ Error status ${code}:`, data);
      process.exit(1);
    }
  };
};

res.on('finish', () => {
  out.end();
});

out.on('finish', () => {
  console.log('✅ PDF generated successfully in test_quote_output.pdf');
  process.exit(0);
});

async function test() {
  try {
    await sequelize.authenticate();
    
    // Find or create customer
    let customer = await CustomerProfile.findOne();
    if (!customer) {
      // Create user first
      const user = await User.create({
        email: 'test-client@mct.ci',
        first_name: 'FRANCETRUCK',
        last_name: 'CI',
        role: 'customer',
        status: 'active'
      });
      customer = await CustomerProfile.create({
        id: 1,
        customerId: user.id,
        user_id: user.id,
        first_name: 'FRANCETRUCK',
        last_name: 'CI',
        phone: '0707070707'
      });
    }
    
    // Delete existing test quote if it exists
    await Quote.destroy({ where: { id: 1 } });
    
    // Create Quote
    const quote = await Quote.create({
      id: 1,
      reference: 'DEV-260703-1200-1',
      customerId: customer.id,
      customerName: 'FRANCETRUCK-CI',
      issueDate: '2026-07-03',
      expiryDate: '2026-08-02',
      status: 'sent',
      subtotal: 130000,
      taxAmount: 23400,
      discountAmount: 0,
      total: 153400,
      objet: "Devis d'entretien préventif de la climatisation",
      notes: "Entretien préventif de climatiseurs splits",
      termsAndConditions: "Validité de l'offre: 30 jours.\nConditions de paiement: 100% après le service.",
      payment_type: 'full',
      line_items: [
        {
          description: "Entretien split mural",
          quantity: 13,
          unit_price: 10000,
          unit: "ens",
          total: 130000
        }
      ]
    });
    
    console.log('✅ Quote created in DB:', quote.reference);
    
    // Call PDF generator
    const { generateQuotePdf } = require('../src/controllers/quote/quoteController');
    await generateQuotePdf(req, res);
    
  } catch (error) {
    console.error('❌ Test failed:', error);
    process.exit(1);
  }
}

test();
