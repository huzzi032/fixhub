import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/local_booking_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class ActiveJobScreen extends ConsumerWidget {
  final String bookingId;
  const ActiveJobScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Active Job')),
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
              subtitle: 'Unable to load this job.',
              icon: Icons.assignment_late_outlined,
            );
          }

          if (user != null && job.providerId != user.uid) {
            return const EmptyStateWidget(
              title: 'Access Restricted',
              subtitle: 'You can only access your assigned jobs.',
              icon: Icons.lock_outline,
            );
          }

          final nextStatus = Helpers.getNextStatus(job.status);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.issueTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                StatusChip(
                  status: Helpers.getStatusDisplayName(job.status),
                  color: Helpers.getStatusColor(job.status),
                ),
                const SizedBox(height: 14),
                Text('Customer: ${job.customerName ?? 'Customer'}'),
                const SizedBox(height: 8),
                Text('Address: ${job.address}'),
                const SizedBox(height: 8),
                Text('Agreed Price: Rs. ${job.agreedPrice ?? 0}'),
                const SizedBox(height: 14),
                const Text(
                  'Issue Description',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(job.issueDescription),
                const Spacer(),
                if (nextStatus != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await LocalBookingService.instance.updateBookingStatus(
                          bookingId: job.bookingId,
                          status: nextStatus,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Status updated to ${Helpers.getStatusDisplayName(nextStatus)}',
                              ),
                            ),
                          );
                          context.goToActiveJob(job.bookingId);
                        }
                      },
                      child: Text(Helpers.getStatusActionLabel(job.status)),
                    ),
                  ),
                if (job.status == 'completed') ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () =>
                          context.goToPaymentReceived(job.bookingId),
                      child: const Text('Mark Payment Received'),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.goToBookingChat(job.bookingId),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat with Customer'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        context.goToProviderJobDetail(job.bookingId),
                    child: const Text('View Full Job Details'),
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
