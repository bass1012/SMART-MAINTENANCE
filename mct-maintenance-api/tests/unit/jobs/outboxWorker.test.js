const { createOutboxWorker } = require('../../../src/jobs/outboxWorker');

describe('outboxWorker', () => {
  afterEach(() => jest.useRealTimers());

  test('évite deux traitements simultanés et attend le traitement à l’arrêt', async () => {
    jest.useFakeTimers();
    let release;
    const dispatch = jest.fn(() => new Promise((resolve) => { release = resolve; }));
    const worker = createOutboxWorker({
      dispatch,
      intervalMs: 1000,
      logger: { log: jest.fn(), error: jest.fn() }
    });

    worker.start();
    expect(worker.isRunning()).toBe(true);
    expect(dispatch).toHaveBeenCalledTimes(1);
    const overlapping = worker.runOnce();
    expect(dispatch).toHaveBeenCalledTimes(1);

    const stopping = worker.stop();
    release([]);
    await overlapping;
    await stopping;
    expect(worker.isRunning()).toBe(false);
  });

  test('journalise une panne puis reste disponible pour le prochain passage', async () => {
    const logger = { log: jest.fn(), error: jest.fn() };
    const dispatch = jest.fn()
      .mockRejectedValueOnce(new Error('base indisponible'))
      .mockResolvedValueOnce([]);
    const worker = createOutboxWorker({ dispatch, logger });

    await worker.runOnce();
    await worker.runOnce();

    expect(dispatch).toHaveBeenCalledTimes(2);
    expect(logger.error).toHaveBeenCalledWith(expect.stringContaining('base indisponible'));
  });
});
