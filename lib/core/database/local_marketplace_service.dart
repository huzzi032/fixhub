import 'dart:convert';

import '../auth/local_auth_service.dart';
import '../constants/app_constants.dart';

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
    final response = await _getAction('searchServices', <String, String>{
      'query': query.trim(),
      'categories': categories.map(_normalizeCategory).join(','),
      'minPrice': '$minPrice',
      'maxPrice': '$maxPrice',
      'minRating': '$minRating',
      'sortBy': sortBy,
    });

    return _mapServices(response['services']);
  }

  Future<List<MarketplaceServiceItem>> getServicesByCategory(
    String category,
  ) async {
    final response = await _getAction('getServicesByCategory', <String, String>{
      'category': _normalizeCategory(category),
    });

    return _mapServices(response['services']);
  }

  Future<List<MarketplaceServiceItem>> getProviderServices(
    String providerId,
  ) async {
    final response = await _getAction('getProviderServices', <String, String>{
      'providerId': providerId,
    });

    return _mapServices(response['services']);
  }

  Future<ProviderPublicProfile?> getProviderPublicProfile(
    String providerId,
  ) async {
    final response = await _getAction(
      'getProviderPublicProfile',
      <String, String>{'providerId': providerId},
    );

    final profileRaw = response['profile'];
    if (profileRaw is! Map) {
      return null;
    }

    final profile = Map<String, dynamic>.from(profileRaw);
    final services = _mapServices(response['services']);
    final reviews = _mapProviderReviews(response['reviews']);

    return ProviderPublicProfile(
      providerId: profile['provider_id']?.toString().trim().isNotEmpty == true
          ? profile['provider_id'].toString()
          : providerId,
      displayName: profile['display_name']?.toString().trim().isNotEmpty == true
          ? profile['display_name'].toString()
          : 'Provider',
      profilePhotoUrl: _asStringOrNull(profile['profile_photo_url']),
      bio: profile['bio']?.toString() ?? '',
      skills: _asStringList(profile['skills']),
      serviceCities: _asStringList(profile['service_cities']),
      hourlyRateMin: _asIntOrNull(profile['hourly_rate_min']),
      hourlyRateMax: _asIntOrNull(profile['hourly_rate_max']),
      verificationStatus:
          profile['verification_status']?.toString() ?? 'pending',
      joinedAt: _asIntOrNull(profile['joined_at']) == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(_asInt(profile['joined_at'])),
      averageRating: _asDouble(profile['average_rating']),
      totalReviews: _asInt(profile['total_reviews']),
      completedJobs: _asInt(profile['completed_jobs']),
      activeServices: _asInt(profile['active_services']),
      services: services,
      reviews: reviews,
    );
  }

  Future<MarketplaceServiceItem?> getServiceById(String serviceId) async {
    final response = await _getAction('getServiceById', <String, String>{
      'serviceId': serviceId,
    });

    final raw = response['service'];
    if (raw is! Map) {
      return null;
    }

    return _mapServiceRow(Map<String, dynamic>.from(raw));
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
    List<String> imageUrls = const <String>[],
    bool isActive = true,
  }) async {
    final response = await _postAction('saveProviderService', <String, dynamic>{
      'serviceId': serviceId,
      'providerId': providerId,
      'providerName': providerName,
      'title': title,
      'description': description,
      'category': _normalizeCategory(category),
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'imageUrls': imageUrls,
      'isActive': isActive,
    });

    final id = response['serviceId']?.toString().trim();
    if (id == null || id.isEmpty) {
      throw StateError('Failed to save provider service.');
    }

    return id;
  }

  Future<void> setServiceActive(String serviceId, bool isActive) async {
    await _postAction('setServiceActive', <String, dynamic>{
      'serviceId': serviceId,
      'isActive': isActive,
    });
  }

  Future<void> deleteService(String serviceId) async {
    await _postAction('deleteService', <String, dynamic>{
      'serviceId': serviceId,
    });
  }

  Future<List<NeighborhoodDealItem>> getDeals({
    String? userId,
    String? city,
    String? area,
  }) async {
    final response = await _getAction('getDeals', <String, String>{
      if (userId != null && userId.trim().isNotEmpty) 'userId': userId.trim(),
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (area != null && area.trim().isNotEmpty) 'area': area.trim(),
    });

    return _mapDeals(response['deals']);
  }

  Future<List<NeighborhoodDealItem>> getFeaturedDeals({
    String? userId,
    int limit = 5,
  }) async {
    final response = await _getAction('getFeaturedDeals', <String, String>{
      if (userId != null && userId.trim().isNotEmpty) 'userId': userId.trim(),
      'limit': '$limit',
    });

    return _mapDeals(response['deals']);
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
    final response = await _postAction('createDeal', <String, dynamic>{
      'createdBy': createdBy,
      'serviceCategory': _normalizeCategory(serviceCategory),
      'area': area,
      'city': city,
      'description': description,
      'minParticipants': minParticipants,
      'maxParticipants': maxParticipants,
      'discountPercent': discountPercent,
      'expiryDays': expiryDays,
    });

    final dealId = response['dealId']?.toString().trim();
    if (dealId == null || dealId.isEmpty) {
      throw StateError('Failed to create deal.');
    }

    return dealId;
  }

  Future<void> joinDeal({
    required String dealId,
    required String userId,
  }) async {
    await _postAction('joinDeal', <String, dynamic>{
      'dealId': dealId,
      'userId': userId,
    });
  }

  Future<void> leaveDeal({
    required String dealId,
    required String userId,
  }) async {
    await _postAction('leaveDeal', <String, dynamic>{
      'dealId': dealId,
      'userId': userId,
    });
  }

  Future<Map<String, dynamic>> _getAction(
    String action,
    Map<String, String> params,
  ) {
    final query = <String, String>{
      'action': action,
      ...params,
    };

    final path = '/api/marketplace?${Uri(queryParameters: query).query}';
    return LocalAuthService.instance.request(
      method: 'GET',
      path: path,
      requireAuth: true,
    );
  }

  Future<Map<String, dynamic>> _postAction(
    String action,
    Map<String, dynamic> payload,
  ) {
    return LocalAuthService.instance.request(
      method: 'POST',
      path: '/api/marketplace',
      requireAuth: true,
      body: <String, dynamic>{
        'action': action,
        ...payload,
      },
    );
  }

  List<MarketplaceServiceItem> _mapServices(dynamic raw) {
    if (raw is! List) {
      return const <MarketplaceServiceItem>[];
    }

    return raw
        .whereType<Map>()
        .map((row) => _mapServiceRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  List<NeighborhoodDealItem> _mapDeals(dynamic raw) {
    if (raw is! List) {
      return const <NeighborhoodDealItem>[];
    }

    return raw
        .whereType<Map>()
        .map((row) => _mapDealRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  List<ProviderReviewItem> _mapProviderReviews(dynamic raw) {
    if (raw is! List) {
      return const <ProviderReviewItem>[];
    }

    return raw
        .whereType<Map>()
        .map(
          (row) => ProviderReviewItem(
            reviewId: row['review_id']?.toString() ?? '',
            bookingId: row['booking_id']?.toString() ?? '',
            customerId: _asStringOrNull(row['customer_id']),
            customerName: row['customer_name']?.toString() ?? 'Customer',
            customerPhotoUrl: _asStringOrNull(row['customer_photo_url']),
            rating: _asInt(row['rating']),
            comment: row['comment']?.toString() ?? '',
            createdAt:
                DateTime.fromMillisecondsSinceEpoch(_asInt(row['created_at'])),
          ),
        )
        .toList();
  }

  MarketplaceServiceItem _mapServiceRow(Map<String, dynamic> row) {
    final imageUrls = _asStringList(row['image_urls']);

    return MarketplaceServiceItem(
      serviceId: row['service_id']?.toString() ?? '',
      providerId: row['provider_id']?.toString() ?? '',
      providerName: row['provider_name']?.toString() ?? 'Provider',
      title: row['title']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      category: row['category']?.toString() ?? 'other',
      imageUrls: imageUrls,
      minPrice: _asInt(row['min_price']),
      maxPrice: _asInt(row['max_price']),
      rating: _asDouble(row['rating']),
      reviewCount: _asInt(row['review_count']),
      isActive: _asInt(row['is_active']) == 1,
    );
  }

  NeighborhoodDealItem _mapDealRow(Map<String, dynamic> row) {
    return NeighborhoodDealItem(
      dealId: row['deal_id']?.toString() ?? '',
      serviceCategory: row['service_category']?.toString() ?? 'other',
      area: row['area']?.toString() ?? '',
      city: row['city']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      minParticipants: _asInt(row['min_participants']),
      maxParticipants: row['max_participants'] == null
          ? null
          : _asInt(row['max_participants']),
      discountPercent: _asInt(row['discount_percent']),
      createdBy: _asStringOrNull(row['created_by']),
      createdByName: _asStringOrNull(row['created_by_name']),
      status: row['status']?.toString() ?? 'open',
      createdAt: DateTime.fromMillisecondsSinceEpoch(_asInt(row['created_at'])),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(_asInt(row['expires_at'])),
      participantsCount: _asInt(row['participants_count']),
      hasJoined: _asInt(row['has_joined']) == 1,
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

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String && value.trim().isNotEmpty) {
      return int.tryParse(value.trim()) ?? fallback;
    }

    return fallback;
  }

  int? _asIntOrNull(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String && value.trim().isNotEmpty) {
      return int.tryParse(value.trim());
    }

    return null;
  }

  double _asDouble(dynamic value, [double fallback = 0]) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String && value.trim().isNotEmpty) {
      return double.tryParse(value.trim()) ?? fallback;
    }

    return fallback;
  }

  String? _asStringOrNull(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = value.trim();
        if (decoded.startsWith('[')) {
          final List<dynamic> parsed =
              List<dynamic>.from(jsonDecode(decoded) as List<dynamic>);
          return parsed
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList();
        }
      } catch (_) {
        return <String>[];
      }
    }

    return <String>[];
  }
}

