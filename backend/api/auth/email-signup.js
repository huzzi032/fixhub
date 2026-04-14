import crypto from 'node:crypto';

import { createAccessToken, hashPassword } from '../../lib/auth.js';
import { db, ensureSchema } from '../../lib/db.js';
import { methodNotAllowed, readJsonBody, sendJson } from '../../lib/http.js';

const EMAIL_REGEX = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;

function isValidEmail(email) {
  if (!email || email.includes('..')) {
    return false;
  }

  const parts = email.split('@');
  if (parts.length !== 2) {
    return false;
  }

  const local = parts[0];
  const domain = parts[1];

  if (
    !local ||
    local.startsWith('.') ||
    local.endsWith('.') ||
    !domain ||
    domain.startsWith('-') ||
    domain.endsWith('-') ||
    !domain.includes('.')
  ) {
    return false;
  }

  return EMAIL_REGEX.test(email);
}

function passwordValidationError(password) {
  if (!password) {
    return 'Password is required.';
  }

  if (password.length < 8) {
    return 'Password must be at least 8 characters.';
  }

  if (password.length > 32) {
    return 'Password must not exceed 32 characters.';
  }

  if (/\s/.test(password)) {
    return 'Password must not contain spaces.';
  }

  if (!/[A-Z]/.test(password)) {
    return 'Password must include at least one uppercase letter.';
  }

  if (!/[a-z]/.test(password)) {
    return 'Password must include at least one lowercase letter.';
  }

  if (!/[0-9]/.test(password)) {
    return 'Password must include at least one number.';
  }

  if (!/[^A-Za-z0-9]/.test(password)) {
    return 'Password must include at least one special character.';
  }

  return null;
}

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

  if (name.length < 2 || name.length > 50) {
    return sendJson(res, 400, {
      error: 'Name must be between 2 and 50 characters.',
    });
  }

  if (!isValidEmail(email)) {
    return sendJson(res, 400, {
      error: 'Please enter a valid email address.',
    });
  }

  const passwordError = passwordValidationError(password);
  if (passwordError) {
    return sendJson(res, 400, {
      error: passwordError,
    });
  }

  const uid = crypto.randomUUID();
  const createdAt = Date.now();
  const passwordHash = await hashPassword(password);

  const insertResult = await db.execute({
    sql: `
      INSERT INTO auth_accounts(uid, email, phone, display_name, password_hash, created_at)
      VALUES (?, ?, NULL, ?, ?, ?)
      ON CONFLICT (email) DO NOTHING
      RETURNING uid, email, phone, display_name
    `,
    args: [uid, email, name, passwordHash, createdAt],
  });

  if (insertResult.rows.length === 0) {
    return sendJson(res, 409, {
      error: 'An account already exists with this email.',
    });
  }

  const row = insertResult.rows[0];

  const token = createAccessToken(uid);

  return sendJson(res, 201, {
    token,
    user: {
      uid: String(row.uid),
      email: row.email ? String(row.email) : null,
      phoneNumber: row.phone ? String(row.phone) : null,
      displayName: row.display_name ? String(row.display_name) : null,
    },
  });
}
