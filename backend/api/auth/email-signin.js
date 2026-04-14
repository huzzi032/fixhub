import { createAccessToken, verifyPassword } from '../../lib/auth.js';
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

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return methodNotAllowed(res, 'POST');
  }

  await ensureSchema();

  const body = readJsonBody(req);
  const email = String(body.email || '').trim().toLowerCase();
  const password = String(body.password || '');

  if (!email || !password) {
    return sendJson(res, 400, {
      error: 'email and password are required.',
    });
  }

  if (!isValidEmail(email)) {
    return sendJson(res, 400, {
      error: 'Please enter a valid email address.',
    });
  }

  const result = await db.execute({
    sql: `
      SELECT uid, email, phone, display_name, password_hash
      FROM auth_accounts
      WHERE email = ?
      LIMIT 1
    `,
    args: [email],
  });

  if (result.rows.length === 0) {
    return sendJson(res, 404, {
      error: 'No account found with this email.',
    });
  }

  const row = result.rows[0];
  if (!row.password_hash) {
    return sendJson(res, 400, {
      error: 'This account does not support email sign in.',
    });
  }

  const isValid = await verifyPassword(password, String(row.password_hash));
  if (!isValid) {
    return sendJson(res, 401, {
      error: 'Incorrect password.',
    });
  }

  const token = createAccessToken(String(row.uid));

  return sendJson(res, 200, {
    token,
    user: {
      uid: String(row.uid),
      email: row.email ? String(row.email) : null,
      phoneNumber: row.phone ? String(row.phone) : null,
      displayName: row.display_name ? String(row.display_name) : null,
    },
  });
}
