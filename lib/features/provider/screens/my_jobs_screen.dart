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
  int _refreshTick = 0;

  Future<void> _refreshJobs() async {
    if (!mounted) return;
    setState(() {
      _refreshTick++;
    });
  }

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              return;
            }
            context.goToProviderDashboard();
          },
        ),
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
              key: ValueKey<int>(_refreshTick),
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
                      onRefresh: _refreshJobs,
                      onTap: (job) => context.goToActiveJob(job.bookingId),
                    ),
                    _JobList(
                      jobs: past,
                      emptyTitle: 'No Past Jobs',
                      emptySubtitle: 'Completed or paid jobs will appear here.',
                      onRefresh: _refreshJobs,
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
  final Future<void> Function() onRefresh;
  final ValueChanged<BookingModel> onTap;

  const _JobList({
    required this.jobs,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onRefresh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            EmptyStateWidget(
              title: emptyTitle,
              subtitle: emptySubtitle,
              icon: Icons.assignment_outlined,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                '${Helpers.getCategoryDisplayName(job.serviceCategory)} - ${job.issueTitle}',
              ),
              subtitle: Text(job.address),
              trailing: StatusChip(
                status: Helpers.getStatusDisplayName(job.status),
                color: Helpers.getStatusColor(job.status),
              ),
              onTap: () => onTap(job),
            ),
          );
        },
      ),
    );
  }
}
