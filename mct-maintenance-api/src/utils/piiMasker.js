'use strict';

const SENSITIVE_KEYS = new Set([
  'password',
  'oldpassword',
  'newpassword',
  'token',
  'refreshtoken',
  'jwt',
  'secret',
  'apikey',
  'api_key',
  'authorization',
  'creditcard',
  'cardnumber',
  'cvv',
  'ssn'
]);

/**
 * Masque récursivement les propriétés sensibles dans un objet/array/string
 */
const maskSensitiveData = (data, depth = 0) => {
  if (depth > 8 || data === null || data === undefined) {
    return data;
  }

  if (typeof data === 'string') {
    return data;
  }

  if (Array.isArray(data)) {
    return data.map((item) => maskSensitiveData(item, depth + 1));
  }

  if (typeof data === 'object') {
    const masked = {};
    for (const [key, value] of Object.entries(data)) {
      const lowerKey = key.toLowerCase();
      if (SENSITIVE_KEYS.has(lowerKey)) {
        masked[key] = '***MASKED***';
      } else {
        masked[key] = maskSensitiveData(value, depth + 1);
      }
    }
    return masked;
  }

  return data;
};

module.exports = {
  maskSensitiveData,
  SENSITIVE_KEYS
};
