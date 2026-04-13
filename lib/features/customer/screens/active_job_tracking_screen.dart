import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/local_booking_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class ActiveJobTrackingScreen extends ConsumerWidget {
  final String bookingId;
  const ActiveJobTrackingScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Track Job')),
      body: FutureBuilder<BookingModel?>(
        future: LocalBookingService.instance.getBookingById(bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoadingIndicator());
          }

          final booking = snapshot.data;
          if (booking == null) {
            return const EmptyStateWidget(
              title: 'Booking Not Found',
              subtitle: 'Unable to track this job right now.',
              icon: Icons.location_off,
            );
          }

          if (user != null && booking.customerId != user.uid) {
            return const EmptyStateWidget(
              title: 'Access Restricted',
              subtitle: 'You can only track your own booking.',
              icon: Icons.lock_outline,
            );
          }
          final progressValue = _statusProgress(booking.status);
          final etaText = _statusEtaText(booking);
          final nextMilestone = _nextMilestone(booking.status);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.issueTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StatusChip(
                        status: Helpers.getStatusDisplayName(booking.status),
                        color: Helpers.getStatusColor(booking.status),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Provider: ${booking.providerName ?? 'Awaiting assignment'}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Address: ${booking.address}',
                        style:
                            const TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Progress',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progressValue / 100,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(999),
                        backgroundColor: AppColors.background,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$progressValue% complete',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        etaText,
                        style:
                            const TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                      if (nextMilestone != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Next: $nextMilestone',
                          style: const TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (booking.providerId != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.goToBookingChat(booking.bookingId),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat with Provider'),
                  ),
                ),
              const SizedBox(height: 8),
              const SizedBox(height: 16),
              if (booking.status == 'completed')
                ElevatedButton(
                  onPressed: () =>
                      context.goToPaymentConfirmation(booking.bookingId),
                  child: const Text('Proceed to Payment'),
                ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => context.goToBookingDetail(booking.bookingId),
                child: const Text('View Full Booking Details'),
              ),
            ],
          );
        },
      ),
    );
  }
}

int _statusProgress(String status) {
  switch (status) {
    case 'pending':
      return 10;
    case 'accepted':
      return 30;
    case 'enRoute':
      return 50;
    case 'inProgress':
      return 75;
    case 'completed':
      return 90;
    case 'paid':
      return 100;
    default:
      return 0;
  }
}

String _statusEtaText(BookingModel booking) {
  final now = DateTime.now();
  final difference = booking.scheduledAt.difference(now);

  if (booking.status == 'paid') {
    return 'Job closed and payment completed.';
  }

  if (booking.status == 'completed') {
    return 'Service completed. Please confirm payment.';
  }

  if (difference.inMinutes > 0) {
    return 'Estimated start in ${difference.inMinutes} minutes.';
  }

  if (booking.status == 'inProgress') {
    return 'Provider is actively working on your request.';
  }

  return 'You will receive status updates in real time.';
}

String? _nextMilestone(String status) {
  switch (status) {
    case 'pending':
      return 'Provider accepts your booking';
    case 'accepted':
      return 'Provider marks On the Way';
    case 'enRoute':
      return 'Provider starts work';
    case 'inProgress':
      return 'Provider completes service';
    case 'completed':
      return 'You confirm payment';
    default:
      return null;
  }
}
