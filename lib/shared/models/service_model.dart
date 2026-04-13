import 'model_types.dart';

class ServiceModel {
  final String serviceId;
  final String providerId;
  final String title;
  final String description;
  final String category;
  final List<String> images;
  final String priceType;
  final int? fixedPrice;
  final int? hourlyRate;
  final List<String> tags;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceModel({
    required this.serviceId,
    required this.providerId,
    required this.title,
    required this.description,
    required this.category,
    this.images = const [],
    required this.priceType,
    this.fixedPrice,
    this.hourlyRate,
    this.tags = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return ServiceModel(
      serviceId:
          (data['serviceId'] ?? data['service_id'] ?? id ?? '') as String,
      providerId: data['providerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'other',
      images: (data['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      priceType: data['priceType'] ?? 'quote',
      fixedPrice: data['fixedPrice'] as int?,
      hourlyRate: data['hourlyRate'] as int?,
      tags:
          (data['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      isActive: _parseBool(data['isActive'], true),
      createdAt: parseDateTime(data['createdAt'] ?? data['created_at']),
      updatedAt: parseDateTime(data['updatedAt'] ?? data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'serviceId': serviceId,
      'providerId': providerId,
      'title': title,
      'description': description,
      'category': category,
      'images': images,
      'priceType': priceType,
      'fixedPrice': fixedPrice,
      'hourlyRate': hourlyRate,
      'tags': tags,
      'isActive': isActive,
      'createdAt': toEpochMillis(createdAt),
      'updatedAt': toEpochMillis(updatedAt),
    };
  }

  ServiceModel copyWith({
    String? serviceId,
    String? providerId,
    String? title,
    String? description,
    String? category,
    List<String>? images,
    String? priceType,
    int? fixedPrice,
    int? hourlyRate,
    List<String>? tags,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      serviceId: serviceId ?? this.serviceId,
      providerId: providerId ?? this.providerId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      images: images ?? this.images,
      priceType: priceType ?? this.priceType,
      fixedPrice: fixedPrice ?? this.fixedPrice,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayPrice {
    switch (priceType) {
      case 'fixed':
        return fixedPrice != null ? 'Rs. $fixedPrice' : 'Contact for price';
      case 'hourly':
        return hourlyRate != null ? 'Rs. $hourlyRate/hr' : 'Contact for rate';
      case 'quote':
      default:
        return 'Get a Quote';
    }
  }

  String get coverImage => images.isNotEmpty ? images[0] : '';
  bool get hasFixedPrice => priceType == 'fixed' && fixedPrice != null;
  bool get hasHourlyRate => priceType == 'hourly' && hourlyRate != null;
  bool get requiresQuote => priceType == 'quote';
}

bool _parseBool(dynamic value, bool fallback) {
  if (value is bool) {
    return value;
  }

  if (value is int) {
    return value == 1;
  }

  return fallback;
}
