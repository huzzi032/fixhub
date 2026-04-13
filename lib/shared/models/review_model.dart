import 'model_types.dart';

class ReviewModel {
  final String reviewId;
  final String bookingId;
  final String customerId;
  final String providerId;
  final String? serviceId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String? providerReply;

  const ReviewModel({
    required this.reviewId,
    required this.bookingId,
    required this.customerId,
    required this.providerId,
    this.serviceId,
    required this.rating,
    this.comment = '',
    required this.createdAt,
    this.providerReply,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return ReviewModel(
      reviewId: (data['reviewId'] ?? data['review_id'] ?? id ?? '') as String,
      bookingId: data['bookingId'] ?? '',
      customerId: data['customerId'] ?? '',
      providerId: data['providerId'] ?? '',
      serviceId: data['serviceId'] as String?,
      rating: data['rating'] ?? 5,
      comment: data['comment'] ?? '',
      createdAt: parseDateTime(data['createdAt'] ?? data['created_at']),
      providerReply: data['providerReply'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'reviewId': reviewId,
      'bookingId': bookingId,
      'customerId': customerId,
      'providerId': providerId,
      'serviceId': serviceId,
      'rating': rating,
      'comment': comment,
      'createdAt': toEpochMillis(createdAt),
      'providerReply': providerReply,
    };
  }

  ReviewModel copyWith({
    String? reviewId,
    String? bookingId,
    String? customerId,
    String? providerId,
    String? serviceId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    String? providerReply,
  }) {
    return ReviewModel(
      reviewId: reviewId ?? this.reviewId,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      providerId: providerId ?? this.providerId,
      serviceId: serviceId ?? this.serviceId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      providerReply: providerReply ?? this.providerReply,
    );
  }

  bool get hasReply => providerReply != null && providerReply!.isNotEmpty;
  bool get hasComment => comment.isNotEmpty;

  String get ratingText {
    switch (rating) {
      case 5:
        return 'Excellent';
      case 4:
        return 'Very Good';
      case 3:
        return 'Good';
      case 2:
        return 'Fair';
      case 1:
        return 'Poor';
      default:
        return '';
    }
  }
}
