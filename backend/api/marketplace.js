import crypto from 'node:crypto';

import { getBearerToken, verifyAccessToken } from '../lib/auth.js';
import { db, ensureSchema } from '../lib/db.js';
import { methodNotAllowed, readJsonBody, sendJson } from '../lib/http.js';

function getQueryValue(req, key) {
  if (req?.query && req.query[key] != null) {
    return String(req.query[key]).trim();
  }

  if (typeof req?.url === 'string' && req.url.length > 0) {
    try {
      const url = new URL(req.url, 'http://localhost');
      const value = url.searchParams.get(key);
      return value == null ? '' : value.trim();
    } catch (_) {
      return '';
    }
  }

  return '';
}

function toInt(value, fallback = 0) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Math.trunc(value);
  }

  if (typeof value === 'string' && value.trim().length > 0) {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) {
      return Math.trunc(parsed);
    }
  }

  return fallback;
}

function toDouble(value, fallback = 0) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value;
  }

  if (typeof value === 'string' && value.trim().length > 0) {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }

  return fallback;
}

function normalizeCategory(input) {
  const value = String(input || '').trim().toLowerCase().replaceAll(' ', '_');

  const aliases = {
    ac: 'ac_repair',
    acrepair: 'ac_repair',
    a_c_repair: 'ac_repair',
    carmechanic: 'car_mechanic',
    car_mechanics: 'car_mechanic',
  };

  const normalized = aliases[value] || value;
  const allowed = new Set([
    'plumber',
    'electrician',
    'carpenter',
    'painter',
    'car_mechanic',
    'ac_repair',
    'cleaning',
    'other',
  ]);

  return allowed.has(normalized) ? normalized : 'other';
}

function normalizeServiceRow(row) {
  return {
    service_id: String(row.service_id || ''),
    provider_id: row.provider_id == null ? '' : String(row.provider_id),
    provider_name: row.provider_name == null ? 'Provider' : String(row.provider_name),
    title: String(row.title || ''),
    description: String(row.description || ''),
    category: String(row.category || 'other'),
    min_price: toInt(row.min_price),
    max_price: toInt(row.max_price),
    rating: toDouble(row.rating),
    review_count: toInt(row.review_count),
    is_active: toInt(row.is_active),
    created_at: toInt(row.created_at),
  };
}

function normalizeDealRow(row) {
  return {
    deal_id: String(row.deal_id || ''),
    service_category: String(row.service_category || 'other'),
    area: String(row.area || ''),
    city: String(row.city || ''),
    description: String(row.description || ''),
    min_participants: toInt(row.min_participants),
    max_participants:
      row.max_participants == null ? null : toInt(row.max_participants),
    discount_percent: toInt(row.discount_percent),
    created_by: row.created_by == null ? null : String(row.created_by),
    created_by_name:
      row.created_by_name == null ? null : String(row.created_by_name),
    status: String(row.status || 'open'),
    created_at: toInt(row.created_at),
    expires_at: toInt(row.expires_at),
    participants_count: toInt(row.participants_count),
    has_joined: toInt(row.has_joined),
  };
}

async function refreshDealStatus(dealId) {
  const dealRows = await db.execute({
    sql: `
      SELECT max_participants, expires_at
      FROM neighborhood_deals
      WHERE deal_id = ?
      LIMIT 1
    `,
    args: [dealId],
  });

  if (dealRows.rows.length === 0) {
    return;
  }

  const deal = dealRows.rows[0];
  const maxParticipants =
    deal.max_participants == null ? null : toInt(deal.max_participants);
  const expiresAt = toInt(deal.expires_at);

  const countRows = await db.execute({
    sql: 'SELECT COUNT(*)::INT AS count FROM deal_participants WHERE deal_id = ?',
    args: [dealId],
  });

  const participantCount = toInt(countRows.rows[0]?.count);

  let nextStatus = 'open';
  if (Date.now() > expiresAt) {
    nextStatus = 'expired';
  } else if (maxParticipants != null && participantCount >= maxParticipants) {
    nextStatus = 'filled';
  }

  await db.execute({
    sql: 'UPDATE neighborhood_deals SET status = ? WHERE deal_id = ?',
    args: [nextStatus, dealId],
  });
}

function ensureSelf(res, authUid, targetUid) {
  if (authUid === targetUid) {
    return true;
  }

  sendJson(res, 403, { error: 'Forbidden for current user.' });
  return false;
}

