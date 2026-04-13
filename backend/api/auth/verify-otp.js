import crypto from 'node:crypto';

import { createAccessToken } from '../../lib/auth.js';
import { db, ensureSchema } from '../../lib/db.js';
import { methodNotAllowed, readJsonBody, sendJson } from '../../lib/http.js';

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return methodNotAllowed(res, 'POST');
  }

  await ensureSchema();

  const body = readJsonBody(req);
  const verificationId = String(body.verificationId || '').trim();
  const otp = String(body.otp || '').trim();

  if (!verificationId || !otp) {
    return sendJson(res, 400, {
      error: 'verificationId and otp are required.',
    });
  }

  const otpResult = await db.execute({
    sql: `
      SELECT verification_id, phone, otp_code, expires_at
      FROM otp_codes
      WHERE verification_id = ?
      LIMIT 1
    `,
    args: [verificationId],
  });

  if (otpResult.rows.length === 0) {
    return sendJson(res, 400, {
      error: 'Invalid verification. Please request a new OTP.',
    });
  }

  const otpRow = otpResult.rows[0];

  if (Number(otpRow.expires_at) < Date.now()) {
    await db.execute({
      sql: 'DELETE FROM otp_codes WHERE verification_id = ?',
      args: [verificationId],
    });

    return sendJson(res, 400, {
      error: 'OTP has expired. Please request a new one.',
    });
  }

  if (String(otpRow.otp_code) != otp) {
    return sendJson(res, 400, {
      error: 'Invalid OTP. Please try again.',
    });
  }

  const phoneNumber = String(otpRow.phone);

  await db.execute({
    sql: 'DELETE FROM otp_codes WHERE verification_id = ?',
    args: [verificationId],
  });

  const existing = await db.execute({
    sql: `
      SELECT uid, email, phone, display_name
      FROM auth_accounts
      WHERE phone = ?
      LIMIT 1
    `,
    args: [phoneNumber],
  });

  let uid;
  let email = null;
  let displayName = null;

  if (existing.rows.length > 0) {
    const row = existing.rows[0];
    uid = String(row.uid);
    email = row.email ? String(row.email) : null;
    displayName = row.display_name ? String(row.display_name) : null;
  } else {
    uid = crypto.randomUUID();

    await db.execute({
      sql: `
        INSERT INTO auth_accounts(uid, email, phone, display_name, password_hash, created_at)
        VALUES (?, NULL, ?, NULL, NULL, ?)
      `,
      args: [uid, phoneNumber, Date.now()],
    });
  }

  const token = createAccessToken(uid);

  return sendJson(res, 200, {
    token,
    user: {
      uid,
      email,
      phoneNumber,
      displayName,
    },
  });
}
