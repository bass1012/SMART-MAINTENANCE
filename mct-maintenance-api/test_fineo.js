require('dotenv').config();
const axios = require('axios');

async function test() {
  try {
    const response = await axios.post(
      'https://dev.fineopay.com/api/v1/business/dev/checkout-link',
      {
        title: "Test Redirect",
        amount: 100,
        callbackUrl: "https://google.com",
        redirectUrl: "smartmaintenance://payment-callback",
        autoRedirect: true,
        syncRef: "TEST_123"
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'businessCode': process.env.FINEOPAY_BUSINESS_CODE,
          'apiKey': process.env.FINEOPAY_API_KEY
        }
      }
    );
    console.log(response.data);
  } catch(e) {
    console.log(e.response ? e.response.data : e.message);
  }
}
test();
