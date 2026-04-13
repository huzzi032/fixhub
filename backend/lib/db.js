import { Pool } from 'pg';

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  throw new Error(
    'DATABASE_URL is required. Use your Supabase Postgres connection string.',
  );
}

const useSsl = String(process.env.DATABASE_SSL || 'true').toLowerCase() !== 'false';

const pool = new Pool({
  connectionString: databaseUrl,
  ssl: useSsl ? { rejectUnauthorized: false } : undefined,
  max: Number(process.env.DATABASE_POOL_MAX || 10),
});

function convertQuestionMarkParams(sql) {
  let index = 0;
  return sql.replace(/\?/g, () => `$${++index}`);
}

export const db = {
  async execute(input) {
    if (typeof input === 'string') {
      return pool.query(input);
    }

    const sql = String(input?.sql || '').trim();
    const args = Array.isArray(input?.args) ? input.args : [];

    if (!sql) {
      throw new Error('db.execute requires a non-empty SQL statement.');
    }

    const text = convertQuestionMarkParams(sql);
    return pool.query(text, args);
  },
};

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
        created_at BIGINT NOT NULL
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
        created_at BIGINT NOT NULL,
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
        joined_at BIGINT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(uid) ON DELETE CASCADE
      )
    `);

    await db.execute(`
      CREATE TABLE IF NOT EXISTS otp_codes (
        verification_id TEXT PRIMARY KEY,
        phone TEXT NOT NULL,
        otp_code TEXT NOT NULL,
        expires_at BIGINT NOT NULL,
        created_at BIGINT NOT NULL
      )
    `);

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_auth_accounts_email ON auth_accounts(email)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_auth_accounts_phone ON auth_accounts(phone)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_users_role ON users(role)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_otp_codes_phone ON otp_codes(phone)',
    );
  })();

  return schemaInitPromise;
}
