import { getBearerToken, verifyAccessToken } from '../../lib/auth.js';
import { db, ensureSchema } from '../../lib/db.js';
import { methodNotAllowed, readJsonBody, sendJson } from '../../lib/http.js';

const ALLOWED_ROLES = new Set(['customer', 'provider', 'admin']);
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

function toInt(value) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Math.trunc(value);
  }

  if (typeof value === 'string' && value.trim().length > 0) {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) {
      return Math.trunc(parsed);
    }
  }

  return null;
}

function toStringList(value) {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((item) => String(item || '').trim())
    .filter((item) => item.length > 0);
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

  const authAccountResult = await db.execute({
    sql: `
      SELECT email
      FROM auth_accounts
      WHERE uid = ?
      LIMIT 1
    `,
    args: [uid],
  });
  const authAccountEmail =
    authAccountResult.rows.length > 0 && authAccountResult.rows[0].email
      ? String(authAccountResult.rows[0].email).trim().toLowerCase()
      : null;

  const body = readJsonBody(req);
  const name = String(body.name || '').trim();
  const phone = String(body.phone || '').trim();
  const normalizedEmail = String(body.email || '').trim().toLowerCase();
  const email = normalizedEmail === '' ? authAccountEmail : normalizedEmail;
  const profilePhotoUrl =
    body.profilePhotoUrl == null
      ? null
      : String(body.profilePhotoUrl).trim() || null;
  const role = String(body.role || '').trim();
  const providerBio = String(body.providerBio || '').trim();
  const providerSkills = toStringList(body.providerSkills);
  const providerCities = toStringList(body.providerCities);
  const hourlyRateMin = toInt(body.hourlyRateMin);
  const hourlyRateMax = toInt(body.hourlyRateMax);

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

  if (email && !isValidEmail(email)) {
    return sendJson(res, 400, {
      error: 'Please enter a valid email address.',
    });
  }

  if (email) {
    const existingAuthAccount = await db.execute({
      sql: `
        SELECT uid
        FROM auth_accounts
        WHERE LOWER(email) = ? AND uid <> ?
        LIMIT 1
      `,
      args: [email, uid],
    });

    if (existingAuthAccount.rows.length > 0) {
      return sendJson(res, 409, {
        error: 'This email is already linked with another account.',
      });
    }

    const existingProfile = await db.execute({
      sql: `
        SELECT uid
        FROM users
        WHERE LOWER(email) = ? AND uid <> ?
        LIMIT 1
      `,
      args: [email, uid],
    });

    if (existingProfile.rows.length > 0) {
      return sendJson(res, 409, {
        error: 'This email is already linked with another account.',
      });
    }
  }

  const now = Date.now();

  await db.execute({
    sql: `
      INSERT INTO users(uid, name, phone, email, role, profile_photo_url, fcm_token, created_at, is_active)
      VALUES (?, ?, ?, ?, ?, ?, NULL, ?, 1)
      ON CONFLICT(uid) DO UPDATE SET
        name = excluded.name,
        phone = excluded.phone,
        email = excluded.email,
        role = excluded.role,
        profile_photo_url = COALESCE(excluded.profile_photo_url, users.profile_photo_url),
        is_active = 1
    `,
    args: [uid, name, phone, email, role, profilePhotoUrl, now],
  });

  if (role === 'customer') {
    await db.execute({
      sql: `
        INSERT INTO customers(user_id, saved_addresses, loyalty_points, total_orders_placed)
        VALUES (?, '[]', 0, 0)
        ON CONFLICT (user_id) DO NOTHING
      `,
      args: [uid],
    });
  }

  if (role === 'provider') {
    await db.execute({
      sql: `
        INSERT INTO providers(user_id, verification_status, wallet_balance, earnings_total, joined_at)
        VALUES (?, 'pending', 0, 0, ?)
        ON CONFLICT (user_id) DO NOTHING
      `,
      args: [uid, now],
    });

    await db.execute({
      sql: `
        UPDATE providers
        SET verification_status = 'pending',
            bio = ?,
            skills = ?,
            service_cities = ?,
            hourly_rate_min = ?,
            hourly_rate_max = ?
        WHERE user_id = ?
      `,
      args: [
        providerBio,
        JSON.stringify(providerSkills),
        JSON.stringify(providerCities),
        hourlyRateMin,
        hourlyRateMax,
        uid,
      ],
    });
  }

  return sendJson(res, 200, {
    message: 'Profile saved successfully.',
  });
}
