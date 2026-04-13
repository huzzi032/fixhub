import 'dart:async';

import '../auth/local_auth_service.dart';
import '../../shared/models/booking_model.dart';

class LocalBookingService {
  LocalBookingService._();

  static final LocalBookingService instance = LocalBookingService._();

  Future<String> createBooking({
    required String customerId,
    required String serviceCategory,
    required String issueTitle,
    required String issueDescription,
    required String address,
    required DateTime scheduledAt,
    String? serviceId,
    String? customerName,
    bool isSOS = false,
  }) async {
    final response = await _postAction('createBooking', <String, dynamic>{
      'customerId': customerId,
      'serviceCategory': serviceCategory,
      'issueTitle': issueTitle,
      'issueDescription': issueDescription,
      'address': address,
      'scheduledAt': scheduledAt.millisecondsSinceEpoch,
      'serviceId': serviceId,
      'customerName': customerName,
      'isSOS': isSOS,
    });

    final bookingId = response['bookingId']?.toString().trim();
    if (bookingId == null || bookingId.isEmpty) {
      throw StateError('Failed to create booking.');
    }

    return bookingId;
  }

  Future<BookingModel?> getBookingById(String bookingId) async {
    final response = await _getAction('getById', <String, String>{
      'bookingId': bookingId,
    });

    final row = response['booking'];
    if (row is! Map) {
      return null;
    }

    return _mapRowToBooking(Map<String, dynamic>.from(row));
  }

  Future<List<BookingModel>> getCustomerBookings(String customerId) async {
    final response = await _getAction('getCustomerBookings', <String, String>{
      'customerId': customerId,
    });
    return _mapBookings(response['bookings']);
  }

  Future<List<BookingModel>> getProviderActiveBookings(
      String providerId) async {
    final response = await _getAction(
      'getProviderActiveBookings',
      <String, String>{'providerId': providerId},
    );
    return _mapBookings(response['bookings']);
  }

  Future<List<BookingModel>> getProviderJobs(String providerId) async {
    final response = await _getAction('getProviderJobs', <String, String>{
      'providerId': providerId,
    });
    return _mapBookings(response['bookings']);
  }

  Future<List<BookingModel>> getIncomingLeads() async {
    final response = await _getAction('getIncomingLeads');
    return _mapBookings(response['bookings']);
  }

  Future<void> acceptLead({
    required String bookingId,
    required String providerId,
    required String providerName,
    required int quoteAmount,
    String? providerNote,
  }) async {
    await _postAction('acceptLead', <String, dynamic>{
      'bookingId': bookingId,
      'providerId': providerId,
      'providerName': providerName,
      'quoteAmount': quoteAmount,
      'providerNote': providerNote,
    });
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    await _postAction('updateBookingStatus', <String, dynamic>{
      'bookingId': bookingId,
      'status': status,
    });
  }

  Future<void> markPaymentCollected({
    required String bookingId,
  }) async {
    await _postAction('markPaymentCollected', <String, dynamic>{
      'bookingId': bookingId,
    });
  }

  Future<int> getProviderWalletBalance(String providerId) async {
    final response =
        await _getAction('getProviderWalletBalance', <String, String>{
      'providerId': providerId,
    });

    return _asInt(response['walletBalance']);
  }

  Future<void> topUpWallet({
    required String providerId,
    required int amount,
  }) async {
    await _postAction('topUpWallet', <String, dynamic>{
      'providerId': providerId,
      'amount': amount,
    });
  }

  Future<ProviderEarningsSummary> getProviderEarnings(String providerId) async {
    final response = await _getAction('getProviderEarnings', <String, String>{
      'providerId': providerId,
    });

    final summaryRaw = response['summary'];
    if (summaryRaw is! Map) {
      return const ProviderEarningsSummary(
        totalEarned: 0,
        pendingAmount: 0,
        walletBalance: 0,
        completedJobs: 0,
        activeJobs: 0,
      );
    }

    final summary = Map<String, dynamic>.from(summaryRaw);
    return ProviderEarningsSummary(
      totalEarned: _asInt(summary['totalEarned']),
      pendingAmount: _asInt(summary['pendingAmount']),
      walletBalance: _asInt(summary['walletBalance']),
      completedJobs: _asInt(summary['completedJobs']),
      activeJobs: _asInt(summary['activeJobs']),
    );
  }

  Future<void> submitReview({
    required String bookingId,
    required String providerId,
    required String customerId,
    required int rating,
    String? comment,
  }) async {
    await _postAction('submitReview', <String, dynamic>{
      'bookingId': bookingId,
      'providerId': providerId,
      'customerId': customerId,
      'rating': rating,
      'comment': comment,
    });
  }

  Future<void> sendBookingMessage({
    required String bookingId,
    required String senderId,
    required String message,
  }) async {
    await _postAction('sendMessage', <String, dynamic>{
      'bookingId': bookingId,
      'senderId': senderId,
      'message': message,
    });
  }

