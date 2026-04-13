import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/local_booking_service.dart';
import '../../../core/database/local_marketplace_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class ServiceAnalyticsScreen extends ConsumerWidget {
  final String serviceId;
  const ServiceAnalyticsScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Service Analytics')),
      body: user == null
          ? const EmptyStateWidget(
              title: 'Sign In Required',
              subtitle: 'Please sign in to view analytics.',
              icon: Icons.lock_outline,
            )
          : FutureBuilder<MarketplaceServiceItem?>(
              future:
                  LocalMarketplaceService.instance.getServiceById(serviceId),
              builder: (context, serviceSnapshot) {
                if (serviceSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: AppLoadingIndicator());
                }

                final service = serviceSnapshot.data;
                if (service == null) {
                  return const EmptyStateWidget(
                    title: 'Service Not Found',
                    subtitle: 'Unable to load analytics for this service.',
                    icon: Icons.analytics_outlined,
                  );
                }

                return FutureBuilder<List<BookingModel>>(
                  future:
                      LocalBookingService.instance.getProviderJobs(user.uid),
                  builder: (context, jobsSnapshot) {
                    final jobs = jobsSnapshot.data ?? const <BookingModel>[];
                    final serviceJobs = jobs
                        .where((job) => job.serviceId == service.serviceId)
                        .toList();

                    final totalLeads = serviceJobs.length;
                    final active =
                        serviceJobs.where((job) => job.isActive).length;
                    final completed =
                        serviceJobs.where((job) => job.status == 'paid').length;
                    final revenue = serviceJobs
                        .where((job) => job.status == 'paid')
                        .fold<int>(
                            0, (sum, job) => sum + (job.agreedPrice ?? 0));

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          service.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service.categoryLabel,
                          style: const TextStyle(
                              color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _MetricCard(
                              title: 'Total Leads',
                              value: '$totalLeads',
                              color: AppColors.primary,
                            ),
                            _MetricCard(
                              title: 'Active Jobs',
                              value: '$active',
                              color: AppColors.warning,
                            ),
                            _MetricCard(
                              title: 'Completed',
                              value: '$completed',
                              color: AppColors.success,
                            ),
                            _MetricCard(
                              title: 'Revenue',
                              value: 'Rs. $revenue',
                              color: AppColors.secondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Recent Jobs',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        if (serviceJobs.isEmpty)
                          const EmptyStateWidget(
                            title: 'No Jobs Yet',
                            subtitle: 'Jobs for this service will appear here.',
                            icon: Icons.assignment_outlined,
                          )
                        else
                          ...serviceJobs.take(10).map(
                                (job) => Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    title: Text(job.issueTitle),
                                    subtitle:
                                        Text(job.customerName ?? 'Customer'),
                                    trailing: Text(
                                      job.displayStatus,
                                      style: TextStyle(
                                        color: job.isFinished
                                            ? AppColors.success
                                            : AppColors.warning,
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: color.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
