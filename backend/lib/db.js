import { createClient } from '@libsql/client';

const databaseUrl = process.env.DATABASE_URL || 'file:./dev.db';
const databaseAuthToken = process.env.DATABASE_AUTH_TOKEN;

export const db = createClient({
  url: databaseUrl,
  authToken: databaseAuthToken,
});

let schemaInitPromise;

export async function ensureSchema() {
  if (schemaInitPromise) {
    return schemaInitPromise;
  }

  schemaInitPromise = (async () => {
    await db.execute(`
      CREATE TABLE IF NOT EXISTS auth_accounts (
        uid TEXT PRIMARY KEY,
        email TEXT UNIQUE,
        phone TEXT UNIQUE,
        display_name TEXT,
        password_hash TEXT,
        created_at INTEGER NOT NULL
      )
    `);

    await db.execute(`
      CREATE TABLE IF NOT EXISTS users (
        uid TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL DEFAULT '',
        email TEXT,
        role TEXT NOT NULL DEFAULT 'customer',
        profile_photo_url TEXT,
        fcm_token TEXT,
        created_at INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    `);

    await db.execute(`
      CREATE TABLE IF NOT EXISTS customers (
        user_id TEXT PRIMARY KEY,
        saved_addresses TEXT NOT NULL DEFAULT '[]',
        loyalty_points INTEGER NOT NULL DEFAULT 0,
        total_orders_placed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(user_id) REFERENCES users(uid) ON DELETE CASCADE
      )
    `);

    await db.execute(`
      CREATE TABLE IF NOT EXISTS providers (
        user_id TEXT PRIMARY KEY,
        verification_status TEXT NOT NULL DEFAULT 'pending',
        wallet_balance INTEGER NOT NULL DEFAULT 0,
        earnings_total INTEGER NOT NULL DEFAULT 0,
        joined_at INTEGER NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(uid) ON DELETE CASCADE
      )
    `);

    await db.execute(`
      CREATE TABLE IF NOT EXISTS otp_codes (
        verification_id TEXT PRIMARY KEY,
        phone TEXT NOT NULL,
        otp_code TEXT NOT NULL,
        expires_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    `);
  })();

  return schemaInitPromise;
}
