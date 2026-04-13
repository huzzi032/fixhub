import 'model_types.dart';

class BookingModel {
  final String bookingId;
  final String customerId;
  final String? providerId;
  final String? serviceId;
  final String serviceCategory;
  final String issueTitle;
  final String issueDescription;
  final List<String> imageUrls;
  final String address;
  final AppGeoPoint? locationGeoPoint;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final String status;
  final bool isSOS;
  final int? agreedPrice;
  final String paymentMethod;
  final String paymentStatus;
  final String? providerNote;
  final bool customerConfirmed;
  final String? cancellationReason;
  final String? customerName;
  final String? customerPhone;
  final String? customerPhoto;
  final String? providerName;
  final String? providerPhone;
  final String? providerPhoto;

  const BookingModel({
    required this.bookingId,
    required this.customerId,
    this.providerId,
    this.serviceId,
    required this.serviceCategory,
    required this.issueTitle,
    required this.issueDescription,
    this.imageUrls = const [],
    required this.address,
    this.locationGeoPoint,
    required this.scheduledAt,
    required this.createdAt,
    this.status = 'pending',
    this.isSOS = false,
    this.agreedPrice,
    this.paymentMethod = 'cash',
    this.paymentStatus = 'pending',
    this.providerNote,
    this.customerConfirmed = false,
    this.cancellationReason,
    this.customerName,
    this.customerPhone,
    this.customerPhoto,
    this.providerName,
    this.providerPhone,
    this.providerPhoto,
  });

