const crypto = require('crypto');
const {
  verifyFineoPayWebhook,
  FineoPayWebhookVerificationError
} = require('../../../src/services/payment/fineoPayWebhookVerificationService');

const callback = {
  reference: 'TRX-123',
  syncRef: 'ORDER_42',
  status: 'success',
  amount: 10000
};

const providerResponse = (overrides = {}) => ({
  success: true,
  data: {
    ...callback,
    amount: '10000.00',
    ...overrides
  }
});

const verify = (overrides = {}) => verifyFineoPayWebhook({
  body: callback,
  rawBody: Buffer.from(JSON.stringify(callback)),
  signature: undefined,
  webhookSecret: undefined,
  fetchTransaction: jest.fn().mockResolvedValue(providerResponse()),
  ...overrides
});

const expectVerificationError = async (promise, code, statusCode) => {
  await expect(promise).rejects.toEqual(expect.objectContaining({
    name: 'FineoPayWebhookVerificationError',
    code,
    statusCode
  }));
};

describe('verifyFineoPayWebhook', () => {
  test('accepte un callback uniquement après confirmation exacte par FineoPay', async () => {
    const fetchTransaction = jest.fn().mockResolvedValue(providerResponse());

    const result = await verify({ fetchTransaction });

    expect(fetchTransaction).toHaveBeenCalledWith('TRX-123');
    expect(result).toEqual(expect.objectContaining({
      reference: 'TRX-123',
      syncRef: 'ORDER_42',
      status: 'success',
      amount: 10000,
      providerVerified: true,
      signatureChecked: false
    }));
  });

  test('accepte aussi un échec authentifié par le fournisseur', async () => {
    const body = { ...callback, status: 'failed' };
    const result = await verify({
      body,
      fetchTransaction: jest.fn().mockResolvedValue(providerResponse({ status: 'failed' }))
    });

    expect(result.status).toBe('failed');
    expect(result.providerVerified).toBe(true);
  });

  test.each([
    ['reference', 'OTHER', 'REFERENCE_MISMATCH'],
    ['syncRef', 'ORDER_99', 'SYNC_REF_MISMATCH'],
    ['status', 'failed', 'STATUS_MISMATCH'],
    ['amount', 9999, 'AMOUNT_MISMATCH']
  ])('refuse une incohérence du champ %s', async (field, value, code) => {
    await expectVerificationError(
      verify({ fetchTransaction: jest.fn().mockResolvedValue(providerResponse({ [field]: value })) }),
      code,
      401
    );
  });

  test('refuse temporairement le callback si FineoPay est indisponible', async () => {
    const error = verify({
      fetchTransaction: jest.fn().mockRejectedValue(new Error('timeout'))
    });

    await expectVerificationError(error, 'PROVIDER_UNAVAILABLE', 503);
    await expect(error).rejects.toEqual(expect.objectContaining({ retryable: true }));
  });

  test('refuse une réponse fournisseur non confirmée', async () => {
    await expectVerificationError(
      verify({ fetchTransaction: jest.fn().mockResolvedValue({ success: false }) }),
      'PROVIDER_RESPONSE_INVALID',
      502
    );
  });

  test('vérifie une signature HMAC sur les octets bruts lorsqu’elle est configurée', async () => {
    const rawBody = Buffer.from('{"reference":"TRX-123", "amount":10000}');
    const webhookSecret = 'test-secret';
    const signature = `sha256=${crypto
      .createHmac('sha256', webhookSecret)
      .update(rawBody)
      .digest('hex')}`;

    const result = await verify({ rawBody, webhookSecret, signature });

    expect(result.signatureChecked).toBe(true);
    expect(result.signatureValid).toBe(true);
  });

  test.each(['abc', 'z'.repeat(64), '0'.repeat(64)])(
    'refuse une signature malformée ou incorrecte',
    async (signature) => {
      const fetchTransaction = jest.fn();

      await expectVerificationError(
        verify({ signature, webhookSecret: 'test-secret', fetchTransaction }),
        'INVALID_SIGNATURE',
        401
      );
      expect(fetchTransaction).not.toHaveBeenCalled();
    }
  );

  test('refuse un payload incomplet avant tout appel fournisseur', async () => {
    const fetchTransaction = jest.fn();

    await expectVerificationError(
      verify({ body: { reference: 'TRX-123', amount: 10000 }, fetchTransaction }),
      'INVALID_CALLBACK_PAYLOAD',
      400
    );
    expect(fetchTransaction).not.toHaveBeenCalled();
  });

  test('expose un type d’erreur dédié au contrôleur', () => {
    expect(new FineoPayWebhookVerificationError(401, 'TEST', 'test'))
      .toBeInstanceOf(FineoPayWebhookVerificationError);
  });
});
