import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';
import 'app_database.dart';

class LocalMarketplaceService {
  LocalMarketplaceService._();

  static final LocalMarketplaceService instance = LocalMarketplaceService._();

  Future<List<MarketplaceServiceItem>> searchServices({
    String query = '',
    Set<String> categories = const <String>{},
    int minPrice = 0,
    int maxPrice = 5000,
    double minRating = 0,
    String sortBy = 'nearest',
  }) async {
    final db = await AppDatabase.instance.database;

    final normalizedCategories = categories
        .map(_normalizeCategory)
        .where((element) => element.isNotEmpty)
        .toSet();

    final whereClauses = <String>['is_active = 1'];
    final whereArgs = <Object>[];

    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isNotEmpty) {
      whereClauses.add(
        '(LOWER(title) LIKE ? OR LOWER(description) LIKE ? OR LOWER(provider_name) LIKE ? OR LOWER(category) LIKE ?)',
      );
      final like = '%$normalizedQuery%';
      whereArgs
        ..add(like)
        ..add(like)
        ..add(like)
        ..add(like);
    }

    if (normalizedCategories.isNotEmpty) {
      final placeholders =
          List<String>.filled(normalizedCategories.length, '?');
      whereClauses.add('category IN (${placeholders.join(',')})');
      whereArgs.addAll(normalizedCategories);
    }

    whereClauses.add('max_price >= ?');
    whereArgs.add(minPrice);
    whereClauses.add('min_price <= ?');
    whereArgs.add(maxPrice);

    whereClauses.add('rating >= ?');
    whereArgs.add(minRating);

    final orderBy = switch (sortBy) {
      'rating' => 'rating DESC, review_count DESC',
      'price_low' => 'min_price ASC',
      'price_high' => 'max_price DESC',
      _ => 'created_at DESC',
    };

    final rows = await db.query(
      'provider_services',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: orderBy,
    );

