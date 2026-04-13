import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/local_booking_service.dart';
import '../../../core/database/local_settings_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class ProviderDashboardScreen extends ConsumerStatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  ConsumerState<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState
    extends ConsumerState<ProviderDashboardScreen> {
  int _onlineRefreshTick = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar(context)),
            SliverToBoxAdapter(
              child: _buildOnlineToggle(context, currentUser?.uid),
            ),
            SliverToBoxAdapter(
              child: _buildSummaryCards(context, currentUser?.uid),
            ),
            SliverToBoxAdapter(child: _buildIncomingLeads(context)),
            SliverToBoxAdapter(
              child: _buildActiveJobs(context, currentUser?.uid),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
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
            child: const Icon(Icons.handyman, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          const Text(
            'Provider Dashboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => context.goToCreateDeal(),
            icon: const Icon(Icons.local_offer_outlined),
          ),
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

  Widget _buildOnlineToggle(BuildContext context, String? providerId) {
    if (providerId == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<bool>(
      key: ValueKey<int>(_onlineRefreshTick),
      future: LocalSettingsService.instance.getProviderOnline(providerId),
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isOnline
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOnline ? AppColors.success : AppColors.outline,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isOnline
                        ? AppColors.success
                        : AppColors.onSurfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOnline ? 'You are Online' : 'You are Offline',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isOnline
                              ? AppColors.success
                              : AppColors.onSurface,
                        ),
                      ),
                      Text(
                        isOnline
                            ? 'You will receive new job requests'
                            : 'You won\'t receive new job requests',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isOnline,
                  onChanged: (value) async {
                    await LocalSettingsService.instance
                        .setProviderOnline(providerId, value);
                    if (!mounted) return;
                    setState(() {
                      _onlineRefreshTick++;
                    });
                  },
                  activeThumbColor: AppColors.success,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(BuildContext context, String? providerId) {
    if (providerId == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<ProviderEarningsSummary>(
      future: LocalBookingService.instance.getProviderEarnings(providerId),
      builder: (context, snapshot) {
        final summary = snapshot.data;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Active Jobs',
                  value: '${summary?.activeJobs ?? 0}',
                  icon: Icons.assignment,
                  color: AppColors.primary,
                  onTap: () => context.goToMyJobs(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Pending',
                  value: 'Rs. ${summary?.pendingAmount ?? 0}',
                  icon: Icons.schedule,
                  color: AppColors.warning,
                  onTap: () => context.goToEarnings(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Wallet',
                  value: 'Rs. ${summary?.walletBalance ?? 0}',
                  icon: Icons.wallet,
                  color: AppColors.secondary,
                  onTap: () => context.goToWallet(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIncomingLeads(BuildContext context) {
    return FutureBuilder<List<BookingModel>>(
      future: LocalBookingService.instance.getIncomingLeads(),
      builder: (context, snapshot) {
        final leads = snapshot.data ?? const <BookingModel>[];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: AppLoadingIndicator()),
          );
        }

        if (leads.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: EmptyStateWidget(
              title: 'No Incoming Leads',
              subtitle: 'New customer requests will appear here.',
              icon: Icons.notifications_none,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Incoming Leads',
              actionText: 'See All',
              onAction: () => context.goToMyJobs(),
            ),
            SizedBox(
              height: 180,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: leads.length,
                itemBuilder: (context, index) {
                  final lead = leads[index];
                  return _LeadCard(
                    category:
                        Helpers.getCategoryDisplayName(lead.serviceCategory),
                    issue: lead.issueTitle,
                    area: lead.address,
                    timeAgo: _timeAgo(lead.createdAt),
                    isSOS: lead.isSOS,
                    onTap: () => context.goToLeadDetail(lead.bookingId),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveJobs(BuildContext context, String? providerId) {
    if (providerId == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<BookingModel>>(
      future:
          LocalBookingService.instance.getProviderActiveBookings(providerId),
      builder: (context, snapshot) {
        final jobs = snapshot.data ?? const <BookingModel>[];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: AppLoadingIndicator()),
          );
        }

        if (jobs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: EmptyStateWidget(
              title: 'No Active Jobs',
              subtitle: 'Accepted jobs will appear here.',
              icon: Icons.assignment_outlined,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'My Active Jobs'),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return _ActiveJobCard(
                  customerName: job.customerName ?? 'Customer',
                  service: job.issueTitle,
                  status: job.status,
                  address: job.address,
                  onTap: () => context.goToActiveJob(job.bookingId),
                );
              },
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
            context.goToMyJobs();
            break;
          case 2:
            context.goToMyServices();
            break;
          case 3:
            context.goToEarnings();
            break;
          case 4:
            context.goToProviderOwnProfile();
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: 'My Jobs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.handyman_outlined),
          activeIcon: Icon(Icons.handyman),
          label: 'Services',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined),
          activeIcon: Icon(Icons.account_balance_wallet),
          label: 'Earnings',
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

String _timeAgo(DateTime createdAt) {
  final difference = DateTime.now().difference(createdAt);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
  if (difference.inHours < 24) return '${difference.inHours} h ago';
  return '${difference.inDays} d ago';
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final String category;
  final String issue;
  final String area;
  final String timeAgo;
  final bool isSOS;
  final VoidCallback? onTap;

  const _LeadCard({
    required this.category,
    required this.issue,
    required this.area,
    required this.timeAgo,
    this.isSOS = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSOS ? AppColors.sosRed.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSOS ? AppColors.sosRed : AppColors.outline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isSOS)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sosRed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'SOS',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              issue,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    area,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              timeAgo,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveJobCard extends StatelessWidget {
  final String customerName;
  final String service;
  final String status;
  final String address;
  final VoidCallback? onTap;

  const _ActiveJobCard({
    required this.customerName,
    required this.service,
    required this.status,
    required this.address,
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
                children: [
                  UserAvatar(name: customerName, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          service,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(
                    status: Helpers.getStatusDisplayName(status),
                    color: Helpers.getStatusColor(status),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
