import { ensureSchema } from '../lib/db.js';
import { methodNotAllowed, sendJson } from '../lib/http.js';

export default async function handler(req, res) {
  if (req.method !== 'GET') {
    return methodNotAllowed(res, 'GET');
  }

  await ensureSchema();

  return sendJson(res, 200, {
    status: 'ok',
    message: 'FixHub backend is running.',
    timestamp: Date.now(),
  });
}
