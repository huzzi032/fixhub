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
        bio TEXT NOT NULL DEFAULT '',
        skills TEXT NOT NULL DEFAULT '[]',
        service_cities TEXT NOT NULL DEFAULT '[]',
        hourly_rate_min INTEGER,
        hourly_rate_max INTEGER,
        wallet_balance INTEGER NOT NULL DEFAULT 0,
        earnings_total INTEGER NOT NULL DEFAULT 0,
        joined_at BIGINT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(uid) ON DELETE CASCADE
      )
    `);

    await db.execute(
      "ALTER TABLE providers ADD COLUMN IF NOT EXISTS bio TEXT NOT NULL DEFAULT ''",
    );
    await db.execute(
      "ALTER TABLE providers ADD COLUMN IF NOT EXISTS skills TEXT NOT NULL DEFAULT '[]'",
    );
    await db.execute(
      "ALTER TABLE providers ADD COLUMN IF NOT EXISTS service_cities TEXT NOT NULL DEFAULT '[]'",
    );
    await db.execute(
      'ALTER TABLE providers ADD COLUMN IF NOT EXISTS hourly_rate_min INTEGER',
    );
    await db.execute(
      'ALTER TABLE providers ADD COLUMN IF NOT EXISTS hourly_rate_max INTEGER',
    );

    await db.execute(`
      CREATE TABLE IF NOT EXISTS otp_codes (
        verification_id TEXT PRIMARY KEY,
        phone TEXT NOT NULL,
        otp_code TEXT NOT NULL,
        expires_at BIGINT NOT NULL,
        created_at BIGINT NOT NULL
      )
    `);

    await db.execute(`
      CREATE TABLE IF NOT EXISTS bookings (
        booking_id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        provider_id TEXT,
        service_id TEXT,
        service_category TEXT NOT NULL,
        issue_title TEXT NOT NULL,
        issue_description TEXT NOT NULL,
        address TEXT NOT NULL,
        scheduled_at BIGINT NOT NULL,
        created_at BIGINT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        is_sos INTEGER NOT NULL DEFAULT 0,
        agreed_price INTEGER,
        payment_status TEXT NOT NULL DEFAULT 'pending',
        provider_note TEXT,
        customer_name TEXT,
        provider_name TEXT
      )
    `);

    await db.execute(`
      CREATE TABLE IF NOT EXISTS provider_services (
        service_id TEXT PRIMARY KEY,
        provider_id TEXT,
        provider_name TEXT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        image_urls TEXT NOT NULL DEFAULT '[]',
        min_price INTEGER NOT NULL DEFAULT 0,
        max_price INTEGER NOT NULL DEFAULT 0,
        rating REAL NOT NULL DEFAULT 0,
        review_count INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at BIGINT NOT NULL
      )
    `);

    await db.execute(
      "ALTER TABLE provider_services ADD COLUMN IF NOT EXISTS image_urls TEXT NOT NULL DEFAULT '[]'",
    );

    await db.execute(`
      CREATE TABLE IF NOT EXISTS neighborhood_deals (
        deal_id TEXT PRIMARY KEY,
        service_category TEXT NOT NULL,
        area TEXT NOT NULL,
        city TEXT NOT NULL,
        description TEXT NOT NULL,
        min_participants INTEGER NOT NULL,
        max_participants INTEGER,
        discount_percent INTEGER NOT NULL,
        created_by TEXT,
        status TEXT NOT NULL DEFAULT 'open',
        created_at BIGINT NOT NULL,
        expires_at BIGINT NOT NULL
      )
    `);

    await db.execute(`
      CREATE TABLE IF NOT EXISTS deal_participants (
        deal_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        joined_at BIGINT NOT NULL,
        PRIMARY KEY (deal_id, user_id)
      )
    `);

    await db.execute(`
      CREATE TABLE IF NOT EXISTS reviews (
        review_id TEXT PRIMARY KEY,
        booking_id TEXT NOT NULL,
        provider_id TEXT,
        customer_id TEXT NOT NULL,
        rating INTEGER NOT NULL,
        comment TEXT,
        created_at BIGINT NOT NULL
      )
    `);

    await db.execute(`
      CREATE TABLE IF NOT EXISTS booking_chat_messages (
        message_id TEXT PRIMARY KEY,
        booking_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        sender_role TEXT NOT NULL,
        recipient_id TEXT,
        message_text TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        sent_at BIGINT NOT NULL
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
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_bookings_customer_created ON bookings(customer_id, created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_bookings_provider_created ON bookings(provider_id, created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_chat_by_booking_sent_at ON booking_chat_messages(booking_id, sent_at)',
    );

    const serviceCountResult = await db.execute(
      'SELECT COUNT(*)::INT AS count FROM provider_services',
    );
    const serviceCount = Number(serviceCountResult.rows[0]?.count || 0);

    if (serviceCount === 0) {
      const now = Date.now();
      const seedServices = [
        {
          serviceId: 'service_plumber_1',
          providerId: 'provider_seed_1',
          providerName: 'Ali Khan',
          title: 'Professional Plumbing Services',
          description:
            'Leak repairs, fixture replacement and pipe maintenance for home plumbing.',
          category: 'plumber',
          minPrice: 500,
          maxPrice: 2000,
          rating: 4.5,
          reviewCount: 38,
        },
        {
          serviceId: 'service_electrician_1',
          providerId: 'provider_seed_2',
          providerName: 'Usman Raza',
          title: 'Home Electrical Repair',
          description:
            'Wiring fixes, switch board replacement and emergency fault diagnosis.',
          category: 'electrician',
          minPrice: 700,
          maxPrice: 3000,
          rating: 4.7,
          reviewCount: 52,
        },
        {
          serviceId: 'service_ac_1',
          providerId: 'provider_seed_3',
          providerName: 'Hamza Arif',
          title: 'AC Repair and Gas Refill',
          description:
            'AC diagnostic, cleaning, gas top-up and compressor troubleshooting.',
          category: 'ac_repair',
          minPrice: 1200,
          maxPrice: 4500,
          rating: 4.3,
          reviewCount: 27,
        },
        {
          serviceId: 'service_cleaning_1',
          providerId: 'provider_seed_4',
          providerName: 'Sara Services',
          title: 'Deep Cleaning for Home',
          description:
            'Kitchen, bathroom and floor deep cleaning with professional equipment.',
          category: 'cleaning',
          minPrice: 1500,
          maxPrice: 5000,
          rating: 4.8,
          reviewCount: 61,
        },
      ];

      for (const service of seedServices) {
        await db.execute({
          sql: `
            INSERT INTO provider_services(
              service_id, provider_id, provider_name, title, description, category,
              min_price, max_price, rating, review_count, is_active, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
            ON CONFLICT (service_id) DO NOTHING
          `,
          args: [
            service.serviceId,
            service.providerId,
            service.providerName,
            service.title,
            service.description,
            service.category,
            service.minPrice,
            service.maxPrice,
            service.rating,
            service.reviewCount,
            now,
          ],
        });
      }
    }

    const dealsCountResult = await db.execute(
      'SELECT COUNT(*)::INT AS count FROM neighborhood_deals',
    );
    const dealsCount = Number(dealsCountResult.rows[0]?.count || 0);

    if (dealsCount === 0) {
      const now = Date.now();
      const seedDeals = [
        {
          dealId: 'deal_plumber_gulshan',
          serviceCategory: 'plumber',
          area: 'Gulshan-e-Iqbal',
          city: 'Karachi',
          description: 'Group discount for kitchen and bathroom plumbing.',
          minParticipants: 10,
          maxParticipants: 20,
          discountPercent: 20,
          expiresAt: now + 7 * 24 * 60 * 60 * 1000,
        },
        {
          dealId: 'deal_ac_johar',
          serviceCategory: 'ac_repair',
          area: 'Johar Town',
          city: 'Lahore',
          description: 'Seasonal AC service package for your block.',
          minParticipants: 8,
          maxParticipants: 15,
          discountPercent: 15,
          expiresAt: now + 5 * 24 * 60 * 60 * 1000,
        },
        {
          dealId: 'deal_cleaning_dha',
          serviceCategory: 'cleaning',
          area: 'DHA Phase 5',
          city: 'Karachi',
          description: 'Deep cleaning discount for apartments in your lane.',
          minParticipants: 6,
          maxParticipants: 12,
          discountPercent: 18,
          expiresAt: now + 6 * 24 * 60 * 60 * 1000,
        },
      ];

      for (const deal of seedDeals) {
        await db.execute({
          sql: `
            INSERT INTO neighborhood_deals(
              deal_id, service_category, area, city, description,
              min_participants, max_participants, discount_percent,
              created_by, status, created_at, expires_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NULL, 'open', ?, ?)
            ON CONFLICT (deal_id) DO NOTHING
          `,
          args: [
            deal.dealId,
            deal.serviceCategory,
            deal.area,
            deal.city,
            deal.description,
            deal.minParticipants,
            deal.maxParticipants,
            deal.discountPercent,
            now,
            deal.expiresAt,
          ],
        });
      }
    }
  })();

  return schemaInitPromise;
}
