import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/local_booking_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: user == null
          ? const EmptyStateWidget(
              title: 'Sign In Required',
              subtitle: 'Please sign in as provider to view earnings.',
              icon: Icons.lock_outline,
            )
          : FutureBuilder<ProviderEarningsSummary>(
              future:
                  LocalBookingService.instance.getProviderEarnings(user.uid),
              builder: (context, summarySnapshot) {
                if (summarySnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: AppLoadingIndicator());
                }

                final summary = summarySnapshot.data;
                if (summary == null) {
                  return const EmptyStateWidget(
                    title: 'No Earnings Data',
                    subtitle: 'Complete jobs to build your earnings history.',
                    icon: Icons.account_balance_wallet_outlined,
                  );
                }

                return FutureBuilder<List<BookingModel>>(
                  future:
                      LocalBookingService.instance.getProviderJobs(user.uid),
                  builder: (context, jobsSnapshot) {
                    final jobs = jobsSnapshot.data ?? const <BookingModel>[];
                    final paidJobs =
                        jobs.where((job) => job.status == 'paid').toList();

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _EarningCard(
                                title: 'Total Earned',
                                value: 'Rs. ${summary.totalEarned}',
                                color: AppColors.success,
                                icon: Icons.trending_up,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _EarningCard(
                                title: 'Pending',
                                value: 'Rs. ${summary.pendingAmount}',
                                color: AppColors.warning,
                                icon: Icons.pending_actions,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _EarningCard(
                                title: 'Wallet',
                                value: 'Rs. ${summary.walletBalance}',
                                color: AppColors.secondary,
                                icon: Icons.wallet,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _EarningCard(
                                title: 'Completed Jobs',
                                value: '${summary.completedJobs}',
                                color: AppColors.primary,
                                icon: Icons.assignment_turned_in,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => context.goToWallet(),
                            icon: const Icon(Icons.account_balance_wallet),
                            label: const Text('Manage Wallet'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Recent Paid Jobs',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (paidJobs.isEmpty)
                          const EmptyStateWidget(
                            title: 'No Paid Jobs Yet',
                            subtitle:
                                'Paid jobs will appear here once completed.',
                            icon: Icons.payments_outlined,
                          )
                        else
                          ...paidJobs.take(8).map(
                                (job) => Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    title: Text(job.issueTitle),
                                    subtitle:
                                        Text(job.customerName ?? 'Customer'),
                                    trailing: Text(
                                      'Rs. ${job.agreedPrice ?? 0}',
                                      style: const TextStyle(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}

class _EarningCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _EarningCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: color.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}