    return rows.map(_mapServiceRow).toList();
  }

  Future<List<MarketplaceServiceItem>> getServicesByCategory(
    String category,
  ) async {
    return searchServices(categories: <String>{category});
  }

  Future<List<MarketplaceServiceItem>> getProviderServices(
      String providerId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'provider_services',
      where: 'provider_id = ?',
      whereArgs: <Object>[providerId],
      orderBy: 'created_at DESC',
    );

    return rows.map(_mapServiceRow).toList();
  }

  Future<MarketplaceServiceItem?> getServiceById(String serviceId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'provider_services',
      where: 'service_id = ?',
      whereArgs: <Object>[serviceId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _mapServiceRow(rows.first);
  }

  Future<String> saveProviderService({
    String? serviceId,
    required String providerId,
    required String providerName,
    required String title,
    required String description,
    required String category,
    required int minPrice,
    required int maxPrice,
    bool isActive = true,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = serviceId ?? const Uuid().v4();

    await db.insert(
      'provider_services',
      <String, Object?>{
        'service_id': id,
        'provider_id': providerId,
        'provider_name': providerName,
        'title': title,
        'description': description,
        'category': _normalizeCategory(category),
        'min_price': minPrice,
        'max_price': maxPrice,
        'rating': 4.0,
        'review_count': 0,
        'is_active': isActive ? 1 : 0,
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return id;
  }

  Future<void> setServiceActive(String serviceId, bool isActive) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'provider_services',
      <String, Object?>{'is_active': isActive ? 1 : 0},
      where: 'service_id = ?',
      whereArgs: <Object>[serviceId],
    );
  }

  Future<void> deleteService(String serviceId) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'provider_services',
      where: 'service_id = ?',
      whereArgs: <Object>[serviceId],
    );
  }

  Future<List<NeighborhoodDealItem>> getDeals({
    String? userId,
    String? city,
    String? area,
  }) async {
    final db = await AppDatabase.instance.database;

    final whereClauses = <String>['d.status = ?'];
    final whereArgs = <Object>['open'];

    if (city != null && city.trim().isNotEmpty) {
      whereClauses.add('LOWER(d.city) = ?');
      whereArgs.add(city.trim().toLowerCase());
    }

    if (area != null && area.trim().isNotEmpty) {
      whereClauses.add('LOWER(d.area) LIKE ?');
      whereArgs.add('%${area.trim().toLowerCase()}%');
    }

    final joinUser = userId ?? '';

    final rows = await db.rawQuery(
      '''
      SELECT
        d.*,
        creator.name AS created_by_name,
        COUNT(p.user_id) AS participants_count,
        MAX(CASE WHEN p.user_id = ? THEN 1 ELSE 0 END) AS has_joined
      FROM neighborhood_deals d
      LEFT JOIN deal_participants p ON p.deal_id = d.deal_id
      LEFT JOIN users creator ON creator.uid = d.created_by
      WHERE ${whereClauses.join(' AND ')}
      GROUP BY d.deal_id
      ORDER BY d.created_at DESC
      ''',
      <Object>[joinUser, ...whereArgs],
    );

    return rows.map(_mapDealRow).toList();
  }

  Future<List<NeighborhoodDealItem>> getFeaturedDeals({
    String? userId,
    int limit = 5,
  }) async {
    final deals = await getDeals(userId: userId);
    if (deals.length <= limit) {
      return deals;
    }
    return deals.sublist(0, limit);
  }

  Future<String> createDeal({
    required String createdBy,
    required String serviceCategory,
    required String area,
    required String city,
    required String description,
    required int minParticipants,
    int? maxParticipants,
    required int discountPercent,
    int expiryDays = 7,
  }) async {
    final db = await AppDatabase.instance.database;
    final creatorRows = await db.query(
      'users',
      columns: <String>['uid', 'role'],
      where: 'uid = ? AND role = ?',
      whereArgs: <Object>[createdBy, 'provider'],
      limit: 1,
    );

    if (creatorRows.isEmpty) {
      throw StateError('Only verified providers can create deals');
    }

    final now = DateTime.now();
    final dealId = const Uuid().v4();

    await db.insert(
      'neighborhood_deals',
      <String, Object?>{
        'deal_id': dealId,
        'service_category': _normalizeCategory(serviceCategory),
        'area': area.trim(),
        'city': city.trim(),
        'description': description.trim(),
        'min_participants': minParticipants,
        'max_participants': maxParticipants,
        'discount_percent': discountPercent,
        'created_by': createdBy,
        'status': 'open',
        'created_at': now.millisecondsSinceEpoch,
        'expires_at':
            now.add(Duration(days: expiryDays)).millisecondsSinceEpoch,
      },
    );

    return dealId;
  }

  Future<void> joinDeal({
    required String dealId,
    required String userId,
  }) async {
    final db = await AppDatabase.instance.database;

    final participantRows = await db.query(
      'users',
      columns: <String>['uid', 'role'],
      where: 'uid = ? AND role = ?',
      whereArgs: <Object>[userId, 'customer'],
      limit: 1,
    );

    if (participantRows.isEmpty) {
      throw StateError('Only customers can join neighborhood deals');
    }

    final dealRows = await db.query(
      'neighborhood_deals',
      columns: <String>['created_by'],
      where: 'deal_id = ?',
      whereArgs: <Object>[dealId],
      limit: 1,
    );

    if (dealRows.isNotEmpty && dealRows.first['created_by'] == userId) {
      throw StateError('Deal creators cannot join their own deals');
    }

    await db.insert(
      'deal_participants',
      <String, Object?>{
        'deal_id': dealId,
        'user_id': userId,
        'joined_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await _refreshDealStatus(dealId);
  }

  Future<void> leaveDeal({
    required String dealId,
    required String userId,
  }) async {
    final db = await AppDatabase.instance.database;

    await db.delete(
      'deal_participants',
      where: 'deal_id = ? AND user_id = ?',
      whereArgs: <Object>[dealId, userId],
    );

    await _refreshDealStatus(dealId);
  }

  Future<void> _refreshDealStatus(String dealId) async {
    final db = await AppDatabase.instance.database;

    final dealRows = await db.query(
      'neighborhood_deals',
      where: 'deal_id = ?',
      whereArgs: <Object>[dealId],
      limit: 1,
    );

    if (dealRows.isEmpty) {
      return;
    }

    final deal = dealRows.first;
    final maxParticipants = deal['max_participants'] as int?;
    final expiresAt = deal['expires_at'] as int? ?? 0;

    final participantCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM deal_participants WHERE deal_id = ?',
            <Object>[dealId],
          ),
        ) ??
        0;

    String nextStatus = 'open';
    if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
      nextStatus = 'expired';
    } else if (maxParticipants != null && participantCount >= maxParticipants) {
      nextStatus = 'filled';
    }

    await db.update(
      'neighborhood_deals',
      <String, Object?>{'status': nextStatus},
      where: 'deal_id = ?',
      whereArgs: <Object>[dealId],
    );
  }

  MarketplaceServiceItem _mapServiceRow(Map<String, Object?> row) {
    return MarketplaceServiceItem(
      serviceId: row['service_id'] as String,
      providerId: row['provider_id'] as String? ?? '',
      providerName: row['provider_name'] as String? ?? 'Provider',
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      category: row['category'] as String? ?? 'other',
      minPrice: row['min_price'] as int? ?? 0,
      maxPrice: row['max_price'] as int? ?? 0,
      rating: (row['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: row['review_count'] as int? ?? 0,
      isActive: (row['is_active'] as int? ?? 0) == 1,
    );
  }

  NeighborhoodDealItem _mapDealRow(Map<String, Object?> row) {
    return NeighborhoodDealItem(
      dealId: row['deal_id'] as String,
      serviceCategory: row['service_category'] as String? ?? 'other',
      area: row['area'] as String? ?? '',
      city: row['city'] as String? ?? '',
      description: row['description'] as String? ?? '',
      minParticipants: row['min_participants'] as int? ?? 1,
      maxParticipants: row['max_participants'] as int?,
      discountPercent: row['discount_percent'] as int? ?? 0,
      createdBy: row['created_by'] as String?,
      createdByName: row['created_by_name'] as String?,
      status: row['status'] as String? ?? 'open',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at'] as int? ?? 0,
      ),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        row['expires_at'] as int? ?? 0,
      ),
      participantsCount: row['participants_count'] as int? ?? 0,
      hasJoined: (row['has_joined'] as int? ?? 0) == 1,
    );
  }

  String _normalizeCategory(String input) {
    final value = input.trim().toLowerCase().replaceAll(' ', '_');

    final aliases = <String, String>{
      'ac': 'ac_repair',
      'acrepair': 'ac_repair',
      'a_c_repair': 'ac_repair',
      'carmechanic': 'car_mechanic',
      'car_mechanics': 'car_mechanic',
    };

    final normalized = aliases[value] ?? value;

    if (AppConstants.serviceCategories.contains(normalized)) {
      return normalized;
    }

    return 'other';
  }
}

