jest.mock('../../../src/models/Notification', () => ({
  create: jest.fn(),
  findOrCreate: jest.fn()
}));
jest.mock('../../../src/models', () => ({
  User: { findByPk: jest.fn(), findAll: jest.fn() }
}));
jest.mock('../../../src/services/fcmService', () => ({
  sendToDevice: jest.fn()
}));

const Notification = require('../../../src/models/Notification');
const { User } = require('../../../src/models');
const fcmService = require('../../../src/services/fcmService');
const notificationService = require('../../../src/services/notificationService');

describe('notificationService idempotence', () => {
  const notification = {
    id: 12,
    type: 'payment_confirmed',
    title: 'Paiement confirmé',
    message: 'Votre paiement est confirmé',
    data: {},
    priority: 'high',
    action_url: null,
    user_id: 7
  };

  beforeEach(() => {
    jest.clearAllMocks();
    notificationService.io = null;
    User.findByPk.mockResolvedValue(null);
  });

  test('compose une clé propre au destinataire et envoie une seule fois', async () => {
    Notification.findOrCreate.mockResolvedValue([notification, true]);

    await notificationService.create({
      userId: 7,
      type: 'payment_confirmed',
      title: notification.title,
      message: notification.message,
      priority: 'high',
      idempotencyKey: 'fineopay:TRX-1:customer-confirmation'
    });

    expect(Notification.findOrCreate).toHaveBeenCalledWith({
      where: {
        user_id: 7,
        dedupe_key: 'fineopay:TRX-1:customer-confirmation'
      },
      defaults: expect.objectContaining({
        user_id: 7,
        dedupe_key: 'fineopay:TRX-1:customer-confirmation'
      })
    });
    expect(User.findByPk).toHaveBeenCalledTimes(1);
  });

  test('un rejeu retourne la notification existante sans Socket.IO ni FCM', async () => {
    const fetchSockets = jest.fn();
    notificationService.io = { in: jest.fn(() => ({ fetchSockets })) };
    Notification.findOrCreate.mockResolvedValue([notification, false]);

    const result = await notificationService.create({
      userId: 7,
      type: 'payment_confirmed',
      title: notification.title,
      message: notification.message,
      idempotencyKey: 'fineopay:TRX-1:customer-confirmation'
    });

    expect(result).toBe(notification);
    expect(fetchSockets).not.toHaveBeenCalled();
    expect(User.findByPk).not.toHaveBeenCalled();
    expect(fcmService.sendToDevice).not.toHaveBeenCalled();
  });

  test('préserve le comportement historique sans clé', async () => {
    Notification.create.mockResolvedValue(notification);

    await notificationService.create({
      userId: 7,
      type: 'general',
      title: 'Information',
      message: 'Message'
    });

    expect(Notification.create).toHaveBeenCalledWith(expect.objectContaining({
      user_id: 7,
      dedupe_key: null
    }));
    expect(Notification.findOrCreate).not.toHaveBeenCalled();
  });

  test('refuse une clé trop longue avant toute écriture', async () => {
    await expect(notificationService.create({
      userId: 7,
      type: 'general',
      title: 'Information',
      message: 'Message',
      idempotencyKey: 'x'.repeat(192)
    })).rejects.toThrow('dépasse 191 caractères');

    expect(Notification.create).not.toHaveBeenCalled();
    expect(Notification.findOrCreate).not.toHaveBeenCalled();
  });

  test('refuse une clé vide au lieu de contourner la déduplication', async () => {
    await expect(notificationService.create({
      userId: 7,
      type: 'general',
      title: 'Information',
      message: 'Message',
      idempotencyKey: '   '
    })).rejects.toThrow('chaîne non vide');

    expect(Notification.create).not.toHaveBeenCalled();
    expect(Notification.findOrCreate).not.toHaveBeenCalled();
  });
});
