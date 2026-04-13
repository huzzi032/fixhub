import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/local_booking_service.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class ProviderAcceptedViewScreen extends ConsumerWidget {
  final String bookingId;
  const ProviderAcceptedViewScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Provider Accepted')),
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
              subtitle: 'Unable to load provider details for this booking.',
              icon: Icons.person_off,
            );
          }

          if (user != null && booking.customerId != user.uid) {
            return const EmptyStateWidget(
              title: 'Access Restricted',
              subtitle: 'You can only access your own booking details.',
              icon: Icons.lock_outline,
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your request has been accepted',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const UserAvatar(name: 'Provider', size: 42),
                    title: Text(booking.providerName ?? 'Provider'),
                    subtitle: Text('Quote: Rs. ${booking.agreedPrice ?? 0}'),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Issue: ${booking.issueTitle}'),
                const SizedBox(height: 8),
                Text('Address: ${booking.address}'),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        context.goToBookingTracking(booking.bookingId),
                    child: const Text('Track Provider'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: booking.providerId == null
                        ? null
                        : () => context.goToBookingChat(booking.bookingId),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat with Provider'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        context.goToBookingDetail(booking.bookingId),
                    child: const Text('View Booking Details'),
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
