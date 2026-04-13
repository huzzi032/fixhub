import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _databaseName = 'fixhub.db';
  static const int _databaseVersion = 4;

  Database? _database;

  Future<void> initialize() async {
    await database;
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final databasesPath = await getDatabasesPath();
    final databasePath = p.join(databasesPath, _databaseName);

    _database = await openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );

    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE auth_accounts (
        uid TEXT PRIMARY KEY,
        email TEXT UNIQUE,
        phone TEXT UNIQUE,
        display_name TEXT,
        password_hash TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
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
    ''');

    await db.execute('''
      CREATE TABLE customers (
        user_id TEXT PRIMARY KEY,
        saved_addresses TEXT NOT NULL DEFAULT '[]',
        loyalty_points INTEGER NOT NULL DEFAULT 0,
        total_orders_placed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(user_id) REFERENCES users(uid) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE providers (
        user_id TEXT PRIMARY KEY,
        verification_status TEXT NOT NULL DEFAULT 'pending',
        wallet_balance INTEGER NOT NULL DEFAULT 0,
        earnings_total INTEGER NOT NULL DEFAULT 0,
        joined_at INTEGER NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(uid) ON DELETE CASCADE
      )
    ''');

    await _createBookingsTable(db);
    await _createProviderServicesTable(db);
    await _createNeighborhoodDealsTables(db);
    await _createReviewsTable(db);
    await _createChatTables(db);
    await _seedDefaultMarketplaceData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createBookingsTable(db);
    }

    if (oldVersion < 3) {
      await _ensureBookingsColumns(db);
      await _createProviderServicesTable(db);
      await _createNeighborhoodDealsTables(db);
      await _createReviewsTable(db);
      await _seedDefaultMarketplaceData(db);
    }

    if (oldVersion < 4) {
      await _createChatTables(db);
    }
  }

  Future<void> _ensureBookingsColumns(Database db) async {
    final tableInfo = await db.rawQuery('PRAGMA table_info(bookings)');
    final existingColumns =
        tableInfo.map((row) => (row['name'] as String?) ?? '').toSet();

    if (!existingColumns.contains('is_sos')) {
      await db.execute(
        'ALTER TABLE bookings ADD COLUMN is_sos INTEGER NOT NULL DEFAULT 0',
      );
    }

    if (!existingColumns.contains('provider_note')) {
      await db.execute('ALTER TABLE bookings ADD COLUMN provider_note TEXT');
    }
  }

  Future<void> _createBookingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bookings (
        booking_id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        provider_id TEXT,
        service_id TEXT,
        service_category TEXT NOT NULL,
        issue_title TEXT NOT NULL,
        issue_description TEXT NOT NULL,
        address TEXT NOT NULL,
        scheduled_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        is_sos INTEGER NOT NULL DEFAULT 0,
        agreed_price INTEGER,
        payment_status TEXT NOT NULL DEFAULT 'pending',
        provider_note TEXT,
        customer_name TEXT,
        provider_name TEXT
      )
    ''');
  }

  Future<void> _createProviderServicesTable(Database db) async {
    await db.execute('''
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
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createNeighborhoodDealsTables(Database db) async {
    await db.execute('''
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
        created_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS deal_participants (
        deal_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        joined_at INTEGER NOT NULL,
        PRIMARY KEY (deal_id, user_id)
      )
    ''');
  }

  Future<void> _createReviewsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reviews (
        review_id TEXT PRIMARY KEY,
        booking_id TEXT NOT NULL,
        provider_id TEXT,
        customer_id TEXT NOT NULL,
        rating INTEGER NOT NULL,
        comment TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createChatTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS booking_chat_messages (
        message_id TEXT PRIMARY KEY,
        booking_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        sender_role TEXT NOT NULL,
        recipient_id TEXT,
        message_text TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        sent_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_chat_by_booking_sent_at
      ON booking_chat_messages (booking_id, sent_at)
    ''');
  }

  Future<void> _seedDefaultMarketplaceData(Database db) async {
    final serviceCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM provider_services'),
    );

    if ((serviceCount ?? 0) == 0) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final seedServices = <Map<String, Object?>>[
        <String, Object?>{
          'service_id': 'service_plumber_1',
          'provider_id': 'provider_seed_1',
          'provider_name': 'Ali Khan',
          'title': 'Professional Plumbing Services',
          'description':
              'Leak repairs, fixture replacement and pipe maintenance for home plumbing.',
          'category': 'plumber',
          'min_price': 500,
          'max_price': 2000,
          'rating': 4.5,
          'review_count': 38,
          'is_active': 1,
          'created_at': now,
        },
        <String, Object?>{
          'service_id': 'service_electrician_1',
          'provider_id': 'provider_seed_2',
          'provider_name': 'Usman Raza',
          'title': 'Home Electrical Repair',
          'description':
              'Wiring fixes, switch board replacement and emergency fault diagnosis.',
          'category': 'electrician',
          'min_price': 700,
          'max_price': 3000,
          'rating': 4.7,
          'review_count': 52,
          'is_active': 1,
          'created_at': now,
        },
        <String, Object?>{
          'service_id': 'service_ac_1',
          'provider_id': 'provider_seed_3',
          'provider_name': 'Hamza Arif',
          'title': 'AC Repair and Gas Refill',
          'description':
              'AC diagnostic, cleaning, gas top-up and compressor troubleshooting.',
          'category': 'ac_repair',
          'min_price': 1200,
          'max_price': 4500,
          'rating': 4.3,
          'review_count': 27,
          'is_active': 1,
          'created_at': now,
        },
        <String, Object?>{
          'service_id': 'service_cleaning_1',
          'provider_id': 'provider_seed_4',
          'provider_name': 'Sara Services',
          'title': 'Deep Cleaning for Home',
          'description':
              'Kitchen, bathroom and floor deep cleaning with professional equipment.',
          'category': 'cleaning',
          'min_price': 1500,
          'max_price': 5000,
          'rating': 4.8,
          'review_count': 61,
          'is_active': 1,
          'created_at': now,
        },
      ];

      for (final service in seedServices) {
        await db.insert('provider_services', service);
      }
    }

    final dealsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM neighborhood_deals'),
    );

    if ((dealsCount ?? 0) == 0) {
      final now = DateTime.now();
      final seedDeals = <Map<String, Object?>>[
        <String, Object?>{
          'deal_id': 'deal_plumber_gulshan',
          'service_category': 'plumber',
          'area': 'Gulshan-e-Iqbal',
          'city': 'Karachi',
          'description': 'Group discount for kitchen and bathroom plumbing.',
          'min_participants': 10,
          'max_participants': 20,
          'discount_percent': 20,
          'created_by': null,
          'status': 'open',
          'created_at': now.millisecondsSinceEpoch,
          'expires_at': now.add(const Duration(days: 7)).millisecondsSinceEpoch,
        },
        <String, Object?>{
          'deal_id': 'deal_ac_johar',
          'service_category': 'ac_repair',
          'area': 'Johar Town',
          'city': 'Lahore',
          'description': 'Seasonal AC service package for your block.',
          'min_participants': 8,
          'max_participants': 15,
          'discount_percent': 15,
          'created_by': null,
          'status': 'open',
          'created_at': now.millisecondsSinceEpoch,
          'expires_at': now.add(const Duration(days: 5)).millisecondsSinceEpoch,
        },
        <String, Object?>{
          'deal_id': 'deal_cleaning_dha',
          'service_category': 'cleaning',
          'area': 'DHA Phase 5',
          'city': 'Karachi',
          'description': 'Deep cleaning discount for apartments in your lane.',
          'min_participants': 6,
          'max_participants': 12,
          'discount_percent': 18,
          'created_by': null,
          'status': 'open',
          'created_at': now.millisecondsSinceEpoch,
          'expires_at': now.add(const Duration(days: 6)).millisecondsSinceEpoch,
        },
      ];

      for (final deal in seedDeals) {
        await db.insert('neighborhood_deals', deal);
      }
    }
  }
}
