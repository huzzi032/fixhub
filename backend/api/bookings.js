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

function normalizeBookingRow(row) {
  return {
    booking_id: String(row.booking_id || ''),
    customer_id: String(row.customer_id || ''),
    provider_id: row.provider_id == null ? null : String(row.provider_id),
    service_id: row.service_id == null ? null : String(row.service_id),
    service_category: String(row.service_category || 'other'),
    issue_title: String(row.issue_title || ''),
    issue_description: String(row.issue_description || ''),
    address: String(row.address || ''),
    scheduled_at: toInt(row.scheduled_at),
    created_at: toInt(row.created_at),
    status: String(row.status || 'pending'),
    is_sos: toInt(row.is_sos),
    agreed_price: row.agreed_price == null ? null : toInt(row.agreed_price),
    payment_status: String(row.payment_status || 'pending'),
    provider_note: row.provider_note == null ? null : String(row.provider_note),
    customer_name: row.customer_name == null ? null : String(row.customer_name),
    provider_name: row.provider_name == null ? null : String(row.provider_name),
  };
}

function normalizeMessageRow(row) {
  return {
    message_id: String(row.message_id || ''),
    booking_id: String(row.booking_id || ''),
    sender_id: String(row.sender_id || ''),
    sender_role: String(row.sender_role || 'customer'),
    recipient_id: row.recipient_id == null ? null : String(row.recipient_id),
    message_text: String(row.message_text || ''),
    is_read: toInt(row.is_read),
    sent_at: toInt(row.sent_at),
  };
}

function requireSameUser(res, authUid, targetUid) {
  if (!targetUid || targetUid === authUid) {
    return true;
  }

  sendJson(res, 403, { error: 'Forbidden for current user.' });
  return false;
}

