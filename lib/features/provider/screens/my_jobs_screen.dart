import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/local_booking_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class MyJobsScreen extends ConsumerStatefulWidget {
  const MyJobsScreen({super.key});

  @override
  ConsumerState<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends ConsumerState<MyJobsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: user == null
          ? const EmptyStateWidget(
              title: 'Sign In Required',
              subtitle: 'Please sign in as provider to view jobs.',
              icon: Icons.lock_outline,
            )
          : FutureBuilder<List<BookingModel>>(
              future: LocalBookingService.instance.getProviderJobs(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: AppLoadingIndicator());
                }

                final jobs = snapshot.data ?? const <BookingModel>[];
                final active = jobs.where((job) => job.isActive).toList();
                final past = jobs.where((job) => job.isFinished).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _JobList(
                      jobs: active,
                      emptyTitle: 'No Active Jobs',
                      emptySubtitle: 'Accepted jobs will appear here.',
                      onTap: (job) => context.goToActiveJob(job.bookingId),
                    ),
                    _JobList(
                      jobs: past,
                      emptyTitle: 'No Past Jobs',
                      emptySubtitle: 'Completed or paid jobs will appear here.',
                      onTap: (job) =>
                          context.goToProviderJobDetail(job.bookingId),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _JobList extends StatelessWidget {
  final List<BookingModel> jobs;
  final String emptyTitle;
  final String emptySubtitle;
  final ValueChanged<BookingModel> onTap;

  const _JobList({
    required this.jobs,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return EmptyStateWidget(
        title: emptyTitle,
        subtitle: emptySubtitle,
        icon: Icons.assignment_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(job.issueTitle),
            subtitle: Text(job.address),
            trailing: StatusChip(
              status: Helpers.getStatusDisplayName(job.status),
              color: Helpers.getStatusColor(job.status),
            ),
            onTap: () => onTap(job),
          ),
        );
      },
    );
  }
}