  factory BookingModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return BookingModel(
      bookingId:
          (data['bookingId'] ?? data['booking_id'] ?? id ?? '') as String,
      customerId: data['customerId'] ?? '',
      providerId: data['providerId'] as String?,
      serviceId: data['serviceId'] as String?,
      serviceCategory: data['serviceCategory'] ?? 'other',
      issueTitle: data['issueTitle'] ?? '',
      issueDescription: data['issueDescription'] ?? '',
      imageUrls: (data['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      address: data['address'] ?? '',
      locationGeoPoint: _parseGeoPoint(data['locationGeoPoint']),
      scheduledAt: parseDateTime(data['scheduledAt'] ?? data['scheduled_at']),
      createdAt: parseDateTime(data['createdAt'] ?? data['created_at']),
      status: data['status'] ?? 'pending',
      isSOS: _parseBool(data['isSOS'], false),
      agreedPrice: data['agreedPrice'] as int?,
      paymentMethod: data['paymentMethod'] ?? 'cash',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      providerNote: data['providerNote'] as String?,
      customerConfirmed: _parseBool(data['customerConfirmed'], false),
      cancellationReason: data['cancellationReason'] as String?,
      customerName: data['customerName'] as String?,
      customerPhone: data['customerPhone'] as String?,
      customerPhoto: data['customerPhoto'] as String?,
      providerName: data['providerName'] as String?,
      providerPhone: data['providerPhone'] as String?,
      providerPhoto: data['providerPhoto'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'bookingId': bookingId,
      'customerId': customerId,
      'providerId': providerId,
      'serviceId': serviceId,
      'serviceCategory': serviceCategory,
      'issueTitle': issueTitle,
      'issueDescription': issueDescription,
      'imageUrls': imageUrls,
      'address': address,
      'locationGeoPoint': locationGeoPoint?.toMap(),
      'scheduledAt': toEpochMillis(scheduledAt),
      'createdAt': toEpochMillis(createdAt),
      'status': status,
      'isSOS': isSOS,
      'agreedPrice': agreedPrice,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'providerNote': providerNote,
      'customerConfirmed': customerConfirmed,
      'cancellationReason': cancellationReason,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerPhoto': customerPhoto,
      'providerName': providerName,
      'providerPhone': providerPhone,
      'providerPhoto': providerPhoto,
    };
  }

  BookingModel copyWith({
    String? bookingId,
    String? customerId,
    String? providerId,
    String? serviceId,
    String? serviceCategory,
    String? issueTitle,
    String? issueDescription,
    List<String>? imageUrls,
    String? address,
    AppGeoPoint? locationGeoPoint,
    DateTime? scheduledAt,
    DateTime? createdAt,
    String? status,
    bool? isSOS,
    int? agreedPrice,
    String? paymentMethod,
    String? paymentStatus,
    String? providerNote,
    bool? customerConfirmed,
    String? cancellationReason,
    String? customerName,
    String? customerPhone,
    String? customerPhoto,
    String? providerName,
    String? providerPhone,
    String? providerPhoto,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      providerId: providerId ?? this.providerId,
      serviceId: serviceId ?? this.serviceId,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      issueTitle: issueTitle ?? this.issueTitle,
      issueDescription: issueDescription ?? this.issueDescription,
      imageUrls: imageUrls ?? this.imageUrls,
      address: address ?? this.address,
      locationGeoPoint: locationGeoPoint ?? this.locationGeoPoint,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      isSOS: isSOS ?? this.isSOS,
      agreedPrice: agreedPrice ?? this.agreedPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      providerNote: providerNote ?? this.providerNote,
      customerConfirmed: customerConfirmed ?? this.customerConfirmed,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerPhoto: customerPhoto ?? this.customerPhoto,
      providerName: providerName ?? this.providerName,
      providerPhone: providerPhone ?? this.providerPhone,
      providerPhoto: providerPhoto ?? this.providerPhoto,
    );
  }

  // Status helpers
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isEnRoute => status == 'enRoute';
  bool get isInProgress => status == 'inProgress';
  bool get isCompleted => status == 'completed';
  bool get isPaid => status == 'paid';
  bool get isCancelled => status == 'cancelled';
  bool get isDisputed => status == 'disputed';
  bool get isRejected => status == 'rejected';

  bool get isActive => [
        'pending',
        'accepted',
        'enRoute',
        'inProgress',
      ].contains(status);

  bool get isFinished => [
        'completed',
        'paid',
        'cancelled',
        'disputed',
        'rejected',
      ].contains(status);

  bool get canCancel => ['pending', 'accepted'].contains(status);
  bool get canBePaid => status == 'completed' && !customerConfirmed;
  bool get canBeReviewed => status == 'paid';
  bool get providerAssigned => providerId != null;
  bool get isPaymentCollected => paymentStatus == 'collected';

  String get displayStatus {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'enRoute':
        return 'En Route';
      case 'inProgress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'paid':
        return 'Paid';
      case 'cancelled':
        return 'Cancelled';
      case 'disputed':
        return 'Disputed';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }
}

class BidModel {
  final String bidId;
  final String bookingId;
  final String providerId;
  final String providerName;
  final String? providerPhoto;
  final double providerRating;
  final int bidAmount;
  final int estimatedArrivalMinutes;
  final String message;
  final DateTime createdAt;
  final String status;

  const BidModel({
    required this.bidId,
    required this.bookingId,
    required this.providerId,
    required this.providerName,
    this.providerPhoto,
    required this.providerRating,
    required this.bidAmount,
    required this.estimatedArrivalMinutes,
    this.message = '',
    required this.createdAt,
    this.status = 'pending',
  });

  factory BidModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return BidModel(
      bidId: (data['bidId'] ?? data['bid_id'] ?? id ?? '') as String,
      bookingId: data['bookingId'] ?? '',
      providerId: data['providerId'] ?? '',
      providerName: data['providerName'] ?? '',
      providerPhoto: data['providerPhoto'] as String?,
      providerRating: (data['providerRating'] as num?)?.toDouble() ?? 0.0,
      bidAmount: data['bidAmount'] ?? 0,
      estimatedArrivalMinutes: data['estimatedArrivalMinutes'] ?? 30,
      message: data['message'] ?? '',
      createdAt: parseDateTime(data['createdAt'] ?? data['created_at']),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'bidId': bidId,
      'bookingId': bookingId,
      'providerId': providerId,
      'providerName': providerName,
      'providerPhoto': providerPhoto,
      'providerRating': providerRating,
      'bidAmount': bidAmount,
      'estimatedArrivalMinutes': estimatedArrivalMinutes,
      'message': message,
      'createdAt': toEpochMillis(createdAt),
      'status': status,
    };
  }

  BidModel copyWith({
    String? bidId,
    String? bookingId,
    String? providerId,
    String? providerName,
    String? providerPhoto,
    double? providerRating,
    int? bidAmount,
    int? estimatedArrivalMinutes,
    String? message,
    DateTime? createdAt,
    String? status,
  }) {
    return BidModel(
      bidId: bidId ?? this.bidId,
      bookingId: bookingId ?? this.bookingId,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      providerPhoto: providerPhoto ?? this.providerPhoto,
      providerRating: providerRating ?? this.providerRating,
      bidAmount: bidAmount ?? this.bidAmount,
      estimatedArrivalMinutes:
          estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
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