class MarketplaceServiceItem {
  final String serviceId;
  final String providerId;
  final String providerName;
  final String title;
  final String description;
  final String category;
  final int minPrice;
  final int maxPrice;
  final double rating;
  final int reviewCount;
  final bool isActive;

  const MarketplaceServiceItem({
    required this.serviceId,
    required this.providerId,
    required this.providerName,
    required this.title,
    required this.description,
    required this.category,
    required this.minPrice,
    required this.maxPrice,
    required this.rating,
    required this.reviewCount,
    required this.isActive,
  });

  String get categoryLabel =>
      AppConstants.categoryDisplayNames[category] ?? 'Other';
}

class NeighborhoodDealItem {
  final String dealId;
  final String serviceCategory;
  final String area;
  final String city;
  final String description;
  final int minParticipants;
  final int? maxParticipants;
  final int discountPercent;
  final String? createdBy;
  final String? createdByName;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int participantsCount;
  final bool hasJoined;

  const NeighborhoodDealItem({
    required this.dealId,
    required this.serviceCategory,
    required this.area,
    required this.city,
    required this.description,
    required this.minParticipants,
    this.maxParticipants,
    required this.discountPercent,
    this.createdBy,
    this.createdByName,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.participantsCount,
    required this.hasJoined,
  });

  String get categoryLabel =>
      AppConstants.categoryDisplayNames[serviceCategory] ?? 'Other';

  String get participantsLabel =>
      '$participantsCount/${maxParticipants ?? minParticipants} joined';

  String get organizerLabel => createdByName?.trim().isNotEmpty == true
      ? createdByName!
      : 'Provider Community';

  bool get isOpen => status == 'open';
}
