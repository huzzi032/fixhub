import 'model_types.dart';

class DealModel {
  final String dealId;
  final String createdBy;
  final String serviceCategory;
  final String area;
  final String city;
  final String description;
  final int minParticipants;
  final List<String> participants;
  final int? maxParticipants;
  final int discountPercent;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String? creatorName;
  final String? creatorPhoto;

  const DealModel({
    required this.dealId,
    required this.createdBy,
    required this.serviceCategory,
    required this.area,
    required this.city,
    required this.description,
    required this.minParticipants,
    this.participants = const [],
    this.maxParticipants,
    required this.discountPercent,
    this.status = 'open',
    required this.expiresAt,
    required this.createdAt,
    this.creatorName,
    this.creatorPhoto,
  });

  factory DealModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return DealModel(
      dealId: (data['dealId'] ?? data['deal_id'] ?? id ?? '') as String,
      createdBy: data['createdBy'] ?? '',
      serviceCategory: data['serviceCategory'] ?? 'other',
      area: data['area'] ?? '',
      city: data['city'] ?? '',
      description: data['description'] ?? '',
      minParticipants: data['minParticipants'] ?? 5,
      participants: (data['participants'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      maxParticipants: data['maxParticipants'] as int?,
      discountPercent: data['discountPercent'] ?? 10,
      status: data['status'] ?? 'open',
      expiresAt: parseDateTime(data['expiresAt'] ?? data['expires_at']),
      createdAt: parseDateTime(data['createdAt'] ?? data['created_at']),
      creatorName: data['creatorName'] as String?,
      creatorPhoto: data['creatorPhoto'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'dealId': dealId,
      'createdBy': createdBy,
      'serviceCategory': serviceCategory,
      'area': area,
      'city': city,
      'description': description,
      'minParticipants': minParticipants,
      'participants': participants,
      'maxParticipants': maxParticipants,
      'discountPercent': discountPercent,
      'status': status,
      'expiresAt': toEpochMillis(expiresAt),
      'createdAt': toEpochMillis(createdAt),
      'creatorName': creatorName,
      'creatorPhoto': creatorPhoto,
    };
  }

  DealModel copyWith({
    String? dealId,
    String? createdBy,
    String? serviceCategory,
    String? area,
    String? city,
    String? description,
    int? minParticipants,
    List<String>? participants,
    int? maxParticipants,
    int? discountPercent,
    String? status,
    DateTime? expiresAt,
    DateTime? createdAt,
    String? creatorName,
    String? creatorPhoto,
  }) {
    return DealModel(
      dealId: dealId ?? this.dealId,
      createdBy: createdBy ?? this.createdBy,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      area: area ?? this.area,
      city: city ?? this.city,
      description: description ?? this.description,
      minParticipants: minParticipants ?? this.minParticipants,
      participants: participants ?? this.participants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      discountPercent: discountPercent ?? this.discountPercent,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      creatorName: creatorName ?? this.creatorName,
      creatorPhoto: creatorPhoto ?? this.creatorPhoto,
    );
  }

  // Status helpers
  bool get isOpen => status == 'open';
  bool get isFilled => status == 'filled';
  bool get isExpired => status == 'expired';
  bool get isCancelled => status == 'cancelled';

  // Participant helpers
  int get currentParticipants => participants.length;
  bool get hasMinParticipants => currentParticipants >= minParticipants;
  bool get isFull =>
      maxParticipants != null && currentParticipants >= maxParticipants!;

  bool hasJoined(String userId) => participants.contains(userId);

  bool canJoin(String userId) {
    return isOpen && !hasJoined(userId) && !isFull;
  }

  String get participantsText {
    return '$currentParticipants/$minParticipants joined';
  }

  String get discountText => '$discountPercent% OFF';

  Duration get timeRemaining {
    return expiresAt.difference(DateTime.now());
  }

  bool get isExpiringSoon {
    final remaining = timeRemaining;
    return remaining.inHours < 24 && remaining.inHours > 0;
  }

  String get categoryDisplayName {
    final names = {
      'plumber': 'Plumber',
      'electrician': 'Electrician',
      'carpenter': 'Carpenter',
      'painter': 'Painter',
      'car_mechanic': 'Car Mechanic',
      'ac_repair': 'AC Repair',
      'cleaning': 'Cleaning',
      'other': 'Other',
    };
    return names[serviceCategory] ?? serviceCategory;
  }
}
