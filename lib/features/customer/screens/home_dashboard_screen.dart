import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/local_booking_service.dart';
import '../../../core/database/local_marketplace_service.dart';
import '../../../core/database/local_settings_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() =>
      _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  int _locationRefreshTick = 0;

  Future<void> _editLocation(String initialValue, String uid) async {
    final controller = TextEditingController(text: initialValue);

    final nextValue = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Set Your Location'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Example: Gulshan, Karachi',
              labelText: 'Location',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (nextValue == null || nextValue.isEmpty) {
      return;
    }

    await LocalSettingsService.instance.setLocationLabel(uid, nextValue);
    if (!mounted) return;

    setState(() {
      _locationRefreshTick++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar(context)),
            SliverToBoxAdapter(
              child: _buildLocationBar(context, currentUser?.uid),
            ),
            SliverToBoxAdapter(child: _buildSearchBar(context)),
            SliverToBoxAdapter(
              child: _buildActiveBookingBanner(context, currentUser?.uid),
            ),
            SliverToBoxAdapter(child: _buildCategoriesSection(context)),
            SliverToBoxAdapter(
              child: _buildDealsSection(context, currentUser?.uid),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.goToSOS(),
        backgroundColor: AppColors.sosRed,
        icon: const Icon(Icons.emergency, color: Colors.white),
        label: const Text(
          'SOS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(context, 0),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.home_repair_service, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          const Text(
            AppConstants.appName,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Stack(
            children: [
              IconButton(
                onPressed: () => context.goToNotifications(),
                icon: const Icon(Icons.notifications_outlined),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBar(BuildContext context, String? uid) {
    if (uid == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<String>(
      key: ValueKey<int>(_locationRefreshTick),
      future: LocalSettingsService.instance.getLocationLabel(uid),
      builder: (context, snapshot) {
        final location = snapshot.data ?? 'Karachi, Sindh';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            onTap: () => _editLocation(location, uid),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Location',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          location,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => context.goToSearch(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: AppColors.onSurfaceVariant),
              SizedBox(width: 12),
              Text(
                'Search for services...',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveBookingBanner(BuildContext context, String? uid) {
    if (uid == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<BookingModel>>(
      future: LocalBookingService.instance.getCustomerBookings(uid),
      builder: (context, snapshot) {
        final activeBookings = (snapshot.data ?? const <BookingModel>[])
            .where((item) => item.isActive);

        if (activeBookings.isEmpty) {
          return const SizedBox.shrink();
        }

        final booking = activeBookings.first;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            onTap: () => context.goToBookingTracking(booking.bookingId),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.handyman, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Active Booking',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          booking.issueTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            Helpers.getStatusDisplayName(booking.status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    final categories = <Map<String, Object>>[
      <String, Object>{
        'key': 'plumber',
        'name': 'Plumber',
        'icon': Icons.plumbing
      },
      <String, Object>{
        'key': 'electrician',
        'name': 'Electrician',
        'icon': Icons.electrical_services,
      },
      <String, Object>{
        'key': 'carpenter',
        'name': 'Carpenter',
        'icon': Icons.chair
      },
      <String, Object>{
        'key': 'painter',
        'name': 'Painter',
        'icon': Icons.format_paint
      },
      <String, Object>{
        'key': 'car_mechanic',
        'name': 'Car Mechanic',
        'icon': Icons.car_repair
      },
      <String, Object>{
        'key': 'ac_repair',
        'name': 'AC Repair',
        'icon': Icons.ac_unit
      },
      <String, Object>{
        'key': 'cleaning',
        'name': 'Cleaning',
        'icon': Icons.cleaning_services
      },
      <String, Object>{
        'key': 'search',
        'name': 'More',
        'icon': Icons.more_horiz
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Categories'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final key = category['key']! as String;
              return _CategoryItem(
                name: category['name']! as String,
                icon: category['icon']! as IconData,
                onTap: () {
                  if (key == 'search') {
                    context.goToSearch();
                    return;
                  }

                  context.goToCategory(key);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDealsSection(BuildContext context, String? uid) {
    if (uid == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<NeighborhoodDealItem>>(
      future: LocalMarketplaceService.instance
          .getFeaturedDeals(userId: uid, limit: 6),
      builder: (context, snapshot) {
        final deals = snapshot.data ?? const <NeighborhoodDealItem>[];

        if (deals.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Neighborhood Deals',
              actionText: 'See All',
              onAction: () => context.goToDeals(),
            ),
            SizedBox(
              height: 170,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: deals.length,
                itemBuilder: (context, index) {
                  final deal = deals[index];
                  return _DealCard(
                    category: deal.categoryLabel,
                    area: deal.area,
                    discount: deal.discountPercent,
                    participants: deal.participantsCount,
                    minParticipants: deal.minParticipants,
                    onTap: () => context.goToDeals(),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            break;
          case 1:
            context.goToOrders();
            break;
          case 2:
            context.goToDeals();
            break;
          case 3:
            context.goToCustomerProfile();
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: 'My Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_offer_outlined),
          activeIcon: Icon(Icons.local_offer),
          label: 'Deals',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String name;
  final IconData icon;
  final VoidCallback? onTap;

  const _CategoryItem({
    required this.name,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final String category;
  final String area;
  final int discount;
  final int participants;
  final int minParticipants;
  final VoidCallback? onTap;

  const _DealCard({
    required this.category,
    required this.area,
    required this.discount,
    required this.participants,
    required this.minParticipants,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondary,
              AppColors.secondary.withValues(alpha: 0.8)
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$discount% OFF',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Text(
              category,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              area,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '$participants/$minParticipants joined',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
