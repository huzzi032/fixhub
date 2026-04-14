import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_booking_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<BookingModel> _bookings = <BookingModel>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() {
        _bookings = <BookingModel>[];
        _isLoading = false;
      });
      return;
    }

    final bookings =
        await LocalBookingService.instance.getCustomerBookings(user.uid);

    if (!mounted) return;

    setState(() {
      _bookings = bookings;
      _isLoading = false;
    });
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _isLoading = true;
    });
    await _loadBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              return;
            }
            context.goToCustomerHome();
          },
        ),
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: AppLoadingIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveOrders(),
                _buildPastOrders(),
                _buildCancelledOrders(),
              ],
            ),
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  Widget _buildActiveOrders() {
    final activeOrders =
        _bookings.where((booking) => booking.isActive).toList();

    if (activeOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            EmptyStateWidget(
              title: 'No Active Orders',
              subtitle: 'You don\'t have any active bookings at the moment',
              icon: Icons.assignment_outlined,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: activeOrders.length,
        itemBuilder: (context, index) {
          final order = activeOrders[index];
          return _OrderCard(
            id: order.bookingId,
            title: order.issueTitle,
            provider: order.providerName ?? 'Awaiting provider',
            status: order.status,
            date: order.createdAt,
            amount: order.agreedPrice ?? 0,
            onTap: () => context.goToBookingTracking(order.bookingId),
          );
        },
      ),
    );
  }

  Widget _buildPastOrders() {
    final pastOrders =
        _bookings.where((booking) => booking.isFinished).toList();

    if (pastOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            EmptyStateWidget(
              title: 'No Past Orders',
              subtitle: 'Your completed bookings will appear here',
              icon: Icons.history,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: pastOrders.length,
        itemBuilder: (context, index) {
          final order = pastOrders[index];
          return _OrderCard(
            id: order.bookingId,
            title: order.issueTitle,
            provider: order.providerName ?? 'N/A',
            status: order.status,
            date: order.createdAt,
            amount: order.agreedPrice ?? 0,
            onTap: () => context.goToBookingDetail(order.bookingId),
          );
        },
      ),
    );
  }

  Widget _buildCancelledOrders() {
    final cancelledOrders =
        _bookings.where((booking) => booking.isCancelled).toList();

    if (cancelledOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            EmptyStateWidget(
              title: 'No Cancelled Orders',
              subtitle: 'Your cancelled bookings will appear here',
              icon: Icons.cancel_outlined,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: cancelledOrders.length,
        itemBuilder: (context, index) {
          final order = cancelledOrders[index];
          return _OrderCard(
            id: order.bookingId,
            title: order.issueTitle,
            provider: order.providerName ?? 'N/A',
            status: order.status,
            date: order.createdAt,
            amount: order.agreedPrice ?? 0,
            onTap: () => context.goToBookingDetail(order.bookingId),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.goToCustomerHome();
            break;
          case 1:
            // Already on orders
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

class _OrderCard extends StatelessWidget {
  final String id;
  final String title;
  final String provider;
  final String status;
  final DateTime date;
  final int amount;
  final VoidCallback? onTap;

  const _OrderCard({
    required this.id,
    required this.title,
    required this.provider,
    required this.status,
    required this.date,
    required this.amount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Order ID
                  Text(
                    '#$id',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  // Status Chip
                  StatusChip(
                    status: Helpers.getStatusDisplayName(status),
                    color: Helpers.getStatusColor(status),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // Provider
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    provider,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date and Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${date.day}/${date.month}/${date.year}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Rs. $amount',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
