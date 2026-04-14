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
    return sendJson(res, 401, {
      error: 'Missing authorization token.',
    });
  }

  let decoded;
  try {
    decoded = verifyAccessToken(token);
  } catch (_) {
    return sendJson(res, 401, {
      error: 'Invalid authorization token.',
    });
  }

  const uid = String(decoded.uid || '');
  if (!uid) {
    return sendJson(res, 401, {
      error: 'Invalid token payload.',
    });
  }

  const authResult = await db.execute({
    sql: `
      SELECT uid, email, phone, display_name
      FROM auth_accounts
      WHERE uid = ?
      LIMIT 1
    `,
    args: [uid],
  });

  if (authResult.rows.length === 0) {
    return sendJson(res, 404, {
      error: 'User account not found.',
    });
  }

  const profileResult = await db.execute({
    sql: `
      SELECT uid, name, phone, email, role, profile_photo_url, fcm_token, created_at, is_active
      FROM users
      WHERE uid = ?
      LIMIT 1
    `,
    args: [uid],
  });

  const providerResult = await db.execute({
    sql: `
      SELECT verification_status, bio, skills, service_cities, hourly_rate_min, hourly_rate_max,
             wallet_balance, earnings_total, joined_at
      FROM providers
      WHERE user_id = ?
      LIMIT 1
    `,
    args: [uid],
  });

  const authRow = authResult.rows[0];
  const profileRow = profileResult.rows.length > 0 ? profileResult.rows[0] : null;
  const providerRow =
    providerResult.rows.length > 0 ? providerResult.rows[0] : null;

  const parseStringList = (value) => {
    if (typeof value !== 'string' || value.trim().length === 0) {
      return [];
    }

    try {
      const parsed = JSON.parse(value);
      if (!Array.isArray(parsed)) {
        return [];
      }
      return parsed
        .map((item) => String(item || '').trim())
        .filter((item) => item.length > 0);
    } catch (_) {
      return [];
    }
  };

  return sendJson(res, 200, {
    user: {
      uid,
      email: authRow.email ? String(authRow.email) : null,
      phoneNumber: authRow.phone ? String(authRow.phone) : null,
      displayName: authRow.display_name ? String(authRow.display_name) : null,
      profile: profileRow
        ? {
            name: String(profileRow.name || ''),
            phone: String(profileRow.phone || ''),
            email: profileRow.email ? String(profileRow.email) : null,
            role: String(profileRow.role || 'customer'),
            profilePhotoUrl: profileRow.profile_photo_url
              ? String(profileRow.profile_photo_url)
              : null,
            fcmToken: profileRow.fcm_token ? String(profileRow.fcm_token) : null,
            createdAt: Number(profileRow.created_at || Date.now()),
            isActive: Number(profileRow.is_active || 1) === 1,
            providerProfile: providerRow
              ? {
                  verificationStatus: providerRow.verification_status
                    ? String(providerRow.verification_status)
                    : 'pending',
                  bio: String(providerRow.bio || ''),
                  skills: parseStringList(String(providerRow.skills || '[]')),
                  serviceCities: parseStringList(
                    String(providerRow.service_cities || '[]'),
                  ),
                  hourlyRateMin:
                    providerRow.hourly_rate_min == null
                      ? null
                      : Number(providerRow.hourly_rate_min),
                  hourlyRateMax:
                    providerRow.hourly_rate_max == null
                      ? null
                      : Number(providerRow.hourly_rate_max),
                  walletBalance: Number(providerRow.wallet_balance || 0),
                  earningsTotal: Number(providerRow.earnings_total || 0),
                  joinedAt: Number(providerRow.joined_at || Date.now()),
                }
              : null,
          }
        : null,
    },
  });
}
