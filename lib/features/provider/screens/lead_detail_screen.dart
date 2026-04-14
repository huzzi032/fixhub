import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/app_auth_user.dart';
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

  Future<void> _recoverJoinAndChat(
    BuildContext context,
    WidgetRef ref,
    AppAuthUser currentUser,
  ) async {
    final userData = ref.read(currentUserDataProvider).asData?.value;
    final providerName = (userData?.name.trim().isNotEmpty == true)
        ? userData!.name.trim()
        : (currentUser.displayName?.trim().isNotEmpty == true
            ? currentUser.displayName!.trim()
            : 'Provider');

    try {
      await LocalBookingService.instance.acceptLead(
        bookingId: bookingId,
        providerId: currentUser.uid,
        providerName: providerName,
        quoteAmount: 1500,
        providerNote: 'Accepted via lead access recovery.',
      );

      if (!context.mounted) return;
      context.goToBookingChat(bookingId);
    } catch (error) {
      if (!context.mounted) return;

      final message = error.toString().toLowerCase();
      if (message.contains('already been accepted') ||
          message.contains('no longer available')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This lead was accepted by another provider.'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

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

          if (snapshot.hasError) {
            final errorText = snapshot.error.toString();
            final normalizedError = errorText.toLowerCase();

            if (normalizedError.contains('forbidden for current user') ||
                normalizedError.contains('already been accepted') ||
                normalizedError.contains('no longer available')) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.sync_problem,
                      size: 56,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Lead Sync Issue',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Trying join can fix stale assignment and open chat with customer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    if (currentUser != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _recoverJoinAndChat(context, ref, currentUser),
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Join Lead & Open Chat'),
                        ),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.goToProviderDashboard(),
                        child: const Text('Back to Dashboard'),
                      ),
                    ),
                  ],
                ),
              );
            }

            return EmptyStateWidget(
              title: 'Unable to Open Lead',
              subtitle: errorText,
              icon: Icons.error_outline,
              buttonText: 'Back to Dashboard',
              onAction: () => context.goToProviderDashboard(),
            );
          }

          final lead = snapshot.data;
          if (lead == null) {
            return const EmptyStateWidget(
              title: 'Lead Not Found',
              subtitle: 'This lead may no longer be available.',
              icon: Icons.search_off,
            );
          }

          if (currentUser != null &&
              lead.providerId != null &&
              lead.providerId != currentUser.uid) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_search,
                    size: 56,
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Lead Ownership Mismatch',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'If this is your service booking, use Join Lead to continue with customer chat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _recoverJoinAndChat(context, ref, currentUser),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Join Lead & Open Chat'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.goToProviderDashboard(),
                      child: const Text('Back to Dashboard'),
                    ),
                  ),
                ],
              ),
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
                if (lead.isSOS) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.sosRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.sosRed.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.sos, color: AppColors.sosRed),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Emergency SOS request. Prioritize quick response and direct customer contact.',
                            style: TextStyle(
                              color: AppColors.sosRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _DetailItem(
                  icon: Icons.person_outline,
                  label: 'Customer',
                  value: lead.customerName ?? 'Customer',
                ),
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
                          try {
                            await LocalBookingService.instance.acceptLead(
                              bookingId: lead.bookingId,
                              providerId: currentUser.uid,
                              providerName: userData.name,
                              quoteAmount: 1500,
                              providerNote: 'Accepted with standard quote.',
                            );

                            if (context.mounted) {
                              final action = await showDialog<String>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Lead Accepted'),
                                  content: const Text(
                                    'You can now chat with the customer or open the active job view.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext)
                                              .pop('job'),
                                      child: const Text('Active Job'),
                                    ),
                                    FilledButton.icon(
                                      onPressed: () =>
                                          Navigator.of(dialogContext)
                                              .pop('chat'),
                                      icon:
                                          const Icon(Icons.chat_bubble_outline),
                                      label: const Text('Open Chat'),
                                    ),
                                  ],
                                ),
                              );

                              if (!context.mounted) {
                                return;
                              }

                              if (action == 'chat') {
                                context.goToBookingChat(lead.bookingId);
                                return;
                              }

                              context.goToActiveJob(lead.bookingId);
                            }
                          } catch (error) {
                            if (!context.mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
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
