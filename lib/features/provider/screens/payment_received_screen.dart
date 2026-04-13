import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/local_booking_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class PaymentReceivedScreen extends ConsumerWidget {
  final String bookingId;
  const PaymentReceivedScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Received')),
      body: FutureBuilder(
        future: LocalBookingService.instance.getBookingById(bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoadingIndicator());
          }

          final job = snapshot.data;
          if (job == null) {
            return const EmptyStateWidget(
              title: 'Job Not Found',
              subtitle: 'Unable to complete payment update.',
              icon: Icons.payments_outlined,
            );
          }

          if (user != null && job.providerId != user.uid) {
            return const EmptyStateWidget(
              title: 'Access Restricted',
              subtitle: 'You can only update payment for your own jobs.',
              icon: Icons.lock_outline,
            );
          }

          final alreadyPaid = job.paymentStatus == 'collected';

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.issueTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text('Customer: ${job.customerName ?? 'Customer'}'),
                const SizedBox(height: 8),
                Text('Amount: Rs. ${job.agreedPrice ?? 0}'),
                const SizedBox(height: 12),
                if (alreadyPaid)
                  const Chip(
                    label: Text('Payment already marked received'),
                    avatar: Icon(Icons.check_circle, color: AppColors.success),
                  ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => context.goToBookingChat(job.bookingId),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat with Customer'),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: alreadyPaid
                        ? null
                        : () async {
                            await LocalBookingService.instance
                                .markPaymentCollected(
                              bookingId: job.bookingId,
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Payment marked as received.'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              context.goToProviderJobDetail(job.bookingId);
                            }
                          },
                    child: const Text('Confirm Received'),
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
