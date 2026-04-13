import { getBearerToken, verifyAccessToken } from '../../lib/auth.js';
import { db, ensureSchema } from '../../lib/db.js';
import { methodNotAllowed, readJsonBody, sendJson } from '../../lib/http.js';

const ALLOWED_ROLES = new Set(['customer', 'provider', 'admin']);

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
  const name = String(body.name || '').trim();
  const phone = String(body.phone || '').trim();
  const email = body.email ? String(body.email).trim().toLowerCase() : null;
  const role = String(body.role || '').trim();

  if (!name || !role) {
    return sendJson(res, 400, {
      error: 'name and role are required.',
    });
  }

  if (!ALLOWED_ROLES.has(role)) {
    return sendJson(res, 400, {
      error: 'role must be one of: customer, provider, admin.',
    });
  }

  const now = Date.now();

  await db.execute({
    sql: `
      INSERT INTO users(uid, name, phone, email, role, profile_photo_url, fcm_token, created_at, is_active)
      VALUES (?, ?, ?, ?, ?, NULL, NULL, ?, 1)
      ON CONFLICT(uid) DO UPDATE SET
        name = excluded.name,
        phone = excluded.phone,
        email = excluded.email,
        role = excluded.role,
        is_active = 1
    `,
    args: [uid, name, phone, email, role, now],
  });

  if (role === 'customer') {
    await db.execute({
      sql: `
        INSERT OR IGNORE INTO customers(user_id, saved_addresses, loyalty_points, total_orders_placed)
        VALUES (?, '[]', 0, 0)
      `,
      args: [uid],
    });
  }

  if (role === 'provider') {
    await db.execute({
      sql: `
        INSERT OR IGNORE INTO providers(user_id, verification_status, wallet_balance, earnings_total, joined_at)
        VALUES (?, 'pending', 0, 0, ?)
      `,
      args: [uid, now],
    });
  }

  return sendJson(res, 200, {
    message: 'Profile saved successfully.',
  });
}
