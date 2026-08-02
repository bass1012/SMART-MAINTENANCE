const { dispatchOutboxBatch } = require('../services/outboxService');

const createOutboxWorker = ({
  dispatch = dispatchOutboxBatch,
  intervalMs = Number(process.env.OUTBOX_POLL_INTERVAL_MS || 2000),
  logger = console
} = {}) => {
  let timer = null;
  let activeRun = null;

  const runOnce = async () => {
    if (activeRun) return activeRun;
    activeRun = dispatch()
      .catch((error) => logger.error(`❌ Erreur worker outbox: ${error.message}`))
      .finally(() => { activeRun = null; });
    return activeRun;
  };

  const start = () => {
    if (timer) return;
    timer = setInterval(runOnce, intervalMs);
    timer.unref?.();
    void runOnce();
    logger.log(`📤 Worker outbox démarré (intervalle ${intervalMs} ms)`);
  };

  const stop = async () => {
    if (timer) clearInterval(timer);
    timer = null;
    if (activeRun) await activeRun;
  };

  return { start, stop, runOnce, isRunning: () => Boolean(timer) };
};

module.exports = { createOutboxWorker };