async function getBookingByIdInternal(bookingId) {
  const result = await db.execute({
    sql: 'SELECT * FROM bookings WHERE booking_id = ? LIMIT 1',
    args: [bookingId],
  });

  if (result.rows.length === 0) {
    return null;
  }

  return normalizeBookingRow(result.rows[0]);
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

    if (action === 'getById') {
      const bookingId = getQueryValue(req, 'bookingId');
      if (!bookingId) {
        return sendJson(res, 400, { error: 'bookingId is required.' });
      }

      const booking = await getBookingByIdInternal(bookingId);
      if (!booking) {
        return sendJson(res, 404, { error: 'Booking not found.' });
      }

      if (booking.customer_id !== authUid && booking.provider_id !== authUid) {
        return sendJson(res, 403, { error: 'Forbidden for current user.' });
      }

      return sendJson(res, 200, { booking });
    }

    if (action === 'getCustomerBookings') {
      const customerId = getQueryValue(req, 'customerId') || authUid;
      if (!requireSameUser(res, authUid, customerId)) {
        return;
      }

      const result = await db.execute({
        sql: 'SELECT * FROM bookings WHERE customer_id = ? ORDER BY created_at DESC',
        args: [customerId],
      });

      return sendJson(res, 200, {
        bookings: result.rows.map(normalizeBookingRow),
      });
    }

    if (action === 'getProviderActiveBookings') {
      const providerId = getQueryValue(req, 'providerId') || authUid;
      if (!requireSameUser(res, authUid, providerId)) {
        return;
      }

      const result = await db.execute({
        sql: `
          SELECT *
          FROM bookings
          WHERE provider_id = ? AND status IN ('accepted', 'enRoute', 'inProgress')
          ORDER BY created_at DESC
        `,
        args: [providerId],
      });

      return sendJson(res, 200, {
        bookings: result.rows.map(normalizeBookingRow),
      });
    }

    if (action === 'getProviderJobs') {
      const providerId = getQueryValue(req, 'providerId') || authUid;
      if (!requireSameUser(res, authUid, providerId)) {
        return;
      }

      const result = await db.execute({
        sql: 'SELECT * FROM bookings WHERE provider_id = ? ORDER BY created_at DESC',
        args: [providerId],
      });

      return sendJson(res, 200, {
        bookings: result.rows.map(normalizeBookingRow),
      });
    }

    if (action === 'getIncomingLeads') {
      const result = await db.execute({
        sql: `
          SELECT *
          FROM bookings
          WHERE provider_id IS NULL AND status = 'pending'
          ORDER BY created_at DESC
          LIMIT 20
        `,
      });

      return sendJson(res, 200, {
        bookings: result.rows.map(normalizeBookingRow),
      });
    }

    if (action === 'getProviderWalletBalance') {
      const providerId = getQueryValue(req, 'providerId') || authUid;
      if (!requireSameUser(res, authUid, providerId)) {
        return;
      }

      const result = await db.execute({
        sql: 'SELECT wallet_balance FROM providers WHERE user_id = ? LIMIT 1',
        args: [providerId],
      });

      const walletBalance =
        result.rows.length > 0 ? toInt(result.rows[0].wallet_balance) : 0;

      return sendJson(res, 200, { walletBalance });
    }

    if (action === 'getProviderEarnings') {
      const providerId = getQueryValue(req, 'providerId') || authUid;
      if (!requireSameUser(res, authUid, providerId)) {
        return;
      }

      const jobsResult = await db.execute({
        sql: 'SELECT status, agreed_price FROM bookings WHERE provider_id = ?',
        args: [providerId],
      });

      const walletResult = await db.execute({
        sql: 'SELECT wallet_balance FROM providers WHERE user_id = ? LIMIT 1',
        args: [providerId],
      });

      const jobs = jobsResult.rows;
      const walletBalance =
        walletResult.rows.length > 0
          ? toInt(walletResult.rows[0].wallet_balance)
          : 0;

      const totalEarned = jobs
        .filter((job) => String(job.status || '') === 'paid')
        .reduce((sum, job) => sum + toInt(job.agreed_price), 0);

      const pendingAmount = jobs
        .filter((job) => String(job.status || '') === 'completed')
        .reduce((sum, job) => sum + toInt(job.agreed_price), 0);

      const activeJobs = jobs.filter((job) => {
        const status = String(job.status || '');
        return (
          status === 'accepted' ||
          status === 'enRoute' ||
          status === 'inProgress'
        );
      }).length;

      const completedJobs = jobs.filter(
        (job) => String(job.status || '') === 'paid',
      ).length;

      return sendJson(res, 200, {
        summary: {
          totalEarned,
          pendingAmount,
          walletBalance,
          completedJobs,
          activeJobs,
        },
      });
    }

    if (action === 'getMessages') {
      const bookingId = getQueryValue(req, 'bookingId');
      if (!bookingId) {
        return sendJson(res, 400, { error: 'bookingId is required.' });
      }

      const booking = await getBookingByIdInternal(bookingId);
      if (!booking) {
        return sendJson(res, 404, { error: 'Booking not found.' });
      }

      if (booking.customer_id !== authUid && booking.provider_id !== authUid) {
        return sendJson(res, 403, { error: 'Forbidden for current user.' });
      }

      const result = await db.execute({
        sql: 'SELECT * FROM booking_chat_messages WHERE booking_id = ? ORDER BY sent_at ASC',
        args: [bookingId],
      });

      return sendJson(res, 200, {
        messages: result.rows.map(normalizeMessageRow),
      });
    }

    return sendJson(res, 400, { error: 'Unsupported bookings action.' });
  }

  const body = readJsonBody(req);
  const action = String(body.action || '').trim();

  if (action === 'createBooking') {
    const bookingId = crypto.randomUUID();
    const customerId = String(body.customerId || authUid).trim();
    const serviceCategory = String(body.serviceCategory || '').trim();
    const issueTitle = String(body.issueTitle || '').trim();
    const issueDescription = String(body.issueDescription || '').trim();
    const address = String(body.address || '').trim();
    const scheduledAt = toInt(body.scheduledAt);
    const serviceId = body.serviceId == null ? null : String(body.serviceId);
    const customerName =
      body.customerName == null ? null : String(body.customerName);
    const isSos = Boolean(body.isSOS);

    if (!requireSameUser(res, authUid, customerId)) {
      return;
    }

    if (
      !serviceCategory ||
      !issueTitle ||
      !issueDescription ||
      !address ||
      !scheduledAt
    ) {
      return sendJson(res, 400, {
        error:
          'customerId, serviceCategory, issueTitle, issueDescription, address and scheduledAt are required.',
      });
    }

    await db.execute({
      sql: `
        INSERT INTO bookings(
          booking_id, customer_id, provider_id, service_id, service_category,
          issue_title, issue_description, address, scheduled_at, created_at,
          status, is_sos, agreed_price, payment_status, provider_note,
          customer_name, provider_name
        ) VALUES (?, ?, NULL, ?, ?, ?, ?, ?, ?, ?, 'pending', ?, NULL, 'pending', NULL, ?, NULL)
      `,
      args: [
        bookingId,
        customerId,
        serviceId,
        serviceCategory,
        issueTitle,
        issueDescription,
        address,
        scheduledAt,
        Date.now(),
        isSos ? 1 : 0,
        customerName,
      ],
    });

    return sendJson(res, 200, { bookingId });
  }

  if (action === 'acceptLead') {
    const bookingId = String(body.bookingId || '').trim();
    const providerId = String(body.providerId || authUid).trim();
    const providerName = String(body.providerName || '').trim();
    const quoteAmount = toInt(body.quoteAmount);
    const providerNote =
      body.providerNote == null ? null : String(body.providerNote);

    if (!bookingId || !providerId || !providerName || quoteAmount <= 0) {
      return sendJson(res, 400, {
        error:
          'bookingId, providerId, providerName and quoteAmount are required.',
      });
    }

    if (!requireSameUser(res, authUid, providerId)) {
      return;
    }

    await db.execute({
      sql: `
        UPDATE bookings
        SET provider_id = ?,
            provider_name = ?,
            agreed_price = ?,
            provider_note = ?,
            status = 'accepted'
        WHERE booking_id = ?
      `,
      args: [providerId, providerName, quoteAmount, providerNote, bookingId],
    });

    return sendJson(res, 200, { message: 'Lead accepted.' });
  }

  if (action === 'updateBookingStatus') {
    const bookingId = String(body.bookingId || '').trim();
    const status = String(body.status || '').trim();

    if (!bookingId || !status) {
      return sendJson(res, 400, { error: 'bookingId and status are required.' });
    }

    const booking = await getBookingByIdInternal(bookingId);
    if (!booking) {
      return sendJson(res, 404, { error: 'Booking not found.' });
    }

    if (booking.customer_id !== authUid && booking.provider_id !== authUid) {
      return sendJson(res, 403, { error: 'Forbidden for current user.' });
    }

    await db.execute({
      sql: 'UPDATE bookings SET status = ? WHERE booking_id = ?',
      args: [status, bookingId],
    });

    return sendJson(res, 200, { message: 'Booking status updated.' });
  }

  if (action === 'markPaymentCollected') {
    const bookingId = String(body.bookingId || '').trim();
    if (!bookingId) {
      return sendJson(res, 400, { error: 'bookingId is required.' });
    }

    const booking = await getBookingByIdInternal(bookingId);
    if (!booking) {
      return sendJson(res, 404, { error: 'Booking not found.' });
    }

    if (booking.customer_id !== authUid && booking.provider_id !== authUid) {
      return sendJson(res, 403, { error: 'Forbidden for current user.' });
    }

    await db.execute({
      sql: `
        UPDATE bookings
        SET status = 'paid', payment_status = 'collected'
        WHERE booking_id = ?
      `,
      args: [bookingId],
    });

    const providerId = booking.provider_id;
    const amount = booking.agreed_price == null ? 0 : toInt(booking.agreed_price);

    if (providerId && amount > 0) {
      await db.execute({
        sql: `
          INSERT INTO providers(user_id, verification_status, wallet_balance, earnings_total, joined_at)
          VALUES (?, 'pending', 0, 0, ?)
          ON CONFLICT (user_id) DO NOTHING
        `,
        args: [providerId, Date.now()],
      });

      await db.execute({
        sql: `
          UPDATE providers
          SET wallet_balance = wallet_balance + ?,
              earnings_total = earnings_total + ?
          WHERE user_id = ?
        `,
        args: [amount, amount, providerId],
      });
    }

    return sendJson(res, 200, { message: 'Payment marked as collected.' });
  }

  if (action === 'topUpWallet') {
    const providerId = String(body.providerId || authUid).trim();
    const amount = toInt(body.amount);

    if (!providerId || amount <= 0) {
      return sendJson(res, 400, {
        error: 'providerId and positive amount are required.',
      });
    }

    if (!requireSameUser(res, authUid, providerId)) {
      return;
    }

    await db.execute({
      sql: `
        INSERT INTO providers(user_id, verification_status, wallet_balance, earnings_total, joined_at)
        VALUES (?, 'pending', 0, 0, ?)
        ON CONFLICT (user_id) DO NOTHING
      `,
      args: [providerId, Date.now()],
    });

    await db.execute({
      sql: 'UPDATE providers SET wallet_balance = wallet_balance + ? WHERE user_id = ?',
      args: [amount, providerId],
    });

    return sendJson(res, 200, { message: 'Wallet topped up.' });
  }

  if (action === 'submitReview') {
    const bookingId = String(body.bookingId || '').trim();
    const providerId = String(body.providerId || '').trim();
    const customerId = String(body.customerId || authUid).trim();
    const rating = toInt(body.rating);
    const comment = body.comment == null ? null : String(body.comment).trim();

    if (!bookingId || !providerId || !customerId || rating < 1 || rating > 5) {
      return sendJson(res, 400, {
        error: 'bookingId, providerId, customerId and rating (1-5) are required.',
      });
    }

    if (!requireSameUser(res, authUid, customerId)) {
      return;
    }

    await db.execute({
      sql: `
        INSERT INTO reviews(review_id, booking_id, provider_id, customer_id, rating, comment, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `,
      args: [
        crypto.randomUUID(),
        bookingId,
        providerId,
        customerId,
        rating,
        comment,
        Date.now(),
      ],
    });

    const ratingRow = await db.execute({
      sql: `
        SELECT AVG(rating)::FLOAT AS avg_rating, COUNT(*)::INT AS total_count
        FROM reviews
        WHERE provider_id = ?
      `,
      args: [providerId],
    });

    const avg = Number(ratingRow.rows[0]?.avg_rating || 0);
    const count = toInt(ratingRow.rows[0]?.total_count || 0);

    await db.execute({
      sql: `
        UPDATE provider_services
        SET rating = ?, review_count = ?
        WHERE provider_id = ?
      `,
      args: [avg, count, providerId],
    });

    return sendJson(res, 200, { message: 'Review submitted.' });
  }

  if (action === 'sendMessage') {
    const bookingId = String(body.bookingId || '').trim();
    const senderId = String(body.senderId || authUid).trim();
    const text = String(body.message || '').trim();

    if (!bookingId || !senderId || !text) {
      return sendJson(res, 400, {
        error: 'bookingId, senderId and message are required.',
      });
    }

    if (!requireSameUser(res, authUid, senderId)) {
      return;
    }

    if (text.length > 500) {
      return sendJson(res, 400, { error: 'Message is too long.' });
    }

    const booking = await getBookingByIdInternal(bookingId);
    if (!booking) {
      return sendJson(res, 404, { error: 'Booking not found.' });
    }

    const isCustomer = senderId === booking.customer_id;
    const isAssignedProvider =
      booking.provider_id != null && senderId === booking.provider_id;

    if (!isCustomer && !isAssignedProvider) {
      return sendJson(res, 403, {
        error: 'User is not allowed to chat for this booking.',
      });
    }

    const senderRole = isCustomer ? 'customer' : 'provider';
    const recipientId = isCustomer ? booking.provider_id : booking.customer_id;

    await db.execute({
      sql: `
        INSERT INTO booking_chat_messages(
          message_id, booking_id, sender_id, sender_role,
          recipient_id, message_text, is_read, sent_at
        ) VALUES (?, ?, ?, ?, ?, ?, 0, ?)
      `,
      args: [
        crypto.randomUUID(),
        bookingId,
        senderId,
        senderRole,
        recipientId,
        text,
        Date.now(),
      ],
    });

    return sendJson(res, 200, { message: 'Message sent.' });
  }

  if (action === 'markMessagesRead') {
    const bookingId = String(body.bookingId || '').trim();
    const viewerId = String(body.viewerId || authUid).trim();

    if (!bookingId || !viewerId) {
      return sendJson(res, 400, { error: 'bookingId and viewerId are required.' });
    }

    if (!requireSameUser(res, authUid, viewerId)) {
      return;
    }

    await db.execute({
      sql: `
        UPDATE booking_chat_messages
        SET is_read = 1
        WHERE booking_id = ? AND recipient_id = ? AND is_read = 0
      `,
      args: [bookingId, viewerId],
    });

    return sendJson(res, 200, { message: 'Messages marked as read.' });
  }

  return sendJson(res, 400, { error: 'Unsupported bookings action.' });
}
