import { getBearerToken, verifyAccessToken } from '../../lib/auth.js';
import { db, ensureSchema } from '../../lib/db.js';
import { methodNotAllowed, sendJson } from '../../lib/http.js';

function parseSavedAddresses(raw) {
  if (!raw || typeof raw !== 'string') {
    return [];
  }

  try {
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) {
      return [];
    }

    return parsed
      .filter((item) => item && typeof item === 'object')
      .map((item, index) => ({
        id: String(item.id || `addr-${index + 1}`),
        label: String(item.label || ''),
        address: String(item.address || ''),
        ...(item.geoPoint && typeof item.geoPoint === 'object'
          ? { geoPoint: item.geoPoint }
          : {}),
      }))
      .filter((item) => item.label && item.address);
  } catch (_) {
    return [];
  }
}

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
    sql: 'SELECT saved_addresses FROM customers WHERE user_id = ? LIMIT 1',
    args: [uid],
  });

  if (result.rows.length === 0) {
    return sendJson(res, 200, { savedAddresses: [] });
  }

  const row = result.rows[0];
  const savedAddresses = parseSavedAddresses(
    row.saved_addresses ? String(row.saved_addresses) : '',
  );

  return sendJson(res, 200, { savedAddresses });
}
