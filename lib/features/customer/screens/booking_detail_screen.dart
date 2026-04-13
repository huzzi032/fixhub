import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/local_booking_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
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
              subtitle: 'This booking may have been removed.',
              icon: Icons.search_off,
            );
          }

          if (user != null && booking.customerId != user.uid) {
            return const EmptyStateWidget(
              title: 'Access Restricted',
              subtitle: 'You can only view your own bookings.',
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
                              booking.issueTitle,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          StatusChip(
                            status:
                                Helpers.getStatusDisplayName(booking.status),
                            color: Helpers.getStatusColor(booking.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(booking.issueDescription),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.category_outlined,
                        label: 'Category',
                        value: Helpers.getCategoryDisplayName(
                            booking.serviceCategory),
                      ),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Address',
                        value: booking.address,
                      ),
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Scheduled',
                        value:
                            '${booking.scheduledAt.day}/${booking.scheduledAt.month}/${booking.scheduledAt.year} ${booking.scheduledAt.hour.toString().padLeft(2, '0')}:${booking.scheduledAt.minute.toString().padLeft(2, '0')}',
                      ),
                      _InfoRow(
                        icon: Icons.payments_outlined,
                        label: 'Amount',
                        value: booking.agreedPrice == null
                            ? 'Pending quote'
                            : 'Rs. ${booking.agreedPrice}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (booking.isActive)
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () =>
                        context.goToBookingTracking(booking.bookingId),
                    child: const Text('Track Job'),
                  ),
                ),
              if (booking.status == 'completed') ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () =>
                        context.goToPaymentConfirmation(booking.bookingId),
                    child: const Text('Confirm Payment'),
                  ),
                ),
              ],
              if (booking.status == 'paid') ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => context.goToReview(<String, dynamic>{
                      'bookingId': booking.bookingId,
                      'providerId': booking.providerId ?? '',
                      'providerName': booking.providerName ?? 'Provider',
                      'providerPhoto': booking.providerPhoto,
                    }),
                    child: const Text('Leave Review'),
                  ),
                ),
              ],
              if (booking.providerId != null &&
                  booking.status != 'cancelled') ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => context.goToBookingChat(booking.bookingId),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat with Provider'),
                  ),
                ),
              ],
              if (booking.canCancel) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () async {
                      await LocalBookingService.instance.updateBookingStatus(
                        bookingId: booking.bookingId,
                        status: 'cancelled',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Booking cancelled.')),
                        );
                        context.goToOrders();
                      }
                    },
                    child: const Text('Cancel Booking'),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => context.goToDispute(booking.bookingId),
                icon: const Icon(Icons.report_problem_outlined),
                label: const Text('Report an Issue'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
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
