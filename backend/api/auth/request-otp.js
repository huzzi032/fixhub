import crypto from 'node:crypto';

import { db, ensureSchema } from '../../lib/db.js';
import { methodNotAllowed, readJsonBody, sendJson } from '../../lib/http.js';

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return methodNotAllowed(res, 'POST');
  }

  await ensureSchema();

  const body = readJsonBody(req);
  const phoneNumber = String(body.phoneNumber || '').trim();

  if (!phoneNumber) {
    return sendJson(res, 400, {
      error: 'phoneNumber is required.',
    });
  }

  const verificationId = crypto.randomUUID();
  const otpCode =
    process.env.FIXHUB_DEV_OTP || String(Math.floor(100000 + Math.random() * 900000));
  const now = Date.now();
  const expiresAt = now + 5 * 60 * 1000;

  await db.execute({
    sql: 'DELETE FROM otp_codes WHERE phone = ?',
    args: [phoneNumber],
  });

  await db.execute({
    sql: `
      INSERT INTO otp_codes(verification_id, phone, otp_code, expires_at, created_at)
      VALUES (?, ?, ?, ?, ?)
    `,
    args: [verificationId, phoneNumber, otpCode, expiresAt, now],
  });

  return sendJson(res, 200, {
    verificationId,
    expiresInSeconds: 300,
    devOtp: process.env.NODE_ENV === 'production' ? undefined : otpCode,
  });
}
