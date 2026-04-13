import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/local_booking_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userDataAsync = ref.watch(currentUserDataProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const EmptyStateWidget(
          title: 'Sign In Required',
          subtitle: 'Sign in to view notifications.',
          icon: Icons.notifications_off_outlined,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: userDataAsync.when(
        data: (userData) {
          final role = userData?.role ?? 'customer';
          final future = role == 'provider'
              ? LocalBookingService.instance.getProviderJobs(user.uid)
              : LocalBookingService.instance.getCustomerBookings(user.uid);

          return FutureBuilder<List<BookingModel>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: AppLoadingIndicator());
              }

              final items = snapshot.data ?? const <BookingModel>[];
              if (items.isEmpty) {
                return const EmptyStateWidget(
                  title: 'No Notifications',
                  subtitle: 'You are all caught up for now.',
                  icon: Icons.notifications_none,
                );
              }

              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final booking = items[index];
                  final details = _buildNotificationText(booking, role);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: details.color.withValues(alpha: 0.12),
                      child: Icon(details.icon, color: details.color),
                    ),
                    title: Text(details.title),
                    subtitle: Text(details.subtitle),
                    trailing: Text(
                      '${booking.createdAt.day}/${booking.createdAt.month}',
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (error, _) => const EmptyStateWidget(
          title: 'Unable to load',
          subtitle: 'Please try again shortly.',
          icon: Icons.error_outline,
        ),
      ),
    );
  }
}

_NotificationDetails _buildNotificationText(BookingModel booking, String role) {
  if (role == 'provider') {
    if (booking.providerId == null) {
      return const _NotificationDetails(
        title: 'New Lead Available',
        subtitle: 'A customer needs urgent help nearby.',
        icon: Icons.new_releases_outlined,
        color: AppColors.primary,
      );
    }

    return _NotificationDetails(
      title: 'Job Update: ${booking.issueTitle}',
      subtitle: 'Current status: ${booking.displayStatus}',
      icon: Icons.assignment_outlined,
      color: AppColors.info,
    );
  }

  if (booking.providerId == null) {
    return const _NotificationDetails(
      title: 'Booking Submitted',
      subtitle: 'Providers are reviewing your request.',
      icon: Icons.hourglass_bottom_outlined,
      color: AppColors.warning,
    );
  }

  return _NotificationDetails(
    title: 'Booking Update',
    subtitle: 'Status changed to ${booking.displayStatus}',
    icon: Icons.notifications_active_outlined,
    color: AppColors.success,
  );
}

class _NotificationDetails {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _NotificationDetails({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
