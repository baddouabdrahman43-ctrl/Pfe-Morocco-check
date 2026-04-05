import * as Sentry from '@sentry/node';
import runtimeConfig from './runtime.js';

let isMonitoringInitialized = false;

export function initMonitoring() {
  if (!runtimeConfig.monitoring.enabled || isMonitoringInitialized) {
    return isMonitoringInitialized;
  }

  Sentry.init({
    dsn: runtimeConfig.monitoring.dsn,
    environment: runtimeConfig.monitoring.environment,
    tracesSampleRate: runtimeConfig.monitoring.tracesSampleRate,
    sendDefaultPii: false
  });

  process.on('unhandledRejection', (reason) => {
    captureException(
      reason instanceof Error ? reason : new Error(String(reason)),
      {
        tags: { source: 'unhandledRejection' }
      }
    );
  });

  process.on('uncaughtException', (error) => {
    captureException(error, {
      tags: { source: 'uncaughtException' }
    });
  });

  isMonitoringInitialized = true;
  return true;
}

export function captureException(error, context = {}) {
  if (!isMonitoringInitialized) {
    return;
  }

  Sentry.withScope((scope) => {
    const tags = context.tags || {};
    const extras = context.extras || {};
    const user = context.user || {};

    Object.entries(tags).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        scope.setTag(key, String(value));
      }
    });

    Object.entries(extras).forEach(([key, value]) => {
      if (value !== undefined) {
        scope.setExtra(key, value);
      }
    });

    if (Object.keys(user).length) {
      scope.setUser(user);
    }

    Sentry.captureException(error);
  });
}

export function isMonitoringEnabled() {
  return isMonitoringInitialized;
}
