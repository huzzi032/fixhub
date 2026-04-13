import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/local_booking_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class PaymentConfirmationScreen extends ConsumerWidget {
  final String bookingId;
  const PaymentConfirmationScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Payment')),
      body: FutureBuilder(
        future: LocalBookingService.instance.getBookingById(bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoadingIndicator());
          }

          final booking = snapshot.data;
          if (booking == null) {
            return const EmptyStateWidget(
              title: 'Booking Not Found',
              subtitle: 'Unable to process payment for this booking.',
              icon: Icons.payments_outlined,
            );
          }

          if (user != null && booking.customerId != user.uid) {
            return const EmptyStateWidget(
              title: 'Access Restricted',
              subtitle: 'You can only complete payment for your own booking.',
              icon: Icons.lock_outline,
            );
          }

          final amount = booking.agreedPrice ?? 0;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.issueTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text('Provider: ${booking.providerName ?? 'Provider'}'),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Text(
                          'Payable Amount',
                          style: TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        Text(
                          'Rs. $amount',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'This marks the service as paid and updates the provider wallet.',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: booking.providerId == null
                      ? null
                      : () => context.goToBookingChat(booking.bookingId),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat with Provider'),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await LocalBookingService.instance.markPaymentCollected(
                        bookingId: booking.bookingId,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment marked as received.'),
                          ),
                        );
                        context.goToReview(<String, dynamic>{
                          'bookingId': booking.bookingId,
                          'providerId': booking.providerId ?? '',
                          'providerName': booking.providerName ?? 'Provider',
                          'providerPhoto': booking.providerPhoto,
                        });
                      }
                    },
                    child: const Text('Confirm Cash Payment'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
