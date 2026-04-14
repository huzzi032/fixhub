import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/local_booking_service.dart';
import '../../../core/database/local_marketplace_service.dart';
import '../../../core/database/local_settings_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<List<_NotificationItem>> _loadNotificationItems({
    required String uid,
    required String role,
    required UserNotificationSettings settings,
  }) async {
    final items = <_NotificationItem>[];

    if (settings.bookingUpdates) {
      final bookings = role == 'provider'
          ? await LocalBookingService.instance.getProviderJobs(uid)
          : await LocalBookingService.instance.getCustomerBookings(uid);

      items.addAll(
        bookings.map((booking) {
          final details = _buildBookingNotificationText(booking, role);
          return _NotificationItem(
            title: details.title,
            subtitle: details.subtitle,
            icon: details.icon,
            color: details.color,
            createdAt: booking.createdAt,
            booking: booking,
          );
        }),
      );
    }

    if (role == 'customer' &&
        (settings.promotions || settings.neighborhoodDeals)) {
      final deals = await LocalMarketplaceService.instance.getFeaturedDeals(
        userId: uid,
        limit: 8,
      );

      for (final deal in deals) {
        if (settings.neighborhoodDeals) {
          items.add(
            _NotificationItem(
              title: 'Neighborhood Deal: ${deal.categoryLabel}',
              subtitle:
                  '${deal.discountPercent}% off in ${deal.area}, ${deal.city}',
              icon: Icons.people_outline,
              color: AppColors.secondary,
              createdAt: deal.createdAt,
              isDealItem: true,
            ),
          );
        }

        if (settings.promotions) {
          items.add(
            _NotificationItem(
              title: 'Promotion Available',
              subtitle:
                  'Save ${deal.discountPercent}% on ${deal.categoryLabel} services.',
              icon: Icons.local_offer_outlined,
              color: AppColors.primary,
              createdAt: deal.createdAt,
              isDealItem: true,
            ),
          );
        }
      }
    }

    if (role == 'provider' && settings.promotions) {
      items.add(
        _NotificationItem(
          title: 'Promote Your Services',
          subtitle: 'Create neighborhood deals to attract more customers.',
          icon: Icons.campaign_outlined,
          color: AppColors.primary,
          createdAt: DateTime.now(),
          isDealItem: true,
          isProviderPromotion: true,
        ),
      );
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

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
          return FutureBuilder<UserNotificationSettings>(
            future:
                LocalSettingsService.instance.getNotificationSettings(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: AppLoadingIndicator());
              }

              final settings = snapshot.data ??
                  const UserNotificationSettings(
                    bookingUpdates: true,
                    promotions: true,
                    neighborhoodDeals: true,
                  );

              return FutureBuilder<List<_NotificationItem>>(
                future: _loadNotificationItems(
                  uid: user.uid,
                  role: role,
                  settings: settings,
                ),
                builder: (context, itemsSnapshot) {
                  if (itemsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: AppLoadingIndicator());
                  }

                  if (itemsSnapshot.hasError) {
                    return const EmptyStateWidget(
                      title: 'Unable to load notifications',
                      subtitle: 'Please try again shortly.',
                      icon: Icons.error_outline,
                    );
                  }

                  final items =
                      itemsSnapshot.data ?? const <_NotificationItem>[];

                  if (items.isEmpty) {
                    if (!settings.bookingUpdates &&
                        !settings.promotions &&
                        !settings.neighborhoodDeals) {
                      return const EmptyStateWidget(
                        title: 'Notifications Disabled',
                        subtitle:
                            'All notification types are turned off in profile settings.',
                        icon: Icons.notifications_off_outlined,
                      );
                    }

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
                      final item = items[index];
                      return ListTile(
                        onTap: () {
                          if (item.isDealItem) {
                            if (item.isProviderPromotion) {
                              context.goToCreateDeal();
                            } else {
                              context.goToDeals();
                            }
                            return;
                          }

                          final booking = item.booking;
                          if (booking == null) {
                            return;
                          }

                          if (role == 'provider') {
                            context.goToProviderJobDetail(booking.bookingId);
                            return;
                          }

                          if (booking.isActive) {
                            context.goToBookingTracking(booking.bookingId);
                          } else {
                            context.goToBookingDetail(booking.bookingId);
                          }
                        },
                        leading: CircleAvatar(
                          backgroundColor: item.color.withValues(alpha: 0.12),
                          child: Icon(item.icon, color: item.color),
                        ),
                        title: Text(item.title),
                        subtitle: Text(item.subtitle),
                        trailing: Text(
                          '${item.createdAt.day}/${item.createdAt.month}',
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

_NotificationDetails _buildBookingNotificationText(
  BookingModel booking,
  String role,
) {
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

class _NotificationItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DateTime createdAt;
  final BookingModel? booking;
  final bool isDealItem;
  final bool isProviderPromotion;

  const _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.createdAt,
    this.booking,
    this.isDealItem = false,
    this.isProviderPromotion = false,
  });
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
