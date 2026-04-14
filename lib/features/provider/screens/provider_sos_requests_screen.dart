import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/local_booking_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';

class ProviderSosRequestsScreen extends ConsumerStatefulWidget {
  const ProviderSosRequestsScreen({super.key});

  @override
  ConsumerState<ProviderSosRequestsScreen> createState() =>
      _ProviderSosRequestsScreenState();
}

class _ProviderSosRequestsScreenState
    extends ConsumerState<ProviderSosRequestsScreen> {
  int _refreshTick = 0;
  String? _processingBookingId;

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _refreshTick++;
    });
  }

  Future<void> _acceptSosAndChat({
    required BookingModel lead,
    required String providerId,
    required String providerName,
  }) async {
    if (_processingBookingId == lead.bookingId) {
      return;
    }

    setState(() {
      _processingBookingId = lead.bookingId;
    });

    try {
      await LocalBookingService.instance.acceptLead(
        bookingId: lead.bookingId,
        providerId: providerId,
        providerName: providerName,
        quoteAmount: lead.agreedPrice ?? 1500,
        providerNote: 'SOS accepted. Reaching customer urgently.',
      );

      if (!mounted) return;
      context.goToBookingChat(lead.bookingId);
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().toLowerCase();
      if (message.contains('already been accepted') ||
          message.contains('no longer available')) {
        try {
          final latest =
              await LocalBookingService.instance.getBookingById(lead.bookingId);
          if (!mounted) return;

          if (latest != null && latest.providerId == providerId) {
            context.goToBookingChat(lead.bookingId);
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This SOS request has already been accepted.'),
            ),
          );
          await _refresh();
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This SOS request has already been accepted.'),
            ),
          );
          await _refresh();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingBookingId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userData = ref.watch(currentUserDataProvider).asData?.value;
    final providerName = (userData?.name.trim().isNotEmpty == true)
        ? userData!.name.trim()
        : (user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!.trim()
            : 'Provider');

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
        title: const Text('SOS Requests'),
      ),
      body: user == null
          ? const EmptyStateWidget(
              title: 'Sign In Required',
              subtitle: 'Please sign in as provider to view SOS requests.',
              icon: Icons.lock_outline,
            )
          : FutureBuilder<List<BookingModel>>(
              key: ValueKey<int>(_refreshTick),
              future: LocalBookingService.instance.getIncomingLeads(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: AppLoadingIndicator());
                }

                final leads = snapshot.data ?? const <BookingModel>[];
                final sosLeads = leads.where((lead) => lead.isSOS).toList();

                if (sosLeads.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        EmptyStateWidget(
                          title: 'No SOS Requests',
                          subtitle:
                              'Emergency requests will appear here when available.',
                          icon: Icons.sos,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: sosLeads.length,
                    itemBuilder: (context, index) {
                      final lead = sosLeads[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: AppColors.sosRed.withValues(alpha: 0.05),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Text(
                            lead.issueTitle,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Helpers.getCategoryDisplayName(
                                    lead.serviceCategory,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(lead.address),
                                const SizedBox(height: 4),
                                Text(
                                  _timeAgo(lead.createdAt),
                                  style: const TextStyle(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: ElevatedButton(
                            onPressed: _processingBookingId == lead.bookingId
                                ? null
                                : () => _acceptSosAndChat(
                                      lead: lead,
                                      providerId: user.uid,
                                      providerName: providerName,
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.sosRed,
                              foregroundColor: Colors.white,
                            ),
                            child: _processingBookingId == lead.bookingId
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Accept & Chat'),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
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
