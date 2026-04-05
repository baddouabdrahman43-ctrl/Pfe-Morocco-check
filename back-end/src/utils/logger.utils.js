export function buildLogContext(req, extra = {}) {
  return {
    request_id: req?.requestId || null,
    method: req?.method || null,
    path: req?.originalUrl || req?.url || null,
    ip: req?.ip || null,
    user_id: req?.userId || req?.user?.id || null,
    user_role: req?.userRole || req?.user?.role || null,
    ...extra
  };
}

function writeLog(level, event, context = {}) {
  const payload = {
    level,
    event,
    timestamp: new Date().toISOString(),
    ...context
  };

  const line = JSON.stringify(payload);
  if (level === 'error' || level === 'warn') {
    console.error(line);
    return;
  }

  console.log(line);
}

export function logInfo(event, context = {}) {
  writeLog('info', event, context);
}

export function logWarn(event, context = {}) {
  writeLog('warn', event, context);
}

export function logError(event, context = {}) {
  writeLog('error', event, context);
}

export function logAudit(event, req, extra = {}) {
  logInfo(event, buildLogContext(req, extra));
}
