import 'model_types.dart';

class NotificationModel {
  final String notificationId;
  final String title;
  final String body;
  final String type;
  final String? bookingId;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  const NotificationModel({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.type,
    this.bookingId,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return NotificationModel(
      notificationId: (data['notificationId'] ??
          data['notification_id'] ??
          id ??
          '') as String,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'general',
      bookingId: data['bookingId'] as String?,
      isRead: _parseBool(data['isRead'], false),
      createdAt: parseDateTime(data['createdAt'] ?? data['created_at']),
      data: data['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'notificationId': notificationId,
      'title': title,
      'body': body,
      'type': type,
      'bookingId': bookingId,
      'isRead': isRead,
      'createdAt': toEpochMillis(createdAt),
      'data': data,
    };
  }

  NotificationModel copyWith({
    String? notificationId,
    String? title,
    String? body,
    String? type,
    String? bookingId,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      bookingId: bookingId ?? this.bookingId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }

  String get iconName {
    switch (type) {
      case 'booking_update':
        return 'assignment';
      case 'bid_accepted':
        return 'check_circle';
      case 'new_lead':
        return 'notifications_active';
      case 'verification_update':
        return 'verified_user';
      case 'deal_update':
        return 'local_offer';
      case 'dispute_update':
        return 'gavel';
      case 'wallet_update':
        return 'account_balance_wallet';
      default:
        return 'notifications';
    }
  }

  String? get deepLinkRoute {
    switch (type) {
      case 'booking_update':
      case 'bid_accepted':
        if (bookingId != null) {
          return '/customer/booking/track?bookingId=$bookingId';
        }
        return '/customer/orders';
      case 'new_lead':
        if (bookingId != null) {
          return '/provider/lead/$bookingId';
        }
        return '/provider/dashboard';
      case 'verification_update':
        return '/provider/dashboard';
      case 'deal_update':
        return '/customer/deals';
      case 'dispute_update':
        return '/customer/orders';
      case 'wallet_update':
        return '/provider/wallet';
      default:
        return null;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day} ${_getMonthName(createdAt.month)}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}

// FCM Message Model for handling push notifications
class FCMMessageModel {
  final String? title;
  final String? body;
  final String type;
  final String? bookingId;
  final Map<String, dynamic>? data;

  const FCMMessageModel({
    this.title,
    this.body,
    required this.type,
    this.bookingId,
    this.data,
  });

  factory FCMMessageModel.fromRemoteMessage(Map<String, dynamic> message) {
    final notification = message['notification'] as Map<String, dynamic>?;
    final data = message['data'] as Map<String, dynamic>?;

    return FCMMessageModel(
      title: notification?['title'] as String?,
      body: notification?['body'] as String?,
      type: data?['type'] ?? 'general',
      bookingId: data?['bookingId'] as String?,
      data: data,
    );
  }

  Map<String, dynamic> toRemoteMessage() {
    return {
      'notification': {
        'title': title,
        'body': body,
      },
      'data': {
        'type': type,
        'bookingId': bookingId,
        ...?data,
      },
    };
  }
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
