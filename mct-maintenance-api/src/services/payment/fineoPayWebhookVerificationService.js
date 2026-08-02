const crypto = require('crypto');

class FineoPayWebhookVerificationError extends Error {
  constructor(statusCode, code, message, retryable = false) {
    super(message);
    this.name = 'FineoPayWebhookVerificationError';
    this.statusCode = statusCode;
    this.code = code;
    this.retryable = retryable;
  }
}

const normalizeAmount = (value) => {
  const amount = Number(value);
  if (!Number.isFinite(amount) || amount <= 0) {
    throw new FineoPayWebhookVerificationError(
      400,
      'INVALID_AMOUNT',
      'Montant de callback invalide'
    );
  }
  return amount;
};

const normalizeSignature = (signature) => {
  if (typeof signature !== 'string') return null;
  return signature.trim().replace(/^sha256=/i, '').toLowerCase();
};

const verifyOptionalSignature = ({ rawBody, signature, webhookSecret }) => {
  if (!signature || !webhookSecret) {
    return { signatureChecked: false, signatureValid: null };
  }

  const normalizedSignature = normalizeSignature(signature);
  if (!normalizedSignature || !/^[a-f0-9]{64}$/.test(normalizedSignature)) {
    throw new FineoPayWebhookVerificationError(
      401,
      'INVALID_SIGNATURE',
      'Signature webhook invalide'
    );
  }
  if (!Buffer.isBuffer(rawBody)) {
    throw new FineoPayWebhookVerificationError(
      500,
      'RAW_BODY_UNAVAILABLE',
      'Corps brut indisponible pour vérifier la signature',
      true
    );
  }

  const expectedSignature = crypto
    .createHmac('sha256', webhookSecret)
    .update(rawBody)
    .digest('hex');
  const receivedBuffer = Buffer.from(normalizedSignature, 'hex');
  const expectedBuffer = Buffer.from(expectedSignature, 'hex');

  if (
    receivedBuffer.length !== expectedBuffer.length
    || !crypto.timingSafeEqual(receivedBuffer, expectedBuffer)
  ) {
    throw new FineoPayWebhookVerificationError(
      401,
      'INVALID_SIGNATURE',
      'Signature webhook invalide'
    );
  }

  return { signatureChecked: true, signatureValid: true };
};

const validateCallbackBody = (body) => {
  const reference = typeof body?.reference === 'string' ? body.reference.trim() : '';
  const syncRef = typeof body?.syncRef === 'string' ? body.syncRef.trim() : '';
  const status = typeof body?.status === 'string' ? body.status.trim().toLowerCase() : '';

  if (!reference || !syncRef || !['success', 'failed'].includes(status)) {
    throw new FineoPayWebhookVerificationError(
      400,
      'INVALID_CALLBACK_PAYLOAD',
      'Payload callback FineoPay incomplet ou invalide'
    );
  }

  return {
    reference,
    syncRef,
    status,
    amount: normalizeAmount(body.amount)
  };
};

const verifyFineoPayWebhook = async ({
  body,
  rawBody,
  signature,
  webhookSecret,
  fetchTransaction
}) => {
  const callback = validateCallbackBody(body);
  const signatureResult = verifyOptionalSignature({
    rawBody,
    signature,
    webhookSecret
  });

  let providerResponse;
  try {
    providerResponse = await fetchTransaction(callback.reference);
  } catch (error) {
    throw new FineoPayWebhookVerificationError(
      503,
      'PROVIDER_UNAVAILABLE',
      'Vérification FineoPay temporairement indisponible',
      true
    );
  }

  if (providerResponse?.success !== true || !providerResponse?.data) {
    throw new FineoPayWebhookVerificationError(
      502,
      'PROVIDER_RESPONSE_INVALID',
      'FineoPay n’a pas confirmé cette transaction',
      true
    );
  }

  const transaction = providerResponse.data;
  const providerReference = typeof transaction.reference === 'string'
    ? transaction.reference.trim()
    : '';
  const providerSyncRef = typeof transaction.syncRef === 'string'
    ? transaction.syncRef.trim()
    : '';
  const providerStatus = typeof transaction.status === 'string'
    ? transaction.status.trim().toLowerCase()
    : '';
  const providerAmount = normalizeAmount(transaction.amount);

  if (providerReference !== callback.reference) {
    throw new FineoPayWebhookVerificationError(
      401,
      'REFERENCE_MISMATCH',
      'Référence FineoPay incohérente'
    );
  }
  if (providerSyncRef !== callback.syncRef) {
    throw new FineoPayWebhookVerificationError(
      401,
      'SYNC_REF_MISMATCH',
      'Référence de synchronisation incohérente'
    );
  }
  if (providerStatus !== callback.status) {
    throw new FineoPayWebhookVerificationError(
      401,
      'STATUS_MISMATCH',
      'Statut FineoPay incohérent'
    );
  }
  if (Math.round(providerAmount * 100) !== Math.round(callback.amount * 100)) {
    throw new FineoPayWebhookVerificationError(
      401,
      'AMOUNT_MISMATCH',
      'Montant FineoPay incohérent'
    );
  }

  return {
    reference: providerReference,
    syncRef: providerSyncRef,
    status: providerStatus,
    amount: providerAmount,
    transaction,
    ...signatureResult,
    providerVerified: true
  };
};

module.exports = {
  verifyFineoPayWebhook,
  FineoPayWebhookVerificationError
};