class MarketplaceServiceItem {
  final String serviceId;
  final String providerId;
  final String providerName;
  final String title;
  final String description;
  final String category;
  final List<String> imageUrls;
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
    this.imageUrls = const <String>[],
    required this.minPrice,
    required this.maxPrice,
    required this.rating,
    required this.reviewCount,
    required this.isActive,
  });

  String get categoryLabel =>
      AppConstants.categoryDisplayNames[category] ?? 'Other';

  String? get coverImageUrl => imageUrls.isEmpty ? null : imageUrls.first;
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

class ProviderPublicProfile {
  final String providerId;
  final String displayName;
  final String? profilePhotoUrl;
  final String bio;
  final List<String> skills;
  final List<String> serviceCities;
  final int? hourlyRateMin;
  final int? hourlyRateMax;
  final String verificationStatus;
  final DateTime? joinedAt;
  final double averageRating;
  final int totalReviews;
  final int completedJobs;
  final int activeServices;
  final List<MarketplaceServiceItem> services;
  final List<ProviderReviewItem> reviews;

  const ProviderPublicProfile({
    required this.providerId,
    required this.displayName,
    this.profilePhotoUrl,
    this.bio = '',
    this.skills = const <String>[],
    this.serviceCities = const <String>[],
    this.hourlyRateMin,
    this.hourlyRateMax,
    this.verificationStatus = 'pending',
    this.joinedAt,
    this.averageRating = 0,
    this.totalReviews = 0,
    this.completedJobs = 0,
    this.activeServices = 0,
    this.services = const <MarketplaceServiceItem>[],
    this.reviews = const <ProviderReviewItem>[],
  });

  bool get isVerified => verificationStatus == 'approved';
}

class ProviderReviewItem {
  final String reviewId;
  final String bookingId;
  final String? customerId;
  final String customerName;
  final String? customerPhotoUrl;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const ProviderReviewItem({
    required this.reviewId,
    required this.bookingId,
    this.customerId,
    required this.customerName,
    this.customerPhotoUrl,
    required this.rating,
    this.comment = '',
    required this.createdAt,
  });
}
