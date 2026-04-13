import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/local_booking_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class ProviderJobDetailScreen extends ConsumerWidget {
  final String bookingId;
  const ProviderJobDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: FutureBuilder<BookingModel?>(
        future: LocalBookingService.instance.getBookingById(bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoadingIndicator());
          }

          final job = snapshot.data;
          if (job == null) {
            return const EmptyStateWidget(
              title: 'Job Not Found',
              subtitle: 'This job may have been removed.',
              icon: Icons.search_off,
            );
          }

          if (user != null && job.providerId != user.uid) {
            return const EmptyStateWidget(
              title: 'Access Restricted',
              subtitle: 'You can only open your assigned jobs.',
              icon: Icons.lock_outline,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              job.issueTitle,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          StatusChip(
                            status: Helpers.getStatusDisplayName(job.status),
                            color: Helpers.getStatusColor(job.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(job.issueDescription),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Customer',
                        value: job.customerName ?? 'Customer',
                      ),
                      _InfoRow(label: 'Address', value: job.address),
                      _InfoRow(
                        label: 'Category',
                        value:
                            Helpers.getCategoryDisplayName(job.serviceCategory),
                      ),
                      _InfoRow(
                        label: 'Scheduled',
                        value:
                            '${job.scheduledAt.day}/${job.scheduledAt.month}/${job.scheduledAt.year}',
                      ),
                      _InfoRow(
                        label: 'Amount',
                        value: 'Rs. ${job.agreedPrice ?? 0}',
                      ),
                      _InfoRow(
                        label: 'Payment Status',
                        value: job.paymentStatus,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (job.isActive)
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => context.goToActiveJob(job.bookingId),
                    child: const Text('Open Active Job View'),
                  ),
                ),
              if (job.status == 'completed') ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => context.goToPaymentReceived(job.bookingId),
                    child: const Text('Mark Payment Received'),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => context.goToBookingChat(job.bookingId),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat with Customer'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AppColors.onSurface),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