export default async function handler(req, res) {
  if (req.method !== 'GET' && req.method !== 'POST') {
    return methodNotAllowed(res, 'GET/POST');
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

  const authUid = String(decoded.uid || '');
  if (!authUid) {
    return sendJson(res, 401, { error: 'Invalid token payload.' });
  }

  if (req.method === 'GET') {
    const action = getQueryValue(req, 'action');

    if (action === 'searchServices') {
      const query = getQueryValue(req, 'query').toLowerCase();
      const categoriesCsv = getQueryValue(req, 'categories');
      const minPrice = toInt(getQueryValue(req, 'minPrice'), 0);
      const maxPrice = toInt(getQueryValue(req, 'maxPrice'), 5000);
      const minRating = toDouble(getQueryValue(req, 'minRating'), 0);
      const sortBy = getQueryValue(req, 'sortBy') || 'nearest';

      const categories = categoriesCsv
        .split(',')
        .map((item) => normalizeCategory(item))
        .filter((item, index, arr) => item && arr.indexOf(item) === index);

      const whereClauses = ['is_active = 1'];
      const whereArgs = [];

      if (query) {
        const like = `%${query}%`;
        whereClauses.push(
          '(LOWER(title) LIKE ? OR LOWER(description) LIKE ? OR LOWER(provider_name) LIKE ? OR LOWER(category) LIKE ?)',
        );
        whereArgs.push(like, like, like, like);
      }

      if (categories.length > 0) {
        const placeholders = new Array(categories.length).fill('?').join(', ');
        whereClauses.push(`category IN (${placeholders})`);
        whereArgs.push(...categories);
      }

      whereClauses.push('max_price >= ?');
      whereArgs.push(minPrice);
      whereClauses.push('min_price <= ?');
      whereArgs.push(maxPrice);
      whereClauses.push('rating >= ?');
      whereArgs.push(minRating);

      const orderBy =
        sortBy === 'rating'
          ? 'rating DESC, review_count DESC'
          : sortBy === 'price_low'
            ? 'min_price ASC'
            : sortBy === 'price_high'
              ? 'max_price DESC'
              : 'created_at DESC';

      const result = await db.execute({
        sql: `
          SELECT *
          FROM provider_services
          WHERE ${whereClauses.join(' AND ')}
          ORDER BY ${orderBy}
        `,
        args: whereArgs,
      });

      return sendJson(res, 200, {
        services: result.rows.map(normalizeServiceRow),
      });
    }

    if (action === 'getServicesByCategory') {
      const category = normalizeCategory(getQueryValue(req, 'category'));
      const result = await db.execute({
        sql: `
          SELECT *
          FROM provider_services
          WHERE category = ? AND is_active = 1
          ORDER BY created_at DESC
        `,
        args: [category],
      });

      return sendJson(res, 200, {
        services: result.rows.map(normalizeServiceRow),
      });
    }

    if (action === 'getProviderServices') {
      const providerId = getQueryValue(req, 'providerId');
      if (!providerId) {
        return sendJson(res, 400, { error: 'providerId is required.' });
      }

      const result = await db.execute({
        sql: 'SELECT * FROM provider_services WHERE provider_id = ? ORDER BY created_at DESC',
        args: [providerId],
      });

      return sendJson(res, 200, {
        services: result.rows.map(normalizeServiceRow),
      });
    }

    if (action === 'getServiceById') {
      const serviceId = getQueryValue(req, 'serviceId');
      if (!serviceId) {
        return sendJson(res, 400, { error: 'serviceId is required.' });
      }

      const result = await db.execute({
        sql: 'SELECT * FROM provider_services WHERE service_id = ? LIMIT 1',
        args: [serviceId],
      });

      if (result.rows.length === 0) {
        return sendJson(res, 200, { service: null });
      }

      return sendJson(res, 200, {
        service: normalizeServiceRow(result.rows[0]),
      });
    }

    if (action === 'getDeals' || action === 'getFeaturedDeals') {
      const userId = getQueryValue(req, 'userId') || authUid;
      const city = getQueryValue(req, 'city').toLowerCase();
      const area = getQueryValue(req, 'area').toLowerCase();
      const limit = toInt(getQueryValue(req, 'limit'), 5);

      const whereClauses = ['d.status = ?'];
      const whereArgs = ['open'];

      if (city) {
        whereClauses.push('LOWER(d.city) = ?');
        whereArgs.push(city);
      }

      if (area) {
        whereClauses.push('LOWER(d.area) LIKE ?');
        whereArgs.push(`%${area}%`);
      }

      const result = await db.execute({
        sql: `
          SELECT
            d.*,
            creator.name AS created_by_name,
            COUNT(p.user_id)::INT AS participants_count,
            MAX(CASE WHEN p.user_id = ? THEN 1 ELSE 0 END)::INT AS has_joined
          FROM neighborhood_deals d
          LEFT JOIN deal_participants p ON p.deal_id = d.deal_id
          LEFT JOIN users creator ON creator.uid = d.created_by
          WHERE ${whereClauses.join(' AND ')}
          GROUP BY d.deal_id, creator.name
          ORDER BY d.created_at DESC
        `,
        args: [userId, ...whereArgs],
      });

      const deals = result.rows.map(normalizeDealRow);
      if (action === 'getFeaturedDeals') {
        return sendJson(res, 200, {
          deals: deals.slice(0, Math.max(1, limit)),
        });
      }

      return sendJson(res, 200, { deals });
    }

    return sendJson(res, 400, { error: 'Unsupported marketplace action.' });
  }

  const body = readJsonBody(req);
  const action = String(body.action || '').trim();

  if (action === 'saveProviderService') {
    const providerId = String(body.providerId || '').trim();
    if (!providerId) {
      return sendJson(res, 400, { error: 'providerId is required.' });
    }

    if (!ensureSelf(res, authUid, providerId)) {
      return;
    }

    const serviceId = String(body.serviceId || crypto.randomUUID());
    const providerName = String(body.providerName || '').trim();
    const title = String(body.title || '').trim();
    const description = String(body.description || '').trim();
    const category = normalizeCategory(body.category);
    const minPrice = toInt(body.minPrice);
    const maxPrice = toInt(body.maxPrice);
    const isActive = body.isActive == null ? true : Boolean(body.isActive);

    if (!title || !description) {
      return sendJson(res, 400, {
        error: 'title and description are required.',
      });
    }

    await db.execute({
      sql: `
        INSERT INTO provider_services(
          service_id, provider_id, provider_name, title, description,
          category, min_price, max_price, rating, review_count, is_active, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 4.0, 0, ?, ?)
        ON CONFLICT (service_id) DO UPDATE SET
          provider_id = excluded.provider_id,
          provider_name = excluded.provider_name,
          title = excluded.title,
          description = excluded.description,
          category = excluded.category,
          min_price = excluded.min_price,
          max_price = excluded.max_price,
          is_active = excluded.is_active
      `,
      args: [
        serviceId,
        providerId,
        providerName || 'Provider',
        title,
        description,
        category,
        minPrice,
        maxPrice,
        isActive ? 1 : 0,
        Date.now(),
      ],
    });

    return sendJson(res, 200, { serviceId });
  }

  if (action === 'setServiceActive') {
    const serviceId = String(body.serviceId || '').trim();
    const isActive = Boolean(body.isActive);

    if (!serviceId) {
      return sendJson(res, 400, { error: 'serviceId is required.' });
    }

    const existing = await db.execute({
      sql: 'SELECT provider_id FROM provider_services WHERE service_id = ? LIMIT 1',
      args: [serviceId],
    });

    if (existing.rows.length === 0) {
      return sendJson(res, 404, { error: 'Service not found.' });
    }

    if (String(existing.rows[0].provider_id || '') !== authUid) {
      return sendJson(res, 403, { error: 'Forbidden for current user.' });
    }

    await db.execute({
      sql: 'UPDATE provider_services SET is_active = ? WHERE service_id = ?',
      args: [isActive ? 1 : 0, serviceId],
    });

    return sendJson(res, 200, { message: 'Service updated.' });
  }

  if (action === 'deleteService') {
    const serviceId = String(body.serviceId || '').trim();
    if (!serviceId) {
      return sendJson(res, 400, { error: 'serviceId is required.' });
    }

    const existing = await db.execute({
      sql: 'SELECT provider_id FROM provider_services WHERE service_id = ? LIMIT 1',
      args: [serviceId],
    });

    if (existing.rows.length === 0) {
      return sendJson(res, 200, { message: 'Service deleted.' });
    }

    if (String(existing.rows[0].provider_id || '') !== authUid) {
      return sendJson(res, 403, { error: 'Forbidden for current user.' });
    }

    await db.execute({
      sql: 'DELETE FROM provider_services WHERE service_id = ?',
      args: [serviceId],
    });

    return sendJson(res, 200, { message: 'Service deleted.' });
  }

  if (action === 'createDeal') {
    const createdBy = String(body.createdBy || authUid).trim();
    if (!ensureSelf(res, authUid, createdBy)) {
      return;
    }

    const serviceCategory = normalizeCategory(body.serviceCategory);
    const area = String(body.area || '').trim();
    const city = String(body.city || '').trim();
    const description = String(body.description || '').trim();
    const minParticipants = toInt(body.minParticipants, 1);
    const maxParticipants =
      body.maxParticipants == null ? null : toInt(body.maxParticipants);
    const discountPercent = toInt(body.discountPercent, 0);
    const expiryDays = toInt(body.expiryDays, 7);

    if (!area || !city || !description || minParticipants <= 0) {
      return sendJson(res, 400, {
        error:
          'serviceCategory, area, city, description and minParticipants are required.',
      });
    }

    const providerRows = await db.execute({
      sql: 'SELECT uid FROM users WHERE uid = ? AND role = ? LIMIT 1',
      args: [createdBy, 'provider'],
    });

    if (providerRows.rows.length === 0) {
      return sendJson(res, 400, {
        error: 'Only providers can create neighborhood deals.',
      });
    }

    const dealId = crypto.randomUUID();
    const createdAt = Date.now();
    const expiresAt = createdAt + Math.max(1, expiryDays) * 24 * 60 * 60 * 1000;

    await db.execute({
      sql: `
        INSERT INTO neighborhood_deals(
          deal_id, service_category, area, city, description,
          min_participants, max_participants, discount_percent,
          created_by, status, created_at, expires_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'open', ?, ?)
      `,
      args: [
        dealId,
        serviceCategory,
        area,
        city,
        description,
        minParticipants,
        maxParticipants,
        discountPercent,
        createdBy,
        createdAt,
        expiresAt,
      ],
    });

    return sendJson(res, 200, { dealId });
  }

  if (action === 'joinDeal') {
    const dealId = String(body.dealId || '').trim();
    const userId = String(body.userId || authUid).trim();

    if (!dealId || !userId) {
      return sendJson(res, 400, { error: 'dealId and userId are required.' });
    }

    if (!ensureSelf(res, authUid, userId)) {
      return;
    }

    const customerRows = await db.execute({
      sql: 'SELECT uid FROM users WHERE uid = ? AND role = ? LIMIT 1',
      args: [userId, 'customer'],
    });

    if (customerRows.rows.length === 0) {
      return sendJson(res, 400, {
        error: 'Only customers can join neighborhood deals.',
      });
    }

    const dealRows = await db.execute({
      sql: 'SELECT created_by FROM neighborhood_deals WHERE deal_id = ? LIMIT 1',
      args: [dealId],
    });

    if (dealRows.rows.length === 0) {
      return sendJson(res, 404, { error: 'Deal not found.' });
    }

    if (String(dealRows.rows[0].created_by || '') === userId) {
      return sendJson(res, 400, {
        error: 'Deal creators cannot join their own deals.',
      });
    }

    await db.execute({
      sql: `
        INSERT INTO deal_participants(deal_id, user_id, joined_at)
        VALUES (?, ?, ?)
        ON CONFLICT (deal_id, user_id) DO NOTHING
      `,
      args: [dealId, userId, Date.now()],
    });

    await refreshDealStatus(dealId);

    return sendJson(res, 200, { message: 'Joined deal.' });
  }

  if (action === 'leaveDeal') {
    const dealId = String(body.dealId || '').trim();
    const userId = String(body.userId || authUid).trim();

    if (!dealId || !userId) {
      return sendJson(res, 400, { error: 'dealId and userId are required.' });
    }

    if (!ensureSelf(res, authUid, userId)) {
      return;
    }

    await db.execute({
      sql: 'DELETE FROM deal_participants WHERE deal_id = ? AND user_id = ?',
      args: [dealId, userId],
    });

    await refreshDealStatus(dealId);

    return sendJson(res, 200, { message: 'Left deal.' });
  }

  return sendJson(res, 400, { error: 'Unsupported marketplace action.' });
}
