import 'model_types.dart';

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String? email;
  final String role;
  final String? profilePhotoUrl;
  final String? fcmToken;
  final DateTime createdAt;
  final bool isActive;

  const UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    this.profilePhotoUrl,
    this.fcmToken,
    required this.createdAt,
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return UserModel(
      uid: (data['uid'] ?? id ?? '') as String,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      role: data['role'] ?? 'customer',
      profilePhotoUrl: data['profilePhotoUrl'] ?? data['profile_photo_url'],
      fcmToken: data['fcmToken'] ?? data['fcm_token'],
      createdAt: parseDateTime(
        data['createdAt'] ?? data['created_at'],
      ),
      isActive:
          _parseBool(data['isActive'] ?? data['is_active'], fallback: true),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'profilePhotoUrl': profilePhotoUrl,
      'fcmToken': fcmToken,
      'createdAt': toEpochMillis(createdAt),
      'isActive': isActive,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? phone,
    String? email,
    String? role,
    String? profilePhotoUrl,
    String? fcmToken,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class CustomerModel {
  final String userId;
  final List<SavedAddress> savedAddresses;
  final int loyaltyPoints;
  final int totalOrdersPlaced;

  const CustomerModel({
    required this.userId,
    this.savedAddresses = const [],
    this.loyaltyPoints = 0,
    this.totalOrdersPlaced = 0,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return CustomerModel(
      userId: (data['userId'] ?? data['user_id'] ?? id ?? '') as String,
      savedAddresses: (data['savedAddresses'] as List<dynamic>?)
              ?.map((e) => SavedAddress.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      loyaltyPoints:
          (data['loyaltyPoints'] ?? data['loyalty_points'] ?? 0) as int,
      totalOrdersPlaced: (data['totalOrdersPlaced'] ??
          data['total_orders_placed'] ??
          0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'savedAddresses': savedAddresses.map((e) => e.toMap()).toList(),
      'loyaltyPoints': loyaltyPoints,
      'totalOrdersPlaced': totalOrdersPlaced,
    };
  }

  CustomerModel copyWith({
    String? userId,
    List<SavedAddress>? savedAddresses,
    int? loyaltyPoints,
    int? totalOrdersPlaced,
  }) {
    return CustomerModel(
      userId: userId ?? this.userId,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      totalOrdersPlaced: totalOrdersPlaced ?? this.totalOrdersPlaced,
    );
  }
}

class SavedAddress {
  final String id;
  final String label;
  final String address;
  final AppGeoPoint? geoPoint;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    this.geoPoint,
  });

  factory SavedAddress.fromMap(Map<String, dynamic> map) {
    return SavedAddress(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      address: map['address'] ?? '',
      geoPoint: _parseGeoPoint(map['geoPoint']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'address': address,
      'geoPoint': geoPoint?.toMap(),
    };
  }

  SavedAddress copyWith({
    String? id,
    String? label,
    String? address,
    AppGeoPoint? geoPoint,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      geoPoint: geoPoint ?? this.geoPoint,
    );
  }
}

class ProviderModel {
  final String userId;
  final String? cnicFrontUrl;
  final String? cnicBackUrl;
  final List<String> certificateUrls;
  final String bio;
  final List<String> skills;
  final List<String> serviceCities;
  final double serviceRadiusKm;
  final int? hourlyRateMin;
  final int? hourlyRateMax;
  final String verificationStatus;
  final String? rejectionReason;
  final bool isOnline;
  final AppGeoPoint? currentLocation;
  final int trustLevel;
  final double averageRating;
  final int totalRatings;
  final int totalJobsDone;
  final int walletBalance;
  final int earningsTotal;
  final DateTime joinedAt;

  const ProviderModel({
    required this.userId,
    this.cnicFrontUrl,
    this.cnicBackUrl,
    this.certificateUrls = const [],
    this.bio = '',
    this.skills = const [],
    this.serviceCities = const [],
    this.serviceRadiusKm = 10.0,
    this.hourlyRateMin,
    this.hourlyRateMax,
    this.verificationStatus = 'pending',
    this.rejectionReason,
    this.isOnline = false,
    this.currentLocation,
    this.trustLevel = 1,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.totalJobsDone = 0,
    this.walletBalance = 0,
    this.earningsTotal = 0,
    required this.joinedAt,
  });

  factory ProviderModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return ProviderModel(
      userId: (data['userId'] ?? data['user_id'] ?? id ?? '') as String,
      cnicFrontUrl: data['cnicFrontUrl'],
      cnicBackUrl: data['cnicBackUrl'],
      certificateUrls: (data['certificateUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      bio: data['bio'] ?? '',
      skills: (data['skills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      serviceCities: (data['serviceCities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      serviceRadiusKm: (data['serviceRadiusKm'] as num?)?.toDouble() ?? 10.0,
      hourlyRateMin: data['hourlyRateMin'] as int?,
      hourlyRateMax: data['hourlyRateMax'] as int?,
      verificationStatus: data['verificationStatus'] ?? 'pending',
      rejectionReason: data['rejectionReason'],
      isOnline: _parseBool(data['isOnline'], fallback: false),
      currentLocation: _parseGeoPoint(data['currentLocation']),
      trustLevel: data['trustLevel'] ?? 1,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: data['totalRatings'] ?? 0,
      totalJobsDone: data['totalJobsDone'] ?? 0,
      walletBalance: data['walletBalance'] ?? data['wallet_balance'] ?? 0,
      earningsTotal: data['earningsTotal'] ?? data['earnings_total'] ?? 0,
      joinedAt: parseDateTime(data['joinedAt'] ?? data['joined_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'cnicFrontUrl': cnicFrontUrl,
      'cnicBackUrl': cnicBackUrl,
      'certificateUrls': certificateUrls,
      'bio': bio,
      'skills': skills,
      'serviceCities': serviceCities,
      'serviceRadiusKm': serviceRadiusKm,
      'hourlyRateMin': hourlyRateMin,
      'hourlyRateMax': hourlyRateMax,
      'verificationStatus': verificationStatus,
      'rejectionReason': rejectionReason,
      'isOnline': isOnline,
      'currentLocation': currentLocation?.toMap(),
      'trustLevel': trustLevel,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'totalJobsDone': totalJobsDone,
      'walletBalance': walletBalance,
      'earningsTotal': earningsTotal,
      'joinedAt': toEpochMillis(joinedAt),
    };
  }

  ProviderModel copyWith({
    String? userId,
    String? cnicFrontUrl,
    String? cnicBackUrl,
    List<String>? certificateUrls,
    String? bio,
    List<String>? skills,
    List<String>? serviceCities,
    double? serviceRadiusKm,
    int? hourlyRateMin,
    int? hourlyRateMax,
    String? verificationStatus,
    String? rejectionReason,
    bool? isOnline,
    AppGeoPoint? currentLocation,
    int? trustLevel,
    double? averageRating,
    int? totalRatings,
    int? totalJobsDone,
    int? walletBalance,
    int? earningsTotal,
    DateTime? joinedAt,
  }) {
    return ProviderModel(
      userId: userId ?? this.userId,
      cnicFrontUrl: cnicFrontUrl ?? this.cnicFrontUrl,
      cnicBackUrl: cnicBackUrl ?? this.cnicBackUrl,
      certificateUrls: certificateUrls ?? this.certificateUrls,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      serviceCities: serviceCities ?? this.serviceCities,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      hourlyRateMin: hourlyRateMin ?? this.hourlyRateMin,
      hourlyRateMax: hourlyRateMax ?? this.hourlyRateMax,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isOnline: isOnline ?? this.isOnline,
      currentLocation: currentLocation ?? this.currentLocation,
      trustLevel: trustLevel ?? this.trustLevel,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      totalJobsDone: totalJobsDone ?? this.totalJobsDone,
      walletBalance: walletBalance ?? this.walletBalance,
      earningsTotal: earningsTotal ?? this.earningsTotal,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  bool get isApproved => verificationStatus == 'approved';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';
  bool get isSuspended => verificationStatus == 'suspended';
  bool get canAcceptJobs => isApproved && walletBalance >= 50;
}

bool _parseBool(dynamic value, {required bool fallback}) {
  if (value is bool) {
    return value;
  }

  if (value is int) {
    return value == 1;
  }

  return fallback;
}

AppGeoPoint? _parseGeoPoint(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is AppGeoPoint) {
    return value;
  }

  if (value is Map<String, dynamic>) {
    return AppGeoPoint.fromMap(value);
  }

  return null;
}