  Future<List<BookingChatMessage>> getBookingMessages(
    String bookingId,
  ) async {
    final response = await _getAction('getMessages', <String, String>{
      'bookingId': bookingId,
    });

    final raw = response['messages'];
    if (raw is! List) {
      return const <BookingChatMessage>[];
    }

    return raw
        .whereType<Map>()
        .map((row) => _mapRowToChatMessage(Map<String, dynamic>.from(row)))
        .toList();
  }

  Stream<List<BookingChatMessage>> watchBookingMessages(
    String bookingId, {
    Duration pollInterval = const Duration(seconds: 1),
  }) async* {
    String? lastDigest;

    while (true) {
      final messages = await getBookingMessages(bookingId);
      final digest = messages.isEmpty
          ? 'empty'
          : '${messages.length}:${messages.last.messageId}:${messages.last.sentAt.millisecondsSinceEpoch}:${messages.last.isRead ? 1 : 0}';

      if (digest != lastDigest) {
        yield messages;
        lastDigest = digest;
      }

      await Future<void>.delayed(pollInterval);
    }
  }

  Future<void> markMessagesRead({
    required String bookingId,
    required String viewerId,
  }) async {
    await _postAction('markMessagesRead', <String, dynamic>{
      'bookingId': bookingId,
      'viewerId': viewerId,
    });
  }

  Future<Map<String, dynamic>> _getAction(
    String action, [
    Map<String, String>? params,
  ]) {
    final query = <String, String>{
      'action': action,
      ...?params,
    };

    final path = '/api/bookings?${Uri(queryParameters: query).query}';
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
      path: '/api/bookings',
      requireAuth: true,
      body: <String, dynamic>{
        'action': action,
        ...payload,
      },
    );
  }

  List<BookingModel> _mapBookings(dynamic raw) {
    if (raw is! List) {
      return const <BookingModel>[];
    }

    return raw
        .whereType<Map>()
        .map((row) => _mapRowToBooking(Map<String, dynamic>.from(row)))
        .toList();
  }

  BookingModel _mapRowToBooking(Map<String, dynamic> row) {
    final map = <String, dynamic>{
      'bookingId': row['booking_id']?.toString() ?? '',
      'customerId': row['customer_id']?.toString() ?? '',
      'providerId': _asStringOrNull(row['provider_id']),
      'serviceId': _asStringOrNull(row['service_id']),
      'serviceCategory': row['service_category']?.toString() ?? 'other',
      'issueTitle': row['issue_title']?.toString() ?? '',
      'issueDescription': row['issue_description']?.toString() ?? '',
      'imageUrls': const <String>[],
      'address': row['address']?.toString() ?? '',
      'locationGeoPoint': null,
      'scheduledAt': _asInt(row['scheduled_at']),
      'createdAt': _asInt(row['created_at']),
      'status': row['status']?.toString() ?? 'pending',
      'isSOS': _asInt(row['is_sos']) == 1,
      'agreedPrice': _asIntOrNull(row['agreed_price']),
      'paymentMethod': 'cash',
      'paymentStatus': row['payment_status']?.toString() ?? 'pending',
      'providerNote': _asStringOrNull(row['provider_note']),
      'customerConfirmed': false,
      'cancellationReason': null,
      'customerName': _asStringOrNull(row['customer_name']),
      'customerPhone': null,
      'customerPhoto': null,
      'providerName': _asStringOrNull(row['provider_name']),
      'providerPhone': null,
      'providerPhoto': null,
    };

    return BookingModel.fromMap(map);
  }

  BookingChatMessage _mapRowToChatMessage(Map<String, dynamic> row) {
    return BookingChatMessage(
      messageId: row['message_id']?.toString() ?? '',
      bookingId: row['booking_id']?.toString() ?? '',
      senderId: row['sender_id']?.toString() ?? '',
      senderRole: row['sender_role']?.toString() ?? 'customer',
      recipientId: _asStringOrNull(row['recipient_id']),
      messageText: row['message_text']?.toString() ?? '',
      isRead: _asInt(row['is_read']) == 1,
      sentAt: DateTime.fromMillisecondsSinceEpoch(_asInt(row['sent_at'])),
    );
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

    return _asInt(value);
  }

  String? _asStringOrNull(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString();
    return text.isEmpty ? null : text;
  }
}

class ProviderEarningsSummary {
  final int totalEarned;
  final int pendingAmount;
  final int walletBalance;
  final int completedJobs;
  final int activeJobs;

  const ProviderEarningsSummary({
    required this.totalEarned,
    required this.pendingAmount,
    required this.walletBalance,
    required this.completedJobs,
    required this.activeJobs,
  });
}

class BookingChatMessage {
  final String messageId;
  final String bookingId;
  final String senderId;
  final String senderRole;
  final String? recipientId;
  final String messageText;
  final bool isRead;
  final DateTime sentAt;

  const BookingChatMessage({
    required this.messageId,
    required this.bookingId,
    required this.senderId,
    required this.senderRole,
    required this.recipientId,
    required this.messageText,
    required this.isRead,
    required this.sentAt,
  });

  bool get isFromProvider => senderRole == 'provider';
}
