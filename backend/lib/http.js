export function readJsonBody(req) {
  if (!req.body) {
    return {};
  }

  if (typeof req.body === 'string') {
    try {
      return JSON.parse(req.body);
    } catch (_) {
      return {};
    }
  }

  if (typeof req.body === 'object') {
    return req.body;
  }

  return {};
}

export function sendJson(res, statusCode, payload) {
  return res.status(statusCode).json(payload);
}

export function methodNotAllowed(res, allowedMethod) {
  return sendJson(res, 405, {
    error: `Method not allowed. Use ${allowedMethod}.`,
  });
}
