import { getBearerToken, verifyAccessToken } from '../../lib/auth.js';
import { db, ensureSchema } from '../../lib/db.js';
import { methodNotAllowed, sendJson } from '../../lib/http.js';

export default async function handler(req, res) {
  if (req.method !== 'GET') {
    return methodNotAllowed(res, 'GET');
  }

  await ensureSchema();

  const token = getBearerToken(req);
  if (!token) {
    return sendJson(res, 401, { error: 'Missing authorization token.' });
  }

  let decoded;
  try {
    decoded = verifyAccessToken(token);
  } catch (_) {
    return sendJson(res, 401, { error: 'Invalid authorization token.' });
  }

  const uid = String(decoded.uid || '');
  if (!uid) {
    return sendJson(res, 401, { error: 'Invalid token payload.' });
  }

  const result = await db.execute({
    sql: 'SELECT verification_status FROM providers WHERE user_id = ? LIMIT 1',
    args: [uid],
  });

  if (result.rows.length === 0) {
    return sendJson(res, 200, { verificationStatus: 'pending' });
  }

  const row = result.rows[0];
  return sendJson(res, 200, {
    verificationStatus: row.verification_status
      ? String(row.verification_status)
      : 'pending',
  });
}
