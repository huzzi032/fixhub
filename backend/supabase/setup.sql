-- FixHub Supabase initialization script
-- Run this once in Supabase SQL Editor for a clean setup.

CREATE TABLE IF NOT EXISTS auth_accounts (
  uid TEXT PRIMARY KEY,
  email TEXT UNIQUE,
  phone TEXT UNIQUE,
  display_name TEXT,
  password_hash TEXT,
  created_at BIGINT NOT NULL
);

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
);

CREATE TABLE IF NOT EXISTS customers (
  user_id TEXT PRIMARY KEY,
  saved_addresses TEXT NOT NULL DEFAULT '[]',
  loyalty_points INTEGER NOT NULL DEFAULT 0,
  total_orders_placed INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(uid) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS providers (
  user_id TEXT PRIMARY KEY,
  verification_status TEXT NOT NULL DEFAULT 'pending',
  wallet_balance INTEGER NOT NULL DEFAULT 0,
  earnings_total INTEGER NOT NULL DEFAULT 0,
  joined_at BIGINT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(uid) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS otp_codes (
  verification_id TEXT PRIMARY KEY,
  phone TEXT NOT NULL,
  otp_code TEXT NOT NULL,
  expires_at BIGINT NOT NULL,
  created_at BIGINT NOT NULL
);

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
);

CREATE TABLE IF NOT EXISTS provider_services (
  service_id TEXT PRIMARY KEY,
  provider_id TEXT,
  provider_name TEXT,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  min_price INTEGER NOT NULL DEFAULT 0,
  max_price INTEGER NOT NULL DEFAULT 0,
  rating REAL NOT NULL DEFAULT 0,
  review_count INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at BIGINT NOT NULL
);

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
);

CREATE TABLE IF NOT EXISTS deal_participants (
  deal_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  joined_at BIGINT NOT NULL,
  PRIMARY KEY (deal_id, user_id)
);

CREATE TABLE IF NOT EXISTS reviews (
  review_id TEXT PRIMARY KEY,
  booking_id TEXT NOT NULL,
  provider_id TEXT,
  customer_id TEXT NOT NULL,
  rating INTEGER NOT NULL,
  comment TEXT,
  created_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS booking_chat_messages (
  message_id TEXT PRIMARY KEY,
  booking_id TEXT NOT NULL,
  sender_id TEXT NOT NULL,
  sender_role TEXT NOT NULL,
  recipient_id TEXT,
  message_text TEXT NOT NULL,
  is_read INTEGER NOT NULL DEFAULT 0,
  sent_at BIGINT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_auth_accounts_email ON auth_accounts(email);
CREATE INDEX IF NOT EXISTS idx_auth_accounts_phone ON auth_accounts(phone);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_otp_codes_phone ON otp_codes(phone);
CREATE INDEX IF NOT EXISTS idx_bookings_customer_created ON bookings(customer_id, created_at);
CREATE INDEX IF NOT EXISTS idx_bookings_provider_created ON bookings(provider_id, created_at);
CREATE INDEX IF NOT EXISTS idx_chat_by_booking_sent_at ON booking_chat_messages(booking_id, sent_at);
