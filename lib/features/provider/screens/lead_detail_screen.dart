import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/local_booking_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class LeadDetailScreen extends ConsumerWidget {
  final String bookingId;
  const LeadDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userDataAsync = ref.watch(currentUserDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lead Details')),
      body: FutureBuilder<BookingModel?>(
        future: LocalBookingService.instance.getBookingById(bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoadingIndicator());
          }

          final lead = snapshot.data;
          if (lead == null) {
            return const EmptyStateWidget(
              title: 'Lead Not Found',
              subtitle: 'This lead may no longer be available.',
              icon: Icons.search_off,
            );
          }

          if (lead.providerId != null && lead.providerId != currentUser?.uid) {
            return const EmptyStateWidget(
              title: 'Lead Already Taken',
              subtitle: 'Another provider has accepted this booking.',
              icon: Icons.lock_outline,
            );
          }

          final alreadyAcceptedByMe =
              lead.providerId != null && lead.providerId == currentUser?.uid;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lead.issueTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                StatusChip(
                  status: Helpers.getStatusDisplayName(lead.status),
                  color: Helpers.getStatusColor(lead.status),
                ),
                const SizedBox(height: 16),
                _DetailItem(
                  icon: Icons.category_outlined,
                  label: 'Category',
                  value: Helpers.getCategoryDisplayName(lead.serviceCategory),
                ),
                _DetailItem(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: lead.address,
                ),
                _DetailItem(
                  icon: Icons.schedule_outlined,
                  label: 'Scheduled',
                  value:
                      '${lead.scheduledAt.day}/${lead.scheduledAt.month}/${lead.scheduledAt.year} ${lead.scheduledAt.hour.toString().padLeft(2, '0')}:${lead.scheduledAt.minute.toString().padLeft(2, '0')}',
                ),
                const SizedBox(height: 10),
                const Text(
                  'Issue Details',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(lead.issueDescription),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: currentUser == null
                        ? null
                        : alreadyAcceptedByMe
                            ? () => context.goToActiveJob(lead.bookingId)
                            : () {
                                context.goToQuoteSubmission(<String, dynamic>{
                                  'bookingId': lead.bookingId,
                                  'customerName':
                                      lead.customerName ?? 'Customer',
                                  'issueTitle': lead.issueTitle,
                                });
                              },
                    child: Text(
                      alreadyAcceptedByMe ? 'Open Active Job' : 'Submit Quote',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (alreadyAcceptedByMe)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.goToBookingChat(lead.bookingId),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Chat with Customer'),
                    ),
                  ),
                if (alreadyAcceptedByMe) const SizedBox(height: 10),
                userDataAsync.maybeWhen(
                  data: (userData) {
                    if (userData == null ||
                        currentUser == null ||
                        alreadyAcceptedByMe) {
                      return const SizedBox.shrink();
                    }

                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          await LocalBookingService.instance.acceptLead(
                            bookingId: lead.bookingId,
                            providerId: currentUser.uid,
                            providerName: userData.name,
                            quoteAmount: 1500,
                            providerNote: 'Accepted with standard quote.',
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lead accepted successfully.'),
                              ),
                            );
                            context.goToActiveJob(lead.bookingId);
                          }
                        },
                        child: const Text('Quick Accept (Rs. 1500)'),
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
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
          ),
        ],
      ),
    );
  }
}
