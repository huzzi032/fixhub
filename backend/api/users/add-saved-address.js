import crypto from 'node:crypto';

import { getBearerToken, verifyAccessToken } from '../../lib/auth.js';
import { db, ensureSchema } from '../../lib/db.js';
import { methodNotAllowed, readJsonBody, sendJson } from '../../lib/http.js';

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
  if (req.method !== 'POST') {
    return methodNotAllowed(res, 'POST');
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

  const body = readJsonBody(req);
  const label = String(body.label || '').trim();
  const address = String(body.address || '').trim();

  if (!label || !address) {
    return sendJson(res, 400, {
      error: 'label and address are required.',
    });
  }

  await db.execute({
    sql: `
      INSERT INTO customers(user_id, saved_addresses, loyalty_points, total_orders_placed)
      VALUES (?, '[]', 0, 0)
      ON CONFLICT (user_id) DO NOTHING
    `,
    args: [uid],
  });

  const current = await db.execute({
    sql: 'SELECT saved_addresses FROM customers WHERE user_id = ? LIMIT 1',
    args: [uid],
  });

  const existing =
    current.rows.length > 0
      ? parseSavedAddresses(String(current.rows[0].saved_addresses || '[]'))
      : [];

  const savedAddress = {
    id: crypto.randomUUID(),
    label,
    address,
  };

  const updated = [...existing, savedAddress];

  await db.execute({
    sql: 'UPDATE customers SET saved_addresses = ? WHERE user_id = ?',
    args: [JSON.stringify(updated), uid],
  });

  return sendJson(res, 200, {
    savedAddress,
    savedAddresses: updated,
  });
}
