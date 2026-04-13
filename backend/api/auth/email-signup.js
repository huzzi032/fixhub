import crypto from 'node:crypto';

import { createAccessToken, hashPassword } from '../../lib/auth.js';
import { db, ensureSchema } from '../../lib/db.js';
import { methodNotAllowed, readJsonBody, sendJson } from '../../lib/http.js';

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return methodNotAllowed(res, 'POST');
  }

  await ensureSchema();

  const body = readJsonBody(req);
  const email = String(body.email || '').trim().toLowerCase();
  const password = String(body.password || '');
  const name = String(body.name || '').trim();

  if (!email || !password || !name) {
    return sendJson(res, 400, {
      error: 'name, email and password are required.',
    });
  }

  if (password.length < 6) {
    return sendJson(res, 400, {
      error: 'Password must be at least 6 characters.',
    });
  }

  const existing = await db.execute({
    sql: 'SELECT uid FROM auth_accounts WHERE email = ? LIMIT 1',
    args: [email],
  });

  if (existing.rows.length > 0) {
    return sendJson(res, 409, {
      error: 'An account already exists with this email.',
    });
  }

  const uid = crypto.randomUUID();
  const createdAt = Date.now();
  const passwordHash = await hashPassword(password);

  await db.execute({
    sql: `
      INSERT INTO auth_accounts(uid, email, phone, display_name, password_hash, created_at)
      VALUES (?, ?, NULL, ?, ?, ?)
    `,
    args: [uid, email, name, passwordHash, createdAt],
  });

  const token = createAccessToken(uid);

  return sendJson(res, 201, {
    token,
    user: {
      uid,
      email,
      phoneNumber: null,
      displayName: name,
    },
  });
}
