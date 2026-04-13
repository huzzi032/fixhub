import 'dart:async';

import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../../shared/models/booking_model.dart';
import 'app_database.dart';

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
    final db = await AppDatabase.instance.database;
    final bookingId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'bookings',
      <String, Object?>{
        'booking_id': bookingId,
        'customer_id': customerId,
        'provider_id': null,
        'service_id': serviceId,
        'service_category': serviceCategory,
        'issue_title': issueTitle,
        'issue_description': issueDescription,
        'address': address,
        'scheduled_at': scheduledAt.millisecondsSinceEpoch,
        'created_at': now,
        'status': 'pending',
        'agreed_price': null,
        'payment_status': 'pending',
        'customer_name': customerName,
        'provider_name': null,
        'is_sos': isSOS ? 1 : 0,
      },
    );

    return bookingId;
  }

  Future<BookingModel?> getBookingById(String bookingId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'bookings',
      where: 'booking_id = ?',
      whereArgs: <Object>[bookingId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _mapRowToBooking(rows.first);
  }

  Future<List<BookingModel>> getCustomerBookings(String customerId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'bookings',
      where: 'customer_id = ?',
      whereArgs: <Object>[customerId],
      orderBy: 'created_at DESC',
    );

    return rows.map(_mapRowToBooking).toList();
  }

  Future<List<BookingModel>> getProviderActiveBookings(
      String providerId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'bookings',
      where: 'provider_id = ? AND status IN (?, ?, ?)',
      whereArgs: <Object>[providerId, 'accepted', 'enRoute', 'inProgress'],
      orderBy: 'created_at DESC',
    );

    return rows.map(_mapRowToBooking).toList();
  }

  Future<List<BookingModel>> getProviderJobs(String providerId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'bookings',
      where: 'provider_id = ?',
      whereArgs: <Object>[providerId],
      orderBy: 'created_at DESC',
    );

    return rows.map(_mapRowToBooking).toList();
  }

  Future<List<BookingModel>> getIncomingLeads() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'bookings',
      where: 'provider_id IS NULL AND status = ?',
      whereArgs: <Object>['pending'],
      orderBy: 'created_at DESC',
      limit: 20,
    );

    return rows.map(_mapRowToBooking).toList();
  }

  Future<void> acceptLead({
    required String bookingId,
    required String providerId,
    required String providerName,
    required int quoteAmount,
    String? providerNote,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'bookings',
      <String, Object?>{
        'provider_id': providerId,
        'provider_name': providerName,
        'agreed_price': quoteAmount,
        'provider_note': providerNote,
        'status': BookingStatus.accepted,
      },
      where: 'booking_id = ?',
      whereArgs: <Object>[bookingId],
    );
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'bookings',
      <String, Object?>{'status': status},
      where: 'booking_id = ?',
      whereArgs: <Object>[bookingId],
    );
  }

  Future<void> markPaymentCollected({
    required String bookingId,
  }) async {
    final db = await AppDatabase.instance.database;
    final booking = await getBookingById(bookingId);
    if (booking == null) {
      return;
    }

    await db.update(
      'bookings',
      <String, Object?>{
        'status': BookingStatus.paid,
        'payment_status': PaymentStatus.collected,
      },
      where: 'booking_id = ?',
      whereArgs: <Object>[bookingId],
    );

    final providerId = booking.providerId;
    final amount = booking.agreedPrice ?? 0;
    if (providerId != null && amount > 0) {
      await db.rawUpdate(
        '''
        UPDATE providers
        SET wallet_balance = wallet_balance + ?,
            earnings_total = earnings_total + ?
        WHERE user_id = ?
        ''',
        <Object>[amount, amount, providerId],
      );
    }
  }

  Future<int> getProviderWalletBalance(String providerId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'providers',
      columns: <String>['wallet_balance'],
      where: 'user_id = ?',
      whereArgs: <Object>[providerId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return 0;
    }

    return rows.first['wallet_balance'] as int? ?? 0;
  }

  Future<void> topUpWallet({
    required String providerId,
    required int amount,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.rawUpdate(
      'UPDATE providers SET wallet_balance = wallet_balance + ? WHERE user_id = ?',
      <Object>[amount, providerId],
    );
  }

  Future<ProviderEarningsSummary> getProviderEarnings(String providerId) async {
    final jobs = await getProviderJobs(providerId);
    final wallet = await getProviderWalletBalance(providerId);

    final totalEarned = jobs
        .where((job) => job.status == BookingStatus.paid)
        .fold<int>(0, (sum, job) => sum + (job.agreedPrice ?? 0));

    final pending = jobs
        .where((job) => job.status == BookingStatus.completed)
        .fold<int>(0, (sum, job) => sum + (job.agreedPrice ?? 0));

    final activeJobs = jobs.where((job) => job.isActive).length;

    return ProviderEarningsSummary(
      totalEarned: totalEarned,
      pendingAmount: pending,
      walletBalance: wallet,
      completedJobs:
          jobs.where((job) => job.status == BookingStatus.paid).length,
      activeJobs: activeJobs,
    );
  }

  Future<void> submitReview({
    required String bookingId,
    required String providerId,
    required String customerId,
    required int rating,
    String? comment,
  }) async {
    final db = await AppDatabase.instance.database;

    await db.insert(
      'reviews',
      <String, Object?>{
        'review_id': const Uuid().v4(),
        'booking_id': bookingId,
        'provider_id': providerId,
        'customer_id': customerId,
        'rating': rating,
        'comment': comment?.trim(),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
    );

    final ratingRow = await db.rawQuery(
      '''
      SELECT AVG(rating) AS avg_rating, COUNT(*) AS total_count
      FROM reviews
      WHERE provider_id = ?
      ''',
      <Object>[providerId],
    );

    final avg = (ratingRow.first['avg_rating'] as num?)?.toDouble() ?? 0;
    final count = (ratingRow.first['total_count'] as int?) ?? 0;

    await db.rawUpdate(
      '''
      UPDATE provider_services
      SET rating = ?, review_count = ?
      WHERE provider_id = ?
      ''',
      <Object>[avg, count, providerId],
    );
  }

  Future<void> sendBookingMessage({
    required String bookingId,
    required String senderId,
    required String message,
  }) async {
    final text = message.trim();
    if (text.isEmpty) {
      return;
    }

    if (text.length > 500) {
      throw ArgumentError('Message is too long');
    }

    final booking = await getBookingById(bookingId);
    if (booking == null) {
      throw ArgumentError('Booking not found');
    }

    final isCustomer = senderId == booking.customerId;
    final isAssignedProvider =
        booking.providerId != null && senderId == booking.providerId;

    if (!isCustomer && !isAssignedProvider) {
      throw StateError('User is not allowed to chat for this booking');
    }

    final senderRole = isCustomer ? 'customer' : 'provider';
    final recipientId = isCustomer ? booking.providerId : booking.customerId;

    final db = await AppDatabase.instance.database;
    await db.insert(
      'booking_chat_messages',
      <String, Object?>{
        'message_id': const Uuid().v4(),
        'booking_id': bookingId,
        'sender_id': senderId,
        'sender_role': senderRole,
        'recipient_id': recipientId,
        'message_text': text,
        'is_read': 0,
        'sent_at': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<List<BookingChatMessage>> getBookingMessages(
    String bookingId,
  ) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'booking_chat_messages',
      where: 'booking_id = ?',
      whereArgs: <Object>[bookingId],
      orderBy: 'sent_at ASC',
    );

    return rows.map(_mapRowToChatMessage).toList();
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
    final db = await AppDatabase.instance.database;
    await db.update(
      'booking_chat_messages',
      <String, Object?>{'is_read': 1},
      where: 'booking_id = ? AND recipient_id = ? AND is_read = 0',
      whereArgs: <Object>[bookingId, viewerId],
    );
  }

  BookingModel _mapRowToBooking(Map<String, Object?> row) {
    final map = <String, dynamic>{
      'bookingId': row['booking_id'],
      'customerId': row['customer_id'],
      'providerId': row['provider_id'],
      'serviceId': row['service_id'],
      'serviceCategory': row['service_category'],
      'issueTitle': row['issue_title'],
      'issueDescription': row['issue_description'],
      'imageUrls': <String>[],
      'address': row['address'],
      'locationGeoPoint': null,
      'scheduledAt': row['scheduled_at'],
      'createdAt': row['created_at'],
      'status': row['status'],
      'isSOS': (row['is_sos'] as int? ?? 0) == 1,
      'agreedPrice': row['agreed_price'],
      'paymentMethod': 'cash',
      'paymentStatus': row['payment_status'],
      'providerNote': row['provider_note'],
      'customerConfirmed': false,
      'cancellationReason': null,
      'customerName': row['customer_name'],
      'customerPhone': null,
      'customerPhoto': null,
      'providerName': row['provider_name'],
      'providerPhone': null,
      'providerPhoto': null,
    };

    return BookingModel.fromMap(map);
  }

  BookingChatMessage _mapRowToChatMessage(Map<String, Object?> row) {
    return BookingChatMessage(
      messageId: row['message_id'] as String,
      bookingId: row['booking_id'] as String,
      senderId: row['sender_id'] as String,
      senderRole: row['sender_role'] as String? ?? 'customer',
      recipientId: row['recipient_id'] as String?,
      messageText: row['message_text'] as String? ?? '',
      isRead: (row['is_read'] as int? ?? 0) == 1,
      sentAt: DateTime.fromMillisecondsSinceEpoch(
        row['sent_at'] as int? ?? 0,
      ),
    );
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
